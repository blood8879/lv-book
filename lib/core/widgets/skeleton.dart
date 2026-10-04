import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A single pulsing placeholder block used to build loading skeletons.
class SkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(
    begin: 0.5,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: colors.cardSoft,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// Placeholder list of card rows (icon badge + two text lines).
class ListSkeleton extends StatelessWidget {
  final int count;

  const ListSkeleton({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      children: List.generate(count, (_) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.line),
          ),
          child: Row(
            children: [
              const SkeletonBox(width: 56, height: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(height: 14, width: 200),
                    SizedBox(height: 10),
                    SkeletonBox(height: 12, width: 140),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// Placeholder for a measurement table (header row + body rows).
class TableSkeleton extends StatelessWidget {
  final int rows;

  const TableSkeleton({super.key, this.rows = 6});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        children: List.generate(rows + 1, (i) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: List.generate(5, (col) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: SkeletonBox(height: i == 0 ? 12 : 14),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}
