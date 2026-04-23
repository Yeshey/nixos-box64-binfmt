# nixos-box64-binfmt
> [!NOTE]  
> This is in the most alpha version imaginable

Uses box64 to run x86_64 and i368 binaries in nixOS. Creates a proper FHS environment and can register binfmt entries to automatically run x86 binaries.
It provides its own `box64-bleeding-edge` package, with the bleeding edge changes and box32 support to run 32bit software (like `steam`) as well.

## Installation with flakes and Usage

Here's a minimal `flake.nix` demonstrating how to include the `nixos-box64-binfmt` module:

```nix
# flake.nix
{
  description = "My NixOS Configuration with Box64 Binfmt";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    box64-binfmt = {
      url = "github:Yeshey/nixos-box64-binfmt";
      # Optional: To ensure box64-binfmt uses the same Nixpkgs version as your system
      # inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = { self, nixpkgs, box64-binfmt, ... }@inputs: {
    nixosConfigurations."your-hostname" = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";

      specialArgs = { inherit inputs; };

      modules = [
        # Import the Box64 Binfmt NixOS module
        inputs.box64-binfmt.nixosModules.default

        ./configuration.nix 
      ];
    };
  };
}
```

Then, in your `configuration.nix` or equivalent add these lines:

```nix
boot.binfmt.emulatedSystems = ["i686-linux" "x86_64-linux" "i386-linux" "i486-linux" "i586-linux" "i686-linux"];
nix.settings.extra-platforms = ["i686-linux" "x86_64-linux" "i386-linux" "i486-linux" "i586-linux" "i686-linux"];
```
Just like demonstrated below. Note that you have to `nixos-rebuild` once with the `emulatedSystems` and `extra-platforms` defined before enabling `box64-binfmt.enable` so your system can compile this flake, it will use qemu emulation only to build the packages that require `x86_64-linux`:

```nix
# configuration.nix
{ pkgs, inputs, ... }:

{
  imports = [
    inputs.box64-binfmt.nixosModules.default
  ];

  boot.binfmt.emulatedSystems = ["i686-linux" "x86_64-linux" "i386-linux" "i486-linux" "i586-linux" "i686-linux"];
  nix.settings.extra-platforms = ["i686-linux" "x86_64-linux" "i386-linux" "i486-linux" "i586-linux" "i686-linux"];
  box64-binfmt.enable = false; # Disable
}
```

Then you may start installing x86 packages, note that hardware acceleration hasn't been tested, and steam doesn't seem to work as of now: 

```nix
# configuration.nix
{ pkgs, inputs, ... }:

{
  imports = [
    inputs.box64-binfmt.nixosModules.default
  ];

  box64-binfmt.enable = true; # Enable 
  
  # Install steam and steamcmd, steamcmd works, steam doesn't
  box64-binfmt.steam.enable = true;

  environment.systemPackages = [
    pkgs.x86.vectoroids             # Standard packages work natively out of the box!
    pkgs.x86.wineWowPackages.stable # WINE (WoW64 version)
    
    pkgs.htop                  # Native packages work as usual

    # This is the box64 version with box32 experimental support built, it is already installed so this is not needed
    # inputs.box64-binfmt.packages.${pkgs.system}.box64-bleeding-edge
  ];
}
```

#### Todo
- GitHub action to auto update box64 according to the latest commits?
- Proper README