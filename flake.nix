{
  description = "A library for parsing Tiled maps";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";

    zig-overlay.url = "github:mitchellh/zig-overlay";
    zig-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    nixpkgs,
    zig-overlay,
    ...
  }:
    builtins.foldl' nixpkgs.lib.recursiveUpdate {} (
      builtins.map (
        system: let
          pkgs-stable = nixpkgs.legacyPackages.${system};
          zig = zig-overlay.packages.${system}."0.14.0";
        in {
          devShells.${system}.default = pkgs-stable.mkShell {
            nativeBuildInputs = with pkgs-stable; [
              sdl3
              sdl3-image
              zig
            ]
            ++ (pkgs.lib.optionals pkgs.stdenv.isLinux [kcov]);
          };

          formatter.${system} = pkgs-stable.alejandra;
        }
      ) (builtins.attrNames zig-overlay.packages)
    );
}
