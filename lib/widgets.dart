import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'state.dart';

/// Reusable rounded card used across all screens.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(18)});
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: dark ? Colors.black45 : Colors.black.withOpacity(.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Small animated bar chart (used for the last 7 days).
class MiniBars extends StatelessWidget {
  final List<double> values;
  const MiniBars({super.key, required this.values});
  @override
  Widget build(BuildContext context) {
    final mx = values.fold(0.0, math.max);
    return SizedBox(
      height: 56,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (final v in values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: mx == 0 ? .08 : (v / mx).clamp(.08, 1.0)),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutBack,
                builder: (_, h, __) => FractionallySizedBox(
                  heightFactor: h.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(v == mx && mx > 0 ? .95 : .4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

class StatTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const StatTile({super.key, required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18))),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ]),
      );
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      );
}

class ExpenseTile extends StatelessWidget {
  final Expense e;
  final VoidCallback onTap;
  const ExpenseTile({super.key, required this.e, required this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: Hero(
          tag: 'icon-${e.id}',
          child: CircleAvatar(
            backgroundColor: e.cat.color.withOpacity(.18),
            child: Icon(e.cat.icon, color: e.cat.color),
          ),
        ),
        title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${e.cat.label} • ${fmtDate(e.date)}'),
        trailing: Text('-${money(e.amount)}',
            style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.redAccent)),
      );
}

class CategoryCard extends StatelessWidget {
  final Cat cat;
  final double amount, share;
  const CategoryCard({super.key, required this.cat, required this.amount, this.share = 0});
  @override
  Widget build(BuildContext context) => AppCard(
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: cat.color.withOpacity(.18), borderRadius: BorderRadius.circular(12)),
            child: Icon(cat.icon, color: cat.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('${cat.label} • ${(share * 100).round()}%', style: Theme.of(context).textTheme.bodySmall),
              FittedBox(child: Text(money(amount), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
            ]),
          ),
        ]),
      );
}

/// Animated donut chart drawn with CustomPainter.
class DonutChart extends StatelessWidget {
  final Map<Cat, double> data;
  const DonutChart({super.key, required this.data});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeOutCubic,
        builder: (_, t, __) => CustomPaint(painter: _DonutPainter(data, t), size: const Size.square(200)),
      );
}

class _DonutPainter extends CustomPainter {
  final Map<Cat, double> data;
  final double t;
  _DonutPainter(this.data, this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final total = data.values.fold(0.0, (a, b) => a + b);
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: size.width / 2 - 14);
    final p = Paint()..style = PaintingStyle.stroke..strokeWidth = 26;
    if (total == 0) {
      canvas.drawArc(rect, 0, math.pi * 2, false, p..color = Colors.grey.withOpacity(.3));
      return;
    }
    var start = -math.pi / 2;
    data.forEach((c, v) {
      final sweep = v / total * math.pi * 2 * t;
      canvas.drawArc(rect, start, math.max(sweep - .03, 0), false, p..color = c.color);
      start += sweep;
    });
  }
  @override
  bool shouldRepaint(_DonutPainter o) => o.t != t || o.data != data;
}