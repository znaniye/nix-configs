{ config, lib, ... }:
{
  options.nixos.desktop.sound.enable = lib.mkEnableOption "desktop sound config" // {
    default = config.nixos.desktop.enable;
  };

  config = lib.mkIf config.nixos.desktop.sound.enable {
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };
}
