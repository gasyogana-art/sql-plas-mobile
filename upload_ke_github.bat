@echo off
echo ========================================================
echo Mempersiapkan Upload Kode Proyek ke GitHub...
echo ========================================================
cd /d "D:\APK_AI\VerilogPLAS_2"

if not exist .git (
    git init
    git remote add origin https://github.com/gasyogana-art/sql-plas-mobile.git
    git branch -M main
)

echo Mengambil update terbaru dari GitHub...
git pull origin main --rebase

echo Menambahkan file kode proyek...
git add .

echo Membuat commit...
git commit -m "Upload source code for iOS build"

echo Mengirim ke GitHub...
git push -u origin main

echo.
echo ========================================================
echo Selesai! Silakan cek tab Actions di GitHub Anda.
echo ========================================================
pause
