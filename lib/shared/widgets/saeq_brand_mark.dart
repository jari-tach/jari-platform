import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/saeq_semantic_colors.dart';

/// فزعة brand mark — route chevron on primary tile.
///
/// Spec: Figma `Brand / فزعة Lockup` (file MNJldEpkMxVjIavCPaPBFh, node 188:2).
class SaeqBrandMark extends StatelessWidget {
  const SaeqBrandMark({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).brandWordmark,
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: SaeqSemanticColors.of(context).primary,
            borderRadius: BorderRadius.circular(size * 0.22),
          ),
          child: CustomPaint(
            painter: const _RouteChevronPainter(color: Color(0xFFFFFFFF)),
          ),
        ),
      ),
    );
  }
}

/// Compact brand for [AppBar] titles (mark + wordmark in a row).
class SaeqBrandAppBarTitle extends StatelessWidget {
  const SaeqBrandAppBarTitle({super.key, this.markSize = 28});

  final double markSize;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = SaeqSemanticColors.of(context);
    return Row(
      key: const Key('saeqBrandAppBarTitle'),
      mainAxisSize: MainAxisSize.min,
      children: [
        SaeqBrandMark(size: markSize),
        const SizedBox(width: AppTheme.spacingSM),
        Flexible(
          child: Text(
            l10n.brandWordmark,
            style: GoogleFonts.cairo(
              color: colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Mark + wordmark **فزعة** / Faz'a using display typeface (Cairo).
class SaeqBrandLockup extends StatelessWidget {
  const SaeqBrandLockup({
    super.key,
    this.markSize = 72,
    this.showTagline = false,
    this.showLatinSubline = false,
    this.compact = false,
    this.alignment = CrossAxisAlignment.center,
  });

  final double markSize;
  final bool showTagline;
  final bool showLatinSubline;
  final bool compact;
  final CrossAxisAlignment alignment;

  TextStyle _wordmarkStyle(Color color, {required bool compact}) {
    // Figma lockup uses Cairo Bold for the Arabic display wordmark.
    return GoogleFonts.cairo(
      color: color,
      fontSize: compact ? 28 : 40,
      fontWeight: FontWeight.w700,
      height: 1.1,
      letterSpacing: -0.5,
    );
  }

  TextStyle _latinStyle(Color color) {
    return GoogleFonts.inter(
      color: color,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 2,
      height: 1.2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = SaeqSemanticColors.of(context);
    final centered = alignment == CrossAxisAlignment.center;

    return Column(
      key: const Key('saeqBrandLockup'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: [
        SaeqBrandMark(size: markSize),
        SizedBox(height: compact ? AppTheme.spacingSM : AppTheme.spacing12),
        Text(
          key: const Key('saeqBrandWordmark'),
          l10n.brandWordmark,
          style: _wordmarkStyle(colors.textPrimary, compact: compact),
          textAlign: centered ? TextAlign.center : TextAlign.start,
          textDirection: l10n.isArabic ? TextDirection.rtl : TextDirection.ltr,
        ),
        const SizedBox(height: AppTheme.spacingXS),
        Container(
          key: const Key('saeqBrandRouteUnderline'),
          width: compact ? 40 : 56,
          height: 3,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        if (showLatinSubline && l10n.isArabic) ...[
          const SizedBox(height: AppTheme.spacingSM),
          Text(
            key: const Key('saeqBrandLatin'),
            "Faz'a",
            style: _latinStyle(colors.primary),
            textAlign: centered ? TextAlign.center : TextAlign.start,
          ),
        ],
        if (showTagline) ...[
          const SizedBox(height: AppTheme.spacing12),
          Text(
            l10n.appTagline,
            style: AppTextStyles.bodyMedium.copyWith(
              color: colors.textSecondary,
              fontSize: AppTheme.fontSizeSM,
            ),
            textAlign: centered ? TextAlign.center : TextAlign.start,
          ),
        ],
      ],
    );
  }
}

class _RouteChevronPainter extends CustomPainter {
  const _RouteChevronPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final inset = size.width * 0.28;
    final midY = size.height * 0.52;
    final path = Path()
      ..moveTo(inset, size.height * 0.68)
      ..lineTo(size.width * 0.42, midY)
      ..lineTo(size.width - inset, size.height * 0.32);
    canvas.drawPath(path, stroke);

    final accent = Path()
      ..moveTo(inset, size.height * 0.78)
      ..lineTo(size.width * 0.48, size.height * 0.62);
    canvas.drawPath(accent, stroke);
  }

  @override
  bool shouldRepaint(covariant _RouteChevronPainter oldDelegate) =>
      oldDelegate.color != color;
}
