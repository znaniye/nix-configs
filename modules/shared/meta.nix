{ config, lib, ... }:

{
  options.meta = {
    username = lib.mkOption {
      description = "Main username.";
      type = lib.types.str;
      default = config.home.username or "znaniye";
    };
    fullname = lib.mkOption {
      description = "Main user full name.";
      type = lib.types.str;
      default = "Samuel Silva";
    };
    email = lib.mkOption {
      description = "Main e-mail.";
      type = lib.types.str;
      default = "zn4niye@proton.me";
    };
    work-email = lib.mkOption {
      description = "Work e-mail.";
      type = lib.types.str;
      default = "samuel@ossystems.com.br";
    };
  };
}
