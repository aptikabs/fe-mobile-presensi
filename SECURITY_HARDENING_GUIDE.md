# Panduan Keamanan & Build Release (Security Hardening Guide)

Dokumen ini berisi pedoman lengkap mengenai implementasi **Security Hardening**, **SSL Pinning**, **Obfuskasi URL**, serta **Cara Build Release** untuk environment **DEV** dan **PROD** pada aplikasi `epresensi_mobile`.

---

## 1. Lingkungan Environment & Obfuskasi URL (`Urls`)

Seluruh Base URL dan endpoint sensitif di-obfuskasi menggunakan **enkripsi XOR runtime (Key `0x57`)** pada file [`lib/api/urls.dart`](file:///Users/alzahfariski/Development/kerjaan/alfaefsatech/project/epresensi_mobile/lib/api/urls.dart) sehingga string plain-text tidak bocor saat biner APK/AAB di-scan dengan tools reverse engineering (*strings*, *Ghidra*, dll).

### Pilihan Environment (DEV vs PROD)

Aplikasi mendukung selektor environment via `--dart-define=ENV=...`:

| Environment | Parameter | Target Domain | Status Obfuskasi |
|---|---|---|:---:|
| **Development** | `--dart-define=ENV=dev` | `https://devepresensimobile.bengkuluprov.go.id/api` | 🔒 Obfuscated XOR |
| **Production** | `--dart-define=ENV=prod` | `https://epresensimobile.bengkuluprov.go.id/api` | 🔒 Obfuscated XOR |

---

## 2. Cara Melakukan Build APK / AppBundle (AAB)

Gunakan skrip otomasi yang telah disediakan di folder `scripts/`:

### A. Build APK versi DEV (Testing/Staging)
```bash
./scripts/build_release.sh dev
```
> **Hasil:** Membangun APK Rilis ter-obfuskasi mengarah ke server DEV (`devepresensimobile`).

### B. Build APK & AppBundle (AAB) versi PROD (Production)
```bash
./scripts/build_release.sh prod
```
> **Hasil:** Membangun APK dan AAB Rilis ter-obfuskasi mengarah ke server PROD (`epresensimobile`).

### C. Lokasi Debug Symbols
File simbol debug tersimpan secara otomatis di:
```text
build/app/outputs/symbols/
```
*Simpan folder `symbols` ini untuk setiap rilis agar bisa melakukan re-symbolicate crash log menggunakan perintah:*
```bash
flutter symbolize -i build/app/outputs/symbols/<file-symbol>.symbols -d crash_log.txt
```

---

## 3. Cara Mengubah Base URL Baru

Jika kelak terdapat perubahan domain Base URL, gunakan skrip generator [`scripts/encode_url.dart`](file:///Users/alzahfariski/Development/kerjaan/alfaefsatech/project/epresensi_mobile/scripts/encode_url.dart):

```bash
dart scripts/encode_url.dart "https://api-baru.bengkuluprov.go.id/api"
```

**Langkah-Langkah:**
1. Jalankan perintah di atas dengan URL baru Anda.
2. Salin array byte XOR yang dihasilkan oleh terminal.
3. Tempel (*paste*) variabel tersebut ke dalam [`lib/api/urls.dart`](file:///Users/alzahfariski/Development/kerjaan/alfaefsatech/project/epresensi_mobile/lib/api/urls.dart).

---

## 4. Cara Running / Debugging di IDE (VS Code & Android Studio)

### Menggunakan Terminal
```bash
# Running mode DEV
flutter run --dart-define=ENV=dev

# Running mode PROD
flutter run --dart-define=ENV=prod
```

### Konfigurasi VS Code (`.vscode/launch.json`)
Tambahkan konfigurasi ini di `.vscode/launch.json` agar mudah mengganti environment via menu **Run & Debug**:

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

## 5. Ringkasan Fitur Proteksi Keamanan

1. **SSL / TLS Certificate Pinning (`PinnedHttpClient`):**
   Memaksa seluruh request HTTP memverifikasi SHA-256 Public Key SPKI server `bengkuluprov.go.id` untuk mencegah penyadapan Man-In-The-Middle (Burp Suite / Charles Proxy).
2. **Native R8 & ProGuard Hardening (`android/app/proguard-rules.pro`):**
   Obfuskasi nama kelas native Android, penghapusan log debug, dan penghapusan nama file sumber (`SourceFile`).
3. **Environment Security Audit (`EnvironmentSecurityService`):**
   Pendeteksian perangkat ter-Root/Jailbroken, Frida Hooking/Instrumentation, Untrusted Emulator, dan Fake GPS / Mock Location.
