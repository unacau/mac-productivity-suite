cask "xomsky" do
  version "1.1.0"
  sha256 "69f4bbce77f08e1e12e66fd4e242c6b91f1fdbd95a2e7cf930f9e00062d640a9"

  url "https://github.com/unacau/mac-productivity-suite/releases/download/v#{version}/Xomsky.dmg"
  name "Xomsky"
  desc "Driverless Caps-Lock remapper & Chrome profile switcher in pure Swift 6"
  homepage "https://github.com/unacau/mac-productivity-suite"

  depends_on macos: :sonoma

  app "Xomsky.app"

  zap trash: [
    "~/Library/Application Support/com.almosteleven.xomsky",
    "~/Library/Caches/com.almosteleven.xomsky",
    "~/Library/Preferences/com.almosteleven.xomsky.plist",
  ]
end
