import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Color variant for [SemanticPill].
///
/// green=GH·적합·사용가능 / blue=IH·BM / orange=TP·주의·Pro·백업 /
/// err=차단오류·사용중지 / neutral=일반.
enum SemanticPillVariant { green, blue, orange, err, neutral }

/// Small stadium-shaped status pill: soft background + colored 600 label.
///
/// Used for BM status pills, validation badges, and other 색+텍스트 병행 states.
class SemanticPill extends StatelessWidget {
  final String label;
  final SemanticPillVariant variant;

  const SemanticPill({
    super.key,
    required this.label,
    this.variant = SemanticPillVariant.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final (Color fg, Color bg) = switch (variant) {
      SemanticPillVariant.green => (colors.green, colors.greenSoft),
      SemanticPillVariant.blue => (colors.blue, colors.blueSoft),
      SemanticPillVariant.orange => (colors.orange, colors.orangeSoft),
      SemanticPillVariant.err => (colors.err, colors.errSoft),
      SemanticPillVariant.neutral => (
        colors.subtext,
        colors.surfaceContainerHighest,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: ShapeDecoration(color: bg, shape: const StadiumBorder()),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Pretendard',
          color: fg,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
    );
  }
}
