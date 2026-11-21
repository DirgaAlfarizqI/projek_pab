import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';

/// =====================================================================
/// UI KIT TANIJAGUNG — Komponen dasar Design System & Mikro-Interaksi
/// Semua animasi bebas Timer (berbasis AnimationController + Interval)
/// dan otomatis dimatikan saat "Kurangi animasi" aktif di sistem.
/// =====================================================================

/// Kartu lembut dengan shadow berlapis, radius 20–28 px, tanpa border tipis.
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Gradient? gradient;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;

  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppRadius.lg,
    this.color,
    this.gradient,
    this.shadows,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(radius);

    Widget content = Container(
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? colors.surface) : null,
        gradient: gradient,
        borderRadius: borderRadius,
        boxShadow: isDark ? null : (shadows ?? AppShadows.soft),
        border: isDark && gradient == null
            ? Border.all(color: colors.border.withValues(alpha: 0.6))
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? Padding(padding: padding, child: child)
            : InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onTap!();
                },
                borderRadius: borderRadius,
                child: Padding(padding: padding, child: child),
              ),
      ),
    );

    if (onTap != null) {
      content = PressableScale(onTap: null, child: content);
    }
    return content;
  }
}

/// Efek tekan: skala 0.97 + haptic ringan. Membungkus widget apa pun.
/// Jika [onTap] diisi, widget ini juga menangani ketukan.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final bool haptic;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.97,
    this.haptic = true,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v && mounted) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduceMotion(context);
    return Listener(
      onPointerDown: (_) {
        _set(true);
        if (widget.haptic) HapticFeedback.selectionClick();
      },
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onTap == null
            ? null
            : () {
                if (widget.haptic) HapticFeedback.lightImpact();
                widget.onTap!();
              },
        child: AnimatedScale(
          scale: (_pressed && !reduce) ? widget.pressedScale : 1.0,
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Animasi masuk bertahap (fade + slide-up). Jeda = index × 60 ms.
/// Tidak memakai Timer: jeda diwujudkan lewat Interval dalam satu controller.
class StaggeredEntrance extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration itemDuration;
  final Duration step;
  final double offsetY;

  const StaggeredEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.itemDuration = const Duration(milliseconds: 360),
    this.step = AppMotion.staggerStep,
    this.offsetY = 20,
  });

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _t;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final delayMs = widget.step.inMilliseconds * widget.index.clamp(0, 12);
    final totalMs = delayMs + widget.itemDuration.inMilliseconds;
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs),
    );
    _t = CurvedAnimation(
      parent: _ctrl,
      curve: Interval(delayMs / totalMs, 1.0, curve: AppMotion.standard),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduceMotion(context)) {
      _ctrl.value = 1.0;
    } else {
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _t.value) * widget.offsetY),
          child: child,
        ),
      ),
    );
  }
}

/// Angka yang menghitung naik (count-up) dari 0 (atau nilai sebelumnya) ke nilai akhir.
class AnimatedCountUp extends StatefulWidget {
  final double value;
  final String Function(double) formatter;
  final TextStyle? style;
  final Duration duration;

  const AnimatedCountUp({
    super.key,
    required this.value,
    required this.formatter,
    this.style,
    this.duration = const Duration(milliseconds: 520),
  });

  @override
  State<AnimatedCountUp> createState() => _AnimatedCountUpState();
}

class _AnimatedCountUpState extends State<AnimatedCountUp> {
  double _from = 0;

  @override
  void didUpdateWidget(covariant AnimatedCountUp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _from = oldWidget.value;
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(widget.value),
      tween: Tween(begin: _from, end: widget.value),
      duration: AppMotion.of(context, widget.duration),
      curve: AppMotion.decelerate,
      builder: (context, v, _) => Text(
        widget.formatter(v),
        style: widget.style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Badge status yang berdenyut halus setiap kali [label] berubah.
class PulseBadge extends StatefulWidget {
  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  const PulseBadge({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  @override
  State<PulseBadge> createState() => _PulseBadgeState();
}

class _PulseBadgeState extends State<PulseBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  @override
  void didUpdateWidget(covariant PulseBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.label != widget.label && !AppMotion.reduceMotion(context)) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final pulse = math.sin(_ctrl.value * math.pi);
        return Transform.scale(scale: 1 + pulse * 0.14, child: child);
      },
      child: AnimatedContainer(
        duration: AppMotion.medium,
        curve: AppMotion.standard,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: widget.background,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: 14, color: widget.foreground),
              const SizedBox(width: 4),
            ],
            Text(
              widget.label,
              style: TextStyle(
                fontFamily: AppTheme.headingFont,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: widget.foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ikon lonceng yang bergoyang lembut saat [animate] bernilai true
/// (misalnya ketika pengingat aktif atau baru saja dibuat).
class AnimatedBellIcon extends StatefulWidget {
  final bool animate;
  final Color? color;
  final double size;

  const AnimatedBellIcon({
    super.key,
    this.animate = false,
    this.color,
    this.size = 22,
  });

  @override
  State<AnimatedBellIcon> createState() => _AnimatedBellIconState();
}

class _AnimatedBellIconState extends State<AnimatedBellIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 580),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _ring();
  }

  @override
  void didUpdateWidget(covariant AnimatedBellIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !oldWidget.animate) {
      _ring();
    }
  }

  void _ring() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || AppMotion.reduceMotion(context)) return;
      _ctrl.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final angle =
            math.sin(_ctrl.value * math.pi * 4) * (1 - _ctrl.value) * 0.32;
        return Transform.rotate(
          angle: angle,
          alignment: Alignment.topCenter,
          child: child,
        );
      },
      child: Icon(
        widget.animate
            ? Icons.notifications_active_rounded
            : Icons.notifications_none_rounded,
        color: widget.color ?? context.appColors.textPrimary,
        size: widget.size,
      ),
    );
  }
}

/// Pull-to-refresh bertema tunas/daun jagung yang tumbuh saat ditarik.
class SproutRefreshWrapper extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const SproutRefreshWrapper({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  @override
  State<SproutRefreshWrapper> createState() => _SproutRefreshWrapperState();
}

class _SproutRefreshWrapperState extends State<SproutRefreshWrapper>
    with SingleTickerProviderStateMixin {
  double _pullProgress = 0.0;
  bool _refreshing = false;
  late final AnimationController _leafCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification &&
        notification.metrics.pixels < 0) {
      final pull = (-notification.metrics.pixels / 80.0).clamp(0.0, 1.0);
      if ((pull - _pullProgress).abs() > 0.04 && mounted) {
        setState(() => _pullProgress = pull);
      }
    } else if (notification is ScrollEndNotification &&
        _pullProgress > 0 &&
        !_refreshing) {
      if (mounted) setState(() => _pullProgress = 0.0);
    }
    return false;
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();
    if (mounted) setState(() => _refreshing = true);
    if (!AppMotion.reduceMotion(context)) {
      _leafCtrl.forward(from: 0);
    }
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() {
          _refreshing = false;
          _pullProgress = 0.0;
        });
      }
    }
  }

  @override
  void dispose() {
    _leafCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _pullProgress > 0.05 || _refreshing;
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: Stack(
        children: [
          RefreshIndicator(
            color: AppTheme.primaryGreen,
            backgroundColor: AppTheme.surfaceWhite,
            strokeWidth: 2.5,
            onRefresh: _handleRefresh,
            child: widget.child,
          ),
          if (visible)
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _leafCtrl,
                    builder: (context, _) {
                      final grow = _refreshing
                          ? (0.85 + 0.15 * math.sin(_leafCtrl.value * math.pi))
                          : _pullProgress;
                      return Transform.scale(
                        scale: grow.clamp(0.4, 1.1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.darkGreen,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            boxShadow: AppShadows.soft,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.spa_rounded,
                                size: 16,
                                color: AppTheme.cornYellow,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Menyegarkan data ladang...',
                                style: TextStyle(
                                  fontFamily: AppTheme.headingFont,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Skeleton Shimmer halus untuk state memuat daftar (bukan spinner).
class SkeletonShimmer extends StatefulWidget {
  final double height;
  final double? width;
  final double radius;

  const SkeletonShimmer({
    super.key,
    this.height = 72,
    this.width,
    this.radius = AppRadius.lg,
  });

  @override
  State<SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!AppMotion.reduceMotion(context)) {
      _ctrl.repeat(count: 3);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        return Container(
          height: widget.height,
          width: widget.width ?? double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * t, -0.2),
              end: Alignment(1.0 + 2.0 * t, 0.2),
              colors: [
                colors.border.withValues(alpha: 0.45),
                colors.surface,
                colors.border.withValues(alpha: 0.45),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Pembungkus Swipe-to-Delete dengan latar merah lembut & ikon sampah animatif.
class SwipeToDeleteWrapper extends StatelessWidget {
  final Key dismissKey;
  final Widget child;
  final Future<void> Function() onDelete;
  final String? confirmTitle;
  final String? confirmMessage;

  const SwipeToDeleteWrapper({
    super.key,
    required this.dismissKey,
    required this.child,
    required this.onDelete,
    this.confirmTitle,
    this.confirmMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: dismissKey,
      direction: DismissDirection.endToStart,
      movementDuration: AppMotion.of(context, AppMotion.medium),
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        if (confirmTitle == null) return true;
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(confirmTitle!),
            content: Text(
              confirmMessage ?? 'Data yang dihapus tidak dapat dikembalikan.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.dangerRed,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Hapus'),
              ),
            ],
          ),
        );
        return ok == true;
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: AppTheme.dangerLight,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hapus',
              style: TextStyle(
                fontFamily: AppTheme.headingFont,
                fontWeight: FontWeight.w800,
                color: AppTheme.dangerRed,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete_outline_rounded, color: AppTheme.dangerRed),
          ],
        ),
      ),
      child: child,
    );
  }
}

/// Helper untuk menampilkan snackbar bergaya toast yang meluncur halus dengan ikon centang.
void showSuccessToast(BuildContext context, String message) {
  if (!context.mounted) return;
  HapticFeedback.lightImpact();
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: const Duration(milliseconds: 2200),
      content: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppTheme.cornYellow,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 16,
              color: AppTheme.darkGreen,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: AppTheme.bodyFont,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Empty state bertema jagung & ladang dengan ilustrasi melayang lembut.
class CornEmptyState extends StatefulWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;
  final double illustrationSize;

  const CornEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
    this.illustrationSize = 120,
  });

  @override
  State<CornEmptyState> createState() => _CornEmptyStateState();
}

class _CornEmptyStateState extends State<CornEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!AppMotion.reduceMotion(context)) {
      _ctrl.repeat(count: 4);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              final t = math.sin(_ctrl.value * 2 * math.pi);
              return Transform.translate(
                offset: Offset(0, t * 6),
                child: Transform.rotate(angle: t * 0.04, child: child),
              );
            },
            child: CornFieldIllustration(size: widget.illustrationSize),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.headingFont,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: colors.textSecondary,
            ),
          ),
          if (widget.actionLabel != null && widget.onAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: widget.onAction,
              icon: Icon(widget.actionIcon ?? Icons.add_rounded, size: 20),
              label: Text(widget.actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

/// Ilustrasi vektor tongkol jagung di atas gundukan tanah (CustomPainter).
class CornFieldIllustration extends StatelessWidget {
  final double size;
  const CornFieldIllustration({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CornFieldPainter()),
    );
  }
}

class _CornFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;

    canvas.drawCircle(
      Offset(w / 2, h / 2),
      w * 0.48,
      Paint()..color = AppTheme.lightGreen,
    );

    canvas.drawCircle(
      Offset(w * 0.76, h * 0.26),
      w * 0.08,
      Paint()..color = AppTheme.cornYellow.withValues(alpha: 0.85),
    );

    final soil = Path()
      ..moveTo(w * 0.12, h * 0.82)
      ..quadraticBezierTo(w * 0.5, h * 0.66, w * 0.88, h * 0.82)
      ..quadraticBezierTo(w * 0.5, h * 0.92, w * 0.12, h * 0.82)
      ..close();
    canvas.drawPath(soil, Paint()..color = const Color(0xFF8B6B45));

    canvas.drawLine(
      Offset(w * 0.5, h * 0.78),
      Offset(w * 0.5, h * 0.36),
      Paint()
        ..color = AppTheme.primaryGreen
        ..strokeWidth = w * 0.035
        ..strokeCap = StrokeCap.round,
    );

    final leafPaint = Paint()..color = AppTheme.primaryGreen;
    final leafL = Path()
      ..moveTo(w * 0.5, h * 0.66)
      ..quadraticBezierTo(w * 0.26, h * 0.6, w * 0.2, h * 0.42)
      ..quadraticBezierTo(w * 0.36, h * 0.52, w * 0.5, h * 0.6)
      ..close();
    final leafR = Path()
      ..moveTo(w * 0.5, h * 0.7)
      ..quadraticBezierTo(w * 0.74, h * 0.66, w * 0.82, h * 0.5)
      ..quadraticBezierTo(w * 0.64, h * 0.58, w * 0.5, h * 0.64)
      ..close();
    canvas.drawPath(leafL, leafPaint);
    canvas.drawPath(
      leafR,
      Paint()..color = AppTheme.darkGreen.withValues(alpha: 0.9),
    );

    final cobRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.4),
      width: w * 0.2,
      height: h * 0.34,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(cobRect, Radius.circular(w * 0.1)),
      Paint()..color = AppTheme.cornYellow,
    );

    final kernel = Paint()..color = AppTheme.cornGold.withValues(alpha: 0.55);
    for (int row = 0; row < 6; row++) {
      for (int col = 0; col < 3; col++) {
        final cx = cobRect.left + cobRect.width * (0.27 + col * 0.23);
        final cy = cobRect.top + cobRect.height * (0.14 + row * 0.145);
        canvas.drawCircle(Offset(cx, cy), w * 0.014, kernel);
      }
    }

    final husk = Path()
      ..moveTo(cobRect.left - w * 0.02, cobRect.bottom - h * 0.12)
      ..quadraticBezierTo(
        cobRect.center.dx - w * 0.02,
        cobRect.bottom + h * 0.02,
        cobRect.center.dx,
        cobRect.bottom + h * 0.04,
      )
      ..quadraticBezierTo(
        cobRect.center.dx + w * 0.02,
        cobRect.bottom + h * 0.02,
        cobRect.right + w * 0.02,
        cobRect.bottom - h * 0.12,
      )
      ..quadraticBezierTo(
        cobRect.center.dx,
        cobRect.bottom - h * 0.02,
        cobRect.left - w * 0.02,
        cobRect.bottom - h * 0.12,
      )
      ..close();
    canvas.drawPath(husk, Paint()..color = const Color(0xFF4FA36B));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Pembatas lebar konten agar layout tidak terlalu melebar di tablet.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = AppSpacing.maxContentWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Grid adaptif: 1 kolom di ponsel, 2 kolom di layar lebar (≥ 600 px).
class AdaptiveTwoColumn extends StatelessWidget {
  final List<Widget> children;
  final double spacing;

  const AdaptiveTwoColumn({
    super.key,
    required this.children,
    this.spacing = AppSpacing.md,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < AppSpacing.twoColumnBreakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: spacing),
                children[i],
              ],
            ],
          );
        }
        final itemWidth = (c.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

/// Judul bagian dengan aksi opsional di kanan.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.sectionTitle.copyWith(
              color: context.appColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}
