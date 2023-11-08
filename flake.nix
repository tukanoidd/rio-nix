{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nci = {
      url = "github:yusdacra/nix-cargo-integration";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    rio = {
      url = "github:raphamorim/rio";
      flake = false;
    };
  };

  outputs =
    inputs @ { parts
    , nci
    , rio
    , ...
    }:
    parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [ nci.flakeModule ];
      perSystem =
        { pkgs
        , config
        , ...
        }:
        let
          crateName = "rioterm";
          crateOutputs = config.nci.outputs.${crateName};

          toolchainConfig = rio + "/rust-toolchain";
        in
        {
          nci = {
            inherit toolchainConfig;

            projects."rio".path = rio;
            crates.${crateName} =
              let
                builAndBuildDepDeps = with pkgs; [
                  pkg-config
                ];
                buildAndBuildDepAndRuntimeDeps = with pkgs; [
                  fontconfig
                ];
                buildRuntimeDeps = with pkgs; [
                  freetype
                  libxkbcommon
                ] ++ buildAndBuildDepAndRuntimeDeps;
              in
              {
                export = true;
                runtimeLibs = with pkgs; [
                  wayland
                  wayland-protocols
                ] ++ buildRuntimeDeps;
                depsDrvConfig = {
                  mkDerivation = {
                    buildInputs = with pkgs; [
                      cmake
                    ] ++ builAndBuildDepDeps ++ buildAndBuildDepAndRuntimeDeps;
                  };
                };
                drvConfig = {
                  mkDerivation = {
                    buildInputs = with pkgs; [
                      gnumake
                      xorg.libxcb
                      python3
                    ] ++ builAndBuildDepDeps ++ buildRuntimeDeps;
                  };
                };
              };
          };
          packages.default = crateOutputs.packages.release;
        };
    };
}
