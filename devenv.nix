{ pkgs, lib, config, inputs, ... }:

{
  # https://devenv.sh/basics/
  env.CHROME_EXECUTABLE = "chromium";

  # https://devenv.sh/packages/
  packages = with pkgs; [ flutter ];

  # https://devenv.sh/scripts/
  # scripts.hello.exec = "echo hello from $GREET";

  # enterShell = ''
  #   hello
  #   git --version
  # '';

  # # https://devenv.sh/tests/
  # enterTest = ''
  #   echo "Running tests"
  #   git --version | grep "2.42.0"
  # '';

  # https://devenv.sh/services/
  # services.postgres.enable = true;

  # https://devenv.sh/languages/
  # languages.nix.enable = true;

  # https://devenv.sh/pre-commit-hooks/
  # pre-commit.hooks.shellcheck.enable = true;

  # https://devenv.sh/processes/
  # processes.ping.exec = "ping example.com";
  android = {
    enable = true;
    flutter.enable = true;
  };

  # See full reference at https://devenv.sh/reference/options/
}
