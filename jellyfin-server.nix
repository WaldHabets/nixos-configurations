{ config, pkgs, lib,... }:

let 
	user = "guest";		
	password = "guest";
	hostname = "rpi4";
in {
	imports  = ["${fetchTarball "https://github.com/NixOS/nixos-hardware/archive/936e4649098d6a5e0762058cb7687be1b2d90550.tar.gz" }/raspberry-pi/4"];
	
	system.stateVersion = "22.11";
	
	fileSystems = {
		"/" = {
			device = "/dev/disk/by-label/NIXOS_SD";
			fsType = "ext4";
			options = [ "noatime" ];
		};
	};

	environment.systemPackages = with pkgs; [
		nano
		nfs-utils
		cifs-utils
		jellyfin
	];
	
	# Networking
	networking.interfaces.eth0.ipv4.addresses = [{
		address = "192.168.0.60";
		prefixLength = 24;
	}];
	networking.defaultGateway = "192.168.0.1";
	networking.nameservers = ["8.8.8.8"];
	networking.firewall.allowedTCPPorts = [ 22 53 80 443 8096 8920 ];
	networking.firewall.allowedUDPPorts = [ 53 1900 7359 ];
	
	# Set Belgian AZERTY layout
	services.xserver.layout = "be";
	#i86n.consoleUseXkbConfig = true;

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
	hardware.pulseaudio.enable = true;

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
				locations."/" = {
					proxyPass = "http://127.0.0.1:8096";
				};
			};
		};
	};
				
}
