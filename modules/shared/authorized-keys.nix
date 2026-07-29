{ lib, ... }:

{
  options.shared.authorizedKeys = lib.mkOption {
    description = "SSH public keys authorized across all hosts (personal machines).";
    type = lib.types.listOf lib.types.str;
    default = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMbJhk5H0h7Oi79LSHLWfuffv6uFcuXtm77kewxrwQsD znaniye@golf"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEtYBH7S5Hp8vvp4atduS6i8KWb22iuXZMnAYhvDIkCP znaniye@felix"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJq0MxaAmkwi516ttv8n+nxiEgifhZMgahDrEslu/XA6 znaniye@massan"
    ];
  };
}
