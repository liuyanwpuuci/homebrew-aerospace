# homebrew-aerospace

Homebrew tap for aerospace engineering tools.

## Available Formulas

| Formula | Description | Version |
|---------|-------------|---------|
| `xfoil` | Subsonic airfoil development system (Mark Drela, MIT) | 6.99 |

## Installation

```bash
brew tap liuyanwpuuci/aerospace
brew install xfoil
```

Or in one command:

```bash
brew install liuyanwpuuci/aerospace/xfoil
```

### XQuartz (optional)

XFoil's graphical interface requires an X11 server:

```bash
brew install --cask xquartz
# Log out and back in for X11 to be available
```

For headless/scripted use (e.g., with [propeller-mcp](https://github.com/liuyanwpuuci/propeller-mcp)), no X server is needed.

## What this tap does

XFoil 6.99 does not compile out-of-the-box on modern macOS (Apple Silicon or Intel with GCC 10+). This formula automatically applies the necessary build patches:

- Adds `-fallow-argument-mismatch` for GCC 10+ compatibility with Fortran 77 code
- Removes the x86-only `-m64` flag for ARM64 support
- Updates X11 paths for Homebrew's `libx11`
- Disables FPE trapping that causes crashes on ARM

No Fortran source code is modified — only build configuration files are patched.

## License

- This tap (formulas and build scripts): MIT
- XFoil: GPL-2.0 (source is downloaded from MIT during build, not redistributed)
