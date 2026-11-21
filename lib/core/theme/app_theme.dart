import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

/// =====================================================================
/// DESIGN SYSTEM TANIJAGUNG (Tahap 1 Redesain — Modern, Hidup, Premium)
/// =====================================================================
/// - Palet: Hijau tua #1B4D3E (primer), Hijau segar #2E7D4F (aksen),
///   Kuning jagung #F5C84C (highlight), Krem lembut #F7F5EE (latar).
///   Merah & jingga HANYA untuk peringatan.
/// - Tipografi: Plus Jakarta Sans (judul & angka uang), Inter (isi).
///   Font dibundel sebagai aset lokal (offline, tanpa unduhan runtime).
/// - Komponen: radius 20–28 px, shadow lembut berlapis, grid 8 px.
/// - Gerak: durasi 150–400 ms (interaksi), maks 600 ms (transisi besar),
///   kurva easeOutCubic / easeOutBack, menghormati "kurangi animasi".
class AppTheme {
  AppTheme._();

  // ---------------------------------------------------------------------
  // PALET UTAMA
  // ---------------------------------------------------------------------
  static const Color darkGreen = Color(0xFF1B4D3E); // Primer
  static const Color primaryGreen = Color(0xFF2E7D4F); // Aksen segar
  static const Color cornYellow = Color(0xFFF5C84C); // Highlight jagung
  static const Color creamBackground = Color(0xFFF7F5EE); // Latar krem
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  static const Color lightGreen = Color(0xFFE6F1E9); // Tint hijau lembut
  static const Color mintGreen = Color(0xFFD3E9DA);
  static const Color cornYellowLight = Color(0xFFFDF4D6);
  static const Color cornGold = Color(0xFFD9A628);

  // Alias kompatibilitas (dipakai oleh layar yang sudah ada)
  static const Color primaryDarkGreen = darkGreen;
  static const Color deepForestGreen = darkGreen;
  static const Color leafGreen = primaryGreen;
  static const Color softMintGreen = lightGreen;
  static const Color lightLeafGreen = lightGreen;

  // Teks & garis
  static const Color textPrimary = Color(
    0xFF13261D,
  ); // Kontras AA di krem/putih
  static const Color textSecondary = Color(0xFF55675C); // ≥ 4.5:1 di putih
  static const Color textMuted = Color(0xFF8A9A90);
  static const Color borderColor = Color(0xFFE6E9E2);

  // Status (khusus peringatan)
  static const Color dangerRed = Color(0xFFD13B2C);
  static const Color dangerLight = Color(0xFFFCEBE9);
  static const Color warningOrange = Color(0xFFE07B1A);
  static const Color warningLight = Color(0xFFFDF0E2);
  static const Color salmonLogout = Color(0xFFD9503F);
  static const Color successGreen = Color(0xFF2E9D5B);
  static const Color infoBlue = Color(0xFF1E6FB8);
  static const Color infoLight = Color(0xFFE7F1FA);

  // Palet Dark Mode
  static const Color darkBackground = Color(0xFF0E1A15);
  static const Color darkSurface = Color(0xFF16261F);
  static const Color darkSurfaceHigh = Color(0xFF1E3229);
  static const Color darkTextPrimary = Color(0xFFEAF2EC);
  static const Color darkTextSecondary = Color(0xFFA9BBB0);
  static const Color darkBorder = Color(0xFF2A3F35);

  // ---------------------------------------------------------------------
  // TIPOGRAFI
  // ---------------------------------------------------------------------
  static const String headingFont = 'PlusJakartaSans';
  static const String bodyFont = 'Inter';

  // ---------------------------------------------------------------------
  // GRADIENT
  // ---------------------------------------------------------------------
  /// Gradient kartu utama (hero) — hijau tua ke hijau segar.
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF173F33), darkGreen, primaryGreen],
    stops: [0.0, 0.45, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradient splash screen.
  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF143A2F), darkGreen, primaryGreen],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Gradient peringatan rugi (hanya saat benar-benar rugi setelah panen).
  static const LinearGradient lossGradient = LinearGradient(
    colors: [Color(0xFFB8321F), dangerRed],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradient kuning jagung untuk highlight/badge.
  static const LinearGradient cornGradient = LinearGradient(
    colors: [Color(0xFFF8D86E), cornYellow, cornGold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ---------------------------------------------------------------------
  // TEMA TERANG
  // ---------------------------------------------------------------------
  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  // ---------------------------------------------------------------------
  // TEMA GELAP (disiapkan; diaktifkan bertahap setelah semua layar memakai
  // warna dari Theme/AppColors agar kontras tetap aman)
  // ---------------------------------------------------------------------
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final bg = isDark ? darkBackground : creamBackground;
    final surface = isDark ? darkSurface : surfaceWhite;
    final onSurface = isDark ? darkTextPrimary : textPrimary;
    final onSurfaceVariant = isDark ? darkTextSecondary : textSecondary;
    final border = isDark ? darkBorder : borderColor;
    final primary = isDark ? const Color(0xFF6CC28E) : darkGreen;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: isDark ? darkBackground : surfaceWhite,
      primaryContainer: isDark ? const Color(0xFF214B3B) : lightGreen,
      onPrimaryContainer: isDark ? darkTextPrimary : darkGreen,
      secondary: cornYellow,
      onSecondary: textPrimary,
      secondaryContainer: isDark ? const Color(0xFF4A3F17) : cornYellowLight,
      onSecondaryContainer: isDark ? const Color(0xFFFBE7A6) : textPrimary,
      tertiary: primaryGreen,
      onTertiary: surfaceWhite,
      error: dangerRed,
      onError: surfaceWhite,
      errorContainer: isDark ? const Color(0xFF5A1F18) : dangerLight,
      onErrorContainer: isDark ? const Color(0xFFFFDAD4) : dangerRed,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      surfaceContainerHighest: isDark ? darkSurfaceHigh : lightGreen,
      outline: border,
      outlineVariant: border,
      shadow: Colors.black,
      surfaceTint: Colors.transparent,
    );

    final textTheme = _buildTextTheme(onSurface, onSurfaceVariant);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      fontFamily: bodyFont,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded, // area sentuh ≥ 48
      extensions: [isDark ? AppColors.dark : AppColors.light],

      // Transisi antar halaman: Shared Axis (horizontal) yang halus
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SharedAxisPageTransitionsBuilder(
            transitionType: SharedAxisTransitionType.horizontal,
          ),
          TargetPlatform.iOS: SharedAxisPageTransitionsBuilder(
            transitionType: SharedAxisTransitionType.horizontal,
          ),
          TargetPlatform.windows: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.linux: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeThroughPageTransitionsBuilder(),
        },
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: headingFont,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: onSurface,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: onSurface, size: 22),
      ),

      // Kartu: tanpa border tipis, shadow lembut ber-tint hijau
      cardTheme: CardThemeData(
        color: surface,
        elevation: isDark ? 0 : 2,
        shadowColor: isDark
            ? Colors.transparent
            : darkGreen.withValues(alpha: 0.10),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: isDark
              ? BorderSide(color: border.withValues(alpha: 0.6))
              : BorderSide.none,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? primary : darkGreen,
          foregroundColor: isDark ? darkBackground : surfaceWhite,
          disabledBackgroundColor: border,
          elevation: 0,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(
            fontFamily: headingFont,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(
            fontFamily: headingFont,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? primary : darkGreen,
          backgroundColor: surface,
          minimumSize: const Size(64, 52),
          side: BorderSide(
            color: isDark ? border : darkGreen.withValues(alpha: 0.22),
            width: 1.4,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(
            fontFamily: headingFont,
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? primary : primaryGreen,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: const TextStyle(
            fontFamily: headingFont,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? darkSurfaceHigh : const Color(0xFFF9FAF6),
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: TextStyle(
          color: onSurfaceVariant,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(
          color: isDark ? primary : primaryGreen,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(
          color: isDark ? darkTextSecondary : textMuted,
          fontSize: 14,
        ),
        prefixIconColor: onSurfaceVariant,
        suffixIconColor: onSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: isDark ? primary : primaryGreen,
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: dangerRed, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: dangerRed, width: 1.8),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surface,
        showDragHandle: true,
        dragHandleColor: border,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        titleTextStyle: TextStyle(
          fontFamily: headingFont,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: onSurface,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? darkSurfaceHigh : darkGreen,
        contentTextStyle: const TextStyle(
          fontFamily: bodyFont,
          color: surfaceWhite,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: cornYellow,
        elevation: 6,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: isDark ? const Color(0xFF214B3B) : lightGreen,
        side: BorderSide(color: border),
        labelStyle: TextStyle(
          fontFamily: bodyFont,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: isDark ? primary : darkGreen,
        textColor: onSurface,
        minVerticalPadding: 12,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? surfaceWhite : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primaryGreen : null,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primaryGreen : null,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: isDark ? primary : primaryGreen,
        linearTrackColor: isDark ? darkSurfaceHigh : lightGreen,
        circularTrackColor: isDark ? darkSurfaceHigh : lightGreen,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        elevation: 0,
        indicatorColor: isDark ? const Color(0xFF214B3B) : lightGreen,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: bodyFont,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? primary : onSurfaceVariant,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark ? primary : darkGreen,
        foregroundColor: isDark ? darkBackground : surfaceWhite,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: border.withValues(alpha: 0.8),
        thickness: 1,
        space: 1,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? darkSurfaceHigh : darkGreen,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: const TextStyle(
          fontFamily: bodyFont,
          color: surfaceWhite,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    TextStyle heading(double size, FontWeight w, {double ls = -0.3}) =>
        TextStyle(
          fontFamily: headingFont,
          fontSize: size,
          fontWeight: w,
          letterSpacing: ls,
          color: primary,
          height: 1.2,
        );
    TextStyle body(double size, FontWeight w, Color c) => TextStyle(
      fontFamily: bodyFont,
      fontSize: size,
      fontWeight: w,
      color: c,
      height: 1.45,
    );

    return TextTheme(
      displayLarge: heading(44, FontWeight.w800, ls: -1.0),
      displayMedium: heading(36, FontWeight.w800, ls: -0.8),
      displaySmall: heading(30, FontWeight.w800, ls: -0.6),
      headlineLarge: heading(28, FontWeight.w800, ls: -0.5),
      headlineMedium: heading(24, FontWeight.w800, ls: -0.4),
      headlineSmall: heading(20, FontWeight.w700),
      titleLarge: heading(18, FontWeight.w700, ls: -0.2),
      titleMedium: heading(16, FontWeight.w700, ls: -0.1),
      titleSmall: heading(14, FontWeight.w700, ls: 0),
      bodyLarge: body(16, FontWeight.w400, primary),
      bodyMedium: body(14, FontWeight.w400, primary),
      bodySmall: body(12.5, FontWeight.w400, secondary),
      labelLarge: body(14, FontWeight.w600, primary),
      labelMedium: body(12.5, FontWeight.w600, secondary),
      labelSmall: body(11, FontWeight.w600, secondary),
    );
  }
}

/// Skala jarak berbasis grid 8 px.
class AppSpacing {
  AppSpacing._();
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;

  /// Padding horizontal halaman standar.
  static const double page = 20;

  /// Lebar maksimum konten agar tidak terlalu melebar di tablet.
  static const double maxContentWidth = 720;

  /// Batas lebar untuk beralih ke grid 2 kolom.
  static const double twoColumnBreakpoint = 600;
}

/// Skala radius sudut (20–28 px untuk kartu utama).
class AppRadius {
  AppRadius._();
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 28;
  static const double pill = 100;
}

/// Shadow lembut berlapis (ambient + key light), bukan border tipis.
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get soft => [
    BoxShadow(
      color: AppTheme.darkGreen.withValues(alpha: 0.05),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: AppTheme.darkGreen.withValues(alpha: 0.07),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get medium => [
    BoxShadow(
      color: AppTheme.darkGreen.withValues(alpha: 0.06),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: AppTheme.darkGreen.withValues(alpha: 0.10),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];

  /// Shadow ber-glow untuk kartu hero bergradient.
  static List<BoxShadow> get hero => [
    BoxShadow(
      color: AppTheme.darkGreen.withValues(alpha: 0.18),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: AppTheme.primaryGreen.withValues(alpha: 0.28),
      blurRadius: 32,
      spreadRadius: -6,
      offset: const Offset(0, 18),
    ),
  ];

  /// Shadow ke atas untuk bottom navigation.
  static List<BoxShadow> get navBar => [
    BoxShadow(
      color: AppTheme.darkGreen.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, -4),
    ),
  ];
}

/// Token durasi & kurva animasi + dukungan "kurangi animasi".
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration short = Duration(milliseconds: 220);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration long = Duration(milliseconds: 400);
  static const Duration page = Duration(milliseconds: 500);
  static const Duration staggerStep = Duration(milliseconds: 60);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutBack;
  static const Curve decelerate = Curves.easeOutQuart;

  /// True jika pengguna mengaktifkan "Hapus/Kurangi animasi" di sistem.
  static bool reduceMotion(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Durasi yang otomatis menjadi nol saat reduce motion aktif.
  static Duration of(BuildContext context, Duration d) =>
      reduceMotion(context) ? Duration.zero : d;
}

/// Gaya teks khusus angka uang (tebal, besar, angka tabular).
class AppTextStyles {
  AppTextStyles._();

  static TextStyle money({
    double size = 28,
    Color color = AppTheme.textPrimary,
    FontWeight weight = FontWeight.w800,
  }) => TextStyle(
    fontFamily: AppTheme.headingFont,
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: -0.6,
    height: 1.1,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: AppTheme.headingFont,
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: AppTheme.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: AppTheme.bodyFont,
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: AppTheme.textSecondary,
  );
}

/// ThemeExtension warna semantik agar layar bisa mengikuti Light/Dark mode
/// melalui `Theme.of(context).extension<AppColors>()!` atau `context.appColors`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color accentTint;
  final Color highlight;
  final Color highlightTint;
  final Color danger;
  final Color dangerTint;
  final Color warning;
  final Color warningTint;

  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.accentTint,
    required this.highlight,
    required this.highlightTint,
    required this.danger,
    required this.dangerTint,
    required this.warning,
    required this.warningTint,
  });

  static const AppColors light = AppColors(
    background: AppTheme.creamBackground,
    surface: AppTheme.surfaceWhite,
    surfaceMuted: Color(0xFFF9FAF6),
    textPrimary: AppTheme.textPrimary,
    textSecondary: AppTheme.textSecondary,
    border: AppTheme.borderColor,
    accentTint: AppTheme.lightGreen,
    highlight: AppTheme.cornYellow,
    highlightTint: AppTheme.cornYellowLight,
    danger: AppTheme.dangerRed,
    dangerTint: AppTheme.dangerLight,
    warning: AppTheme.warningOrange,
    warningTint: AppTheme.warningLight,
  );

  static const AppColors dark = AppColors(
    background: AppTheme.darkBackground,
    surface: AppTheme.darkSurface,
    surfaceMuted: AppTheme.darkSurfaceHigh,
    textPrimary: AppTheme.darkTextPrimary,
    textSecondary: AppTheme.darkTextSecondary,
    border: AppTheme.darkBorder,
    accentTint: Color(0xFF214B3B),
    highlight: AppTheme.cornYellow,
    highlightTint: Color(0xFF4A3F17),
    danger: Color(0xFFFF8A7A),
    dangerTint: Color(0xFF5A1F18),
    warning: Color(0xFFFFB566),
    warningTint: Color(0xFF4F3215),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    Color? accentTint,
    Color? highlight,
    Color? highlightTint,
    Color? danger,
    Color? dangerTint,
    Color? warning,
    Color? warningTint,
  }) => AppColors(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    surfaceMuted: surfaceMuted ?? this.surfaceMuted,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    border: border ?? this.border,
    accentTint: accentTint ?? this.accentTint,
    highlight: highlight ?? this.highlight,
    highlightTint: highlightTint ?? this.highlightTint,
    danger: danger ?? this.danger,
    dangerTint: dangerTint ?? this.dangerTint,
    warning: warning ?? this.warning,
    warningTint: warningTint ?? this.warningTint,
  );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      accentTint: Color.lerp(accentTint, other.accentTint, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      highlightTint: Color.lerp(highlightTint, other.highlightTint, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerTint: Color.lerp(dangerTint, other.dangerTint, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningTint: Color.lerp(warningTint, other.warningTint, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get appColors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
