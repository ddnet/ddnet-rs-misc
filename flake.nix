{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };
  outputs =
    {
      self,
      nixpkgs,
      utils,
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
        rustPlatform = pkgs.makeRustPlatform {
          cargo = toolchain;
          rustc = toolchain;
        };
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "ddnet-rs";
          version = "0.1.0";
          src = ./.;

          nativeBuildInputs = with pkgs; [
            toolchain
            pkg-config
          ];

          buildInputs = with pkgs; [
            ffmpeg
            vulkan-loader
            wayland
            alsa-lib
            opusfile
            xorg.libX11
            xorg.libXcursor
            xorg.libXi

          ];

          buildPhase = ''
            export HOME=$(mktemp -d)
            cargo build --release
          '';

          installPhase = ''
            mkdir -p $out/bin
            cp target/release/ddnet-rs $out/bin/
          '';
        };

        devShell =
          with pkgs;
          mkShell {
            buildInputs = [

              xorg.libX11
              xorg.libXcursor
              xorg.libXi
              libz

              ffmpeg
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
