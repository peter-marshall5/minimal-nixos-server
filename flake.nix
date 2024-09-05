{
  description = "Minimal image-based NixOS configuration";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs = { self, nixpkgs }: let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
    };
    relInfo = {
      system.image.id = "nixos-image";
      system.image.version = "1";
      system.image.updates.url = "https://github.com/petm5/nixlet/releases/latest/download/";
    };
  in {
    nixosModules.server = {
      imports = [
        ./modules/profiles/server.nix
      ];
    };
    nixosModules.image = {
      imports = [
        ./modules
        ./modules/profiles/base.nix
        ./modules/image/disk
      ];
    };
    nixosConfigurations.release = nixpkgs.lib.nixosSystem {
      modules = [
        ({ lib, ... }: {
          nixpkgs.hostPlatform = "x86_64-linux";
          system.stateVersion = "24.05";
        })
        {
          boot.kernelParams = [ "quiet" ];
        }
        self.nixosModules.image
        self.nixosModules.server
        relInfo
      ];
    };
    nixosConfigurations.releaseNoTpm = nixpkgs.lib.nixosSystem {
      modules = [
        ({ lib, ... }: {
          nixpkgs.hostPlatform = "x86_64-linux";
          system.stateVersion = "24.05";
          system.image.encrypt = false;
        })
        {
          boot.kernelParams = [ "quiet" ];
        }
        self.nixosModules.image
        self.nixosModules.server
        relInfo
      ];
    };
    nixosConfigurations.debugInsecure = nixpkgs.lib.nixosSystem {
      modules = [
        ({ lib, ... }: {
          nixpkgs.hostPlatform = "x86_64-linux";
          system.stateVersion = "24.05";
          system.image.id = "nixos-debug";
          system.image.version = "1";
          system.image.encrypt = false;
          users.users.root.initialPassword = "toor";
          systemd.services."getty@tty1".enable = false;
          systemd.services."autovt@".enable = false;
        })
        self.nixosModules.image
        self.nixosModules.server
      ];
    };
    packages.x86_64-linux.releaseImage = self.nixosConfigurations.release.config.system.build.image;
    packages.x86_64-linux.releaseImageNoTpm = self.nixosConfigurations.releaseNoTpm.config.system.build.image;
    packages.x86_64-linux.debugImageInsecure = self.nixosConfigurations.debugInsecure.config.system.build.image;
    checks."x86_64-linux" = nixpkgs.lib.listToAttrs (map (test: nixpkgs.lib.nameValuePair "${test}" (import ./tests/${test}.nix {
      pkgs = nixpkgs.legacyPackages."x86_64-linux";
      inherit self;
    })) [ "system-update" "ssh-preseed" "podman" ]);
  };
}
