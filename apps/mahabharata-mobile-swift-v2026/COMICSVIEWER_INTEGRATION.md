# ComicsViewer Swift Package Integration Guide

This guide documents the integration of the ComicsViewer Swift Package into the Mahabharata iOS app.

## ✅ Completed Steps

### 1. Import Statements Added
Added `import ComicsViewer` to the following files:
- `ViewControllers/EpisodeViewController.swift`
- `Views/PlayerView.swift`

### 2. Migrated Files Deleted
Removed 17 files that have been migrated to the ComicsViewer package:

**Comics Models (4 files):**
- `Model/DataClasses/Visual/Comics.swift`
- `Model/DataClasses/Visual/Layer.swift`
- `Model/DataClasses/Visual/Image.swift`
- `Model/DataClasses/Visual/Sound.swift`

**Animation Models (6 files):**
- `Model/DataClasses/Visual/Animations/Anim.swift`
- `Model/DataClasses/Visual/Animations/AlphaAnim.swift`
- `Model/DataClasses/Visual/Animations/TranslateAnim.swift`
- `Model/DataClasses/Visual/Animations/ScaleAnim.swift`
- `Model/DataClasses/Visual/Animations/RotateAnim.swift`
- `Model/DataClasses/Visual/Animations/SoundAnim.swift`

**Views (2 files):**
- `Views/Tiles/TileImageView.swift`
- `Views/Tiles/ImageScrollView.swift`

**Utilities (3 files):**
- `Model/DataClasses/ArchiveManager.swift`
- `Library/SoundManager/SoundManager.swift`
- `Extensions/AVPlayer/AVPlayer+Fade.swift`

**Puzzle Models (2 files):**
- `Model/DataClasses/Puzzle.swift`
- `Model/DataClasses/Piece.swift`

## 🔧 Manual Steps Required

### Step 1: Add Swift Package to Xcode Project

1. Open `Mahabharata.xcodeproj` in Xcode
2. Select the project in the navigator
3. Select the "Mahabharata" target
4. Go to the "General" tab
5. Scroll to "Frameworks, Libraries, and Embedded Content"
6. Click the "+" button
7. Click "Add Other..." → "Add Local..."
8. Navigate to: `/libs/comics_viewer/comics-viewer-ios`
9. Select the `Package.swift` file or the folder
10. Click "Add Package"
11. Ensure "ComicsViewer" is selected and click "Add Package"

**Alternative Method (File → Add Package Dependencies):**
1. File → Add Package Dependencies
2. Click "Add Local..."
3. Navigate to `/libs/comics_viewer/comics-viewer-ios`
4. Click "Add Package"
5. Select "ComicsViewer" library
6. Click "Add Package"

### Step 2: Remove Deleted Files from Xcode Project

The files have been deleted from the filesystem, but Xcode still references them. You need to:

1. Open the Xcode project
2. In the Project Navigator, you'll see red-highlighted files (missing files)
3. Select each missing file and press Delete
4. Choose "Remove Reference" (not "Move to Trash" since files are already deleted)

**Files to remove from Xcode (should appear in red):**
- All 17 files listed in "Migrated Files Deleted" section above

### Step 3: Update API Usage (Optional - Already Compatible)

The migrated library API is designed to be compatible with the existing app code:

**No changes needed for:**
- `Comics`, `Layer`, `Image`, `Sound` - Classes remain the same
- `ImageScrollView` - Same API, added `languageIndex` and `soundEnabled` properties
- `ArchiveManager.shared` - Same singleton pattern
- `SoundManager` - Same API

**New properties available (optional to use):**
```swift
// In EpisodeViewController or similar
scrollView.languageIndex = Settings.shared.language.rawValue
scrollView.soundEnabled = !Settings.shared.soundOff
```

### Step 4: Build and Test

1. Build the project (⌘B)
2. Fix any remaining compilation errors
3. Run on simulator/device
4. Test:
   - Comics viewing
   - Scrolling and animations
   - Sound playback
   - Language switching
   - Puzzle functionality (if used)

## 🔍 Potential Issues and Solutions

### Issue: "No such module 'ComicsViewer'"
**Solution:**
- Ensure the Swift Package was added correctly in Xcode
- Clean build folder (⌘⇧K) and rebuild
- Check that ComicsViewer is listed in "Frameworks and Libraries"

### Issue: Missing symbols or linker errors
**Solution:**
- Verify the package is linked to the Mahabharata target
- Check that all deleted files were removed from Xcode references
- Clean build folder and rebuild

### Issue: Compilation errors in EpisodeViewController
**Solution:**
- Ensure `import ComicsViewer` is present at the top
- Check that no other files are trying to define the same classes
- Verify all 17 migrated files were deleted

### Issue: App crashes at runtime
**Solution:**
- Check that `ArchiveManager.shared.currentArchiveURL` is set correctly
- Verify the comics data files are accessible
- Ensure the app has proper file system permissions

## 📝 API Changes (Minor)

### Layer Class
**Before:**
```swift
let image = layer.image  // Uses Settings.shared.language
let popup = layer.popup  // Uses Settings.shared.language
```

**After (backward compatible):**
```swift
// Old way still works (uses language index 0)
let image = layer.image(languageIndex: 0)
let popup = layer.popup(languageIndex: 0)

// Or use current language setting
let image = layer.image(languageIndex: Settings.shared.language.rawValue)
```

### ImageScrollView
**New Properties:**
```swift
scrollView.languageIndex = 0  // Set language explicitly
scrollView.soundEnabled = true  // Control sound playback
```

## ✅ Verification Checklist

- [ ] Swift Package added to Xcode project
- [ ] ComicsViewer appears in "Frameworks and Libraries"
- [ ] All red (missing) file references removed from Xcode
- [ ] Project builds successfully (⌘B)
- [ ] App launches without crashes
- [ ] Comics display correctly
- [ ] Animations work as expected
- [ ] Sound playback functions properly
- [ ] Language switching works
- [ ] No duplicate symbol errors

## 📚 Documentation

See the ComicsViewer package README for detailed API documentation:
`/libs/comics_viewer/comics-viewer-ios/README.md`

## 🐛 Reporting Issues

If you encounter issues:
1. Check the console for error messages
2. Verify all manual steps were completed
3. Ensure the package builds independently: `cd comics-viewer-ios && swift build`
4. Document the error and report it

---

**Last Updated:** 2026-07-21
**Package Version:** 1.0.0
**iOS App:** mahabharata-mobile-swift-v2026
