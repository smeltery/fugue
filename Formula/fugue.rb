# Homebrew formula for fugue — the canonical template.
#
# On each stable tag, the release workflow (.github/workflows/release.yml)
# renders this with the tagged tarball's url/sha256 and pushes it to
# smeltery/homebrew-tap, so `brew install smeltery/tap/fugue` works. The url
# and sha256 below are placeholders the workflow overwrites; `--HEAD` installs
# from main regardless.
class Fugue < Formula
  desc "Incognito mode for AI coding agents: no-trace, sandboxed sessions"
  homepage "https://github.com/smeltery/fugue"
  url "https://github.com/smeltery/fugue/archive/refs/tags/v0.0.0.tar.gz"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"
  # PolyForm Shield 1.0.0 is not an SPDX identifier Homebrew can represent.
  license :cannot_represent
  head "https://github.com/smeltery/fugue.git", branch: "main"

  depends_on "bash"
  # The docker backend additionally needs Docker; the native backend needs macOS
  # sandbox-exec (built in). Neither can be a hard Homebrew dependency.

  def install
    # Ship the whole tree so the launcher can find profiles/ and src/.
    libexec.install "bin", "src", "profiles"
    (bin/"fugue").write <<~SH
      #!/bin/bash
      exec "#{libexec}/bin/fugue" "$@"
    SH
  end

  test do
    assert_match "Usage", shell_output("#{bin}/fugue --help")
  end
end
