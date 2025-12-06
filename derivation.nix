{ pkgs }:
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
	checkPhase = "
		runHook preCheck
		coverage run -m pytest
		status=0
		coverage report --fail-under=100 || status=$?
		coverage html -d \"$out/Coverage\"
		[ $status -eq 0 ]
		runHook postCheck
	";
}
