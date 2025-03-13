{
  lib,
  stdenv,
  projects ? { },
  runtimes ? { },
  src,
  version,
  newScope,
  ...
}@args:
let
  callPackage = newScope args;
in
{
  default = callPackage ./llvm.nix { };
}
