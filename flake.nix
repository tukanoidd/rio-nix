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
            crates.${crateName} = {
              export = true;
              runtimeLibs = with pkgs; [
                wayland
                wayland-protocols
              ];
              depsDrvConfig = {
                mkDerivation = {
                  buildInputs = with pkgs; [
                    cmake
                    pkg-config
                    fontconfig
                  ];
                };
              };
              drvConfig = {
                mkDerivation = {
                  buildInputs = with pkgs; [
                    pkg-config
                    fontconfig
                    freetype
                    gnumake
                    xorg.libxcb
                    libxkbcommon
                    python3
                  ];
                };
              };
            };
          };
          packages.default = crateOutputs.packages.release;
        };
    };
}
