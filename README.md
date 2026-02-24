# homebrew-aerospace

Homebrew tap for aerospace engineering tools on **macOS** (Apple Silicon M1/M2/M3/M4 & Intel).

## XFoil 6.99

> XFoil is the industry-standard subsonic airfoil analysis tool by Mark Drela (MIT). It does not compile on modern macOS out of the box — this formula fixes that.

### Install

```bash
brew install liuyanwpuuci/aerospace/xfoil
```

That's it. Homebrew handles all dependencies (GCC, X11 libraries) and applies the necessary build patches automatically.

### What gets patched

XFoil 6.99 requires several fixes for macOS with GCC 10+:

| Patch | Why |
|-------|-----|
| `-fallow-argument-mismatch` | GCC 10+ rejects Fortran 77 type mismatches as errors |
| Remove `-m64` | x86-only flag, ARM64 doesn't recognize it |
| X11 paths → Homebrew `libx11` | macOS uses `/opt/homebrew/` not `/usr/X11R6/` |
| Disable `-ffpe-trap` | Benign floating-point exceptions cause crashes on ARM |
| Double precision | Enables `-fdefault-real-8` for numerical accuracy |
| **XFOIL_HEADLESS** | Adds env var to skip X11 display — enables scripted/headless use |

No Fortran source code is modified except the 2-line headless patch.

### Headless mode

For scripted or server use (no GUI needed):

```bash
XFOIL_HEADLESS=1 xfoil < commands.txt
```

### Interactive plotting (optional)

XFoil's graphical interface requires XQuartz:

```bash
brew install --cask xquartz
# Log out and back in for X11 to be available
```

## QPROP 1.22 + QMIL

> QPROP analyzes propeller/windmill performance. QMIL designs minimum induced loss propellers. Both by Mark Drela (MIT).

### Install

```bash
brew install liuyanwpuuci/aerospace/qprop
```

Installs both `qprop` and `qmil`. No X11 required — these are pure command-line tools.

## Roadmap

- [x] XFoil 6.99 — subsonic airfoil analysis
- [x] QPROP 1.22 + QMIL — propeller analysis and design
- [ ] XROTOR — rotor/propeller design and analysis
- [ ] AVL — vortex-lattice aerodynamic analysis

All tools by Mark Drela share the same GCC 10+ / ARM64 build issues and will use the same patching strategy.

## License

- This tap (formulas and build scripts): MIT
- XFoil, QPROP/QMIL: GPL-2.0 (source downloaded from MIT during build, not redistributed)
