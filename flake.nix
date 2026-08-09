{
	description = "Life Log Server";

	inputs.nixpkgs.url = "nixpkgs/nixos-26.05";

	outputs =
		{ self, nixpkgs }:
		let
			pkgs = import nixpkgs {
				system = "x86_64-linux";
				config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ ];
			};

			lls =
				let
					python3Packages = pkgs.python3Packages;
				in
				python3Packages.buildPythonApplication rec {
					pname = "lifelogserver";
					version = "0.8.0a0.dev0"; # TODO: de-dupe. Somehow. Or at least write a unit test?

					pyproject = true;
					build-system = [ python3Packages.setuptools ];

					src = ./src;

					# These should be available at buildtime
					# (e.g. available in nix-shell)
					propagatedNativeBuildInputs = [
						pkgs.sqlite
						python3Packages.black
						python3Packages.flask
						python3Packages.matplotlib
						python3Packages.numpy
						python3Packages.packaging
						python3Packages.setuptools
						python3Packages.waitress
						python3Packages.wheel
					];

					# These should be available at runtime
					# (e.g. when on production server)
					propagatedBuildInputs = [
						pkgs.sqlite
						python3Packages.flask
						python3Packages.matplotlib
						python3Packages.numpy
						python3Packages.packaging
						python3Packages.setuptools
						python3Packages.waitress
						python3Packages.wheel
					];

					# Tests
					doCheck = true;
					nativeCheckInputs = [
						python3Packages.coverage
						python3Packages.pytest
					];
					checkPhase = ''
						runHook preCheck
						coverage run -m pytest
						status=0
						coverage report --fail-under=100 || status=$?
						coverage html -d \"$out/Coverage\"
						[ $status -eq 0 ]
						runHook postCheck
					'';
				};
		in
		{
			packages.x86_64-linux.default = lls;

			devShells.${pkgs.stdenv.hostPlatform.system}.default = pkgs.mkShell {
				buildInputs = with pkgs; [
					pkgs.coreutils
					pkgs.which
					pkgs.bash
					pkgs.git
					pkgs.nix
					pkgs.nixfmt
				];
				shellHook = "";
			};

			nixos = {
				config = {
					# NOTE: LLS does have a `/etc/lifelogserver/server.cfg`
					# configuration file. At present (20240617), it is only used to
					# configure the secret key [1]. I don't have a secret manager
					# setup with NixOS, so I won't bother setting that file up with
					# NixOS.
					#
					# [1]: https://flask.palletsprojects.com/en/3.0.x/config/#SECRET_KEY

					environment.systemPackages = [ lls ];

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
			};
		};
}
