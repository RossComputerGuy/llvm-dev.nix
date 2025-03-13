{
  description = "Easy LLVM development with Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default-linux";
    llvm-project = {
      url = "github:llvm/llvm-project";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-parts,
    systems,
    ...
  }@inputs: flake-parts.lib.mkFlake { inherit inputs; } ({ inputs, ... }@top: {
    systems = import inputs.systems;

    imports = [
      inputs.flake-parts.flakeModules.flakeModules
      ./module/default.nix
    ];

    debug = true;

    flake.flakeModules.default = ./module/default.nix;

    llvm = {
      src = inputs.llvm-project.outPath;
      version = "21.0.0git";
    };
  });
}
