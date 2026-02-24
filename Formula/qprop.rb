class Qprop < Formula
  desc "Propeller/windmill analysis and design (includes QMIL)"
  homepage "https://web.mit.edu/drela/Public/web/qprop/"
  url "https://web.mit.edu/drela/Public/web/qprop/qprop1.22.tar.gz"
  sha256 "0c30cf6382fb0964e0dde41943c5b63ca6735c71cc55c48f47bca05f47f72a91"
  license "GPL-2.0-only"
  version "1.22"

  depends_on "gcc" # provides gfortran

  fails_with :clang # Fortran code — needs gfortran from GCC

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
    # QPROP reads stdin; pipe empty input so it runs with defaults and exits
    output = pipe_output("#{bin}/qprop 2>&1", "\n", 0)
    assert_match "QPROP", output
  end
end
