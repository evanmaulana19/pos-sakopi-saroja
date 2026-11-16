# POS Sakopi Saroja

Aplikasi Point of Sales (POS) berbasis mobile yang dibangun menggunakan **Flutter** dan **Supabase**. Aplikasi ini dibuat untuk memenuhi tugas akhir mata kuliah Pemrograman Aplikasi Bergerak.

## Fitur Utama

Aplikasi ini memiliki 3 hak akses (role) utama:

1. **Kasir (Cashier)**
   - Menambahkan produk ke keranjang belanja.
   - Mengelola kuantitas pesanan.
   - Melakukan checkout dan pembayaran (Tunai / Non-Tunai).
   - Mencetak struk bukti pembayaran.

2. **Admin**
   - Melihat ringkasan penjualan secara singkat.
   - Mengelola Data Produk (Menambah, Mengedit, Menghapus menu/produk).
   - Mengelola Kategori Produk.
   - Mengelola riwayat transaksi harian.

3. **Owner (Pemilik)**
   - Melihat Laporan Keuangan secara komprehensif (Pendapatan Kotor, Laba Bersih, Pengeluaran).
   - Filter laporan berdasarkan rentang waktu (Hari ini, Minggu ini, Bulan ini).
   - Melihat grafik tren penjualan interaktif.
   - Melihat Top 5 Menu terlaris.
   - Mengunduh / Mengekspor laporan keuangan dalam bentuk **PDF**.
   - Mengelola akun staf (Kasir & Admin).

## Teknologi yang Digunakan
- **Frontend:** Flutter & Dart
- **Backend/Database:** Supabase (PostgreSQL, Authentication)
- **State Management:** Riverpod
- **Lainnya:** fl_chart (Grafik), pdf & printing (Ekspor Struk/PDF)

---

## Akun Pengujian (Demo Accounts)

Untuk memudahkan pengujian (testing) oleh dosen atau penilai, berikut adalah akun demo yang dapat digunakan untuk masuk ke masing-masing dashboard (silakan ubah password sesuai dengan yang Anda atur di Supabase Dashboard Anda):

* Catatan untuk Mahasiswa: Pastikan untuk menuliskan email dan password yang Anda buat di Supabase ke dalam daftar ini sebelum diserahkan.*

- **Kasir:**
  - Email: `kasir@sakopi.com` (Ubah dengan email kasir Anda)
  - Password: `password123` (Ubah dengan password kasir Anda)

- **Admin:**
  - Email: `admin@sakopi.com` (Ubah dengan email admin Anda)
  - Password: `password123` (Ubah dengan password admin Anda)

- **Owner:**
  - Email: `owner@sakopi.com` (Ubah dengan email owner Anda)
  - Password: `password123` (Ubah dengan password owner Anda)

---

## Cara Menjalankan Proyek (Bagi Dosen/Penilai)

### Opsi 1: Menginstal File APK (Paling Mudah)
1. Pindahkan file `pos_sakopi.apk` (jika Anda melampirkannya) ke perangkat Android Anda.
2. Buka file manager di perangkat Android, lalu klik file APK tersebut untuk menginstal.
3. Aplikasi siap dijalankan tanpa perlu setup apapun. (Koneksi internet diperlukan).

### Opsi 2: Menjalankan dari Source Code (Flutter)
Jika penilai ingin melihat dan menjalankan langsung dari kode sumber:
1. Pastikan **Flutter SDK** sudah terinstal.
2. Buka folder proyek ini di Terminal / VS Code.
3. Jalankan perintah untuk mengunduh dependency:
   ```bash
   flutter pub get
   ```
4. Pastikan file `.env` sudah disertakan di *root* folder yang berisi konfigurasi Supabase (URL dan Anon Key).
5. Sambungkan emulator atau perangkat asli (Android/iOS).
6. Jalankan proyek:
   ```bash
   flutter run
   ```

---
*Dibuat oleh: [Nama Anda] - [NIM/NPM Anda]*
