{ self, ... }:

final: prev: {

  zls = self.inputs.zls.packages.${prev.system}.default;

}
