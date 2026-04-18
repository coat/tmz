{
  description = "A library for parsing Tiled maps";

  inputs.nixpkgs.url = "nixpkgs/nixos-25.11";
  inputs.zig.url = "github:mitchellh/zig-overlay";

  outputs = {
    nixpkgs,
    zig,
    ...
  }: let
    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
  in
    builtins.foldl' nixpkgs.lib.recursiveUpdate {} (
      builtins.map (
        system: let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [zig.overlays.default];
          };
        in {
          devShells.${system}.default = pkgs.mkShell {
            packages = with pkgs;
              [
                zigpkgs.default
              ]
              ++ (pkgs.lib.optionals pkgs.stdenv.isLinux [kcov]);
          };

          formatter.${system} = pkgs.alejandra;
        }
      )
      systems
    );
}
