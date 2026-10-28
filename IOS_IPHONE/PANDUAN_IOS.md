# Paket & Konfigurasi Khusus iOS (iPhone / iPad)

Folder ini berisi informasi dan konfigurasi untuk menjalankan aplikasi di perangkat **Apple iOS (iPhone / iPad)**:

* **Format File Apple**: `.ipa` (untuk iPhone fisik) atau `.zip` berisi `.app` (untuk iOS Simulator / Appetize.io).
* **Catatan Penting**: Apple secara ketat **TIDAK MENDUKUNG** file `.apk`.
* **Cara Menjalankan untuk iOS**:
  1. **Lewat Cloud GitHub Actions (Gratis)**:
     File workflow sudah kami sediakan di `.github/workflows/build_ios.yml`. Begitu proyek di-push ke GitHub, server Mac GitHub akan otomatis mem-build file `.zip` berisi `Runner.app`.
  2. **Untuk Appetize.io (Online Web)**:
     - Jika ingin testing instan tanpa compile Mac: di web Appetize.io cukup pilih tab **Android** lalu upload file APK dari folder `ANDROID_APK/`.
     - Jika wajib tampilan iPhone: download file `.zip` hasil build GitHub Actions lalu upload ke Appetize.io.
