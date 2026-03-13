class Xrotor < Formula
  desc "Rotor/propeller design and analysis (multi-airfoil, noise, optimization)"
  homepage "https://web.mit.edu/drela/Public/web/xrotor/"
  url "https://web.mit.edu/drela/Public/web/xrotor/Xrotor7.55.tar.tgz"
  sha256 "7bee104afa0f81ce6ca7ce2205f65943b5e3650105507363f1a628bbca3a075b"
  license "GPL-2.0-only"
  version "7.55"

  depends_on "gcc"    # provides gfortran
  depends_on "libx11" # X11 client library

  fails_with :clang # XROTOR is Fortran — needs gfortran from GCC

  def install
    x11 = Formula["libx11"]
    x11_inc = x11.opt_include.to_s
    x11_lib = x11.opt_lib.to_s
    xorgproto_inc = Formula["xorgproto"].opt_include.to_s

    # --- Patch src/xrotor.f: add XROTOR_HEADLESS support ---
    # When XROTOR_HEADLESS env var is set, switch from X11 (IDEV=1) to
    # PostScript-only output (IDEV=4), skipping XOpenDisplay entirely.
    # This enables headless/scripted operation without an X11 display.
    # Re-uses the existing CHARACTER*80 FNAME variable from XROTOR.INC.
    inreplace "src/xrotor.f",
      "c     IDEV = 5   ! both X11 and Color PostScript file \nC\nC---- Re-plotting flag (for hardcopy)",
      "c     IDEV = 5   ! both X11 and Color PostScript file \n" \
      "C---- Headless mode: if XROTOR_HEADLESS env var is set, use PS-only output\n" \
      "      CALL GETENV('XROTOR_HEADLESS', FNAME)\n" \
      "      IF(FNAME(1:1).NE.' ') IDEV = 4\n" \
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
      CFLAGS  = -O2 $(DEFINE) -I#{x11_inc} -I#{xorgproto_inc}
      AR = ar r
      RANLIB = ranlib
      LINKLIB = -L#{x11_lib} -lX11
    CONFIG

    # --- Patch bin/Makefile.gfortran ---
    inreplace "bin/Makefile.gfortran" do |s|
      # 1. X11 library path
      s.gsub! "-L/usr/X11R6/lib -lX11", "-L#{x11_lib} -lX11"

      # 2. Double precision + GCC 10+ compat (must match plotlib precision)
      s.gsub! "FFLAGS = -O", "FFLAGS = -O -fdefault-real-8 -fallow-argument-mismatch"
      s.gsub! "FFLOPT = -O", "FFLOPT = -O -fdefault-real-8 -fallow-argument-mismatch"

      # 3. Use double-precision plotlib (libPlt_gDP.a, not libPlt_gfortran.a)
      s.gsub! "PLTOBJ = ../plotlib/libPlt_gfortran.a",
              "PLTOBJ = ../plotlib/libPlt_gDP.a"
    end

    # --- Build ---
    cd "plotlib" do
      system "make"
    end

    cd "bin" do
      system "make", "-f", "Makefile.gfortran", "xrotor"
    end

    bin.install "bin/xrotor"
  end

  def caveats
    <<~EOS
      XROTOR's graphical interface requires an X11 server.
      For interactive plotting, install XQuartz:
        brew install --cask xquartz
      Then log out and back in (or restart) for X11 to be available.

      Headless/scripted mode (no X server needed):
        XROTOR_HEADLESS=1 xrotor
    EOS
  end

  test do
    ENV["XROTOR_HEADLESS"] = "1"
    output = pipe_output("#{bin}/xrotor", "QUIT\n", 0)
    assert_match "XROTOR", output
  end
end
