# Deployment Guide — PuriDict v2.0.0

> เอกสารบันทึกกระบวนการ release v2.0.0 ขึ้น App Store / Play Store
> (พ.ค. 2569 / May 2026)

---

## 1. App Identity

| Platform | Bundle / Package ID | App ID / Store Listing |
|---|---|---|
| iOS | `org.ctdm.puridict` | App Store Connect: `6743785726` |
| Android | `com.ctdm.puridict` | Play Console app id: `4975818526989701125` |

**Developer:** Phra Anavach Purivaro
**Team ID (Apple):** `7ZFZ2CSF6M`
**Google Developer Account:** `8723322120827447113` (IBS Club CTDM)

---

## 2. Version & Build

- **Version (Marketing):** `2.0.0`
- **Build (iOS `CURRENT_PROJECT_VERSION`):** `8`
- **Build (Android `versionCode`):** `8` (จาก `pubspec.yaml` field `+8`)
- **pubspec:** `version: 2.0.0+8`

---

## 3. iOS — App Store / TestFlight

### Build & Upload
```bash
flutter clean && flutter pub get
flutter build ipa --release
# -> build/ios/ipa/puridict.ipa (48.9 MB)
```
Upload ผ่าน **Transporter.app** หรือ `xcrun altool`

### Status (2026-05-11)
- ✅ Build 8 ขึ้น TestFlight แล้ว
- ✅ Internal testers ทดสอบผ่าน
- ✅ ASC: Version 2.0.0 metadata กรอกครบ (Promotional Text, What's New, Age Ratings 4+)
- ⏳ รอกด **"Add for Review"** + submit Apple App Review

---

## 4. Android — Play Store

### ⚠️ Upload Key Reset (สำคัญ!)

**v1 keystore สูญหาย** — ต้อง request reset ผ่าน Play Console

| Event | Date |
|---|---|
| Request submitted | 2026-05-11 19:33 น. ไทย |
| Google approved | 2026-05-11 21:43 น. ไทย (~10 นาที!) |
| **New upload key active** | **2026-05-13 19:43 น. ไทย** (= 13/05/2569 12:43 UTC) |

หลังจาก active แล้ว — sign .aab ใหม่ด้วย `android/app/upload-keystore.jks` upload ได้ตามปกติ

**New Upload Key Fingerprints:**
- SHA-1: `03:C7:12:7B:F1:CE:B9:FF:B9:3D:55:E5:DC:6B:85:60:24:D3:32:F5`
- SHA-256: `B8:35:82:9D:43:DA:76:3D:61:8F:9C:FF:BF:0C:EC:49:A5:76:71:97:F7:6F:0E:ED:C4:DB:90:CD:72:36:AA:71`

**App Signing Key (Google ถือ, ไม่เปลี่ยน):**
- SHA-256: `5D:C8:76:00:BE:DA:95:33:CB:2B:A0:BE:86:54:3E:5E:7F:2E:B9:52:CC:F6:9E:AA:C1:9B:5D:BF:9C:F8:FA:5A`

### Keystore Backup Location
- Primary: `android/app/upload-keystore.jks` (gitignored)
- iCloud: `~/Library/Mobile Documents/com~apple~CloudDocs/Dev/KeyStore/upload-keystore.jks`
- Credentials: `~/Desktop/puridict-KEYSTORE-BACKUP-README.txt`

### Build & Upload (หลัง 2026-05-13 19:43)
```bash
flutter clean && flutter pub get
flutter build appbundle --release
# -> build/app/outputs/bundle/release/app-release.aab
```
Upload ที่ Play Console > Test and release > Internal testing > Create new release

---

## 5. What's New in 2.0.0

```
🔄 ระบบอัพเดทคำศัพท์ออนไลน์ผ่าน GitHub Releases
🔍 ค้นหาฉลาดขึ้น — ถอดวิภัตติ/ปัจจัย + สนธิ (อิติ/เอว/อปิ)
📖 รองรับสมาสซ้อน (compound_chain) ครบทุกชั้น
🎨 Royal Blue gradient ทั้งแอป + animation
🐛 แก้ overflow, duplicates, Thai search precision
```

ดู release notes ฉบับเต็มที่กรอกใน ASC

---

## 6. Online Data Update System

- ไฟล์ data ที่ bundle: `assets/data/combined.sqlite.gz` (~6.9 MB)
- Asset DB version: `_assetDbVersion = 5` ใน `lib/services/dictionary_service.dart`
  (bump เมื่อแก้ไฟล์ `combined.sqlite` แล้ว rerun `gzip -9 -k -f combined.sqlite`)
- Online manifest hosted on: **GitHub Releases** (repo: `purivaro/puridict`)
- Manifest URL: `https://github.com/purivaro/puridict/releases/latest/download/manifest.json`
- Release script: `./scripts/release-data.sh <version>` (ต้องใช้ `gh` CLI)

---

## 7. Release Checklist

### ก่อน build
- [ ] bump `pubspec.yaml` version ถ้ามีการเปลี่ยนแปลง
- [ ] bump `_assetDbVersion` ถ้าแก้ DB
- [ ] `gzip -9 -k -f assets/data/combined.sqlite` ถ้ามีการแก้ DB
- [ ] `flutter analyze` ผ่าน
- [ ] `flutter test` ผ่าน (ถ้ามี test)
- [ ] ทดสอบในเครื่องจริง อย่างน้อย iPhone + Android

### iOS
- [ ] `flutter build ipa --release`
- [ ] Upload ผ่าน Transporter
- [ ] ทดสอบ TestFlight
- [ ] ASC > Version > metadata + screenshots + age rating
- [ ] ASC > "Add for Review" > submit

### Android
- [ ] รอ upload key active (ครั้งแรก หรือหลัง reset)
- [ ] `flutter build appbundle --release`
- [ ] Play Console > Internal testing > upload .aab
- [ ] ทดสอบ
- [ ] Promote to Production

---

## 8. References

- [App Store Connect — PuriDict](https://appstoreconnect.apple.com/apps/6743785726)
- [Play Console — PuriDict-บาลี](https://play.google.com/console/u/0/developers/8723322120827447113/app/4975818526989701125/app-dashboard)
- [Public Play Store listing](https://play.google.com/store/apps/details?id=com.ctdm.puridict)
- Migration notes (data schema): [`assets/data/migrationfrompalithaijson.md`](assets/data/migrationfrompalithaijson.md)
