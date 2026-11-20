# TaniJagung — Aplikasi Pencatatan & Analisis Usaha Pertanian Jagung

**TaniJagung** adalah aplikasi manajemen usaha pertanian jagung berbasis **Flutter & Dart** yang terintegrasi dengan penyimpanan terisolasi per pengguna (mendukung **Firebase Authentication**, **Cloud Firestore**, **Firebase Storage**, dan **SharedPreferences Persistence**) serta sistem prediksi hasil panen berbasis **Machine Learning (Python, Scikit-learn, Pandas, FastAPI)**.

## Fitur Utama yang Telah Diimplementasikan
1. **Splash Screen, Onboarding & Autentikasi Terisolasi** ([auth_screens.dart](file:///c:/aplikasijagung/lib/screens/auth_screens.dart))
   - Registrasi (Nama, Email, Password, Nama Usaha Tani), Login, Logout, dan Profil.
   - Isolasi penuh per `user_id` sehingga data satu petani tidak terlihat oleh pengguna lain.
   - Opsi memuat data contoh yang secara eksplisit diberi label `[DATA CONTOH]` dan dapat dihapus kapan saja.
2. **Beranda Ringkasan Kondisi Usaha Tani** ([home_screen.dart](file:///c:/aplikasijagung/lib/screens/home_screen.dart))
   - Menampilkan total luas lahan (ha), jumlah lahan terdaftar, musim tanam aktif, pengeluaran musim aktif, target hasil panen, total pendapatan, keuntungan/kerugian, jadwal kegiatan terdekat, dan aktivitas terakhir.
   - 5 Tombol Aksi Cepat: **Tambah Lahan**, **Buat Musim Tanam**, **Catat Pengeluaran**, **Catat Aktivitas**, **Input Hasil Panen**.
3. **Manajemen Lahan & Musim Tanam** ([plots_screen.dart](file:///c:/aplikasijagung/lib/screens/plots_screen.dart))
   - Konversi otomatis luas lahan antara `m²` dan `hektare` (`1 ha = 10.000 m²`).
   - Siklus musim tanam dengan acuan awal 4 bulan sejak tanggal tanam (dapat diubah pengguna), perhitungan umur tanaman (HST), sisa hari menuju perkiraan panen, dan lama aktual setelah tanggal panen diisi.
4. **Pencatatan Benih, Pupuk & Seluruh Pengeluaran Manual** ([app_form_dialogs.dart](file:///c:/aplikasijagung/lib/widgets/app_form_dialogs.dart))
   - Perhitungan otomatis `Subtotal = Jumlah × Harga per satuan`.
   - Pencegahan penghitungan ganda (*anti double-counting*): apabila benih/pupuk diambil dari stok gudang yang sudah dibeli, penggunaannya tidak dihitung ulang sebagai biaya baru.
5. **Kalender Bulanan, Timeline Tanam & Pengingat Tanggal** ([activities_screen.dart](file:///c:/aplikasijagung/lib/screens/activities_screen.dart))
   - Kalender interaktif (`table_calendar`) dan timeline kronologis dari pengolahan lahan, penanaman, pemupukan 1 & berikutnya, pestisida, perawatan, hingga panen.
   - Pengingat otomatis hanya berdasarkan tanggal manual yang diinput pengguna (tanpa fitur cuaca/BMKG).
6. **Input Hasil Panen Aktual** ([app_form_dialogs.dart](file:///c:/aplikasijagung/lib/widgets/app_form_dialogs.dart))
   - Mendukung panen bertahap (lebih dari satu transaksi panen per musim).
   - Konversi otomatis `1 ton = 1.000 kg` dan `Pendapatan Kotor = Hasil Panen (kg) × Harga Jual per kg`.
7. **Analisis Keuangan, Produktivitas & Simulasi Keuntungan** ([analysis_screen.dart](file:///c:/aplikasijagung/lib/screens/analysis_screen.dart))
   - Status otomatis **UNTUNG**, **RUGI**, atau **IMPAS**, persentase laba terhadap biaya, biaya produksi per kg, dan titik impas (*break-even price*) per kg.
   - Produktivitas `kg/ha = Total Hasil Panen (kg) / Luas Lahan (ha)` beserta grafik perbandingan antar lahan dan antar musim.
   - Mode **Simulasi Keuntungan** interaktif berlabel jelas yang tidak mengubah data keuangan aktual.
8. **Stok Gudang Benih & Pupuk** ([inventory_screen.dart](file:///c:/aplikasijagung/lib/screens/inventory_screen.dart))
   - Rumus otomatis `Stok Akhir = Stok Awal + Stok Masuk - Stok Keluar` dan peringatan stok habis/di bawah batas minimum pengguna.
9. **Riwayat, Perbandingan Musim & Ekspor Laporan PDF** ([reports_screen.dart](file:///c:/aplikasijagung/lib/screens/reports_screen.dart) & [pdf_report_service.dart](file:///c:/aplikasijagung/lib/services/pdf_report_service.dart))
   - Laporan lengkap per musim tanam, tabel perbandingan 2+ musim tanam, grafik biaya vs pendapatan, dan cetak/ekspor laporan PDF.
10. **Prediksi Hasil Panen (Machine Learning + FastAPI)** ([prediction_screen.dart](file:///c:/aplikasijagung/lib/screens/prediction_screen.dart) & [main.py](file:///c:/aplikasijagung/backend/main.py))
    - Melatih dan membandingkan **Linear Regression** dan **Random Forest Regression** menggunakan dataset hasil panen jagung ([corn_yield_dataset.csv](file:///c:/aplikasijagung/backend/corn_yield_dataset.csv)) beserta metrik evaluasi **MAE**, **RMSE**, dan **R²**.

## Cara Menjalankan
### 1. Menjalankan Backend Prediksi Python FastAPI
```bash
pip install -r backend/requirements.txt
python backend/main.py
```
Server berjalan pada `http://127.0.0.1:8000` (endpoint `/health` dan `/predict`).

### 2. Menjalankan Aplikasi Flutter
```bash
flutter pub get
flutter run
```
