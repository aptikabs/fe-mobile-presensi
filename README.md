# E-Presensi Mobile Provinsi Bengkulu

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Clean Architecture](https://img.shields.io/badge/Architecture-Clean-green.svg?style=for-the-badge)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

**E-Presensi Mobile** adalah solusi presensi digital yang canggih untuk Aparatur Sipil Negara (ASN) di lingkungan Pemerintah Provinsi Bengkulu. Aplikasi ini dirancang untuk memastikan akurasi kehadiran dengan mengintegrasikan teknologi pengenalan wajah (Face Recognition) dan pemantauan lokasi berbasis GPS (Geo-fencing).

---

## ✨ Fitur Utama

- **🎭 Pengenalan Wajah (Face Recognition)**: Verifikasi identitas yang aman menggunakan Google ML Kit dan model TFLite (MobileFaceNet).
- **📍 Geo-fencing Berbasis GPS**: Memastikan kehadiran hanya dapat dilakukan di dalam zona lokasi kantor yang telah ditentukan secara akurat.
- **⏱️ Presensi Real-time**: Pencatatan waktu masuk dan pulang yang sinkron dengan server pusat.
- **🔔 Notifikasi Pintar**: Pengingat jadwal presensi dan informasi penting melalui sistem notifikasi lokal.
- **📱 Dukungan Offline**: Menyimpan data presensi secara lokal menggunakan Hive saat koneksi internet tidak stabil.
- **🛡️ Keamanan Tinggi**: Dilengkapi dengan deteksi Mock Location dan Root/Jailbreak untuk mencegah kecurangan.
- **📑 Riwayat Presensi**: Tampilan riwayat kehadiran yang informatif dan kalender kegiatan yang terintegrasi.

---

## 🚀 Teknologi yang Digunakan

Aplikasi ini dibangun dengan standar pengembangan modern untuk performa dan skalabilitas yang tinggi:

- **Framework**: [Flutter](https://flutter.dev) (Dart SDK ^3.9.2)
- **State Management**: [flutter_bloc](https://pub.dev/packages/flutter_bloc) (Cubit)
- **Routing**: [go_router](https://pub.dev/packages/go_router)
- **Database Lokal**: [Hive](https://pub.dev/packages/hive)
- **Peta & Lokasi**: [google_maps_flutter](https://pub.dev/packages/google_maps_flutter), [geolocator](https://pub.dev/packages/geolocator)
- **AI/ML**: [google_mlkit_face_detection](https://pub.dev/packages/google_mlkit_face_detection), [tflite_flutter](https://pub.dev/packages/tflite_flutter)
- **Asset Processing**: [image_picker](https://pub.dev/packages/image_picker), [flutter_image_compress](https://pub.dev/packages/flutter_image_compress)
- **Keamanan**: [safe_device](https://pub.dev/packages/safe_device), [security_plus](https://pub.dev/packages/security_plus)

---

## 🏗️ Arsitektur Proyek

Proyek ini menerapkan prinsip **Clean Architecture** untuk memastikan kode tetap terorganisir, mudah diuji, dan dipelihara:

- **`lib/core`**: Utilitas bersama, tema, konstanta, dan konfigurasi dependency injection.
- **`lib/features`**: Pembagian fitur (Attendance, Profile, Auth, History, dll) yang masing-masing memiliki lapisan Data, Domain, dan Presentation.
- **`lib/api`**: Manajemen endpoint dan integrasi dengan backend service.

---

## 🛠️ Memulai (Getting Started)

### 📋 Prasyarat (Prerequisites)

Sebelum menjalankan aplikasi, pastikan sistem Anda telah terpasang:
- **Flutter SDK**: Versi terbaru (kompatibel dengan Dart SDK `^3.9.2` / Flutter 3.29+)
- **Android Studio / VS Code**: Terpasang ekstensi Flutter dan Dart
- **Java Development Kit (JDK)**: JDK 17 atau lebih baru
- **Xcode & CocoaPods** *(khusus macOS untuk iOS build)*
- **Perangkat Fisik (Physical Device)**: Sangat direkomendasikan untuk testing fitur kamera, GPS/Geofencing, dan karena adanya deteksi keamanan (`EnvironmentSecurityService`) yang memblokir emulator secara default.

---

### 📦 Instalasi & Setup

1. **Klon Repositori**
   ```bash
   git clone https://github.com/egovernmentbengkuluprov/epresensi-flutter.git
   cd epresensi_mobile
   ```

2. **Instal Dependensi**
   ```bash
   flutter pub get
   ```

3. **Setup iOS (Opsional - untuk pengguna macOS)**
   ```bash
   cd ios && pod install && cd ..
   ```

---

### 🌐 Konfigurasi Environment & URL

Aplikasi mendukung multi-environment menggunakan parameter `--dart-define=ENV=...`. Seluruh Base URL dienkripsi secara runtime (XOR) di [lib/api/urls.dart](file:///Users/alzahfariski/Development/kerjaan/alfaefsatech/project/epresensi_mobile/lib/api/urls.dart) untuk keamanan dari reverse-engineering.

| Environment | Parameter | Target API URL |
| :--- | :--- | :--- |
| **Development** | `--dart-define=ENV=dev` | `https://devepresensimobile.bengkuluprov.go.id/api` |
| **Production** | `--dart-define=ENV=prod` *(default)* | `https://epresensimobile.bengkuluprov.go.id/api` |

> [!TIP]
> **Mengubah Base URL**: Jika perlu memperbarui Base URL, gunakan generator obfuskasi:
> ```bash
> dart scripts/encode_url.dart "https://api-baru.bengkuluprov.go.id/api"
> ```
> Salin hasil array byte ke [lib/api/urls.dart](file:///Users/alzahfariski/Development/kerjaan/alfaefsatech/project/epresensi_mobile/lib/api/urls.dart).

---

### 🏃 Menjalankan Aplikasi (Development / Debug)

Jalankan perintah berikut pada terminal:

```bash
# Menjalankan di Environment DEV
flutter run --dart-define=ENV=dev

# Menjalankan di Environment PROD
flutter run --dart-define=ENV=prod
```

#### ⚙️ Konfigurasi Debugging VS Code (`.vscode/launch.json`)
Untuk kemudahan debugging via tab *Run & Debug* di VS Code, buat/gunakan konfigurasi berikut:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "E-Presensi (DEV)",
      "request": "launch",
      "type": "dart",
      "args": ["--dart-define=ENV=dev"]
    },
    {
      "name": "E-Presensi (PROD)",
      "request": "launch",
      "type": "dart",
      "args": ["--dart-define=ENV=prod"]
    }
  ]
}
```

---

### 📦 Build Release (Security Hardened & Obfuscated)

Proyek ini menyediakan skrip otomasi build yang menerapkan obfuskasi kode Dart, split debug symbols, serta optimasi R8/ProGuard.

```bash
# Memberikan izin eksekusi skrip (jika belum)
chmod +x scripts/build_release.sh

# 1. Build APK versi DEV (Testing)
./scripts/build_release.sh dev

# 2. Build APK & AAB versi PROD (Production)
./scripts/build_release.sh prod
```

Debug symbols tersimpan otomatis di `build/app/outputs/symbols/` untuk keperluan crash symbolication.

---

### 🧪 Pengujian & Analisis Kode

```bash
# Menjalankan Static Code Analysis (Lint)
flutter analyze

# Menjalankan Unit & Widget Test
flutter test
```

---

### 🔐 Konfigurasi Native & Layanan Pihak Ketiga

- **Google Maps API**: Terkonfigurasi di `android/app/src/main/AndroidManifest.xml` dan `ios/Runner/AppDelegate.swift`.
- **Firebase Core & Crashlytics**: Terkonfigurasi melalui [lib/firebase_options.dart](file:///Users/alzahfariski/Development/kerjaan/alfaefsatech/project/epresensi_mobile/lib/firebase_options.dart), `android/app/google-services.json`, dan `ios/Runner/GoogleService-Info.plist`.
- **Security Hardening**: Lihat rincian proteksi pada [SECURITY_HARDENING_GUIDE.md](file:///Users/alzahfariski/Development/kerjaan/alfaefsatech/project/epresensi_mobile/SECURITY_HARDENING_GUIDE.md).
- **Panduan Adopsi & White-Labeling**: Untuk Tim IT Diskominfo Kabupaten/Kota yang mereplikasi source code ini, panduan lengkap pengisian kredensial Firebase, Google Maps API, dan penggantian identitas daerah tercantum di [adopsi.md](file:///Users/alzahfariski/Development/kerjaan/alfaefsatech/project/epresensi_mobile/adopsi.md).

---

## ⚖️ Lisensi
Distributed under the MIT License. See `LICENSE` for more information.

---
© 2026 Pemerintah Provinsi Bengkulu. All Rights Reserved.
