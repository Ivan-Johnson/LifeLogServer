{ config, pkgs, ... }:

let
	lls = import ./derivation.nix { inherit pkgs; };
in
{
	config = {

		# NOTE: LLS does have a `/etc/lifelogserver/server.cfg`
		# configuration file. At present (20240617), it is only used to
		# configure the secret key [1]. I don't have a secret manager
		# setup with NixOS, so I won't bother setting that file up with
		# NixOS.
		#
		# [1]: https://flask.palletsprojects.com/en/3.0.x/config/#SECRET_KEY

		environment.systemPackages = with pkgs; [ lls ];

		users.groups.lls = { };

		users.users.lls = {
			isSystemUser = true;
			description = "User for the lls server";
			group = "lls";
		};

		systemd.services."lifelog_server" = {
			description = "Lifelog server";
			wantedBy = [ "default.target" ];
			serviceConfig = {
				Type = "exec";
				ExecStart = "${lls}/bin/lifelogserver start";
				User = "lls";
				Group = "lls";
			};
		};
	};
}
