import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'screens/activities_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/auth_screens.dart';
import 'screens/home_screen.dart';
import 'screens/plots_screen.dart';
import 'screens/profile_screen.dart';
import 'services/app_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const TaniJagungApp());
}

class TaniJagungApp extends StatelessWidget {
  const TaniJagungApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaniJagung',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // Dark theme sudah disiapkan; mode gelap diaktifkan bertahap setelah
      // seluruh layar memakai warna semantik (AppColors) agar kontras aman.
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const AppRootFlow(),
    );
  }
}

class AppRootFlow extends StatefulWidget {
  const AppRootFlow({super.key});

  @override
  State<AppRootFlow> createState() => _AppRootFlowState();
}

class _AppRootFlowState extends State<AppRootFlow>
    with SingleTickerProviderStateMixin {
  bool _showSplash = true;
  bool _revealing = false;
  Future<void>? _bootFuture;
  AnimationController? _revealCtrl;

  AnimationController get _ensureRevealCtrl {
    return _revealCtrl ??=
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 560),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            setState(() {
              _showSplash = false;
              _revealing = false;
            });
          }
        });
  }

  @override
  void initState() {
    super.initState();
    // Data dimuat di latar SELAMA animasi splash berjalan
    _bootFuture = AppDataService().initialize();
    _ensureRevealCtrl;
  }

  @override
  void dispose() {
    _revealCtrl?.dispose();
    super.dispose();
  }

  void _handleSplashCompleted() {
    if (!mounted || !_showSplash || _revealing) return;
    if (AppMotion.reduceMotion(context)) {
      setState(() => _showSplash = false);
      return;
    }
    setState(() => _revealing = true);
    _ensureRevealCtrl.forward(from: 0);
  }

  Widget _buildMainFlow() {
    return ListenableBuilder(
      listenable: AppDataService(),
      builder: (context, _) {
        final service = AppDataService();
        if (!service.isLoggedIn) {
          return const AuthScreen();
        }
        return const MainNavigationShell();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_showSplash) return _buildMainFlow();

    final ctrl = _ensureRevealCtrl;
    final splash = SplashScreen(
      onCompleted: _handleSplashCompleted,
      bootFuture: _bootFuture,
    );

    // Transisi keluar: splash memudar & berlubang melingkar yang melebar
    // (circular reveal) memperlihatkan halaman berikutnya di belakangnya.
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_revealing) _buildMainFlow(),
        IgnorePointer(
          ignoring: _revealing,
          child: AnimatedBuilder(
            animation: ctrl,
            builder: (context, child) {
              if (!_revealing) return child!;
              final t = Curves.easeInOutCubic.transform(ctrl.value);
              return Opacity(
                opacity: (1 - t * 0.85).clamp(0.0, 1.0),
                child: ClipPath(
                  clipper: CircularRevealHoleClipper(t),
                  child: Transform.scale(scale: 1 + t * 0.08, child: child),
                ),
              );
            },
            child: splash,
          ),
        ),
      ],
    );
  }
}

/// Bottom Navigation 5 Menu Utama dengan Animasi Transisi Halus (250-300 ms):
/// 1. Beranda
/// 2. Lahan
/// 3. Aktivitas
/// 4. Analisis
/// 5. Profil
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late final AnimationController _pageAnimCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  static const List<_NavTabItem> _tabs = [
    _NavTabItem(
      label: 'Beranda',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    _NavTabItem(
      label: 'Lahan',
      icon: Icons.eco_outlined,
      activeIcon: Icons.eco_rounded,
    ),
    _NavTabItem(
      label: 'Aktivitas',
      icon: Icons.access_time_outlined,
      activeIcon: Icons.access_time_filled_rounded,
    ),
    _NavTabItem(
      label: 'Analisis',
      icon: Icons.pie_chart_outline_rounded,
      activeIcon: Icons.pie_chart_rounded,
    ),
    _NavTabItem(
      label: 'Profil',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: 1.0,
    );
    _fadeAnim = CurvedAnimation(
      parent: _pageAnimCtrl,
      curve: Curves.easeOutCubic,
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.015), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _pageAnimCtrl, curve: Curves.easeOutCubic),
        );
  }

  void _selectTab(int index) {
    if (index == _selectedIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
    if (AppMotion.reduceMotion(context)) {
      _pageAnimCtrl.value = 1.0;
    } else {
      _pageAnimCtrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _pageAnimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onNavigateTab: _selectTab),
      const PlotsScreen(),
      const ActivitiesScreen(),
      const AnalysisScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: IndexedStack(index: _selectedIndex, children: pages),
        ),
      ),
      bottomNavigationBar: _AnimatedBottomNavBar(
        tabs: _tabs,
        selectedIndex: _selectedIndex,
        onTabSelected: _selectTab,
      ),
    );
  }
}

class _NavTabItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavTabItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

class _AnimatedBottomNavBar extends StatelessWidget {
  final List<_NavTabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const _AnimatedBottomNavBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final dur = AppMotion.of(context, AppMotion.medium);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: AppShadows.navBar,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / tabs.length;
              final pillWidth = (tabWidth * 0.68).clamp(42.0, 68.0);
              final pillLeft =
                  (selectedIndex * tabWidth) + (tabWidth - pillWidth) / 2;

              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Pill Indikator Hijau Muda yang Bergeser Mulus Antar Tab
                  AnimatedPositioned(
                    duration: dur,
                    curve: AppMotion.standard,
                    left: pillLeft,
                    top: 9,
                    child: Container(
                      width: pillWidth,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colors.accentTint,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  // Baris 5 Tab Navigasi (Ikon aktif melenting 1.0 -> 1.15 -> 1.0 + label fade)
                  Row(
                    children: List.generate(tabs.length, (idx) {
                      final item = tabs[idx];
                      final isSelected = idx == selectedIndex;

                      return Expanded(
                        child: InkWell(
                          onTap: () => onTabSelected(idx),
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 30,
                                  child: Center(
                                    child: TweenAnimationBuilder<double>(
                                      key: ValueKey<String>(
                                        'nav_${idx}_$isSelected',
                                      ),
                                      tween: Tween<double>(
                                        begin: 0.0,
                                        end: isSelected ? 1.0 : 0.0,
                                      ),
                                      duration: dur,
                                      curve: AppMotion.standard,
                                      builder: (context, t, child) {
                                        // Melenting 1.0 -> 1.15 -> 1.0 saat dipilih
                                        final bounce = isSelected
                                            ? 1.0 + 0.15 * math.sin(t * math.pi)
                                            : 1.0;
                                        return Transform.translate(
                                          offset: Offset(
                                            0,
                                            isSelected ? -1.5 * t : 0.0,
                                          ),
                                          child: Transform.scale(
                                            scale: bounce,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: AnimatedSwitcher(
                                        duration: AppMotion.of(
                                          context,
                                          AppMotion.short,
                                        ),
                                        child: Icon(
                                          isSelected
                                              ? item.activeIcon
                                              : item.icon,
                                          key: ValueKey<bool>(isSelected),
                                          size: 23,
                                          color: isSelected
                                              ? AppTheme.darkGreen
                                              : colors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                AnimatedOpacity(
                                  duration: AppMotion.of(
                                    context,
                                    AppMotion.short,
                                  ),
                                  opacity: isSelected ? 1.0 : 0.78,
                                  child: AnimatedDefaultTextStyle(
                                    duration: AppMotion.of(
                                      context,
                                      AppMotion.short,
                                    ),
                                    curve: Curves.easeOut,
                                    style: TextStyle(
                                      fontFamily: AppTheme.bodyFont,
                                      fontSize: 11.5,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? AppTheme.darkGreen
                                          : colors.textSecondary,
                                    ),
                                    child: Text(
                                      item.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
