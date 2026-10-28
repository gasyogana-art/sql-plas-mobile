# Panduan Build & Upload iOS untuk Appetize.io / Online Simulator

Direktori ini (`ios_release/`) disiapkan khusus untuk kebutuhan distribusi dan testing versi **iOS (iPhone)** tanpa mengganggu file [`VerilogPLAS.apk`](../VerilogPLAS.apk).

---

## 1. Menjalankan di Appetize.io Secara Langsung (Solusi Instan)
Di website **Appetize.io**:
* Layar yang muncul di screenshot Anda meminta `.zip` karena sedang berada di tab/pilihan **iOS**.
* **Appetize.io juga mendukung Android secara langsung!**
* Anda bisa memilih tab **Android** di Appetize.io, lalu langsung upload file [`VerilogPLAS.apk`](../VerilogPLAS.apk).
* Aplikasi VPLAS Verilog akan langsung berjalan di browser dalam emulator Android (Google Pixel / Samsung).

---

## 2. Mengapa iOS Memerlukan File `.zip` (.app bundle)?
Pesan di screenshot Anda:
> *" For iOS, upload a .zip or .tar.gz file containing your compressed .app bundle."*

Sistem operasi iOS Apple mewajibkan kompilasi binary Mach-O menggunakan **Apple Xcode & Clang compiler** (yang secara legal dan teknis hanya tersedia di sistem operasi macOS). Oleh karena itu, laptop/PC berbasis Windows tidak dapat mengkompilasi file `.app` secara offline langsung.

---

## 3. Cara Mendapatkan File iOS `.app.zip` untuk Appetize.io

Ada 2 cara mudah dan gratis untuk mendapatkan file `.app.zip` tersebut:

### Cara A: Otomatis & Gratis via GitHub Actions (Rekomendasi jika memakai Windows)
Kami telah membuatkan file konfigurasi otomatis di [`.github/workflows/build_ios.yml`](../.github/workflows/build_ios.yml):
1. Push proyek ini ke repository GitHub Anda (bisa Private atau Public).
2. Buka tab **Actions** di GitHub, workflow **"Build iOS Simulator App for Appetize.io"** akan berjalan otomatis di server Mac gratis milik GitHub.
3. Setelah selesai (±3-5 menit), unduh artifact bernama **`VerilogPLAS_iOS_Simulator_Appetize`**.
4. Di dalamnya sudah ada file `.zip` berisi `Runner.app` yang siap langsung di-upload ke Appetize.io.

### Cara B: Jika Menggunakan Komputer Mac (MacBook / iMac)
Jika Anda atau teman Anda memiliki MacBook:
1. Buka Terminal di folder proyek ini:
   ```bash
   flutter pub get
   flutter build ios --simulator --no-codesign
   ```
2. Kompres folder hasil build ke format `.zip`:
   ```bash
   cd build/ios/iphonesimulator
   zip -r -y VerilogPLAS_iOS.zip Runner.app
   ```
3. Upload file `VerilogPLAS_iOS.zip` tersebut ke Appetize.io.
