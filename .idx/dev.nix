{ pkgs, ... }: {
  # Which nixpkgs channel to use.
  channel = "stable-23.11"; # Or "unstable"
  # Use https://search.nixos.org/packages to find packages
  packages = [
    pkgs.astro
    # pkgs.gildas
    # pkgs.go
    # pkgs.python311
    # pkgs.python311Packages.pip
    # pkgs.nodejs_20
    # pkgs.nodePackages.nodemon
  ];
  # Sets environment variables in the workspace
  env = {};
  idx = {
    # Search for the extensions you want on https://open-vsx.org/ and use "publisher.id"
    extensions = [
      # "svelte.svelte-vscode"
    ];
    # Enable previews and customize configuration
    previews = {
      enable = true;
      previews = [
        {
          # The application process to start on port 3000
          command = [ "npm" "run" "dev" ];
          manager = "web";
          id = "web";
          env = {
            # Environment variables to set for your application
            PORT = "$PORT";
          };
        }
      ];
    };
    # Workspace Lifecycle hooks
    onCreate = {
      # Example: Run a command on workspace creation
      # "on-create-command" = "echo 'Welcome to your new workspace!'";
    };
    onStart = {
      # Example: Run a command on workspace startup
      # "on-start-command" = "npm install";
    };
  };
}
