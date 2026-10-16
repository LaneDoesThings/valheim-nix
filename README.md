# Valheim Server Flake
A Nix flake for the Valheim dedicated server, providing both an overlay and a NixOS module.

## Usage
(Your NixOS system configuration must already be a flake.)

Add this flake as an input, and add the NixOS module.  Your config should look something like this.
```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    
    valheim-nix = {
      url = "github:LaneDoesThings/valheim-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  
  outputs = inputs@{ self, nixpkgs }:
  let
    system = "x86_64-linux";
  in {
    nixosConfigurations.HOSTNAME = nixpkgs.lib.nixosSystem {
      modules = [
        ./configuration.nix
        valheim-server.nixosModules.default
      ];
      specialArgs = {
        inherit inputs;
      };
    };
  };
}
```

Then in your `configuration.nix`,
```nix
{ config, pkgs, ...  }:

{
  # ...
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "valheim-server"
      "steamworks-sdk-redist"
    ];
  # ...
  services.valheim = {
    enable = true;
    serverName = "Serverheim";
    worldName = "Worldheim";
    openFirewall = true;
    password = "sekkritpasswd";
  #...
  };
  # ...
}
```

### Managing the server
The NixOS module in this flake runs Valheim server as a systemd service, which you can manage this service using `systemctl` and `journalctl`.

```sh
# Start, stop, or restart the server (requires superuser).
$ systemctl <start|stop|restart> valheim
```

```sh
# Show the runtime status with most recent log data. 
$ systemctl status valheim
```
Note that `nixos-rebuild switch` automatically restarts the service if any attributes under `services.valheim` are changed.  Also be aware that stopping a service does not disable it, and the service will be started again on next boot, `nixos-rebuild switch`, etc.

```sh
# Show live log from the service.
$ journalctl -u valheim -f
```
