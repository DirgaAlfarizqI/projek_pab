class AppConstants {
  static const String appName = 'TaniJagung';
  static const String appSlogan = 'Kelola Usaha Tani, Raih Hasil Maksimal';
  static const String subSlogan = 'Bersama Petani Menuju Panen Maksimal';

  // Konfigurasi Internal URL Backend Prediksi FastAPI (Tidak ditampilkan di form profil pengguna)
  static const String internalPredictionApiUrl = 'http://127.0.0.1:8000';

  // 5 Kategori Pengeluaran Sesuai Revisi 1:
  // "Tenaga kerja", "Sewa alat", "Transportasi", dan "Biaya panen" digabung ke "Lain-lain"
  static const List<String> expenseCategories = [
    'Pupuk',
    'Benih',
    'Pestisida',
    'Pengolahan lahan',
    'Lain-lain',
  ];

  // Daftar kategori lama yang dimigrasikan otomatis ke "Lain-lain"
  static const Set<String> migratedToOtherCategories = {
    'Tenaga kerja',
    'Sewa alat',
    'Sewa alat atau mesin',
    'Transportasi',
    'Biaya panen',
    'Biaya lainnya',
    'Lainnya',
  };

  static String normalizeExpenseCategory(String rawCategory) {
    final trimmed = rawCategory.trim();
    if (migratedToOtherCategories.contains(trimmed)) {
      return 'Lain-lain';
    }
    if (expenseCategories.contains(trimmed)) {
      return trimmed;
    }
    return 'Lain-lain';
  }

  // Kategori Aktivitas & Kalender
  static const List<String> activityCategories = [
    'Mulai Penanaman',
    'Pemupukan Pertama',
    'Pemupukan Kedua',
    'Penyemprotan',
    'Perawatan',
    'Perkiraan Panen',
    'Panen Aktual',
  ];

  // Jenis Kegiatan Pengingat Jadwal
  static const List<String> reminderActivityTypes = [
    'Penyiraman',
    'Pemupukan',
    'Penyemprotan',
    'Perawatan Lahan',
    'Lainnya',
  ];

  // Pilihan Pengulangan Pengingat Jadwal
  static const List<String> reminderRepeatTypes = [
    'Sekali',
    'Harian',
    'Mingguan',
    'Interval Hari',
  ];

  // Status Musim Tanam
  static const List<String> cycleStatuses = [
    'Persiapan',
    'Aktif',
    'Berlangsung',
    'Menunggu Panen',
    'Selesai',
  ];

  // Satuan Luas
  static const List<String> areaUnits = ['hektare', 'm²'];

  // Satuan Berat Panen
  static const List<String> weightUnits = ['ton', 'kg', 'kuintal'];

  // Satuan Kuantitas Input
  static const List<String> inputUnits = [
    'kg',
    'gram',
    'liter',
    'karung',
    'paket',
    'unit',
  ];
}
