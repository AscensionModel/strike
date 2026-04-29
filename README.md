# Strike

Strike is a tiny macOS menu bar app for a team-wide celebratory gong.

Click the menu bar icon to strike. Everyone connected with the same team code hears the gong at roughly the same scheduled time. Right-click the icon for connection controls, settings, and quit.

## Build

```sh
chmod +x scripts/package-app.sh
./scripts/package-app.sh
```

The local machine must have the Xcode command line tools available and the Xcode license accepted.

Open `build/Strike.app` from Finder, or drag it into `/Applications`.

## Release

```sh
chmod +x scripts/release.sh
./scripts/release.sh
```

This creates:

- `dist/Strike-0.0.2.zip`
- `dist/Strike-0.0.2.dmg`
- `docs/appcast.xml`
- `docs/releases/Strike-0.0.2.zip`

For quick internal testing, share the zip or DMG. Because the app is not notarized yet, teammates may need to right-click Strike and choose Open the first time.

The release build is universal, so it runs on both Apple Silicon and Intel Macs running macOS 13 or newer.

## Realtime Debugging

Use the debug script to test Supabase without a second teammate:

```sh
npm install
npm run realtime:listen -- TEAM-CODE
npm run realtime:send -- TEAM-CODE "Debug Sender"
```

Run `listen` in one Terminal tab, then click Strike in the app or run `send` in another tab. The listener should print incoming broadcast messages.

For public distribution, sign and notarize with an Apple Developer ID certificate:

```sh
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./scripts/release.sh
```

## Updates

Strike uses Sparkle for app updates. The app checks:

```text
https://raw.githubusercontent.com/AscensionModel/strike/main/docs/appcast.xml
```

The first Sparkle-enabled build still has to be installed manually. After that, future versions can be delivered through `Check for Updates...` in the menu bar menu.

Sparkle update signing uses an EdDSA key. The public key is stored in [Info.plist](/Users/tyleryork/Documents/STRIKE/Info.plist). The private key is in the local macOS keychain from Sparkle's `generate_keys` tool and must not be committed.

## Shared Supabase Setup

Strike uses one shared Supabase Realtime project for the app. Users do not need to bring their own Supabase project or table.

Create a Supabase project and copy its project URL and public anon key into [AppConfig.swift](/Users/tyleryork/Documents/STRIKE/Sources/Strike/AppConfig.swift):

```swift
static let supabaseURL = "https://YOUR_PROJECT.supabase.co"
static let supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY"
```

No database table is required. Strike uses Supabase Realtime broadcast messages only.

Each Strike install generates a team code automatically. To join a team, teammates paste the same team code in Settings.

## Behavior

- Left click: strike the gong.
- Right click: open the menu.
- Active orange icon ring: a gong is currently ringing.
- Dim icon: not connected.
- Label-colored icon: connected.
- Notifications appear for teammate strikes when enabled.
