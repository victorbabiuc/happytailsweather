# 📱 App Icon Mapping Guide

## **Xcode AppIcon Slots → Icon Files**

### **iPhone App Icon**
| Xcode Slot | Icon File | Device |
|------------|-----------|---------|
| **App Store** | `app-icon-1024.png` | App Store |
| **iPhone 6 Plus and later** | `app-icon-180.png` | iPhone 6 Plus, 7 Plus, 8 Plus, X, XS, XS Max, 11, 11 Pro, 11 Pro Max, 12, 12 mini, 12 Pro, 12 Pro Max, 13, 13 mini, 13 Pro, 13 Pro Max, 14, 14 Plus, 14 Pro, 14 Pro Max, 15, 15 Plus, 15 Pro, 15 Pro Max |
| **iPhone 4 and later** | `app-icon-120.png` | iPhone 4, 4S, 5, 5S, 5C, 6, 6S, 7, 8, SE (1st gen), SE (2nd gen), SE (3rd gen) |
| **iPhone 6 Plus and later** | `app-icon-87.png` | Spotlight (iPhone 6 Plus and later) |
| **iPhone 4 and later** | `app-icon-80.png` | Spotlight (iPhone 4 and later) |
| **iPhone 4 and later** | `app-icon-60.png` | Settings (iPhone 4 and later) |
| **iPhone 4 and later** | `app-icon-58.png` | Settings (iPhone 4 and later) |
| **iPhone 4 and later** | `app-icon-40.png` | Spotlight (iPhone 4 and later) |
| **iPhone 4 and later** | `app-icon-29.png` | Settings (iPhone 4 and later) |

## **Quick Steps:**

1. **Run the script**: `./resize_app_icon.sh`
2. **Open Xcode**: Navigate to `Assets.xcassets → AppIcon`
3. **Drag and drop** each icon file to its corresponding slot
4. **Verify**: All slots should show a checkmark ✅

## **Troubleshooting:**

- **Missing icons**: Ensure `app-icon-1024.png` exists in project root
- **Wrong sizes**: Delete `AppIcons/` folder and run script again
- **Xcode not recognizing**: Clean build folder (`Product → Clean Build Folder`)

## **Icon Requirements:**

- ✅ **Format**: PNG
- ✅ **No transparency**: Solid background required
- ✅ **Square**: All icons must be square
- ✅ **High quality**: No pixelation or blur
- ✅ **Safe area**: Keep important elements within 10% margins 