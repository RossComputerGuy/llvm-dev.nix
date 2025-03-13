{ config, lib, withSystem, ... }@top:
let
  inherit (lib) mkEnableOption mkOption mkDefault mkMerge mkIf genAttrs types;

  cfg = config.llvm;

  projectOpts = types.submodule ({ config, ... }: {
    options =
    let
      mkCMakeFlags = name: mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = ''
          CMake flags for ${name}
        '';
      };

      mkSubproject = name: {
        enable = mkEnableOption name;
        cmakeFlags = mkCMakeFlags name;
      };

      projects = {
        bolt = {};
        clang = {};
        clang-tools-extra = {};
        compiler-rt = {};
        libc = {
          mode = mkOption {
            type = types.enum [ "overlay" "full" ];
            default = "full";
            description = ''
              Whether to perform an overlay build or full build.
            '';
          };
        };
        libclc = {};
        lld = {};
        lldb = {};
        libunwind = {};
        mlir = {};
        openmp = {};
        polly = {};
      };

    in lib.mapAttrs (name: extra: mkSubproject name // extra) projects;

    config = mkMerge [
      (mkIf config.libc.enable {
        libc.cmakeFlags = {
          LLVM_LIBC_FULL_BUILD = lib.boolToString (config.libc.mode == "full");
        };
      })
    ];
  });
in
{
  options.llvm = {
    projects = mkOption {
      type = projectOpts;
      description = ''
        The specific LLVM projects to enable.
      '';
    };

    runtimes = mkOption {
      type = types.attrsOf (types.submodule ({ name, config, ... }@runtime: {
        options = {
          name = mkOption {
            type = types.str;
            description = ''
              Target triple name
            '';
          };

          projects = mkOption {
            type = projectOpts;
            description = ''
              The specific LLVM projects to enable in the runtime.
            '';
          };

          cmakeFlags = mkOption {
            type = types.attrsOf types.str;
            default = {};
            description = ''
              CMake flags for the specific platform.
            '';
          };
        };

        config = {
          name = mkDefault name;
          cmakeFlags = lib.fold lib.mergeAttrs {} (lib.attrValues (lib.mapAttrs (_: cfg: cfg.cmakeFlags) config.projects));
        };
      }));
    };

    src = mkOption {
      type = types.path;
      description = ''
        Path to the LLVM project source code.
      '';
    };

    version = mkOption {
      type = types.str;
      description = ''
        The version of LLVM being compiled.
      '';
    };
  };

  config = {
    perSystem = { pkgs, ... }: {
      packages = pkgs.callPackages ../pkgs/default.nix {
        inherit (cfg) projects runtimes src version;
      };
    };

    llvm = {
      projects = mkDefault {
        clang.enable = true;
        lld.enable = true;
      };

      runtimes = mkDefault (genAttrs config.systems (system: withSystem system ({ pkgs, ... }: {
        name = pkgs.stdenv.targetPlatform.config;
        projects = mkDefault {
          compiler-rt.enable = true;
          libc.enable = true;
          libunwind.enable = true;
        };
      })));
    };
  };
}
