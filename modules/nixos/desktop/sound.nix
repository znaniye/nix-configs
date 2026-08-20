{ config, lib, ... }:
{
  config = lib.mkIf config.nixos.desktop.sound.enable {
    services.pipewire = {
      alsa.enable = true;
      alsa.support32Bit = true;
      enable = true;
      pulse.enable = true;
    };
  };
  options.nixos.desktop.sound.enable = lib.mkEnableOption "desktop sound config" // {
    default = config.nixos.desktop.enable;
  };
}
