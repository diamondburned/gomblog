{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    prettier-gohtml-nix.url = "github:diamondburned/prettier-gohtml-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-parts,
      prettier-gohtml-nix,
    }@inputs:

    # https://flake.parts/module-arguments.html
    flake-parts.lib.mkFlake { inherit inputs; } (
      { ... }:
      {
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
        perSystem =
          {
            pkgs,
            lib,
            self',
            ...
          }:
          {
            devShells.default = pkgs.mkShell {
              packages = with pkgs; [
                cmark
                gomplate
                htmlq
                jq
                just
                minify
                python3 # for just serve
                (pkgs.writeShellScriptBin "parallel-moreutils" ''${pkgs.moreutils}/bin/parallel "$@"'')
              ];

              shellHook = ''
                export MIME_TYPES_PATH="${pkgs.mime-types}/etc/mime.types"
              '';
            };
          };
      }
    );
}
