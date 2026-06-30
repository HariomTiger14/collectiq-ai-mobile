import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/features/home/domain/entities/collector_dashboard_analytics.dart';
import 'package:collectiq_ai/features/home/domain/entities/portfolio_snapshot.dart';
import 'package:flutter/material.dart';

class PortfolioValueTrendCard extends StatelessWidget {
  const PortfolioValueTrendCard({
    required this.snapshots,
    this.title = 'Value History',
    this.subtitle = 'Latest portfolio value snapshots.',
    super.key,
  });

  final List<PortfolioSnapshot> snapshots;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final ordered = [...snapshots]
      ..sort((a, b) => a.periodStart.compareTo(b.periodStart));
    final values = ordered
        .map((snapshot) => snapshot.totalPortfolioValue)
        .toList(growable: false);
    final latest = ordered.isEmpty ? 0.0 : ordered.last.totalPortfolioValue;
    final first = ordered.isEmpty ? 0.0 : ordered.first.totalPortfolioValue;
    final change = latest - first;

    return _VisualCard(
      semanticLabel:
          '$title. Current value ${_formatAud(latest)}. Change ${_formatSignedAud(change)}.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VisualHeader(
            title: title,
            subtitle: ordered.isEmpty
                ? 'History appears after portfolio snapshots are recorded.'
                : subtitle,
            icon: Icons.show_chart_outlined,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (ordered.isEmpty)
            const _EmptyVisualState(
              label: 'No value history yet',
              message: 'Save collectibles to start building trend snapshots.',
            )
          else ...[
            Text(
              _formatAud(latest),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: _valueGold,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Change ${_formatSignedAud(change)} across ${ordered.length} snapshots',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 88,
              width: double.infinity,
              child: CustomPaint(
                painter: _SparklinePainter(
                  values: values,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _SnapshotLabels(
              firstLabel: _formatSnapshotDate(ordered.first.periodStart),
              lastLabel: _formatSnapshotDate(ordered.last.periodStart),
            ),
          ],
        ],
      ),
    );
  }
}

class CollectionScoreTrendCard extends StatelessWidget {
  const CollectionScoreTrendCard({required this.snapshots, super.key});

  final List<PortfolioSnapshot> snapshots;

  @override
  Widget build(BuildContext context) {
    final ordered = [...snapshots]
      ..sort((a, b) => a.periodStart.compareTo(b.periodStart));
    final latest = ordered.isEmpty ? 0 : ordered.last.collectionScore;
    final values = ordered
        .map((snapshot) => snapshot.collectionScore.toDouble())
        .toList(growable: false);

    return _VisualCard(
      semanticLabel:
          'Collection Score Trend. Latest score $latest out of 1000.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _VisualHeader(
            title: 'Collection Score Trend',
            subtitle: 'Score movement from portfolio snapshots.',
            icon: Icons.health_and_safety_outlined,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (ordered.isEmpty)
            const _EmptyVisualState(
              label: 'No score history yet',
              message: 'History starts once portfolio snapshots are available.',
            )
          else ...[
            Row(
              children: [
                Text(
                  '$latest',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '/ 1000',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 72,
              width: double.infinity,
              child: CustomPaint(
                painter: _SparklinePainter(
                  values: values,
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CategoryAllocationVisual extends StatelessWidget {
  const CategoryAllocationVisual({required this.distribution, super.key});

  final Map<CollectorCategory, int> distribution;

  @override
  Widget build(BuildContext context) {
    final total = distribution.values.fold<int>(0, (sum, value) => sum + value);
    final entries = CollectorCategory.values
        .map((category) => MapEntry(category, distribution[category] ?? 0))
        .where((entry) => entry.value > 0)
        .toList(growable: false);

    return _VisualCard(
      semanticLabel: 'Category Allocation. $total collectibles tracked.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _VisualHeader(
            title: 'Category Allocation',
            subtitle: 'How your collection is distributed.',
            icon: Icons.donut_large_outlined,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (entries.isEmpty)
            const _EmptyVisualState(
              label: 'No category data yet',
              message: 'Scan collectibles to build allocation insights.',
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Row(
                children: [
                  for (final entry in entries)
                    Expanded(
                      flex: entry.value,
                      child: Container(
                        height: 16,
                        color: _categoryColor(context, entry.key),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final entry in entries) ...[
              _CategoryAllocationRow(
                category: entry.key,
                count: entry.value,
                total: total,
              ),
              if (entry != entries.last) const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ],
      ),
    );
  }
}

class PortfolioMoverVisualCard extends StatelessWidget {
  const PortfolioMoverVisualCard({
    required this.title,
    required this.mover,
    required this.positive,
    super.key,
  });

  final String title;
  final PortfolioValueMover? mover;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive ? AppColors.success : _warningAmber;
    final icon = positive
        ? Icons.trending_up_outlined
        : Icons.trending_down_outlined;
    final titleText = mover?.title ?? 'No movement yet';
    final change = mover == null
        ? 'AUD 0'
        : _formatSignedAud(mover!.absoluteChange);
    final percent = mover == null
        ? '0%'
        : '${(mover!.percentageChange * 100).toStringAsFixed(0)}%';

    return _VisualCard(
      semanticLabel: '$title. $titleText. Change $change, $percent.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VisualHeader(title: title, subtitle: titleText, icon: icon),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      change,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '$percent change / ${mover?.category ?? 'No category'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryAllocationRow extends StatelessWidget {
  const _CategoryAllocationRow({
    required this.category,
    required this.count,
    required this.total,
  });

  final CollectorCategory category;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0.0 : count / total;
    final color = _categoryColor(context, category);

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            category.label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          '$count / ${(percent * 100).toStringAsFixed(0)}%',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SnapshotLabels extends StatelessWidget {
  const _SnapshotLabels({required this.firstLabel, required this.lastLabel});

  final String firstLabel;
  final String lastLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          firstLabel,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          lastLabel,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _VisualHeader extends StatelessWidget {
  const _VisualHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyVisualState extends StatelessWidget {
  const _EmptyVisualState({required this.label, required this.message});

  final String label;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisualCard extends StatelessWidget {
  const _VisualCard({required this.child, required this.semanticLabel});

  final Widget child;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          boxShadow: AppElevation.level1,
        ),
        child: child,
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }

    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final span = maxValue - minValue;
    final points = <Offset>[];
    for (var index = 0; index < values.length; index++) {
      final x = values.length == 1
          ? size.width / 2
          : size.width * index / (values.length - 1);
      final normalized = span == 0 ? 0.5 : (values[index] - minValue) / span;
      final y = size.height - (size.height * normalized);
      points.add(Offset(x, y.clamp(4, size.height - 4)));
    }

    final fillPath = Path()
      ..moveTo(points.first.dx, size.height)
      ..lineTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      fillPath.lineTo(point.dx, point.dy);
    }
    fillPath
      ..lineTo(points.last.dx, size.height)
      ..close();

    canvas.drawPath(fillPath, Paint()..color = color.withValues(alpha: 0.1));

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    for (final point in points) {
      canvas.drawCircle(point, 4, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}

Color _categoryColor(BuildContext context, CollectorCategory category) {
  return switch (category) {
    CollectorCategory.cards => Theme.of(context).colorScheme.primary,
    CollectorCategory.coins => _valueGold,
    CollectorCategory.comics => AppColors.accent,
    CollectorCategory.memorabilia => AppColors.success,
    CollectorCategory.other => Theme.of(context).colorScheme.tertiary,
  };
}

String _formatAud(double value) {
  final whole = value.toStringAsFixed(0);
  final withCommas = whole.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  return 'AUD $withCommas';
}

String _formatSignedAud(double value) {
  if (value == 0) {
    return 'AUD 0';
  }
  final prefix = value > 0 ? '+' : '-';
  return '$prefix${_formatAud(value.abs())}';
}

String _formatSnapshotDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

const _valueGold = Color(0xFFD97706);
const _warningAmber = Color(0xFFF59E0B);
