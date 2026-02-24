# Plan: 添加 QPROP Formula 到 homebrew-aerospace

## Context

XFoil formula 已完成（含 headless patch）。现在为同一个 tap 添加 QPROP/QMIL。

**QPROP vs XFoil 对比**：QPROP/QMIL 比 XFoil **简单得多**：
- **无 X11 依赖**（纯命令行工具，无 GUI/绘图）
- **无需 headless patch**（天然 headless，不含任何图形代码）
- **无需 `-fallow-argument-mismatch`**（GCC 15.2.0 编译通过，代码无 F77 类型不匹配）
- **只需改 Makefile 两处**：编译器 `ifort` → `gfortran`，标志 `-r8` → `-fdefault-real-8`

## 调查结果

### 源码来源
- **URL**: `https://web.mit.edu/drela/Public/web/qprop/qprop1.22.tar.gz`
- **版本**: 1.22
- **许可**: GPL-2.0
- **解压目录**: `Qprop/`（大写 Q）

### Vanilla Makefile (`bin/Makefile`) 需要改的部分

```makefile
# 原始（vanilla）
FFLAGS = -O -r8           # Intel Fortran 双精度标志
FC = ifort                 # Intel Fortran 编译器

# 改为
FFLAGS = -O -fdefault-real-8   # GCC gfortran 双精度标志
FC = gfortran                   # GCC gfortran
```

### 依赖链（极简）
- `otool -L` 输出：只链接 `libgfortran`、`libquadmath`、`libSystem`
- **不依赖 X11、libx11、XQuartz**
- 唯一依赖：`gcc`（提供 gfortran）

### 安装目标
一个 formula 安装两个二进制：`qprop` 和 `qmil`（同源码树，同 Makefile）

## 实现步骤

### Step 1: 获取 sha256

```bash
curl -sL https://web.mit.edu/drela/Public/web/qprop/qprop1.22.tar.gz | shasum -a 256
```

### Step 2: 创建 `Formula/qprop.rb`

```ruby
class Qprop < Formula
  desc "Propeller/windmill analysis and design (includes QMIL)"
  homepage "https://web.mit.edu/drela/Public/web/qprop/"
  url "https://web.mit.edu/drela/Public/web/qprop/qprop1.22.tar.gz"
  sha256 "<hash>"
  license "GPL-2.0-only"
  version "1.22"

  depends_on "gcc"  # provides gfortran

  fails_with :clang

  def install
    inreplace "bin/Makefile" do |s|
      # Switch from Intel Fortran to GCC gfortran
      s.gsub! "FFLAGS = -O -r8", "FFLAGS = -O -fdefault-real-8"
      s.gsub! "FC = ifort", "FC = gfortran"
    end

    cd "bin" do
      system "make", "qprop"
      system "make", "qmil"
    end

    bin.install "bin/qprop"
    bin.install "bin/qmil"
  end

  test do
    # QPROP prints usage when called without arguments
    output = shell_output("#{bin}/qprop", 1)  # exits 1 with usage
    assert_match "QPROP", output
  end
end
```

关键对比 XFoil formula：
| | XFoil | QPROP |
|---|---|---|
| 依赖 | `gcc` + `libx11` | `gcc` 仅此一个 |
| Makefile 改动 | 6 处 sed + 整体重写 config.make | 2 处 gsub |
| 源码改动 | headless patch (2 行 Fortran) | 无 |
| 构建步骤 | plotlib → xfoil | qprop + qmil |
| 安装 | 1 个二进制 | 2 个二进制 |

### Step 3: 更新 README.md

在 Available Formulas 表中加入 qprop，更新 Roadmap checkbox。

### Step 4: 提交推送

```bash
cd /Users/liuya/2026/homebrew-aerospace
git add Formula/qprop.rb README.md
git commit -m "Add qprop 1.22 formula (includes qmil)"
git push
```

### Step 5: 验证

```bash
brew untap liuyanwpuuci/aerospace && brew tap liuyanwpuuci/aerospace
brew install liuyanwpuuci/aerospace/qprop
brew test qprop
qprop           # 应显示 usage
qmil             # 应显示 usage
```

## 注意事项

- `version "1.22"` 需显式声明（tarball 文件名 `qprop1.22.tar.gz` 非标准格式）
- vanilla Makefile 中 `FC = f77` 在第 8 行，`FC = ifort` 在第 12 行（ifort 覆盖 f77），只需改 ifort 那行
- `f77` 那行保持原样即可（会被后面的 `gfortran` 覆盖）
- test block：QPROP 无参数调用时会打印 usage 并 exit(1)，用 `shell_output(cmd, 1)` 接受非零退出码

## Drela 系列工具通用模式（供 XROTOR/AVL 参考）

所有 Mark Drela 工具共享相同的编译问题和解决策略：

| 问题 | 解决方案 | 适用工具 |
|------|----------|----------|
| 编译器 `ifort` → `gfortran` | `inreplace` Makefile | 全部 |
| 双精度 `-r8` → `-fdefault-real-8` | `inreplace` FFLAGS | 全部 |
| F77 类型不匹配 | `-fallow-argument-mismatch` | XFoil、XROTOR（有大量 F77 松散类型） |
| `-m64` x86 标志 | 删除 | 有 plotlib 的工具（XFoil、XROTOR） |
| X11 路径 | Homebrew `libx11` | 有 plotlib 的工具 |
| 无头模式 | `XFOIL_HEADLESS` 环境变量 | 有交互 GUI 的工具（XFoil、XROTOR） |
| FPE trap | 注释 `-ffpe-trap` | 有浮点敏感计算的工具 |

**判断方法**：
- 有 `plotlib/` 目录 → 需要 X11、headless patch、`-m64` 删除
- 无 `plotlib/` 目录 → 纯命令行，只需编译器切换（如 QPROP）
