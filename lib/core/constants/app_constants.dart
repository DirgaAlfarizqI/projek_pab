class AppConstants {
  static const String appName = 'TaniJagung';
  static const String appSlogan = 'Kelola Usaha Tani, Raih Hasil Maksimal';
  static const String subSlogan = 'Bersama Petani Menuju Panen Maksimal';

  // 9 Kategori Pengeluaran Sesuai Spesifikasi
  static const List<String> expenseCategories = [
    'Benih',
    'Pupuk',
    'Pestisida',
    'Pengolahan lahan',
    'Tenaga kerja',
    'Sewa alat',
    'Transportasi',
    'Biaya panen',
    'Lain-lain',
  ];

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
