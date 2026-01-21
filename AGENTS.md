# AGENTS.md

This is a Nix flake configuration repository for managing NixOS systems and home-manager configurations.

## Build Commands

```bash
# Format all nix files (uses alejandra)
nix fmt

# Check flake validity and imports
nix flake check

# Build a specific package from pkgs/
nix build .#windsurf

# Build a custom package from pkgs/
nix build .#<package-name>

# Test a module
nix-instantiate --eval --strict -E 'import ./nixos/common { outputs = {}; lib = <nixpkgs/lib>; config = {}; pkgs = {}; }'

# Dry-run NixOS rebuild (kharkanas host)
sudo nixos-rebuild dry-build --flake .#kharkanas

# Apply NixOS configuration
sudo nixos-rebuild switch --flake .#kharkanas

# Apply home-manager configuration
home-manager --flake .#mgr8 switch

# Apply home-manager for arr user
home-manager --flake .#arr switch

# Update flake inputs
nix flake update

# Show what the flake provides
nix flake show
```

## Testing

```bash
# Validate all nix files in the flake
nix flake check --show-trace

# Check module syntax
nix-instantiate --parse ./nixos/common/default.nix

# Test overlay syntax
nix-instantiate --eval --strict -E 'import ./overlays { inputs = {}; }'
```

## Code Style Guidelines

### Imports
- Use `import` statements at the top level for module files
- Use `inputs` attribute set to access flake inputs
- Import local modules with relative paths: `./module.nix`, `./subdir/default.nix`

### Formatting
- Use `nix fmt` (alejandra) for automatic formatting
- Use 2-space indentation
- Keep attribute sets aligned when they span multiple lines
- Use `=` for assignments, `:` for attribute set key-value pairs

### Types and Values
- Use explicit types for function arguments: `{ pkgs, lib, ... }:`
- Use `lib.mkEnableOption`, `lib.mkOption`, `lib.mkIf` for module options
- Use `lib.mapAttrs'` for attribute set transformations
- Use `with pkgs;` to import package names locally

### Naming Conventions
- Files: `kebab-case.nix`
- Variables: `camelCase` or `kebab-case` for attributes
- Functions: `camelCase`
- Package definitions: `kebab-case`
- Hostnames: match actual system hostname (e.g., `kharkanas`, `black-coral`, `arr`)
- Modules: descriptive names like `hyprland.nix`, `sound.nix`, `cosmic.nix`

### Error Handling
- Use `lib.mkForce` to override module defaults
- Use `lib.mkDefault` to set sensible defaults
- Use `//` (merge operator) for attribute set overrides
- Use `// { key = value; }` for conditional merging
- Use `mkIf` condition { ... } for conditional configuration

### Attribute Set Patterns
```nix
# Merging with override
config = defaults // { option = value; };

# Conditional merging
config = lib.mkIf condition {
  setting = true;
};

# Using mapAttrs'
lib.mapAttrs' (name: value: {
  name = "prefix/${name}";
  value = value;
}) attrs;
```

### Module Structure
```nix
{ inputs, outputs, lib, config, pkgs, ... }: {
  imports = [ ./path/to/module.nix ];
  options = { };
  config = { services.example.enable = true; };
}
```

### Overlays Pattern
```nix
{inputs, ...}: {
  additions = final: prev: { myPackage = final.callPackage ./pkgs/myPackage { }; };
  modifications = final: prev: { existing = prev.existing.overrideAttrs (old: { patches = [./fix.patch]; }); };
}
```

### Package Definitions (pkgs/)
```nix
pkgs: { my-package = pkgs.callPackage ./my-package { }; }
```

### Best Practices
- Keep host-specific configs in `nixos/<hostname>/`
- Keep user-specific configs in `home-manager/<username>/`
- Share common config in `nixos/common/` and `home-manager/common/`
- Reusable modules go in `modules/nixos/` or `modules/home-manager/`
- Use `FIXME`/`TODO` comments for items needing attention
- Include `hardware-configuration.nix` from `nixos-generate-config`
- Set `system.stateVersion` appropriately (e.g., "23.05")
