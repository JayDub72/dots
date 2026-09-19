# macos/defaults.sh — the single file of `defaults write` commands for
# settings that should stay static (trackpad, keyboard, Finder, Dock,
# screenshots, etc. — see docs/planning.md outcome #3a).
#
# Pulled from the old ~/.dotfiles preference scripts and adapted to this
# repo's conventions, not invented. Some settings require administrator
# privileges — cmd_macos (lib/macos-defaults.sh) is dispatched via the
# request_sudo_keepalive path in bin/dots, so sudo shouldn't prompt
# mid-run. Grouped by application/preference area, same order as the old
# per-app scripts this was consolidated from.
#
# macos_apply "<command>" "<description>" runs <command> (eval'd, so `&&`
# chains work same as the old execute() did) and logs success/failure via
# this repo's log_* functions (from lib/log.sh, already sourced by the
# time cmd_macos sources this file) instead of the old print_in_purple/
# spinner setup, which isn't part of this codebase.
macos_apply() {
    local cmd="$1" desc="${2:-$1}"
    if eval "$cmd" >>"$LOG_FILE" 2>&1; then
        log_success "$desc"
    else
        log_error "${desc} (command failed — see ${LOG_FILE})"
    fi
}

# UI processes that need restarting for changes here to take effect —
# restarted once at the end rather than mid-script per old app section,
# so a process reflects every applicable change in one restart.
RESTART_PROCESSES=(
    "App Store"
    "Google Chrome"
    "Finder"
    "cfprefsd"
    "firefox"
    "Maps"
    "Photos"
    "TextEdit"
    "Transmission"
    "SystemUIServer"
)

# -----------------------------------------------------------------------------
# Close System Settings first, so an open preference pane doesn't
# overwrite what's about to be set here. "System Settings" is the
# current name (renamed from "System Preferences" in macOS Ventura).
# -----------------------------------------------------------------------------

macos_apply "osascript -e 'tell application \"System Settings\" to quit'" \
    "Close System Settings"

# -----------------------------------------------------------------------------
# App Store
# -----------------------------------------------------------------------------

log_step "App Store"

macos_apply "defaults write com.apple.appstore ShowDebugMenu -bool true" \
    "Enable debug menu"

macos_apply "defaults write com.apple.commerce AutoUpdate -bool true" \
    "Turn on auto-update"

macos_apply "defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true" \
    "Enable automatic update check"

macos_apply "defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1" \
    "Download newly available updates in background"

macos_apply "defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1" \
    "Install System data files and security updates"


# -----------------------------------------------------------------------------
# Chrome
# -----------------------------------------------------------------------------

log_step "Chrome"

macos_apply "defaults write com.google.Chrome AppleEnableSwipeNavigateWithScrolls -bool false" \
    "Disable backswipe"

macos_apply "defaults write com.google.Chrome PMPrintingExpandedStateForPrint2 -bool true" \
    "Expand print dialog by default"

macos_apply "defaults write com.google.Chrome DisablePrintPreview -bool true" \
    "Use system-native print preview dialog"


# -----------------------------------------------------------------------------
# Dock
# -----------------------------------------------------------------------------

log_step "Dock"

macos_apply "defaults write com.apple.dock orientation -string bottom" \
    "Move dock to the left side of the screen"

macos_apply "defaults write com.apple.dock autohide -bool true" \
    "Automatically hide/show the Dock"

macos_apply "defaults write com.apple.dock autohide-delay -float 0" \
    "Disable the hide Dock delay"

macos_apply "defaults write com.apple.dock autohide-time-modifier -int 0" \
    "Change autohide timer to 0 seconds"

macos_apply "defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true" \
    "Enable spring loading for all Dock items"

macos_apply "defaults write com.apple.dock expose-animation-duration -float 0.1" \
    "Make all Mission Control related animations faster"

macos_apply "defaults write com.apple.dock expose-group-by-app -bool false" \
    "Do not group windows by application in Mission Control"

macos_apply "defaults write com.apple.dock launchanim -bool false" \
    "Disable opening application animations from the Dock"

macos_apply "defaults write com.apple.dock mineffect -string 'scale'" \
    "Change minimize/maximize window effect"

macos_apply "defaults write com.apple.dock minimize-to-application -bool true" \
    "Reduce clutter by minimizing windows into their application icons"

macos_apply "defaults write com.apple.dock mru-spaces -bool false" \
    "Do not automatically rearrange spaces based on most recent use"

macos_apply "defaults write com.apple.dock persistent-apps -array && \
         defaults write com.apple.dock persistent-others -array" \
    "Wipe all app icons"

macos_apply "defaults write com.apple.Dock showhidden -bool TRUE && killall Dock" \
    "Make hidden apps transparent in the Dock"

macos_apply "defaults write com.apple.dock show-process-indicators -bool true" \
    "Show indicator lights for open applications"

macos_apply "defaults write com.apple.dock show-recents -bool false" \
    "Do not show recent applications in Dock"

macos_apply "defaults write com.apple.dock showhidden -bool true" \
    "Make icons of hidden applications translucent"

macos_apply "defaults write com.apple.dock hide-mirror -bool true" \
    "Make Dock more transparent"

macos_apply "defaults write com.apple.dock tilesize -int 36" \
    "Set icon size"

macos_apply "defaults write com.apple.dock wvous-tr-corner -int 0" \
    "Disable top right hot corner"

macos_apply "defaults write com.apple.dock wvous-tl-corner -int 0" \
    "Disable top left hot corner"

macos_apply "defaults write com.apple.dock wvous-bl-corner -int 0" \
    "Disable bottom left hot corner"

macos_apply "defaults write com.apple.dock wvous-br-corner -int 5" \
    "Enable bottom right hot corner for Screen Saver"

macos_apply "/opt/homebrew/bin/dockutil -r all" \
    "Clear Dock icons"

macos_apply "/opt/homebrew/bin/dockutil --add /Applications/Safari.app/" \
    "Add Safari to the Dock"

macos_apply "/opt/homebrew/bin/dockutil --add /Applications/Firefox.app/" \
    "Add Firefox to the Dock"

macos_apply "/opt/homebrew/bin/dockutil --add /Applications/Ghostty.app/" \
    "Add Ghostty to the Dock"

macos_apply "/opt/homebrew/bin/dockutil --add /System/Applications/Messages.app/" \
    "Add Messages to the Dock"

macos_apply "/opt/homebrew/bin/dockutil --add /Applications/Notion.app/" \
    "Add Notion to the Dock"

macos_apply "/opt/homebrew/bin/dockutil --add /Applications/Obsidian.app/" \
    "Add Obsidian to the Dock"

macos_apply "/opt/homebrew/bin/dockutil --add /Applications/Spotify.app/" \
    "Add Spotify to the Dock"

macos_apply "/opt/homebrew/bin/dockutil --add /Applications/Visual Studio Code.app/" \
    "Add VS Code to the Dock"

macos_apply "/opt/homebrew/bin/dockutil --add /Applications --view grid --display folder --sort name --section others --allhomes" \
    "Add Applications to the Dock"

macos_apply "/opt/homebrew/bin/dockutil --add ~/Documents --view list --display folder --sort name --section others --allhomes" \
    "Add Documents to the Dock"

macos_apply "/opt/homebrew/bin/dockutil --add ~/Downloads --view list --display folder --sort name --section others --allhomes" \
    "Add Downloads to the Dock"

# -----------------------------------------------------------------------------
# Finder
# -----------------------------------------------------------------------------

log_step "Finder"

macos_apply "defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true && \
         defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true && \
         defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true" \
    "Automatically open a new Finder window when a volume is mounted"

macos_apply "defaults write com.apple.finder _FXShowPosixPathInTitle -bool true" \
    "Use full POSIX path as window title"

macos_apply "defaults write com.apple.finder _FXSortFoldersFirst -bool true" \
    "Keep folders on top when sorting by name"

macos_apply "defaults write com.apple.finder DisableAllAnimations -bool true" \
    "Disable all animations"

macos_apply "defaults write com.apple.finder WarnOnEmptyTrash -bool false" \
    "Disable the warning before emptying the Trash"

macos_apply "defaults write com.apple.finder FXDefaultSearchScope -string 'SCcf'" \
    "Search the current directory by default"

macos_apply "defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false" \
    "Disable warning when changing a file extension"

macos_apply "defaults write com.apple.finder FXPreferredViewStyle -string 'Nlsv'" \
    "Use list view in all Finder windows by default"

macos_apply "defaults write com.apple.finder NewWindowTarget -string 'PfDe' && \
         defaults write com.apple.finder NewWindowTargetPath -string 'file://$HOME/'" \
    "Set Desktop as the default location for new Finder windows"

macos_apply "defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true && \
         defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true && \
         defaults write com.apple.finder ShowMountedServersOnDesktop -bool true && \
         defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true" \
    "Show icons for hard drives, servers, and removable media on the desktop"

macos_apply "defaults write com.apple.finder ShowRecentTags -bool false" \
    "Do not show recent tags"

macos_apply "defaults write -g AppleShowAllExtensions -bool true" \
    "Show all filename extensions"

macos_apply "defaults write com.apple.Finder AppleShowAllFiles -bool true" \
    "Show hidden files by default"

macos_apply "defaults write com.apple.finder ShowStatusBar -bool true" \
    "Show status bar"

macos_apply "defaults write com.apple.finder ShowPathbar -bool true" \
    "Show path bar"

macos_apply "/usr/libexec/PlistBuddy -c 'Set :DesktopViewSettings:IconViewSettings:iconSize 32' ~/Library/Preferences/com.apple.finder.plist && \
         /usr/libexec/PlistBuddy -c 'Set :StandardViewSettings:IconViewSettings:iconSize 32' ~/Library/Preferences/com.apple.finder.plist" \
    "Set icon size"

macos_apply "/usr/libexec/PlistBuddy -c 'Set :DesktopViewSettings:IconViewSettings:gridSpacing 54' ~/Library/Preferences/com.apple.finder.plist && \
         /usr/libexec/PlistBuddy -c 'Set :StandardViewSettings:IconViewSettings:gridSpacing 54' ~/Library/Preferences/com.apple.finder.plist" \
    "Set icon grid spacing size"

macos_apply "/usr/libexec/PlistBuddy -c 'Set :DesktopViewSettings:IconViewSettings:textSize 12' ~/Library/Preferences/com.apple.finder.plist && \
         /usr/libexec/PlistBuddy -c 'Set :StandardViewSettings:IconViewSettings:textSize 12' ~/Library/Preferences/com.apple.finder.plist" \
    "Set icon label text size"

macos_apply "/usr/libexec/PlistBuddy -c 'Set :DesktopViewSettings:IconViewSettings:labelOnBottom true' ~/Library/Preferences/com.apple.finder.plist && \
         /usr/libexec/PlistBuddy -c 'Set :StandardViewSettings:IconViewSettings:labelOnBottom true' ~/Library/Preferences/com.apple.finder.plist" \
    "Set icon label position"

macos_apply "/usr/libexec/PlistBuddy -c 'Set :DesktopViewSettings:IconViewSettings:showItemInfo true' ~/Library/Preferences/com.apple.finder.plist && \
         /usr/libexec/PlistBuddy -c 'Set :StandardViewSettings:IconViewSettings:showItemInfo true' ~/Library/Preferences/com.apple.finder.plist" \
    "Show item info"

macos_apply "/usr/libexec/PlistBuddy -c 'Set :DesktopViewSettings:IconViewSettings:arrangeBy grid' ~/Library/Preferences/com.apple.finder.plist && \
         /usr/libexec/PlistBuddy -c 'Set :StandardViewSettings:IconViewSettings:arrangeBy grid' ~/Library/Preferences/com.apple.finder.plist" \
    "Set sort method"


# -----------------------------------------------------------------------------
# Firefox
# -----------------------------------------------------------------------------

log_step "Firefox"

macos_apply "defaults write org.mozilla.firefox AppleEnableSwipeNavigateWithScrolls -bool false" \
    "Disable backswipe"


# iTerm section removed — the terminal decision is Ghostty, not iTerm2
# (see docs/planning.md locked decisions and the Brewfile). Ghostty's
# config isn't `defaults write` at all — it's a plain text file at
# ~/.config/ghostty/config, a separate dotfile to write, not a defaults
# domain to migrate here.

# -----------------------------------------------------------------------------
# Keyboard
# -----------------------------------------------------------------------------

log_step "Keyboard"

macos_apply "defaults write -g AppleKeyboardUIMode -int 3" \
    "Enable full keyboard access for all controls"

macos_apply "defaults write -g ApplePressAndHoldEnabled -bool false" \
    "Disable press-and-hold in favor of key repeat"

macos_apply "defaults write -g 'InitialKeyRepeat_Level_Saved' -int 10" \
    "Set delay until repeat"

macos_apply "defaults write -g KeyRepeat -int 1" \
    "Set the key repeat rate to fast"

macos_apply "defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false" \
    "Disable automatic capitalization"

macos_apply "defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false" \
    "Disable automatic correction"

macos_apply "defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool false" \
    "Disable automatic period substitution"

macos_apply "defaults write -g NSAutomaticDashSubstitutionEnabled -bool false" \
    "Disable smart dashes"

macos_apply "defaults write -g NSAutomaticQuoteSubstitutionEnabled -bool false" \
    "Disable smart quotes"

macos_apply "defaults write com.apple.HIToolbox AppleFnUsageType -int 2" \
    "Remap the emoji picker to the Fn key"

# -----------------------------------------------------------------------------
# Language and Region
# -----------------------------------------------------------------------------

log_step "Language & Region"

macos_apply "defaults write -g AppleLanguages -array 'en'" \
    "Set language"

macos_apply "defaults write -g AppleMeasurementUnits -string 'Inches'" \
    "Set measurement units"

# -----------------------------------------------------------------------------
# Maps
# -----------------------------------------------------------------------------

log_step "Maps"

macos_apply "defaults write com.apple.Maps LastClosedWindowViewOptions '{
            localizeLabels = 1;   // show labels in English
            mapType = 11;         // show hybrid map
            trafficEnabled = 0;   // do not show traffic
         }'" \
    "Set view options"


# -----------------------------------------------------------------------------
# Photos
# -----------------------------------------------------------------------------

log_step "Photos"

macos_apply "defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true" \
    "Prevent Photos from opening automatically when devices are plugged in"


# -----------------------------------------------------------------------------
# Safari
# -----------------------------------------------------------------------------

# Safari settings intentionally skipped — the old per-app script for
# these failed on macOS Sequoia and was never fixed. No content exists in
# this repo to carry forward; add real `macos_apply` lines here if/when
# actually decided.

# -----------------------------------------------------------------------------
# Terminal
# -----------------------------------------------------------------------------

log_step "Terminal"

macos_apply "defaults write com.apple.terminal FocusFollowsMouse -string true" \
    "Make the focus automatically follow the mouse"

macos_apply "defaults write com.apple.terminal SecureKeyboardEntry -bool true" \
    "Enable Secure Keyboard Entry"

macos_apply "defaults write com.apple.Terminal ShowLineMarks -int 0" \
    "Hide line marks"

macos_apply "defaults write com.apple.terminal StringEncodings -array 4" \
    "Only use UTF-8"

# Ensure Touch ID is used when sudo is required.
if ! grep -q "pam_tid.so" "/etc/pam.d/sudo"; then
    macos_apply "sudo sh -c 'echo \"auth sufficient pam_tid.so\" >> /etc/pam.d/sudo'" \
        "Use Touch ID to authenticate sudo"
fi

# -----------------------------------------------------------------------------
# TextEdit
# -----------------------------------------------------------------------------

log_step "TextEdit"

macos_apply "defaults write com.apple.TextEdit PlainTextEncoding -int 4 && \
         defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4" \
    "Open and save files as UTF-8 encoded"

macos_apply "defaults write com.apple.TextEdit RichText 0" \
    "Use plain text mode for new documents"


# -----------------------------------------------------------------------------
# Trackpad
# -----------------------------------------------------------------------------

log_step "Trackpad"

macos_apply "defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true && \
         defaults write com.apple.AppleMultitouchTrackpad Clicking -int 1 && \
         defaults write -g com.apple.mouse.tapBehavior -int 1 && \
         defaults -currentHost write -g com.apple.mouse.tapBehavior -int 1" \
    "Enable Tap to click"

macos_apply "defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true && \
         defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -int 1 && \
         defaults -currentHost write -g com.apple.trackpad.enableSecondaryClick -bool true && \
         defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 0 && \
         defaults write com.apple.AppleMultitouchTrackpad TrackpadCornerSecondaryClick -int 0 && \
         defaults -currentHost write -g com.apple.trackpad.trackpadCornerClickBehavior -int 0" \
    "Map click or tap with two fingers to the secondary click"

macos_apply "defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false" \
    "Disable natural scrolling"

# -----------------------------------------------------------------------------
# Transmission
# -----------------------------------------------------------------------------

log_step "Transmission"

macos_apply "defaults write org.m0k.transmission DeleteOriginalTorrent -bool true" \
    "Delete the original torrent files"

macos_apply "defaults write org.m0k.transmission DownloadAsk -bool false" \
    "Do not prompt for confirmation before downloading"

macos_apply "defaults write org.m0k.transmission MagnetOpenAsk -bool false" \
    "Do not prompt for confirmation before downloading magnet links"

macos_apply "defaults write org.m0k.transmission CheckRemoveDownloading -bool true" \
    "Do not prompt before removing non-downloading active transfers"

macos_apply "defaults write org.m0k.transmission DownloadChoice -string 'Constant' && \
         defaults write org.m0k.transmission DownloadFolder -string '$HOME/Downloads'" \
    "Use ~/Downloads to store complete downloads"

macos_apply "defaults write org.m0k.transmission UseIncompleteDownloadFolder -bool true && \
         defaults write org.m0k.transmission IncompleteDownloadFolder -string '$HOME/Downloads/torrents'" \
    "Use ~/Downloads/torrents to store incomplete downloads"

macos_apply "defaults write org.m0k.transmission WarningDonate -bool false" \
    "Hide the donate message"

macos_apply "defaults write org.m0k.transmission WarningLegal -bool false" \
    "Hide the legal disclaimer"

macos_apply "defaults write org.m0k.transmission RandomPort -bool true" \
    "Randomize port on launch"


# -----------------------------------------------------------------------------
# UI and UX
# -----------------------------------------------------------------------------

log_step "UI & UX"

macos_apply "defaults write NSGlobalDomain AppleEnableMenuBarTransparency -bool false" \
    "Disable menu bar transparency"

macos_apply "defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true && \
         defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true" \
    "Avoid creating .DS_Store files on network or USB volumes"

macos_apply "defaults write com.apple.menuextra.battery ShowPercent -string 'NO'" \
    "Hide battery percentage from the menu bar"

macos_apply "sudo defaults write /Library/Preferences/com.apple.loginwindow showInputMenu -bool true" \
    "Show language menu in the top right corner of the boot screen"

macos_apply "defaults write com.apple.CrashReporter UseUNC 1" \
    "Make crash reports appear as notifications"

macos_apply "sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.locate.plist > /dev/null 2>&1" \
    "Allow locate command to run"

macos_apply "defaults write com.apple.LaunchServices LSQuarantine -bool false" \
    "Disable the application opening confirmation dialog"

macos_apply "defaults write com.apple.print.PrintingPrefs 'Quit When Finished' -bool true" \
    "Automatically quit the printer app when print jobs complete"

macos_apply "sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false" \
    "Disable guest account login"

macos_apply "defaults write com.apple.screencapture disable-shadow -bool true" \
    "Disable shadow in screenshots"

macos_apply "defaults write com.apple.screencapture location -string '$HOME/Desktop'" \
    "Save screenshots to the Desktop"

macos_apply "defaults write com.apple.screencapture show-thumbnail -bool false" \
    "Do not show screenshot thumbnails"

macos_apply "defaults write com.apple.screencapture type -string 'jpg'" \
    "Save screenshots as JPGs"

macos_apply "defaults write com.apple.screensaver askForPassword -int 1 && \
         defaults write com.apple.screensaver askForPasswordDelay -int 0" \
    "Require a password immediately after sleep or screen saver mode"

macos_apply "defaults write -g AppleFontSmoothing -int 2" \
    "Enable subpixel font rendering on non-Apple LCDs"

macos_apply "defaults write -g AppleShowScrollBars -string 'Always'" \
    "Always show scrollbars"

macos_apply "defaults write -g NSAutomaticWindowAnimationsEnabled -bool false" \
    "Disable window opening and closing animations"

macos_apply "defaults write -g NSDisableAutomaticTermination -bool true" \
    "Disable automatic termination of inactive apps"

macos_apply "defaults write -g NSNavPanelExpandedStateForSaveMode -bool true" \
    "Expand save panel by default"

macos_apply "defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false" \
    "Save to disk instead of iCloud by default"

macos_apply "defaults write -g NSTableViewDefaultSizeMode -int 2" \
    "Set sidebar icon size to medium"

macos_apply "defaults write -g NSUseAnimatedFocusRing -bool false" \
    "Disable the focus ring animation"

macos_apply "defaults write -g NSWindowResizeTime -float 0.001" \
    "Accelerate window resizing"

macos_apply "defaults write -g PMPrintingExpandedStateForPrint -bool true" \
    "Expand print panel by default"

macos_apply "defaults write -g QLPanelAnimationDuration -float 0" \
    "Disable Quick Look window animations"

macos_apply "defaults write com.apple.systempreferences NSQuitAlwaysKeepsWindows -bool false" \
    "Disable resume system-wide"

macos_apply "sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string 'tycho' && \
         sudo scutil --set ComputerName 'tycho' && \
         sudo scutil --set HostName 'tycho' && \
         sudo scutil --set LocalHostName 'tycho'" \
    "Set computer name"

macos_apply "sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.DiskArbitration.diskarbitrationd.plist DADisableEjectNotification -bool YES && sudo pkill diskarbitrationd" \
    "Disable the disk warning when unplugging USB drives"

macos_apply "sudo systemsetup -setrestartfreeze on" \
    "Restart automatically if the computer freezes"

macos_apply "sudo defaults write /Library/Preferences/com.apple.Bluetooth.plist ControllerPowerState 0 && \
         sudo launchctl unload /System/Library/LaunchDaemons/com.apple.blued.plist && \
         sudo launchctl load /System/Library/LaunchDaemons/com.apple.blued.plist" \
    "Turn Bluetooth off"

macos_apply "for domain in ~/Library/Preferences/ByHost/com.apple.systemuiserver.*; do
            sudo defaults write \"\${domain}\" dontAutoLoad -array \
                '/System/Library/CoreServices/Menu Extras/TimeMachine.menu' \
                '/System/Library/CoreServices/Menu Extras/Volume.menu'
         done \
            && sudo defaults write com.apple.systemuiserver menuExtras -array \
                '/System/Library/CoreServices/Menu Extras/Bluetooth.menu' \
                '/System/Library/CoreServices/Menu Extras/AirPort.menu' \
                '/System/Library/CoreServices/Menu Extras/Battery.menu' \
                '/System/Library/CoreServices/Menu Extras/Clock.menu'
        " \
    "Hide Time Machine and Volume icons from the menu bar"

# -----------------------------------------------------------------------------
# Restart affected processes
# -----------------------------------------------------------------------------

log_step "Restarting affected processes"

for _proc in "${RESTART_PROCESSES[@]:-}"; do
    killall "$_proc" &>/dev/null || true
done

