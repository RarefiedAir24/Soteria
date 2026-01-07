# TestFlight Build Checklist

**Purpose**: Ensure version and build numbers are updated for each TestFlight build

---

## 📋 Pre-Build Checklist

### 1. Update Version Numbers ⚠️ **REQUIRED**

Before each TestFlight build, **MUST** update version numbers in Xcode:

#### Current Version Settings:
- **Marketing Version** (CFBundleShortVersionString): `1.0`
- **Build Number** (CFBundleVersion): `1`

#### How to Update:

1. **Open Xcode**
2. **Select Project** → `soteria` target
3. **Go to "General" tab**
4. **Update Version Numbers**:
   - **Version**: Increment for major releases (e.g., `1.0` → `1.1` or `2.0`)
   - **Build**: **ALWAYS increment** for each TestFlight build (e.g., `1` → `2` → `3`)

#### Example Version Strategy:
- **Version 1.0**: Build 1, 2, 3, 4... (bug fixes, minor updates)
- **Version 1.1**: Build 1, 2, 3... (new features)
- **Version 2.0**: Build 1, 2, 3... (major updates)

### 2. Verify Version Display in App

After building, verify the version appears correctly in:
- **Profile View** → "App Information" section
- Should display: `1.0 (1)` format (Version (Build))

### 3. Archive and Upload

1. **Product** → **Archive**
2. **Distribute App** → **App Store Connect**
3. **Upload** to TestFlight

---

## 📝 Version Update Log

| Date | Version | Build | Changes | TestFlight Build |
|------|---------|-------|---------|------------------|
| 2026-01-07 | 1.0 | 1 | Initial TestFlight build | - |

---

## 🔍 Verification Steps

After each build:

- [ ] Version number updated in Xcode
- [ ] Build number incremented
- [ ] Version displays correctly in Profile view
- [ ] Archive created successfully
- [ ] Uploaded to App Store Connect
- [ ] TestFlight build processing

---

## ⚠️ Important Notes

1. **Build Number MUST Increment**: Apple requires each build to have a unique, incrementing build number
2. **Version Display**: The version shown in Profile view automatically reflects the current app version and build
3. **No Manual Updates Needed**: The Profile view reads from `CFBundleShortVersionString` and `CFBundleVersion` automatically

---

## 🛠️ Quick Commands

### Check Current Version in Project File:
```bash
grep -A 1 "MARKETING_VERSION\|CURRENT_PROJECT_VERSION" soteria.xcodeproj/project.pbxproj
```

### Verify Version in Built App:
The version is displayed in Profile view → App Information section

---

**Last Updated**: January 7, 2026  
**Next Build**: Version 1.0, Build 2

