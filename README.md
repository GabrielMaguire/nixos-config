# NixOS configuration

### Update the config

```sh
sudo nixos-rebuild switch --flake ./hosts/desktop
# or
sudo nixos-rebuild switch --flake ./hosts/laptop
```

### Update the packages

```sh
# update all inputs
nix flake update --flake ./hosts/desktop

# update a single input (Ex. nixpkgs-unstable)
nix flake update nixpkgs-unstable --flake ./hosts/desktop
```
