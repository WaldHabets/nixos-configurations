{ config, pkgs, lib,... }:

let 
	user = "jelly";		
	password = "jellyfin";
	hostname = "rpi4";
in {
	imports  = ["${fetchTarball "https://github.com/NixOS/nixos-hardware/archive/936e4649098d6a5e0762058cb7687be1b2d90550.tar.gz" }/raspberry-pi/4"];
	
	system.stateVersion = "22.11";
	
	# <!-- Hardware -->
	# Enable GPU acceleration
	hardware.raspberry-pi."4".fkms-3d.enable = true;
	hardware.pulseaudio.enable = true;
	
	# <!-- Packages -->
	# Required System Packages
	environment.systemPackages = with pkgs; [
		nano
		rpcbind
		nfs-utils
		cifs-utils
		jellyfin
	];
	
	# <!-- Users -->
	# Create users first
	
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
	
	# <!-- Networking -->
	# Bind to local static ip and open up required ports
	networking.interfaces.eth0.ipv4.addresses = [{
		address = "192.168.0.60";
		prefixLength = 24;
	}];
	networking.defaultGateway = "192.168.0.1";
	networking.nameservers = ["8.8.8.8"];
	networking.firewall.allowedTCPPorts = [ 22 53 80 111 443 2049 8096 8920 ];
	networking.firewall.allowedUDPPorts = [ 53 111 1900 2049 7359 ];
	
	# Required by NFS
	services.rpcbind.enable = true;
	
	fileSystems = {
		"/" = {
			device = "/dev/disk/by-label/NIXOS_SD";
			fsType = "ext4";
			options = [ "noatime" ];
		};
		"/user/jellyfin/media" = {
			device = "192.168.0.61:/volume1/Media";
			fsType = "nfs";
			options = [ "x-systemd.automount" "noauto" ];
		};
	};
	
	# Set Belgian AZERTY layout
	services.xserver.layout = "be";
	#i86n.consoleUseXkbConfig = true;
	

	# override default NixOs hardening
	systemd.services.jellyfin.serviceConfig.PrivateDevices = lib.mkForce false;

	# Enable Services
	services.jellyfin.enable = true;

	# Setup nginx
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
