# Installed Software Inventory

Generated from `brew_installed.txt` (226 Homebrew packages) and `apps_installed.txt` (contents of `/Applications` and `~/Applications`) on 2026-09-04.

**Summary:** 185 Homebrew formulae (CLI tools/libraries), 41 Homebrew casks (GUI apps/fonts), and 29 additional apps present in `/Applications` that were **not** installed via Homebrew (Apple system apps, Mac App Store apps, and direct-download installs).

A few notable flags before the tables:

- **Cursor** appears as an installed Homebrew cask (`cursor`) but no `Cursor.app` was found in either `/Applications` or `~/Applications` — it may have been uninstalled, moved, or renamed since the cask was installed.
- **Google Docs.app, Google Sheets.app, Google Slides.app** are Chrome-generated web-app shortcuts (created via "Install as app"), not real standalone installs — they just open the web versions in an app-like Chrome window.
- **Microsoft Excel/OneNote/Outlook/PowerPoint/Word.app** and **OneDrive.app** are sub-apps installed by the single Homebrew cask `microsoft-office`, not separate installs.
- Four formulae are installed from **third-party taps** rather than `homebrew/core`: `m4b-tool` (`sandreas/tap`), `sfnt2woff` and `sfnt2woff-zopfli` (`bramstein/webfonttools`), and `ttrpg-convert-cli` (`ebullient/tap`).
- **neofetch** is installed locally but has been removed/disabled in `homebrew/core` (its upstream project was archived in 2024), so it's an orphaned install no longer tracked by any tap.

"Trusted Access" below means: does normal use of this software involve granting it a special macOS permission or elevated privilege — Full Disk Access, Accessibility, Screen Recording, Camera/Microphone, a System Extension/VPN configuration approval, Keychain access, admin/sudo, or USB device access. "No" means ordinary Gatekeeper notarization is the only gate. "Partial" means it's conditional on how the tool is used.

---

## Homebrew Formulae (CLI tools & libraries) — 185

| Name | Tap | Description | Trusted Access |
|---|---|---|---|
| aom | homebrew/core | Codec library for encoding and decoding AV1 video streams | No |
| apr | homebrew/core | Apache Portable Runtime library | No |
| apr-util | homebrew/core | Companion library to apr, the Apache Portable Runtime library | No |
| argon2 | homebrew/core | Password hashing library and CLI utility | No |
| atomicparsley | homebrew/core | MPEG-4 command-line tool | No |
| autoconf | homebrew/core | Automatic configure script builder | No |
| bat | homebrew/core | Clone of cat(1) with syntax highlighting and Git integration | No |
| brotli | homebrew/core | Generic-purpose lossless compression algorithm by Google | No |
| ca-certificates | homebrew/core | Mozilla CA certificate store | No |
| cairo | homebrew/core | Vector graphics library with cross-device output support | No |
| certifi | homebrew/core | Mozilla CA bundle for Python | No |
| coreutils | homebrew/core | GNU File, Shell, and Text utilities | No |
| curl | homebrew/core | Get a file from an HTTP, HTTPS or FTP server | No |
| dav1d | homebrew/core | AV1 decoder targeted to be small and fast | No |
| deno | homebrew/core | Secure runtime for JavaScript and TypeScript | No |
| dockutil | homebrew/core | Tool for managing dock items | No |
| duti | homebrew/core | Select default apps for documents and URL schemes on macOS | No |
| exiftool | homebrew/core | Perl library for reading and writing EXIF metadata | No |
| eza | homebrew/core | Modern, maintained replacement for ls | No |
| fclones | homebrew/core | Efficient duplicate file finder | Partial — Full Disk Access to scan protected folders |
| fdk-aac | homebrew/core | Standalone library of the Fraunhofer FDK AAC code from Android | No |
| fdk-aac-encoder | homebrew/core | Command-line encoder frontend for libfdk-aac | No |
| ffmpeg | homebrew/core | Play, record, convert, and stream audio and video | Partial — Camera/Mic access if capturing devices |
| findutils | homebrew/core | Collection of GNU find, xargs, and locate | No |
| fontconfig | homebrew/core | XML-based font configuration API | No |
| freetds | homebrew/core | Libraries to talk to Microsoft SQL Server and Sybase databases | No |
| freetype | homebrew/core | Software library to render fonts | No |
| fzf | homebrew/core | Command-line fuzzy finder written in Go | No |
| gawk | homebrew/core | GNU awk utility | No |
| gd | homebrew/core | Graphics library to dynamically manipulate images | No |
| gettext | homebrew/core | GNU internationalization (i18n) and localization (l10n) library | No |
| gh | homebrew/core | GitHub command-line tool | Partial — stores auth token in system Keychain |
| giflib | homebrew/core | Library and utilities for processing GIFs | No |
| git | homebrew/core | Distributed revision control system | No |
| git-extras | homebrew/core | Small git utilities | No |
| git-flow | homebrew/core | Extensions to follow Vincent Driessen's branching model | No |
| git-lfs | homebrew/core | Git extension for versioning large files | No |
| glib | homebrew/core | Core application library for C | No |
| gmp | homebrew/core | GNU multiple precision arithmetic library | No |
| gnupg | homebrew/core | GNU Privacy Guard (OpenPGP) | Partial — pinentry prompts for key passphrases, manages local keyring |
| gnutls | homebrew/core | GNU Transport Layer Security (TLS) Library | No |
| gpac | homebrew/core | Multimedia framework for research and academic purposes | No |
| gpgme | homebrew/core | Library access to GnuPG | Partial — wraps GnuPG keyring/agent access |
| gpgmepp | homebrew/core | C++ bindings for gpgme | Partial — bindings to GnuPG keyring access |
| graphite2 | homebrew/core | Smart font renderer for non-Roman scripts | No |
| grc | homebrew/core | Colorize logfiles and command output | No |
| grep | homebrew/core | GNU grep, egrep and fgrep | No |
| harfbuzz | homebrew/core | OpenType text shaping engine | No |
| highway | homebrew/core | Performance-portable, length-agnostic SIMD with runtime dispatch | No |
| icu4c@78 | homebrew/core | C/C++ and Java libraries for Unicode and globalization | No |
| imagemagick | homebrew/core | Tools and libraries to manipulate images in many formats | No |
| imath | homebrew/core | Library of 2D and 3D vector, matrix, and math operations | No |
| jpeg-turbo | homebrew/core | JPEG image codec that aids compression and decompression | No |
| jpeg-xl | homebrew/core | New file format for still image compression | No |
| json-c | homebrew/core | JSON parser for C | No |
| krb5 | homebrew/core | Network authentication protocol | No |
| lame | homebrew/core | High quality MPEG Audio Layer III (MP3) encoder | No |
| ldns | homebrew/core | DNS library written in C | No |
| libassuan | homebrew/core | Assuan IPC Library (underlies GnuPG agent/pinentry) | Partial — IPC lib underlying GnuPG agent/pinentry |
| libavif | homebrew/core | Library for encoding and decoding .avif files | No |
| libcbor | homebrew/core | CBOR protocol implementation for C and others | No |
| libde265 | homebrew/core | Open h.265 video codec implementation | No |
| libdeflate | homebrew/core | Heavily optimized DEFLATE/zlib/gzip compression and decompression | No |
| libfido2 | homebrew/core | Library for FIDO U2F & FIDO2, including USB support | Yes — USB FIDO2/U2F security-key device access |
| libgcrypt | homebrew/core | Cryptographic library based on the code from GnuPG | Partial — crypto lib underlying GnuPG (no direct keychain access itself) |
| libgit2 | homebrew/core | C library of Git core methods, re-entrant and linkable | No |
| libgpg-error | homebrew/core | Common error values for all GnuPG components | No |
| libheif | homebrew/core | HEIF file format decoder and encoder | No |
| libidn2 | homebrew/core | International domain name library (IDNA2008, Punycode, TR46) | No |
| libksba | homebrew/core | X.509 and CMS library | No |
| liblinear | homebrew/core | Library for large linear classification | No |
| libnghttp2 | homebrew/core | HTTP/2 C Library | No |
| libnghttp3 | homebrew/core | HTTP/3 library written in C | No |
| libngtcp2 | homebrew/core | IETF QUIC protocol implementation | No |
| libogg | homebrew/core | Ogg Bitstream Library | No |
| libpng | homebrew/core | Library for manipulating PNG images | No |
| libpq | homebrew/core | Postgres C API library | No |
| libpsl | homebrew/core | C library for the Public Suffix List | No |
| libptytty | homebrew/core | Library for OS-independent pseudo-TTY management | No |
| libsodium | homebrew/core | NaCl networking and cryptography library | No |
| libssh2 | homebrew/core | C library implementing the SSH2 protocol | No |
| libtasn1 | homebrew/core | ASN.1 structure parser library | No |
| libtiff | homebrew/core | TIFF library and utilities | No |
| libtool | homebrew/core | Generic library support script | No |
| libunistring | homebrew/core | C string library for manipulating Unicode strings | No |
| libusb | homebrew/core | Library for USB device access | No — enables USB access at library level but doesn't itself prompt for permission |
| libuv | homebrew/core | Multi-platform support library focused on async I/O | No |
| libvmaf | homebrew/core | Perceptual video quality assessment (multi-method fusion) | No |
| libvorbis | homebrew/core | Vorbis general audio compression codec | No |
| libvpx | homebrew/core | VP8/VP9 video codec | No |
| libx11 | homebrew/core | X.Org: Core X11 protocol client library | No |
| libxau | homebrew/core | X.Org: Sample Authorization Protocol for X | No |
| libxcb | homebrew/core | X.Org: Interface to the X Window System protocol | No |
| libxdmcp | homebrew/core | X.Org: X Display Manager Control Protocol library | No |
| libxext | homebrew/core | X.Org: Library for common extensions to the X11 protocol | No |
| libxrender | homebrew/core | X.Org: Library for the Render Extension to the X11 protocol | No |
| libyaml | homebrew/core | YAML Parser | No |
| libzip | homebrew/core | C library for reading, creating, and modifying zip archives | No |
| little-cms2 | homebrew/core | Color management engine supporting ICC profiles | No |
| llhttp | homebrew/core | Port of http_parser to llparse | No |
| lpeg | homebrew/core | Parsing Expression Grammars for Lua | No |
| lua | homebrew/core | Powerful, lightweight programming language | No |
| luajit | homebrew/core | Just-In-Time Compiler for the Lua programming language | No |
| luv | homebrew/core | Bare libuv bindings for Lua | No |
| lz4 | homebrew/core | Extremely fast compression algorithm | No |
| lzo | homebrew/core | Real-time data compression library | No |
| m4 | homebrew/core | Macro processing language | No |
| m4b-tool | sandreas/tap | Merges/converts audio/ebook files into m4b audiobooks | No |
| mlx | homebrew/core | Array framework for Apple silicon | No |
| mlx-c | homebrew/core | C API for MLX | No |
| moreutils | homebrew/core | Collection of tools that nobody wrote when UNIX was young | No |
| mp4v2 | homebrew/core | Read, create, and modify MP4 files | No |
| mpdecimal | homebrew/core | Library for decimal floating point arithmetic | No |
| mpfr | homebrew/core | C library for multiple-precision floating-point computations | No |
| mpg123 | homebrew/core | MP3 player for Linux and UNIX | No |
| neofetch | *(removed from homebrew/core — orphaned)* | Command-line system information display tool | No |
| neovim | homebrew/core | Ambitious Vim-fork focused on extensibility and agility | No |
| net-snmp | homebrew/core | Implements SNMP v1, v2c, and v3, using IPv4 and IPv6 | No |
| nettle | homebrew/core | Low-level cryptographic library | No |
| nmap | homebrew/core | Port scanning utility for large networks | Partial — needs sudo for raw-socket scans |
| npth | homebrew/core | New GNU portable threads library | No |
| nspr | homebrew/core | Platform-neutral API for system-level and libc-like functions | No |
| nss | homebrew/core | Libraries for security-enabled client and server applications | No |
| ollama | homebrew/core | Create, run, and share large language models (LLMs) locally | Partial — local network access prompt |
| oniguruma | homebrew/core | Regular expressions library | No |
| openexr | homebrew/core | High dynamic-range image file format | No |
| openjdk | homebrew/core | Development kit for the Java programming language | No |
| openjpeg | homebrew/core | Library for JPEG-2000 image manipulation | No |
| openjph | homebrew/core | Open-source implementation of JPEG2000 Part-15 (HTJ2K) | No |
| openldap | homebrew/core | Open source suite of directory software | No |
| openssh | homebrew/core | OpenBSD freely-licensed SSH connectivity tools | Partial — can integrate with macOS Keychain (ssh-add --apple-use-keychain) |
| openssl@3 | homebrew/core | Cryptography and SSL/TLS Toolkit | No |
| opus | homebrew/core | Audio codec | No |
| p11-kit | homebrew/core | Library to load and enumerate PKCS#11 modules | No |
| p7zip | homebrew/core | 7-Zip (high compression file archiver) implementation | No |
| pcre2 | homebrew/core | Perl compatible regular expressions library with a new API | No |
| php | homebrew/core | General-purpose scripting language | No |
| pinentry | homebrew/core | Passphrase entry dialog utilizing the Assuan protocol | Partial — passphrase entry, may prompt for Keychain |
| pipx | homebrew/core | Execute binaries from Python packages in isolated environments | No |
| pixman | homebrew/core | Low-level library for pixel manipulation | No |
| pkgconf | homebrew/core | Package compiler and linker metadata toolkit | No |
| poppler | homebrew/core | PDF rendering library (based on the xpdf-3.0 code base) | No |
| powerlevel10k | homebrew/core | Theme for zsh | No |
| psgrep | homebrew/core | Shortcut for the 'ps aux \| grep' idiom | No |
| pv | homebrew/core | Monitor data's progress through a pipe | No |
| python@3.12 | homebrew/core | Interpreted, interactive, object-oriented programming language | No |
| python@3.14 | homebrew/core | Interpreted, interactive, object-oriented programming language | No |
| rbenv | homebrew/core | Ruby version manager | No |
| readline | homebrew/core | Library for command-line editing | No |
| rename | homebrew/core | Perl-powered file rename script with many helpful built-ins | No |
| rlwrap | homebrew/core | Readline wrapper: adds readline support to tools that lack it | No |
| rtmpdump | homebrew/core | Tool for downloading RTMP streaming media | No |
| ruby | homebrew/core | Powerful, clean, object-oriented scripting language | No |
| ruby-build | homebrew/core | Install various Ruby versions and implementations | No |
| screenresolution | homebrew/core | Get, set, and list display resolution | No |
| sdl2-compat | homebrew/core | SDL2 compatibility layer that uses SDL3 behind the scenes | No |
| sdl3 | homebrew/core | Low-level access to audio, keyboard, mouse, joystick, and graphics | No |
| sfnt2woff | bramstein/webfonttools | Convert existing TrueType/OpenType fonts to WOFF format | No |
| sfnt2woff-zopfli | bramstein/webfonttools | WOFF utilities with Zopfli compression | No |
| sqlite | homebrew/core | Command-line interface for SQLite | No |
| ssh-copy-id | homebrew/core | Add a public key to a remote machine's authorized_keys file | No |
| svt-av1 | homebrew/core | AV1 encoder | No |
| theora | homebrew/core | Open video compression format | No |
| tidy-html5 | homebrew/core | Granddaddy of HTML tools, with support for modern standards | No |
| trash | homebrew/core | CLI tool that moves files or folders to the trash | No |
| tree | homebrew/core | Display directories as trees (with optional color/HTML output) | No |
| tree-sitter | homebrew/core | Incremental parsing library | No |
| ttrpg-convert-cli | ebullient/tap | Converts 5etools/pf2etools JSON into Obsidian-friendly Markdown | No |
| unibilium | homebrew/core | Very basic terminfo library | No |
| unixodbc | homebrew/core | ODBC 3 connectivity for UNIX | No |
| utf8proc | homebrew/core | Clean C library for processing UTF-8 Unicode data | No |
| webp | homebrew/core | Image format providing lossless and lossy compression | No |
| wget | homebrew/core | Internet file retriever | No |
| woff2 | homebrew/core | Utilities to create and convert Web Open Font File (WOFF) files | No |
| x264 | homebrew/core | H.264/AVC encoder | No |
| x265 | homebrew/core | H.265/HEVC encoder | No |
| xorgproto | homebrew/core | X.Org: Protocol Headers | No |
| xz | homebrew/core | General-purpose data compression with high compression ratio | No |
| yt-dlp | homebrew/core | Feature-rich command-line audio/video downloader | No |
| zopfli | homebrew/core | New zlib (gzip, deflate) compatible compressor | No |
| zoxide | homebrew/core | Shell extension to navigate your filesystem faster | No |
| zsh-autosuggestions | homebrew/core | Fish-like fast/unobtrusive autosuggestions for zsh | No |
| zsh-completions | homebrew/core | Additional completion definitions for zsh | No |
| zsh-syntax-highlighting | homebrew/core | Fish shell-like syntax highlighting for zsh | No |
| zstd | homebrew/core | Zstandard real-time compression algorithm | No |

---

## Homebrew Casks (GUI apps & fonts) — 41

| Name | Tap | Description | Trusted Access |
|---|---|---|---|
| 1password | homebrew/cask | Password manager that keeps all passwords secure behind one password | Yes — Accessibility + Keychain/biometric access for autofill |
| 1password-cli | homebrew/cask | Command-line interface for 1Password | Partial — Keychain integration for the op CLI |
| appcleaner | homebrew/cask | Application uninstaller | No |
| backblaze | homebrew/cask | Cloud data backup and storage service | Yes — Full Disk Access and System Extension approval for backup |
| claude-code | homebrew/cask | Terminal-based AI coding assistant | No |
| cursor | homebrew/cask | AI-powered code editor ("write, edit, and chat about your code") | No *(no matching .app found in /Applications — see note above)* |
| discord | homebrew/cask | Voice and text chat software | No |
| firefox | homebrew/cask | Web browser | No |
| font-hack | homebrew/cask | Hack monospaced font | No |
| font-hack-nerd-font | homebrew/cask | Hack Nerd Font (patched with programming icons) | No |
| font-jetbrains-mono | homebrew/cask | JetBrains Mono monospaced font | No |
| font-jetbrains-mono-nerd-font | homebrew/cask | JetBrains Mono Nerd Font (patched with programming icons) | No |
| font-meslo-lg-nerd-font | homebrew/cask | Meslo LG Nerd Font (patched with programming icons) | No |
| font-noto-serif | homebrew/cask | Noto Serif font family | No |
| font-overpass | homebrew/cask | Overpass font family | No |
| font-roboto | homebrew/cask | Roboto font family | No |
| font-rubik | homebrew/cask | Rubik font family | No |
| ghostty | homebrew/cask | Terminal emulator using platform-native UI and GPU acceleration | No |
| gimp | homebrew/cask | Free and open-source image editor | No |
| google-chrome | homebrew/cask | Web browser | No |
| google-drive | homebrew/cask | Client for the Google Drive storage service | Yes — Full Disk Access / File Provider System Extension for sync |
| hiddenbar | homebrew/cask | Utility to hide menu bar items | Yes — Accessibility permission (to detect/manage other menu bar icons) |
| iterm2 | homebrew/cask | Terminal emulator, alternative to Apple's Terminal app | Partial — optional Accessibility permission for hotkey window/global features |
| keka | homebrew/cask | File archiver | No |
| logos | homebrew/cask | Bible study software | No |
| microsoft-auto-update | homebrew/cask | Provides updates to various Microsoft products | Partial — admin password for installer/updates |
| microsoft-office | homebrew/cask | Office suite (installs Word, Excel, PowerPoint, Outlook, OneNote, OneDrive) | Partial — installer needs admin password; individual apps may request Calendar/Contacts access |
| nordvpn | homebrew/cask | VPN client for secure internet access and private browsing | Yes — System Extension / VPN configuration approval |
| notion | homebrew/cask | App to write, plan, collaborate, and get organized | No |
| obsidian | homebrew/cask | Knowledge base built on a local folder of plain-text Markdown files | No |
| omnidisksweeper | homebrew/cask | Finds large, unwanted files and deletes them | Yes — Full Disk Access to scan the whole disk |
| plex-media-player | homebrew/cask | Home media player *(deprecated cask; replaced by plex/plex-htpc)* | No |
| protonvpn | homebrew/cask | VPN client focusing on security | Yes — System Extension / VPN configuration approval |
| rar | homebrew/cask | Archive manager for data compression and backups | No |
| shottr | homebrew/cask | Screenshot measurement and annotation tool | Yes — Screen Recording (and Accessibility) permission to capture screen content |
| spotify | homebrew/cask | Music streaming service | No |
| the-unarchiver | homebrew/cask | Unpacks archive files | No |
| transmission | homebrew/cask | Open-source BitTorrent client | No |
| visual-studio-code | homebrew/cask | Open-source code editor | No |
| vlc | homebrew/cask | Multimedia player | No |
| vscodium | homebrew/cask | Binary releases of VS Code without Microsoft branding/telemetry/licensing | No |

---

## Apps Not Installed via Homebrew — 29

Everything below was found in `/Applications` or `~/Applications` but is not a Homebrew formula or cask — these come from Apple (pre-installed), the Mac App Store, or a direct vendor download.

| Name | Source | Category | Description | Trusted Access |
|---|---|---|---|---|
| 5E_ET | Unknown | Non-Homebrew App | Name pattern suggests a D&D 5th Edition tool (e.g. encounter/combat tracker); no definitive match found | Unknown |
| Adblock Plus | Direct download (adblockplus.org) | Non-Homebrew App | Ad-blocking companion app, installs as a Safari content-blocker extension | Requires enabling as a Safari extension |
| Antigravity | Direct download (antigravity.google) | Non-Homebrew App | Google's agentic AI coding IDE built on Gemini | May prompt for Accessibility/Automation permissions to control editor, terminal, browser |
| Apple Configurator | Mac App Store | Non-Homebrew App | Apple's tool for bulk-configuring and supervising iPhone/iPad/Apple TV devices | Yes — USB device access to manage connected iOS devices; Full Disk Access |
| BackblazeRestore | Bundled with Backblaze | Non-Homebrew App | Helper app to download and restore files from a Backblaze backup archive | Likely Full Disk Access to write restored files |
| balenaEtcher | Direct download (balena.io/etcher) | Non-Homebrew App | Flashes OS images (ISO/IMG) onto USB drives and SD cards | Yes — admin password to write raw disk images |
| Claude | Direct download (claude.ai) | Non-Homebrew App | Anthropic's desktop app for the Claude AI assistant | No — may request Accessibility only if using computer-use/desktop features |
| Foundry Virtual Tabletop | Direct download (foundryvtt.com, licensed) | Non-Homebrew App | Self-hosted virtual tabletop for online D&D/RPG sessions | Partial — runs a local web server, may prompt for local network/firewall access |
| Google Docs / Sheets / Slides | N/A (Chrome web-app shortcut) | N/A | Chrome-generated shortcuts that just open the web apps in an app-like window — not real installs | N/A |
| iMovie | Apple system app | System App | Apple's free video editing app | Partial — Photos library, Camera, Microphone access for importing/recording |
| ImmiBridge | Direct download / GitHub | Non-Homebrew App | Syncs an Apple Photos library to a self-hosted Immich photo server | Partial — Photos library access; network access to reach the server |
| Jellyfin Media Player | Direct download (jellyfin.org) | Non-Homebrew App | Open-source desktop client for a self-hosted Jellyfin media server | Partial — local network access to find/connect to the server |
| Keynote | Apple system app | System App | Apple's presentation app (iWork) | No |
| Libation | Direct download / GitHub (libationapp.com) | Non-Homebrew App | Backs up and downloads owned Audible audiobooks for local storage | Partial — Keychain access to store Audible account credentials |
| Newshosting | Direct download (bundled with Usenet subscription) | Non-Homebrew App | Usenet newsreader client | No — normal internet/Downloads folder access only |
| Nicotine+ | Direct download / GitHub (nicotine-plus.org) | Non-Homebrew App | Open-source client for the Soulseek P2P file-sharing network | Partial — local network/firewall permission for incoming connections |
| Numbers | Apple system app | System App | Apple's spreadsheet app (iWork) | No |
| OpenAudible | Direct download (openaudible.org) | Non-Homebrew App | Downloads and converts owned Audible audiobooks to MP3/M4B | Partial — Keychain access for Audible login; Downloads folder write access |
| Pages | Apple system app | System App | Apple's word processor (iWork) | No |
| Prime Video | Apple system app (pre-installed on recent macOS) | System App | Amazon's video streaming app | No |
| Quicken | Direct download (quicken.com, paid) | Non-Homebrew App | Personal finance/budgeting software | Partial — Full Disk Access for file import; Keychain access for bank credentials |
| Safari | Apple system app | System App | Apple's default web browser | No — extensions require separate, explicit permission |
| Steam | Direct download (store.steampowered.com) | Non-Homebrew App | Valve's PC/Mac gaming distribution platform and launcher | Partial — may request Microphone/Camera for voice chat/streaming |
| Tailscale | Mac App Store or direct download (tailscale.com) | Non-Homebrew App | Zero-config mesh VPN built on WireGuard | Yes — System Extension + VPN configuration approval |
| tinyMediaManager | Direct download (tinymediamanager.org) | Non-Homebrew App | Media library manager that scrapes/organizes movie/TV metadata | Partial — Full Disk Access for media folders; network access for metadata lookups |
| Userscripts | Mac App Store | Non-Homebrew App | Safari extension that runs user-created JavaScript on web pages | Yes — explicit Safari extension permission + "Allow Unsigned Extensions" |
| UTM | Mac App Store (paid) or direct download (free) | Non-Homebrew App | Virtual machine app (QEMU-based) for running other OSes on Mac | Yes — virtualization entitlement (Hypervisor framework) |
| Baldur's Gate 3 | Steam | Non-Homebrew App | Larian Studios' D&D-based role-playing video game | No |
| Claude Code URL Handler | Installed alongside the claude-code CLI | Non-Homebrew App | Helper app that registers/handles claude:// deep links | No |

---

*Compiled from `brew_installed.txt` and `apps_installed.txt` using the Homebrew formulae/cask API (formulae.brew.sh) plus general knowledge of each tool's typical macOS permission requirements. Homebrew's `caveats` field doesn't always document every permission an app requests at runtime, so treat "Trusted Access" as a best-effort guide — check System Settings → Privacy & Security for the definitive, current state on your machine.*
