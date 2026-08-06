{
  description = "NixOS module for the Valheim dedicated server";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    steam-fetcher = {
      url = "github:nix-community/steam-fetcher";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      steam-fetcher,
    }:
    let
      # The Steam Nix fetcher only supports x86_64 Linux.
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          overlays = [
            steam-fetcher.overlay
            self.overlays.default
          ];
        };
      lintersFor =
        system:
        let
          pkgs = pkgsFor system;
        in
        with pkgs;
        [
          nixfmt
        ];
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            packages =
              with pkgs;
              [
                nixd
                nix-output-monitor
              ]
              ++ lintersFor system;
          };
        }
      );

      checks = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          fmt = pkgs.runCommandLocal "nixfmt-check" { } ''
            ${pkgs.nixfmt}/bin/nixfmt --check $(find ${./.} -name '*.nix') > $out
          '';
        }
      );

      formatter = forAllSystems (system: (pkgsFor system).nixfmt);

      nixosModules = rec {
        valheim = import ./nixos-modules/valheim.nix { inherit self steam-fetcher; };
        default = valheim;
      };
      overlays.default = final: prev: {
        valheim-server-unwrapped = final.callPackage ./pkgs/valheim-server { };
        valheim-server = final.callPackage ./pkgs/valheim-server/fhsenv.nix { };
      };
      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          valheim-server = pkgs.valheim-server;
          valheim-server-unwrapped = pkgs.valheim-server-unwrapped;
        }
      );
    };
}
