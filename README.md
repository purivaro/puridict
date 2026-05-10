<div align="center">

# 📖 PuriDict — พจนานุกรมบาลี-ไทย

**พจนานุกรมบาลี-ไทยสำหรับนักศึกษาภาษาบาลี พระภิกษุสามเณร และผู้สนใจภาษาบาลีทั่วโลก**

*A modern, offline-first Pali–Thai dictionary built with Flutter*

[![Version](https://img.shields.io/badge/version-2.0.0-success)]()
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-2.17%2B-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-lightgrey)]()
[![License](https://img.shields.io/badge/license-Personal%20Use-blue)]()

</div>

---

## ✨ คุณสมบัติเด่น

- 🔍 **ค้นหารวดเร็ว** — ค้นได้ทั้งภาษาบาลี → ไทย และไทย → บาลี
- 📚 **คลังศัพท์กว่า 35,000 รายการ** — รวบรวมจากคัมภีร์ธรรมบท ทั้ง 8 ภาค
- 🧩 **โครงสร้างคำครบถ้วน** — แสดงธาตุ ปัจจัย ลิงค์ การแจกวิภัตติ และบทวิเคราะห์
- 📱 **ใช้งาน Offline 100%** — ฐานข้อมูลฝังในแอป ไม่ต้องต่อเน็ตก็ค้นได้ทันที
- ☁️ **อัพเดทคำศัพท์ออนไลน์** — แจ้งเตือนเมื่อมีคำศัพท์ใหม่ ดาวน์โหลดเป็นพื้นหลัง
- ⭐ **บันทึกคำโปรด** — เก็บคำที่ใช้บ่อยไว้เปิดดูอีก
- 🕒 **ประวัติการค้นหา** — ดูคำที่เพิ่งค้นได้รวดเร็ว
- 🌓 **โหมดสว่าง / มืด** — ปรับให้สบายตาได้
- 🔡 **ปรับขนาดตัวอักษร** — เหมาะสำหรับทุกวัย

---

## 🏛️ เกี่ยวกับ PuriDict

**PuriDict v2.0.0** พัฒนาโดย **พระมหาอนวัช ภูริวโร**

หัวหน้าศูนย์พัฒนาเทคโนโลยีเพื่อศีลธรรม
สถาบันพัฒนาเยาวชนโลก

โครงการ **PuriDict** มีเจตนารมณ์เพื่อเป็นเครื่องมือช่วยศึกษาภาษาบาลี อันเป็นภาษาที่บันทึกพระธรรมคำสอนของพระสัมมาสัมพุทธเจ้า ให้สะดวกต่อการเรียนการสอนในยุคปัจจุบัน โดยรวบรวมศัพท์จากแหล่งเอกสารดั้งเดิมและจัดทำให้ใช้งานได้อย่างสะดวกผ่านสมาร์ทโฟน

ชื่อ **"PuriDict"** (ภูริ) มีความหมายว่า *ปัญญา* — Dictionary ที่ช่วยเพิ่มพูนปัญญาให้แก่นักศึกษาภาษาบาลีทุกคน

### ✨ ใหม่ในเวอร์ชัน 2.0.0

- ☁️ **ระบบอัพเดทคำศัพท์ออนไลน์** — รับคำศัพท์ใหม่ผ่าน GitHub Releases โดยไม่ต้องอัพเดทแอปใหม่
- 🎨 **UI/UX ปรับปรุงครั้งใหญ่** — แสดงโครงสร้างคำชัดเจนขึ้น แก้ overflow บนหน้าจอเล็ก
- ⚡ **เพิ่มประสิทธิภาพ** — บันเดิล sqlite แบบ gzip ลดขนาด APK กว่า 90%
- 🔒 **Integrity check** — ตรวจ SHA-256 ก่อนใช้ข้อมูลที่ดาวน์โหลด

> *"สพฺพทานํ ธมฺมทานํ ชินาติ"* — การให้ธรรมะ ชนะการให้ทั้งปวง

---

## 🏗️ สถาปัตยกรรม

```
┌─────────────────────────────────────────────────┐
│                  Flutter App                    │
│  ┌────────────────┐    ┌──────────────────┐     │
│  │  HomeScreen    │◄───┤  DictionaryService│    │
│  │  (Provider)    │    │  (ChangeNotifier) │    │
│  └────────────────┘    └──────────┬────────┘    │
│         │                         │             │
│         ▼                         ▼             │
│  ┌──────────────┐    ┌────────────────────┐     │
│  │ UpdateBanner │    │   sqflite (RO)     │     │
│  └──────────────┘    │  combined.sqlite   │     │
│                      └─────────┬──────────┘     │
│                                │                │
│                ┌───────────────┴───────────┐    │
│                ▼                           ▼    │
│  ┌──────────────────────┐  ┌────────────────┐   │
│  │ Asset (.gz, ~6.5 MB) │  │ UpdateService  │   │
│  │ first-run extraction │  │ ↓ GitHub Rel.  │   │
│  └──────────────────────┘  └────────────────┘   │
└─────────────────────────────────────────────────┘
```

### Highlights

- **`DictionaryService`** ([lib/services/dictionary_service.dart](lib/services/dictionary_service.dart))
  ตัวกลางจัดการฐานข้อมูล, การค้นหา, รายการโปรด, ธีม, และ flow การอัพเดทข้อมูลออนไลน์
- **`UpdateService`** ([lib/services/update_service.dart](lib/services/update_service.dart))
  เช็ค `manifest.json` จาก GitHub Releases, ดาวน์โหลดและตรวจ SHA-256, สลับไฟล์ฐานข้อมูลแบบ atomic
- **Compression strategy** — บันเดิล sqlite แบบ gzip (~6.5 MB) แทน raw (~63 MB) เพื่อลดขนาด APK กว่า **90%**
- **Offline-first** — แอปใช้งานได้ทันทีตั้งแต่ติดตั้ง การอัพเดทเป็นแบบ background ไม่รบกวนผู้ใช้

---

## ☁️ ระบบอัพเดทออนไลน์

ฐานข้อมูลคำศัพท์สามารถอัพเดทได้โดยไม่ต้องอัพเดทแอปจาก Store

**ฝั่งผู้ใช้:**
1. เปิดแอป → ใช้ฐานข้อมูลในเครื่องทันที
2. หลัง UI พร้อม → background fetch `manifest.json` จาก GitHub Releases
3. ถ้ามี version ใหม่ → แสดง banner นุ่มนวล "กำลังอัพเดทคำศัพท์..."
4. ดาวน์โหลด → verify SHA-256 → swap ไฟล์ → ใช้ข้อมูลใหม่ทันที
5. Throttle: เช็คมากที่สุด 1 ครั้ง / 6 ชั่วโมง

**ฝั่งผู้พัฒนา:**

```bash
# แก้ไข assets/data/combined.sqlite แล้วรัน
./scripts/release-data.sh 2026.05.10
```

สคริปต์จะ gzip → คำนวน sha256 → สร้าง `manifest.json` → ดัน GitHub Release ผ่าน `gh` CLI

---

## 🚀 เริ่มต้นใช้งาน (Development)

### Prerequisites

- Flutter SDK ≥ 3.0
- Dart SDK ≥ 2.17
- Android Studio / Xcode สำหรับ build บนมือถือ
- (สำหรับ release data) [GitHub CLI](https://cli.github.com) ติดตั้งและ login แล้ว

### Setup

```bash
git clone git@github.com:purivaro/puridict.git
cd puridict
flutter pub get
flutter run
```

### Build Release

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release
```

---

## 📁 โครงสร้างโปรเจค

```
puridict/
├── assets/
│   ├── data/
│   │   ├── combined.sqlite       # source-of-truth (ไม่ bundle ใน APK)
│   │   └── combined.sqlite.gz    # bundled, decompress on first run
│   ├── fonts/                    # Sarabun font (ไทย)
│   ├── icon/                     # app icon
│   └── splash/                   # splash screen
├── lib/
│   ├── main.dart                 # entry + provider setup
│   ├── models/                   # DictionaryEntry, etc.
│   ├── services/
│   │   ├── dictionary_service.dart
│   │   └── update_service.dart   # online update flow
│   ├── screens/
│   │   ├── home_screen.dart
│   │   └── info_screen.dart
│   ├── widgets/                  # SearchBox, DictionaryCard, ...
│   └── theme/                    # AppTheme, ThemeManager
├── scripts/
│   └── release-data.sh           # publish dataset update via gh CLI
└── pubspec.yaml
```

---

## 📦 Dependencies หลัก

| Package | ใช้สำหรับ |
|---|---|
| `sqflite` | เปิดอ่านฐานข้อมูล SQLite |
| `path_provider` | หา documents directory บนมือถือ |
| `provider` | state management |
| `shared_preferences` | เก็บการตั้งค่า, version tracking |
| `http` | ดาวน์โหลด manifest + dataset |
| `crypto` | ตรวจ SHA-256 ของไฟล์ที่ดาวน์โหลด |
| `google_fonts`, `flutter_tts`, `flutter_spinkit` | UI / UX |

---

## 👤 ผู้พัฒนา

**พระมหาอนวัช ภูริวโร**
*Phra Maha Anavach Purivaro*
หัวหน้าศูนย์พัฒนาเทคโนโลยีเพื่อศีลธรรม
สถาบันพัฒนาเยาวชนโลก

โครงการนี้พัฒนาขึ้นเพื่อเป็นพุทธบูชาและเป็นประโยชน์ต่อการศึกษาภาษาบาลีของชาวโลก

---

## 🙏 กิตติกรรมประกาศ

- คณะอาจารย์และพระเถระผู้ทรงคุณวุฒิด้านภาษาบาลี ที่เป็นแหล่งความรู้และแรงบันดาลใจ
- เอกสารปริวรรตและพจนานุกรมบาลี-ไทยรุ่นก่อนหน้า ที่เป็นพื้นฐานของคลังข้อมูล
- Flutter community สำหรับเครื่องมือพัฒนาที่ทรงพลัง

---

## 📜 License

โครงการนี้พัฒนาขึ้นเพื่อการศึกษาและเผยแผ่พระพุทธศาสนา
หากท่านต้องการนำไปใช้หรือต่อยอด กรุณาติดต่อผู้พัฒนา

---

<div align="center">

*ขอกุศลผลบุญจากการพัฒนาแอปพลิเคชันนี้*
*จงเป็นปัจจัยให้ผู้ใช้ทุกท่านเจริญในธรรม ตลอดกาลนาน เทอญ*

**🪷**

</div>
