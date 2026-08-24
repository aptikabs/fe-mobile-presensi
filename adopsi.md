# 📘 Panduan Adopsi & White-Labeling E-Presensi Mobile
### Untuk Tim IT / Software Engineer Diskominfo Kabupaten / Kota

Dokumen ini berisi panduan teknis resmi bagi Pemerintah Kabupaten/Kota dalam melakukan kloning, instalasi, konfigurasi, penyesuaian identitas (*white-labeling*), hingga *deployment* aplikasi **E-Presensi Mobile** berbasis Flutter yang dikembangkan oleh Pemerintah Provinsi Bengkulu.

---

## 🏛️ Hak Cipta, Integritas Sistem & Ketentuan Provinsi (Wajib Dipatuhi)

Sebagai bentuk kerja sama replikasi dan pemanfaatan sistem antar-pemerintah daerah, terdapat beberapa ketentuan dan hak provinsi yang **TIDAK BOLEH** diubah atau dihapus oleh Tim Pengembang Kabupaten/Kota:

### 1. Watermark & Atribusi Pengembang Asal (*Credit Attribution*)
* **Branding Footer / Watermark Splash**: Logo atau teks atribusi *"Diinisiasi / Dikembangkan bersama Pemerintah Provinsi Bengkulu"* pada elemen branding splash screen (`assets/logo/branding.png` & `assets/logo/branding-android.png`) **wajib dipertahankan**.
* **Halaman Tentang Aplikasi (*About Page*)**: Pada file [`lib/features/profile/presentation/pages/about_page.dart`](file:///Users/alzahfariski/Development/kerjaan/alfaefsatech/project/epresensi_mobile/lib/features/profile/presentation/pages/about_page.dart), kredit pengembang induk / inisiasi sistem Pemprov Bengkulu tidak boleh dihilangkan (boleh ditambahkan: *"Direplikasi / Diadaptasi oleh Diskominfo Kab/Kota [Nama Daerah]"*).
* **Lisensi & Hak Cipta**: Hak Cipta dasar arsitektur dan algoritma tetap melekat pada Pemerintah Provinsi Bengkulu.

### 2. Larangan Komersialisasi
* Source code ini dibagikan untuk kepentingan pelayanan publik ASN / Non-ASN di lingkungan Pemerintah Daerah dan **dilarang keras diperjualbelikan** kepada pihak ketiga atau vendor swasta.

### 3. Integritas Standar Keamanan (*Security Compliance*)
* **Dilarang menonaktifkan modul proteksi integritas**: Modul audit keamanan pada [`lib/core/security/environment_security_service.dart`](file:///Users/alzahfariski/Development/kerjaan/alfaefsatech/project/epresensi_mobile/lib/core/security/environment_security_service.dart) (deteksi Root, Jailbreak, Emulator, dan Mock Location / Fake GPS) wajib tetap aktif demi menjaga integritas data absensi aparatur negara.
* **Dilarang mematikan model AI/ML**: File model deteksi wajah [`assets/mobile_face_net.tflite`](file:///Users/alzahfariski/Development/kerjaan/alfaefsatech/project/epresensi_mobile/assets/mobile_face_net.tflite) dan alur validasi *face liveness* harus tetap dipertahankan.

---

## 1. Persiapan Sistem (Prerequisites)

Workstation atau build server pengembang wajib memiliki perangkat lunak berikut:

* **Flutter SDK**: Versi `3.29.x` ke atas (Dart SDK `^3.9.2`).
* **Java Development Kit (JDK)**: OpenJDK 17 (LTS).
* **Android Studio & Android SDK**:
  * Android SDK Command-line Tools
  * Android SDK Build-Tools (API Level 34 atau 35)
  * Android NDK & CMake (dibutuhkan untuk kompilasi modul keamanan C/C++).
* **Xcode & CocoaPods** *(khusus macOS untuk build iOS)*: CocoaPods `1.14+`.
* **Smartphone Fisik (Android / iOS)**:
  > ⚠️ **Catatan Penting**: Emulator Android/iOS secara otomatis **diblokir** oleh modul keamanan sistem. Pengujian wajib menggunakan perangkat fisik riil dengan koneksi kabel USB debugging.

---

## 2. Akses Repositori & Instalasi Dependensi

### 2.1 Klon Repositori & Pembuatan Branch Daerah
```bash
# Klon repositori induk
git clone https://github.com/egovernmentbengkuluprov/epresensi-flutter.git epresensi_mobile_kabupaten

# Masuk ke direktori
cd epresensi_mobile_kabupaten

# Buat branch kerja khusus daerah Anda
git checkout -b feature/adopsi-kab-namadaerah
```

### 2.2 Instalasi Paket Dependensi
```bash
# Unduh seluruh dependensi Flutter & Dart
flutter pub get

# Setup Pods untuk platform iOS (khusus macOS)
cd ios && pod install --repo-update && cd ..
```

---

## 3. Konfigurasi Lingkungan (Environment & Endpoints)

Aplikasi mengamankan Base URL backend menggunakan **XOR Runtime Obfuscation** (Key `0x57`) agar URL API tidak bocor melalui *binary string scraping*.

### 3.1 Menghasilkan Obfuscated URL untuk Server Daerah
Gunakan skrip generator yang telah disediakan di [`scripts/encode_url.dart`](file:///Users/alzahfariski/Development/kerjaan/alfaefsatech/project/epresensi_mobile/scripts/encode_url.dart):

```bash
# Format: dart scripts/encode_url.dart <URL_API_KABUPATEN>

# 1. URL Staging / Development
dart scripts/encode_url.dart "https://dev-presensi.namakab.go.id/api"

# 2. URL Production
dart scripts/encode_url.dart "https://presensi.namakab.go.id/api"
```

### 3.2 Pasang Hasil ke [`lib/api/urls.dart`](file:///Users/alzahfariski/Development/kerjaan/alfaefsatech/project/epresensi_mobile/lib/api/urls.dart)
Salin array integer hasil dari terminal ke variabel `_devBaseUrl` dan `_prodBaseUrl`:

```dart
// DEV Base URL
static final String _devBaseUrl = _d(
  const [<masukkan_array_bytes_dev_di_sini>],
  0x57,
);

// PROD Base URL
static final String _prodBaseUrl = _d(
  const [<masukkan_array_bytes_prod_di_sini>],
  0x57,
);
```

### 3.3 Penyesuaian SSL Pinning & Domain Whitelist
Pada [`lib/core/network/pinned_http_client.dart`](file:///Users/alzahfariski/Development/kerjaan/alfaefsatech/project/epresensi_mobile/lib/core/network/pinned_http_client.dart):
1. **Daftarkan Domain Daerah**:
   ```dart
   static const List<String> allowedHosts = [
     'namakab.go.id',
     'dev-presensi.namakab.go.id',
     'presensi.namakab.go.id',
   ];
   ```
2. **Perbarui SPKI Hash (SHA-256 Pin)**:
   Ekstrak SHA-256 Public Key hash sertifikat SSL server Anda dan daftarkan pada list `allowedSha256Pins`.

---

## 4. Penyesuaian Identitas Daerah (White-Labeling)

> [!IMPORTANT]
> **Wajib Mengganti Package Name / Application ID**:
> Jangan biarkan nilai default atau placeholder (`id.go.namadaerah.epresensi`). Sesuaikan dengan domain resmi Diskominfo Kabupaten/Kota Anda agar tidak terjadi konflik identitas aplikasi di Play Store / App Store.

### 4.1 Package Name / Application ID
* **Android** ([`android/app/build.gradle.kts`](file:///Users/alzahfariski/Development/kerjaan/alfaefsatech/project/epresensi_mobile/android/app/build.gradle.kts)):
  Ganti `applicationId` dan `namespace`:
  ```kotlin
  android {
      namespace = "id.go.namakab.epresensi" // Contoh: id.go.bengkulutengahkab.epresensi
      defaultConfig {
          applicationId = "id.go.namakab.epresensi"
          // ...
      }
  }
  ```
* **iOS** (Buka di Xcode atau edit [`ios/Runner.xcodeproj/project.pbxproj`](file:///Users/alzahfariski/Development/kerjaan/alfaefsatech/project/epresensi_mobile/ios/Runner.xcodeproj/project.pbxproj) & [`ios/Runner/Info.plist`](file:///Users/alzahfariski/Development/kerjaan/alfaefsatech/project/epresensi_mobile/ios/Runner/Info.plist)):
  Ganti `PRODUCT_BUNDLE_IDENTIFIER` dan `CFBundleIdentifier` menjadi `id.go.namakab.epresensi`.

### 4.2 Nama Tampilan Aplikasi (App Display Name)
* **Android** ([`android/app/src/main/AndroidManifest.xml`](file:///Users/alzahfariski/Development/kerjaan/alfaefsatech/project/epresensi_mobile/android/app/src/main/AndroidManifest.xml)):
  ```xml
  <application
      android:label="E-Presensi Kab. [Nama Daerah]"
      ... >
  ```
* **iOS** ([`ios/Runner/Info.plist`](file:///Users/alzahfariski/Development/kerjaan/alfaefsatech/project/epresensi_mobile/ios/Runner/Info.plist)):
  ```xml
  <key>CFBundleDisplayName</key>
  <string>E-Presensi Kab. [Nama Daerah]</string>
  ```

### 4.3 Penggantian Aset Logo & Gambar
Tim desainer daerah cukup mengganti file gambar pada folder `assets/logo/` dengan nama dan rasio yang sama:
* `assets/logo/logo_app_launcher.png` : Ikon master aplikasi (1024x1024 px PNG).
* `assets/logo/logo.png` & `assets/logo/logo_v3.png` : Logo daerah untuk login & dashboard.
* `assets/logo/logo-android.png` : Ikon tengah splash screen Android 12+.
* `assets/logo/branding.png` & `assets/logo/branding-android.png` : Watermark branding bawah (tetap sertakan logo Pemprov bersama logo Pemkab/Pemkot).

### 4.4 Otomasi Generate Ikon & Splash Screen
Setelah file gambar diganti, jalankan perintah generator:

```bash
# 1. Regenerasi App Icon
dart run flutter_launcher_icons

# 2. Regenerasi Native Splash Screen
dart run flutter_native_splash:create
```

### 4.5 Tema Warna Daerah (Opsional)
Jika daerah memiliki warna tema resmi (misalnya hijau, merah hati, atau biru tua), sesuaikan konstanta warna pada [`lib/core/constants/app_colors.dart`](file:///Users/alzahfariski/Development/kerjaan/alfaefsatech/project/epresensi_mobile/lib/core/constants/app_colors.dart).

---

## 5. Konfigurasi Layanan Pihak Ketiga (Firebase & Maps)

> [!WARNING]
> **Source code template ini TIDAK menyertakan API Key aktif**.
> Anda **WAJIB** mengisi seluruh kredensial Google Maps API dan Firebase secara lengkap dari akun Google Cloud & Firebase milik instansi Anda sendiri sebelum aplikasi dapat dijalankan.

### 5.1 Google Cloud Platform (Google Maps SDK)
1. Buka [Google Cloud Console](https://console.cloud.google.com/).
2. Buat Project baru dan aktifkan **Maps SDK for Android** & **Maps SDK for iOS**.
3. Buat API Key dan isi ke dalam file-file berikut (ganti nilai `YOUR_GOOGLE_MAPS_API_KEY`):
   * **Android** ([`android/app/src/main/AndroidManifest.xml`](file:///Users/alzahfariski/Development/kerjaan/alfaefsatech/project/epresensi_mobile/android/app/src/main/AndroidManifest.xml)):
     ```xml
     <meta-data
         android:name="com.google.android.geo.API_KEY"
         android:value="AIzaSy... (API Key Asli Google Maps Anda)" />
     ```
   * **iOS** ([`ios/Runner/AppDelegate.swift`](file:///Users/alzahfariski/Development/kerjaan/alfaefsatech/project/epresensi_mobile/ios/Runner/AppDelegate.swift)):
     ```swift
     GMSServices.provideAPIKey("AIzaSy... (API Key Asli Google Maps Anda)")
     ```
   * **iOS** ([`ios/Runner/Info.plist`](file:///Users/alzahfariski/Development/kerjaan/alfaefsatech/project/epresensi_mobile/ios/Runner/Info.plist)):
     ```xml
     <key>GMSApiKey</key>
     <string>AIzaSy... (API Key Asli Google Maps Anda)</string>
     ```

### 5.2 Firebase Console (Crashlytics, Analytics & Notification)
1. Buat Project baru di [Firebase Console](https://console.firebase.google.com/) khusus instansi Anda.
2. Daftarkan App Android & iOS menggunakan `applicationId` / `bundleId` baru daerah Anda.
3. Unduh file konfigurasi asli dari Firebase Console:
   * **Android**: Salin file `google-services.json` ke folder `android/app/google-services.json`.
   * **iOS**: Salin file `GoogleService-Info.plist` ke folder `ios/Runner/GoogleService-Info.plist`.
4. Perbarui file [`lib/firebase_options.dart`](file:///Users/alzahfariski/Development/kerjaan/alfaefsatech/project/epresensi_mobile/lib/firebase_options.dart):
   * Jalankan FlutterFire CLI:
     ```bash
     flutterfire configure
     ```
   * *Atau* isi langsung nilai `apiKey`, `appId`, `messagingSenderId`, dan `projectId` pada [`lib/firebase_options.dart`](file:///Users/alzahfariski/Development/kerjaan/alfaefsatech/project/epresensi_mobile/lib/firebase_options.dart) sesuai data Firebase project Anda.

---

## 6. Menjalankan & Build Aplikasi (Deployment)

### 6.1 Menjalankan Debugging
```bash
# Menjalankan di target Staging / DEV
flutter run --dart-define=ENV=dev

# Menjalankan di target Production
flutter run --dart-define=ENV=prod
```

### 6.2 Konfigurasi Release Keystore (Android)
Buat file `android/key.properties` (pastikan file ini di-ignore di git):
```properties
storePassword=password_keystore_daerah
keyPassword=password_alias_daerah
keyAlias=epresensi_key
storeFile=/path/ke/file_keystore_daerah.jks
```

### 6.3 Build Produksi Terproteksi (Obfuscated & Split Symbols)
Gunakan skrip otomasi [`scripts/build_release.sh`](file:///Users/alzahfariski/Development/kerjaan/alfaefsatech/project/epresensi_mobile/scripts/build_release.sh):

```bash
# Beri izin eksekusi skrip
chmod +x scripts/build_release.sh

# Eksekusi build production (APK & AAB)
./scripts/build_release.sh prod
```

Hasil kompilasi:
* **APK Rilis**: `build/app/outputs/flutter-apk/app-release.apk`
* **App Bundle (Play Store)**: `build/app/outputs/bundle/release/app-release.aab`
* **Debug Symbols**: `build/app/outputs/symbols/` *(Simpan file simbol ini untuk menganalisis log crash di Crashlytics).*

---

## 📋 Checklist Verifikasi Pra-Rilis Daerah

- [ ] **Google Maps API**: API Key asli telah diisi lengkap di `AndroidManifest.xml`, `AppDelegate.swift`, dan `Info.plist`.
- [ ] **Firebase Config**: File `google-services.json`, `GoogleService-Info.plist`, dan [`lib/firebase_options.dart`](file:///Users/alzahfariski/Development/kerjaan/alfaefsatech/project/epresensi_mobile/lib/firebase_options.dart) telah diisi lengkap dengan project Firebase daerah.
- [ ] **Package Name / Bundle ID**: `applicationId` di [`android/app/build.gradle.kts`](file:///Users/alzahfariski/Development/kerjaan/alfaefsatech/project/epresensi_mobile/android/app/build.gradle.kts) dan `PRODUCT_BUNDLE_IDENTIFIER` di iOS telah diubah dari placeholder ke domain instansi daerah.
- [ ] **Base URL Backend**: Base URL di [`lib/api/urls.dart`](file:///Users/alzahfariski/Development/kerjaan/alfaefsatech/project/epresensi_mobile/lib/api/urls.dart) telah di-encode XOR dan mengarah ke server API daerah.
- [ ] **SSL Pinning**: Domain whitelist & SPKI hash di [`lib/core/network/pinned_http_client.dart`](file:///Users/alzahfariski/Development/kerjaan/alfaefsatech/project/epresensi_mobile/lib/core/network/pinned_http_client.dart) telah disesuaikan dengan SSL server daerah.
- [ ] **Visual Branding**: Ikon dan Splash Screen telah digenerate ulang (`flutter_launcher_icons` & `flutter_native_splash`).
- [ ] **Watermark & Integritas**: Watermark/atribusi Pemerintah Provinsi Bengkulu dan modul keamanan (`EnvironmentSecurityService`) tetap dipertahankan.
- [ ] **Keystore Signing**: File `android/key.properties` telah dibuat dan mengarah ke file `.jks` resmi daerah.
- [ ] **Build Release**: Build dieksekusi dengan skrip `./scripts/build_release.sh prod`.
