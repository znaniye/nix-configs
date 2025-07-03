{ config, lib, ... }:

{
  options.nixos.desktop.locale.enable = lib.mkEnableOption "locale config" // {
    default = config.nixos.desktop.enable;
  };

  config = lib.mkIf config.nixos.desktop.locale.enable {
    # Select internationalisation properties.
    i18n = {
      defaultLocale = lib.mkDefault "pt_BR.UTF-8";
      extraLocaleSettings = {
        LC_ADDRESS = "pt_BR.UTF-8";
        LC_IDENTIFICATION = "pt_BR.UTF-8";
        LC_MEASUREMENT = "pt_BR.UTF-8";
        LC_MONETARY = "pt_BR.UTF-8";
        LC_NAME = "pt_BR.UTF-8";
        LC_NUMERIC = "pt_BR.UTF-8";
        LC_PAPER = "pt_BR.UTF-8";
        LC_TELEPHONE = "pt_BR.UTF-8";
        LC_TIME = "pt_BR.UTF-8";
      };
    };

    time.timeZone = lib.mkDefault "America/Sao_Paulo";
  };
}
