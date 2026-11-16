# Design System Document (design.md)

*   **Nama Proyek:** POS Sakopi Saroja
*   **Target Resolusi:** Responsif, dioptimalkan untuk Tablet (Landscape) & Smartphone (Portrait).
*   **Tema Utama:** Modern, Bersih, Elegan (Nuansa Kedai Kopi Premium).

---

## 1. Palet Warna (Color Palette)
Aplikasi ini menggunakan kombinasi warna *earth tone* yang memberikan kesan hangat dan profesional, identik dengan kopi.

### 1.1. Warna Utama (Primary)
*   **Hijau Gelap (Dark Green) - `Color(0xFF2E3E34)`**
    *   **Penggunaan:** Sidebar/Navigasi utama, Tombol Aksi Utama (seperti "Semua Menu" yang aktif, "Tunai"), Ikon aktif, teks header di sidebar.
    *   **Deskripsi:** Memberikan kontras yang kuat dan kesan elegan.
*   **Krem Terang (Light Beige / Off-White) - `Color(0xFFF9F5EE)`**
    *   **Penggunaan:** Latar belakang utama (Background) area menu dan area ringkasan pesanan, latar belakang kartu (Card).
    *   **Deskripsi:** Warna dasar yang ramah mata untuk kasir yang menatap layar dalam waktu lama.

### 1.2. Warna Aksen & Sekunder (Accent & Secondary)
*   **Krem Keemasan (Golden Tan) - `Color(0xFFEED596)`**
    *   **Penggunaan:** Tombol Aksi Penting (CTA) seperti "Bayar Sekarang", indikator menu aktif di Owner/Admin, ikon *badge*.
    *   **Deskripsi:** Menarik perhatian namun tetap harmoni dengan warna utama.
*   **Abu-abu Gelap (Dark Gray / Muted Text) - `Color(0xFF5A5A5A)`**
    *   **Penggunaan:** Sub-judul, teks deskripsi, harga produk, *placeholder* input.
*   **Merah Bata (Soft Red/Alert) - `Color(0xFFB54C4C)`**
    *   **Penggunaan:** Tombol "Keluar/Logout", ikon hapus, indikator stok habis/error.

---

## 2. Tipografi (Typography)
Tipografi harus bersih, mudah dibaca sekilas (sangat penting untuk kasir), dan modern (Sans-Serif).

*   **Font Family Rekomendasi:** `Poppins` atau `Inter` (via Google Fonts).
*   **Tingkat Penggunaan (Hierarchy):**
    *   **H1 (Judul Halaman):** Bold, 24sp (contoh: "Kasir", "Pesanan Saat Ini"). Warna: Hijau Gelap / Hitam Pekat.
    *   **H2 (Nama Produk/Sub-judul):** SemiBold, 16sp (contoh: "Salted Caramel", "Total Rp 26.000").
    *   **Body 1 (Harga/Teks Biasa):** Regular/Medium, 14sp (contoh: "Rp 10.000", "Subtotal"). Warna: Abu-abu Gelap.
    *   **Caption (Tanggal/Waktu/Order ID):** Regular, 12sp. Warna: Abu-abu Terang.

---

## 3. Komponen UI Global (Shared Widgets)

### 3.1. Kartu Produk (Product Card)
Digunakan di Halaman Kasir (Menu).
*   **Bentuk:** Persegi panjang vertikal dengan sudut membulat (border-radius: 12px).
*   **Latar Belakang:** Putih / Krem sangat terang dengan efek bayangan lembut (soft drop shadow).
*   **Layout Internal:**
    *   *Top:* Gambar produk (Aspek rasio 4:3 atau kotak, menutupi area atas kartu, background gambar hijau gelap).
    *   *Bottom:* Padding 12px. Nama produk (SemiBold, 14sp, dua baris max), Harga (Regular, 12sp, warna emas/hijau).

### 3.2. Tombol (Buttons)
*   **Primary Button (Aksi Utama):** 
    *   Contoh: "Bayar Sekarang" (Krem Keemasan), "Selesaikan" (Hijau Gelap).
    *   Style: Lebar penuh (*full width* di panelnya), sudut membulat (border-radius: 8px), teks tebal (Bold).
*   **Tab / Filter Button (Pilihan Kategori):**
    *   Contoh: "Semua Menu", "Kopi".
    *   Style (Aktif): Latar Hijau Gelap, Teks Putih.
    *   Style (Tidak Aktif): Latar Putih (dengan border tipis abu-abu), Teks Hijau Gelap/Abu-abu. Bentuk kapsul (border-radius: 24px).
*   **Quantity Button (+ / -):**
    *   Berbentuk lingkaran kecil atau kapsul, latar belakang krem muda, ikon hitam/hijau.

### 3.3. Input Fields (Text Fields)
Digunakan untuk Halaman Admin (Tambah Menu) dan Owner (Tambah Pengeluaran).
*   **Style:** *Outline border* abu-abu terang. Saat fokus, *border* berubah menjadi Hijau Gelap. Sudut membulat (8px). Latar belakang putih.

---

## 4. Tata Letak Halaman (Layout Structure)

### 4.1. Halaman Kasir (POS) - Tablet Landscape
Menggunakan layout 2-kolom (atau 3-kolom jika menghitung sidebar navigasi).
*   **Kolom 1 (Kiri - 20%): Navigasi Vertikal**
    *   Latar Belakang: Hijau Gelap.
    *   Isi: Logo "VERSI NATIVE", Menu (POS, Antrean, Keluar).
*   **Kolom 2 (Tengah - 50%): Area Menu**
    *   Latar Belakang: Krem Terang.
    *   Isi: Header (Judul & Tanggal), Baris Filter Kategori, Grid Layout Produk (3 atau 4 kolom grid tergantung ukuran layar).
*   **Kolom 3 (Kanan - 30%): Panel Ringkasan Pesanan (Cart)**
    *   Latar Belakang: Putih/Krem sangat terang (dipisahkan oleh garis vertikal tipis).
    *   Isi: Judul "Pesanan Saat Ini", ListView item yang dipilih (Nama, Harga, kontrol kuantitas +/-), Garis pemisah putus-putus, Rincian Total, Pilihan Pembayaran, Tombol "Bayar Sekarang" di area *bottom* (lengket/sticky).

### 4.2. Halaman Admin & Owner - Mobile/Tablet Portrait
Menggunakan layout *Bottom Navigation Bar* standar.
*   **Header (AppBar):** 
    *   Latar belakang putih/krem, tanpa bayangan keras (elevation: 0).
    *   Menampilkan Judul (Contoh: "Manajemen Menu") dan ikon profil.
*   **Body:**
    *   Latar belakang krem terang.
    *   Menggunakan ListView atau GridView dengan jarak antar kartu (spacing) sekitar 16px.
*   **Bottom Navigation:**
    *   Warna latar: Putih.
    *   Ikon aktif: Krem Keemasan atau Hijau Gelap (dengan latar membulat kecil di belakang ikon).
    *   Ikon tidak aktif: Abu-abu.

---

## 5. Aset Ikon & Gambar
*   **Ikonografi:** Gunakan *library* seperti `Heroicons` atau `Material Symbols Rounded` (tersedia via *package* Flutter) untuk menjaga konsistensi ketebalan garis (outline style disarankan).
*   **Gambar Produk:** Disimpan di Supabase Storage. UI harus memiliki *placeholder image* (gambar pengganti) atau *shimmer effect* (efek *loading*) saat gambar asli sedang diunduh dari internet.