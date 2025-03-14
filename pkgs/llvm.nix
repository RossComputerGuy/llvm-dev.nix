{
  lib,
  stdenv,
  src,
  version,
  cmake,
  ninja,
  python3,
  projects ? { },
  runtimes ? { },
}:
let
  enabledProjects =
    let
      flattenProjects = lib.mapAttrs (_: proj: proj.enable);
      runtimeProjects = lib.attrValues (lib.mapAttrs (_: cfg: flattenProjects cfg.projects) runtimes);
    in
    lib.mapAttrs (
      name: value:
      let
        whereSet = lib.filter (set: set."${name}" or false) runtimeProjects;
        isSet = (lib.lists.length whereSet > 0) || value;
      in
      isSet
    ) (flattenProjects projects);
in
stdenv.mkDerivation (finalAttrs: {
  pname = "llvm";

  inherit src version;

  cmakeFlags =
    let
      cmakeProjectValue =
        cfg: lib.concatStringsSep ";" (lib.attrNames (lib.filterAttrs (_: s: s.enable) cfg));
    in
    [
      "-S"
      "../llvm"
      (lib.cmakeFeature "LLVM_ENABLE_PROJECTS" (cmakeProjectValue projects))
      (lib.cmakeFeature "LLVM_RUNTIME_TARGETS" (
        lib.concatStringsSep ";" (lib.attrValues (lib.mapAttrs (_: cfg: cfg.name) runtimes))
      ))
    ]
    ++ lib.flatten (
      lib.attrValues (
        lib.mapAttrs (
          _: cfg: lib.attrValues (lib.mapAttrs (key: value: "-D${key}=${value}") (cfg.cmakeFlags or { }))
        ) projects
      )
    )
    ++ lib.flatten (
      lib.attrValues (
        lib.mapAttrs (
          _: cfg:
          [
            (lib.cmakeFeature "RUNTIMES_${cfg.name}_LLVM_ENABLE_RUNTIMES" (cmakeProjectValue cfg.projects))
          ]
          ++ (lib.attrValues (
            lib.mapAttrs (key: value: "-DRUNTIMES_${cfg.name}_${key}=${value}") (cfg.cmakeFlags or { })
          ))
        ) runtimes
      )
    );

  nativeBuildInputs = [
    cmake
    ninja
    (python3.withPackages (
      pythonPackages: with pythonPackages; lib.optional enabledProjects.libc pyyaml
    ))
  ];

  passthru = {
    inherit projects runtimes;
  };
})
