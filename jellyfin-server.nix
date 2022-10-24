{ config, pkgs, lib,... }:

let 
	user = "guest";		
	password = "guest";
	hostname = "rpi4";
in {
	imports  = ["${fetchTarball "https://github.com/NixOS/nixos-hardware/archive/936e4649098d6a5e0762058cb7687be1b2d90550.tar.gz" }/raspberry-pi/4"];
	
	fileSystems = {
		"/" = {
			device = "/dev/disk/by-label/NIXOS_SD";
			fsType = "ext4";
			options = [ "noatime" ];
		};
	};

	environment.systemPackages = with pkgs; [
		nano,
		jellyfin
	];
	
	# Set Belgian AZERTY layout
	services.xserver.layout = "be";
	i86n.consoleUseXkbConfig = true;

	# Enable SSH
	services.openssh.enable = true;

	users = {
		mutableUsers = false;
		users."${user}" = {
			isNormalUser = true;
			password = password;
			extraGroups = [ "wheel" ];
		};
	};

	# Enable GPU acceleration
	hardware.raspberry-pi."4".fkms-3d.enable = true;
	hardware.pulseaudeio.enable = true;

	# override default NixOs hardening
	systemd.services.jellyfin.serviceConfig.PrivateDevices = lib.mkForce false;

	# Enable Services
	services.jellyfin.enable = true;

	services.nginx = {
		enable = true;
		virtualHosts = {
			"jellyfin.lan" = {
				forceSSL = false;
				enableACME = false;
				locations."/".proxypass {
					"http://127.0.0.1:8096"
				};
			};
		};
	};
				
}
