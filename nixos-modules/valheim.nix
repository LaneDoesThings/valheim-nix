{
  self,
  steam-fetcher,
}: {
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.services.valheim;
  stateDir = "/var/lib/valheim";
in {
  options.services.valheim = {
    enable = lib.mkEnableOption (lib.mdDoc "Valheim Dedicated Server");

    serverName = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "Serverheim";
      description = lib.mdDoc "The name listed in the server browser.";
    };

    worldName = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
      example = "Midgard";
      description = lib.mdDoc ''
        The name of the world file to use, without the extension.
        If the world does not exist, then the server will generate a world from
        a random seed.
      '';
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 2456;
      description = lib.mdDoc ''
        The port on which to listen for incoming connections.

        Note that the port just above this one will be used for the Steam server browser service.
      '';
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = lib.mdDoc "Whether to open ports in the firewall.";
    };

    password = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = lib.mdDoc ''
        The server password.

        This can only be passed as a commandline argument to the server, so it
        can be viewed by any user on the system able to list processes.
      '';
    };

    adminList = lib.mkOption {
      type = with lib.types; listOf str;
      default = [];
      example = [
        "72057602627862526"
        "72057602627862527"
      ];
      description = lib.mdDoc ''
        List of Steam IDs to be added to the adminlist.txt file.

        These users will have admin privileges on the server.
      '';
    };

    permittedList = lib.mkOption {
      type = with lib.types; listOf str;
      default = [];
      example = [
        "72057602627862526"
        "72057602627862527"
      ];
      description = lib.mdDoc ''
        List of Steam IDs to be added to the permittedlist.txt file.

        Only these users will be allowed to join the server if the list is not empty.
        If you use this, all players not on the list will be unable to join.
      '';
    };

    bannedList = lib.mkOption {
      type = with lib.types; listOf str;
      default = [];
      example = [
        "72057602627862526"
        "72057602627862527"
      ];
      description = lib.mdDoc ''
        List of Steam IDs to be added to the bannedlist.txt file.

        These users will be banned from the server.
      '';
    };

    config = lib.mkIf cfg.enable {
      nixpkgs.overlays = [
        self.overlays.default
        steam-fetcher.overlays.default
      ];

      users = {
        users.valheim = {
          isSystemUser = true;
          group = "valheim";
          home = stateDir;
          createHome = true;
        };
        groups.valheim = {};
      };

      systemd.services.valheim = {
        description = "Valheim dedicated server";
        requires = ["network.target"];
        after = ["network.target"];
        wantedBy = ["multi-user.target"];

        preStart = let
          createListFile = name: list: ''
            echo "// List of Steam IDs for ${name} ONE per line
            ${lib.strings.concatStringsSep "\n" list}" > ${stateDir}/.config/unity3d/IronGate/Valheim/${name}
            chown valheim:valheim ${stateDir}/.config/unity3d/IronGate/Valheim/${name}
          '';
        in ''
          mkdir -p ${stateDir}/.config/unity3d/IronGate/Valheim
          ${createListFile "adminlist.txt" cfg.adminList}
          ${createListFile "permittedlist.txt" cfg.permittedList}
          ${createListFile "bannedlist.txt" cfg.bannedList}
        '';

        serviceConfig = {
          Type = "exec";
          User = "valheim";
          ExecStart = lib.strings.concatStringsSep " " (
            [
              "${pkgs.valhem-server}/bin/valheim-server"
              "-name \"${cfg.serverName}\""
            ]
            ++ (lib.lists.optional (cfg.worldName != null) "-world \"${cfg.worldName}\"")
            ++ [
              "-port \"${toString cfg.port}\""
              "-password \"${cfg.password}\""
            ]
            ++ (lib.lists.optional cfg.crossplay "-crossplay")
          );
        };
      };
    };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedUDPPorts = [
        cfg.port
        (cfg.port + 1) # Steam server browser
      ];
    };

    assertions = [
      {
        assertion = cfg.serverName != "";
        message = "The server name must not be empty.";
      }
      {
        assertion = cfg.worldName != "";
        message = "The world name must not be empty.";
      }
      {
        assertion = cfg.password != "";
        message = "The password must not be empty.";
      }
    ];
  };
}
