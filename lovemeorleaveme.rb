class Lovemeorleaveme < Formula
  desc "Monitors CPU idle and shuts down the system if idle conditions are met"
  homepage "https://github.com/indigoviolet/lovemeorleaveme"
  url "https://github.com/indigoviolet/lovemeorleaveme/archive/v1.0.0.tar.gz"
  sha256 "REPLACE_WITH_ACTUAL_SHA256_AFTER_CREATING_RELEASE"
  license "MIT"

  depends_on "charmbracelet/tap/gum"

  def install
    bin.install "lol.sh" => "lovemeorleaveme"
  end

  test do
    assert_match "Usage: lovemeorleaveme", shell_output("#{bin}/lovemeorleaveme --help")
  end
end