class Xfoil < Formula
  desc "Subsonic airfoil development system"
  homepage "https://web.mit.edu/drela/Public/web/xfoil/"
  url "https://web.mit.edu/drela/Public/web/xfoil/xfoil6.99.tgz"
  sha256 "5c0250643f52ce0e75d7338ae2504ce7907f2d49a30f921826717b8ac12ebe40"
  license "GPL-2.0-only"
  version "6.99"

  depends_on "gcc"    # provides gfortran
  depends_on "libx11" # X11 client library

  fails_with :clang # XFoil is Fortran — needs gfortran from GCC

  def install
    x11 = Formula["libx11"]
    x11_inc = x11.opt_include.to_s
    x11_lib = x11.opt_lib.to_s

    # --- Patch src/xfoil.f: add XFOIL_HEADLESS support ---
    # When XFOIL_HEADLESS env var is set, switch from X11 (IDEV=1) to
    # PostScript-only output (IDEV=4), skipping XOpenDisplay entirely.
    # This enables headless/scripted operation without an X11 display.
    inreplace "src/xfoil.f",
      "c     IDEV = 5   ! both X11 and Color PostScript file \nC\nC---- Re-plotting flag (for hardcopy)",
      "c     IDEV = 5   ! both X11 and Color PostScript file \n" \
      "C---- Headless mode: if XFOIL_HEADLESS env var is set, use PS-only output\n" \
      "      CALL GETENV('XFOIL_HEADLESS', PREFIX)\n" \
      "      IF(PREFIX(1:1).NE.' ') IDEV = 4\n" \
      "C\n" \
      "C---- Re-plotting flag (for hardcopy)"

    # --- Rewrite plotlib/config.make ---
    # Enable double precision, set correct X11 paths, add GCC 10+ compat flag
    rm buildpath/"plotlib/config.make"
    (buildpath/"plotlib/config.make").write <<~CONFIG
      PLTLIB = libPlt_gDP.a
      DEFINE = -DUNDERSCORE
      FC = gfortran
      CC = #{ENV.cc}
      DP = -fdefault-real-8
      FFLAGS  = -O2 $(DP) -fallow-argument-mismatch
      CFLAGS  = -O2 $(DEFINE) -I#{x11_inc}
      AR = ar r
      RANLIB = ranlib
      LINKLIB = -L#{x11_lib} -lX11
    CONFIG

    # --- Patch bin/Makefile ---
    inreplace "bin/Makefile" do |s|
      # 1. Build in place instead of /home/codes/bin/
      s.gsub! "BINDIR = /home/codes/bin/", "#BINDIR = /home/codes/bin/"
      s.gsub! "#BINDIR = .", "BINDIR = ."

      # 2. X11 library path
      s.gsub! "-L/usr/X11R6/lib -lX11", "-L#{x11_lib} -lX11"

      # 3. Simpler install command
      s.gsub! "INSTALLCMD = install -s", "INSTALLCMD = cp"

      # 4. Disable FPE trapping (causes crashes on ARM with benign FPEs)
      s.gsub! "CHK = -fbounds-check -finit-real=inf -ffpe-trap=invalid,zero",
              "#CHK = -fbounds-check -finit-real=inf -ffpe-trap=invalid,zero"

      # 5. Add -fallow-argument-mismatch (critical for GCC 10+ with F77 code)
      s.gsub! "FFLAGS = -O $(CHK) $(DBL)",
              "FFLAGS = -O $(CHK) $(DBL) -fallow-argument-mismatch"
      s.gsub! "FFLOPT = -O $(CHK) $(DBL)",
              "FFLOPT = -O $(CHK) $(DBL) -fallow-argument-mismatch"

      # 6. Remove post-link install commands
      s.gsub! "\t$(INSTALLCMD) xfoil $(BINDIR)\n", ""
      s.gsub! "\t$(INSTALLCMD) pxplot $(BINDIR)\n", ""
      s.gsub! "\t$(INSTALLCMD) pplot $(BINDIR)\n", ""
      s.gsub! "\t$(INSTALLCMD) blu $(BINDIR)\n", ""
    end

    # --- Build ---
    cd "plotlib" do
      system "make"
    end

    cd "bin" do
      system "make", "xfoil"
    end

    bin.install "bin/xfoil"
  end

  def caveats
    <<~EOS
      XFoil's graphical interface requires an X11 server.
      For interactive plotting, install XQuartz:
        brew install --cask xquartz
      Then log out and back in (or restart) for X11 to be available.

      Headless/scripted mode (no X server needed):
        XFOIL_HEADLESS=1 xfoil
    EOS
  end

  test do
    ENV["XFOIL_HEADLESS"] = "1"
    output = pipe_output("#{bin}/xfoil", "QUIT\n", 0)
    assert_match "XFOIL", output
  end
end
