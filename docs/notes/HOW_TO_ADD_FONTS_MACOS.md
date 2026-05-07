# How to add fonts to the project on macOS

## Problem: copy/paste isn't working

If you can't copy/paste `.ttf` font files into `assets/fonts/` directly from
Finder, here are a few alternatives.

---

## Solution 1: Terminal (recommended)

```bash
# Open Terminal
# Move to the project root
cd /path/to/businessmindset

# Create the font folder (example: Volkhov)
mkdir -p assets/fonts/Volkhov

# Copy the .ttf file from Downloads (example)
cp ~/Downloads/Volkhov-Regular.ttf assets/fonts/Volkhov/

# Confirm the file landed
ls -la assets/fonts/Volkhov/
```

**Multiple fonts at once**:
```bash
# If your fonts live in ~/Downloads/NewFonts/
cp -r ~/Downloads/NewFonts/* assets/fonts/

# Or copy a single file
cp ~/Downloads/MyFont.ttf assets/fonts/FolderName/
```

---

## Solution 2: VS Code / Cursor

1. Open VS Code or Cursor.
2. Go to `assets/fonts/`.
3. Right-click the folder → **New Folder** → create a font folder.
4. Drag the `.ttf` file from Finder into that folder inside the editor.

---

## Solution 3: Tweak folder permissions

If you suspect a permissions issue, run in Terminal:

```bash
cd /path/to/businessmindset

# Grant write access
chmod -R 755 assets/fonts/

# Try the Finder copy again
```

---

## Solution 4: Use Xcode (for the iOS project)

To add fonts directly through Xcode:

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Right-click `Runner` → **Add Files to "Runner"**.
3. Navigate to your `.ttf` files.
4. Tick **"Copy items if needed"**.
5. Tick **Target Membership = `Runner`**.

Then add to `Info.plist`:
```xml
<key>UIAppFonts</key>
<array>
    <string>Volkhov-Regular.ttf</string>
</array>
```

---

## List the installed fonts

```bash
# List every font under the project
find assets/fonts -name "*.ttf" -o -name "*.otf"

# Count them
find assets/fonts -name "*.ttf" | wc -l
```

---

## Fonts currently shipped

According to `pubspec.yaml`, the project bundles:

1. InterTight
2. YesevaOne
3. DidactGothic
4. JosefinSlab
5. Raleway
6. AbhayaLibre
7. Allerta
8. BebasNeue
9. BodoniModa
10. CormorantGaramond
11. EBGaramond
12. JosefinSans
13. Lato
14. LibreBaskerville
15. Lustria
16. MontSerrat (file: `Montserrat`)
17. Oranlenbaum
18. Oswald
19. Ovo
20. PlayfairDisplay
21. Quicksand (+ `Quicksans` alias)
22. Sanchez
23. SourceSansPro
24. Volkhov (+ `Volkorn` alias, folder `Volkorn`)

**Total: 23 font families.**

---

## If a font is missing

### Example: add "Montserrat-Bold"

```bash
cd /path/to/businessmindset

# Create the folder if needed
mkdir -p assets/fonts/Montserrat

# Copy the file in
cp ~/Downloads/Montserrat-Bold.ttf assets/fonts/Montserrat/

# Update pubspec.yaml
```

Then in `pubspec.yaml`:
```yaml
fonts:
  - family: MontSerrat
    fonts:
      - asset: assets/fonts/Montserrat/Montserrat-Regular.ttf
      - asset: assets/fonts/Montserrat/Montserrat-Bold.ttf
        weight: 700
```

---

## Mind the names

The themes (in `themedatas.dart`) reference these names:
- `"MontSerrat"` → file under `Montserrat/`.
- `"Quicksans"` → file under `Quicksand/`.
- `"Volkorn"` → folder `Volkorn/` (contains `Volkhov-Regular.ttf`).

The `fontFamily` value must match the `family` declared in `pubspec.yaml`.

---

## After adding a font

1. Update `pubspec.yaml`.
2. Reset Flutter:
   ```bash
   flutter clean
   flutter pub get
   ```
3. Rebuild the app:
   ```bash
   flutter run
   ```

---

## Recap

**Quickest path**:
```bash
cp /path/to/font.ttf assets/fonts/FolderName/
```

**If it still doesn't work**, double-check:
- Folder permissions (`chmod 755`).
- Available disk space.
- That the file isn't corrupted.

---

> The `pubspec.yaml` already lists every required font family.
