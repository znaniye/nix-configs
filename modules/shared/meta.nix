{ lib, ... }:

{
  options.shared.meta = {
    email = lib.mkOption {
      default = "zn4niye@proton.me";
      description = "Main e-mail.";
      type = lib.types.str;
    };
    fullname = lib.mkOption {
      default = "Samuel Silva";
      description = "Main user full name.";
      type = lib.types.str;
    };
    username = lib.mkOption {
      default = "znaniye";
      description = "Main username.";
      type = lib.types.str;
    };
    work-email = lib.mkOption {
      default = "samuel@ossystems.com.br";
      description = "Work e-mail.";
      type = lib.types.str;
    };
  };
}
