{
  lib,
  runCommand,
  imagemagick,
  librsvg,
  python3,
  nixos-icons,
  dejavu_fonts,
  size ? 32,
  frames ? 12,
  glyphSize ? 10,
  glyphAdvance ? 6,
}:

let
  snowflake = "${nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
  font = "${dejavu_fonts}/share/fonts/truetype/DejaVuSans-Bold.ttf";
  monoFont = "${dejavu_fonts}/share/fonts/truetype/DejaVuSansMono-Bold.ttf";
  python = python3.withPackages (ps: [ ps.pillow ]);
  px = toString size;
in
runCommand "corne-screen-assets"
  {
    nativeBuildInputs = [
      imagemagick
      librsvg
      python
    ];

    meta = {
      description = "LVGL I1 artwork for the Corne OLEDs: Nix snowflake and a spinning lambda";
      license = lib.licenses.mit;
      platforms = lib.platforms.all;
    };
  }
  ''
    mkdir -p $out

    fit() {
      magick "$1" -crop "$2" +repage -resize ${px}x${px} \
        -background black -gravity center -extent ${px}x${px} \
        -negate -threshold 50% -rotate 90 "$3"
    }

    rsvg-convert -w 256 -h 256 -o nix-hi.png ${snowflake}
    magick nix-hi.png -alpha extract nix-mask.png
    fit nix-mask.png "$(magick nix-mask.png -format %@ info:)" nix.pbm

    for i in $(seq 0 ${toString (frames - 1)}); do
      magick -size 256x256 xc:black -fill white -font ${font} -pointsize 150 \
        -gravity center -annotate +0+0 'λ' \
        -virtual-pixel black -distort SRT "$((i * 360 / ${toString frames}))" \
        "hi$(printf %02d "$i").png"
    done

    magick hi*.png -evaluate-sequence max union.png
    box=$(magick union.png -format %@ info:)
    for f in hi*.png; do
      n=''${f#hi}
      fit "$f" "$box" "lambda''${n%.png}.pbm"
    done

    python3 ${./glyphs.py} --font ${monoFont} --size ${toString glyphSize} \
      --advance ${toString glyphAdvance} --out-dir glyphs

    python3 ${./pbm_to_lvgl.py} --invert --symbol art_nix_logo nix.pbm \
      >$out/art_nix_logo.c
    python3 ${./pbm_to_lvgl.py} --invert --symbol art_lambda \
      --array art_lambda_frames lambda*.pbm >$out/art_lambda.c
    python3 ${./pbm_to_lvgl.py} --invert --symbol art_glyph \
      --array art_glyphs glyphs/glyph*.pbm >$out/art_glyphs.c
  ''
