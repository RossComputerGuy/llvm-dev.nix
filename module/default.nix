{ config, lib, withSystem, ... }@top:
let
  inherit (lib) mkEnableOption mkOption mkDefault genAttrs types;

  cfg = config.llvm;

  projectOpts = types.submodule {
    options = {
      bolt.enable = mkEnableOption "bolt post-link optimizer";
      clang.enable = mkEnableOption "Clang C compiler";
      clang-tools-extra.enable = mkEnableOption "extra Clang tools";
      compiler-rt.enable = mkEnableOption "compiler-rt";
      libc.enable = mkEnableOption "libc";
      libclc.enable = mkEnableOption "libclc";
      lld.enable = mkEnableOption "LLD linker";
      lldb.enable = mkEnableOption "lldb debugger";
      mlir.enable = mkEnableOption "mlir";
      openmp.enable = mkEnableOption "openmp";
      polly.enable = mkEnableOption "polly";
    };
  };
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
        };

        config = {
          name = mkDefault name;
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
        };
      })));
    };
  };
}
