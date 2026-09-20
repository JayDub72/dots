# Brewfile — declarative package manifest.
# Regenerate a snapshot of what's currently installed with:
#   brew bundle dump --force --describe
# Apply this file with:
#   brew bundle --file=Brewfile
#
# Anything not listed here should be removable with
# `brew bundle cleanup --file=Brewfile` (dry-run first).
# Grouped by logical purpose rather than alphabetically — see section headers.
#
# Locked decisions (docs/planning.md):
#   - No `mise`, no `uv`.
#   - Editor: VS Code (cask "visual-studio-code"), not VSCodium.
#   - Plex: cask "plex-htpc" (client), not "plex-media-server" (self-hosted
#     server) or the deprecated "plex-media-player".
#   - Terminal emulator: Ghostty (iTerm2 dropped per "pick one, not both").
#   - If Ansible gets used (per docs/ssh-setup-plan.md Phase 7):
#     brew "ansible"

# ============================================================================
# Formulae (CLI tools & libraries)
# ============================================================================

# --- Git & Version Control -------------------------------------------------
brew "git"  # Distributed revision control system
brew "git-extras"  # Small git utilities
brew "git-flow"  # Extensions to follow Vincent Driessen's branching model
brew "git-lfs"  # Git extension for versioning large files
brew "gh"  # GitHub command-line tool
brew "libgit2"  # C library of Git core methods, re-entrant and linkable

# --- Shell, Terminal & Prompt ----------------------------------------------
brew "bat"  # Clone of cat(1) with syntax highlighting and Git integration
brew "eza"  # Modern, maintained replacement for ls
brew "fzf"  # Command-line fuzzy finder written in Go
brew "grc"  # Colorize logfiles and command output
brew "libptytty"  # Library for OS-independent pseudo-TTY management
brew "powerlevel10k"  # Theme for zsh
brew "rename"  # Perl-powered file rename script with many helpful built-ins
brew "rlwrap"  # Readline wrapper: adds readline support to tools that lack it
brew "trash"  # CLI tool that moves files or folders to the trash
brew "tree"  # Display directories as trees (with optional color/HTML output)
brew "zsh-autosuggestions"  # Fish-like fast/unobtrusive autosuggestions for zsh
brew "zsh-completions"  # Additional completion definitions for zsh
brew "zsh-syntax-highlighting"  # Fish shell-like syntax highlighting for zsh

# --- System & Mac Utilities ------------------------------------------------
brew "coreutils"  # GNU File, Shell, and Text utilities
brew "fclones"  # Efficient duplicate file finder
brew "findutils"  # Collection of GNU find, xargs, and locate
brew "gawk"  # GNU awk utility
brew "grep"  # GNU grep, egrep and fgrep
brew "moreutils"  # Collection of tools that nobody wrote when UNIX was young
brew "psgrep"  # Shortcut for the 'ps aux | grep' idiom
brew "pv"  # Monitor data's progress through a pipe

brew "dockutil"  # Tool for managing dock items
brew "duti"  # Select default apps for documents and URL schemes on macOS
brew "mas"  # macOS software installation
brew "mole"  # mac cleanup utility

# --- Media: Video, Image & Audio Processing --------------------------------
brew "aom"  # Codec library for encoding and decoding AV1 video streams
brew "dav1d"  # AV1 decoder targeted to be small and fast
brew "exiftool"  # Perl library for reading and writing EXIF metadata
brew "ffmpeg"  # Play, record, convert, and stream audio and video
brew "freetype"  # Software library to render fonts
brew "giflib"  # Library and utilities for processing GIFs
brew "imagemagick"  # Tools and libraries to manipulate images in many formats
brew "jpeg-turbo"  # JPEG image codec that aids compression and decompression
brew "lame"  # High quality MPEG Audio Layer III (MP3) encoder
brew "libde265"  # Open h.265 video codec implementation
brew "libheif"  # HEIF file format decoder and encoder
brew "libpng"  # Library for manipulating PNG images
brew "libtiff"  # TIFF library and utilities
brew "libvmaf"  # Perceptual video quality assessment (multi-method fusion)
brew "libvpx"  # VP8/VP9 video codec
brew "little-cms2"  # Color management engine supporting ICC profiles
brew "mpg123"  # MP3 player for Linux and UNIX
brew "opus"  # Audio codec
brew "sdl2-compat"  # SDL2 compatibility layer that uses SDL3 behind the scenes
brew "sdl3"  # Low-level access to audio, keyboard, mouse, joystick, and graphics
brew "svt-av1"  # AV1 encoder
brew "yt-dlp"  # Feature-rich command-line audio/video downloader
brew "webp"  # Image format providing lossless and lossy compression
brew "x264"  # H.264/AVC encoder
brew "x265"  # H.265/HEVC encoder

# --- Security, Crypto & SSH ------------------------------------------------
# link: false is required — see docs/ssh-setup-plan.md Phase 3. Homebrew's
# openssh build sits ahead of /usr/bin on PATH if linked; vanilla ssh/ssh-add
# don't understand UseKeychain or --apple-use-keychain at all, so Keychain-
# based passphrase-free auth silently breaks and you get prompted every time.
brew "openssh", link: false  # OpenBSD freely-licensed SSH connectivity tools
brew "openssl@3"  # Cryptography and SSL/TLS Toolkit
brew "ca-certificates"  # Mozilla CA certificate store
brew "certifi"  # Mozilla CA bundle for Python
brew "libfido2"  # Library for FIDO U2F & FIDO2, including USB support
brew "ssh-copy-id"  # Add a public key to a remote machine's authorized_keys file

# --- Networking ------------------------------------------------------------
brew "curl"  # Get a file from an HTTP, HTTPS or FTP server
brew "wget"  # Internet file retriever
brew "libidn2"  # International domain name library (IDNA2008, Punycode, TR46)
brew "ldns"  # DNS library written in C
brew "libnghttp2"  # HTTP/2 C Library
brew "libnghttp3"  # HTTP/3 library written in C
brew "libngtcp2"  # IETF QUIC protocol implementation
brew "libpsl"  # C library for the Public Suffix List
brew "libssh2"  # C library implementing the SSH2 protocol

# --- Compression & Archives ------------------------------------------------
brew "brotli"  # Generic-purpose lossless compression algorithm by Google
brew "lz4"  # Extremely fast compression algorithm
brew "xz"  # General-purpose data compression with high compression ratio
brew "zstd"  # Zstandard real-time compression algorithm
brew "zopfli"  # New zlib (gzip, deflate) compatible compressor
brew "p7zip"  # 7-Zip (high compression file archiver) implementation

# --- Languages & Runtimes --------------------------------------------------
brew "python@3.12"  # Interpreted, interactive, object-oriented programming language
brew "python@3.14"  # Interpreted, interactive, object-oriented programming language
brew "deno"  # Secure runtime for JavaScript and TypeScript
brew "mpdecimal"  # Library for decimal floating point arithmetic
brew "sqlite"  # Command-line interface for SQLite
brew "pipx"  # Execute binaries from Python packages in isolated environments

# --- Supporting Libraries (auto-pulled by the above) -----------------------
brew "gmp"  # GNU multiple precision arithmetic library
brew "mpfr"  # C library for multiple-precision floating-point computations
brew "json-c"  # JSON parser for C
brew "libcbor"  # CBOR protocol implementation for C and others
brew "llhttp"  # Port of http_parser to llparse
brew "m4"  # Macro processing language
brew "oniguruma"  # Regular expressions library
brew "readline"  # Library for command-line editing
brew "libtool"  # Generic library support script
brew "libunistring"  # C string library for manipulating Unicode strings
brew "gettext"  # GNU internationalization (i18n) and localization (l10n) library
brew "pcre2"  # Perl compatible regular expressions library with a new API

# ============================================================================
# Casks (GUI apps & fonts)
# ============================================================================

# --- Security, Privacy & VPN -----------------------------------------------
cask "1password"  # Password manager that keeps all passwords secure behind one password
cask "1password-cli"  # Command-line interface for 1Password
cask "protonvpn"  # VPN client focusing on security

# --- Browsers --------------------------------------------------------------
cask "firefox"  # Web browser
cask "google-chrome"  # Web browser

# --- Dev Tools & Terminals -------------------------------------------------
cask "claude-code"  # Terminal-based AI coding assistant
cask "ghostty"  # Terminal emulator using platform-native UI and GPU acceleration
cask "visual-studio-code"  # Open-source code editor

# --- Productivity & Notes --------------------------------------------------
cask "logos"  # Bible study software
cask "microsoft-office"  # Office suite (installs Word, Excel, PowerPoint, Outlook, OneNote, OneDrive)
cask "microsoft-auto-update"  # Provides updates to various Microsoft products
cask "notion"  # App to write, plan, collaborate, and get organized
cask "obsidian"  # Knowledge base built on a local folder of plain-text Markdown files

# --- Communication ---------------------------------------------------------
cask "discord"  # Voice and text chat software

# --- Cloud Storage & Backup ------------------------------------------------
cask "backblaze"  # Cloud data backup and storage service
cask "google-drive"  # Client for the Google Drive storage service

# --- Media & Entertainment -------------------------------------------------
cask "gimp"  # Free and open-source image editor
cask "plex-htpc"  # Plex client (home theater PC app)
cask "spotify"  # Music streaming service
cask "transmission"  # Open-source BitTorrent client
cask "vlc"  # Multimedia player

# --- Mac Utilities ---------------------------------------------------------
cask "appcleaner"  # Application uninstaller
cask "hiddenbar"  # Utility to hide menu bar items
cask "keka"  # File archiver
cask "omnidisksweeper"  # Finds large, unwanted files and deletes them
cask "shottr"  # Screenshot measurement and annotation tool

# --- Fonts -----------------------------------------------------------------
cask "font-hack"  # Hack monospaced font
cask "font-hack-nerd-font"  # Hack Nerd Font (patched with programming icons)
cask "font-jetbrains-mono"  # JetBrains Mono monospaced font
cask "font-jetbrains-mono-nerd-font"  # JetBrains Mono Nerd Font (patched with programming icons)
cask "font-meslo-lg-nerd-font"  # Meslo LG Nerd Font (patched with programming icons)


# ============================================================================
# Visual Studio Code Extensions (vscode) — see also lib/vscode.sh
# ============================================================================

vscode "anthropic.claude-code"  # Claude Code integration
vscode "catppuccin.catppuccin-vsc"  # Catppuccin color themes
vscode "catppuccin.catppuccin-vsc-icons"  # Catppuccin file icons
vscode "esbenp.prettier-vscode"  # Prettier formatter
vscode "github.codespaces"  # GitHub Codespaces
vscode "github.remotehub"  # GitHub remote repositories
vscode "ms-vscode-remote.remote-ssh"  # Remote development over SSH
vscode "ms-vscode-remote.remote-ssh-edit"  # Edit SSH configuration
vscode "ms-vscode.remote-explorer"  # Remote target explorer
vscode "ms-vscode.remote-repositories"  # Remote repository support
vscode "pkief.material-icon-theme"  # Material file icons
vscode "pkief.material-product-icons"  # Material product icons
vscode "redhat.vscode-yaml"  # YAML language support
vscode "shd101wyy.markdown-preview-enhanced"  # Markdown preview
vscode "vscode-icons-team.vscode-icons"  # VS Code file icons
