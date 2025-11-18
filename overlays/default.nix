{ self, ... }:

final: prev: {

  zls = self.inputs.zls.packages.${prev.stdenv.hostPlatform.system}.default;

}
