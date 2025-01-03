{
  inputs = {
    naersk.url = "github:nix-community/naersk/master";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };
  outputs =
    {
      self,
      nixpkgs,
      utils,
      naersk,
      rust-overlay,
    }:
    utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ rust-overlay.overlays.default ];
        };

        # this is a running release, always pin nightly
        toolchain = pkgs.rust-bin.nightly.latest.default.override {
          extensions = [ "rust-src" ];
        };
        naersk-lib = pkgs.callPackage naersk {
          cargo = toolchain;
          rustc = toolchain;
        };
      in
      {
        defaultPackage = naersk-lib.buildPackage ./.;
        devShell =
          with pkgs;
          mkShell {
            buildInputs = [
              vulkan-loader
              wayland
              alsa-lib
              pkg-config
              toolchain
              opusfile
              cargo-watch
              pre-commit
              rustPackages.clippy
            ];
            RUST_SRC_PATH = "${toolchain}/lib/rustlib/src/rust/library";
            LD_LIBRARY_PATH = "${pkgs.vulkan-loader}/lib:${pkgs.libxkbcommon}/lib";
          };
      }
    );
}
