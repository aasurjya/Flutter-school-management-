import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../auth/providers/auth_provider.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _bg = Color(0xFFF2F4F6);         // near-white cool tint
const _strip = Color(0xFFE8EEF2);      // icy blue-gray (showcase strip)
const _neu = Color(0xFFECF0F3);        // neumorphic card bg
const _ink = Color(0xFF0D0D0D);        // near-black text
const _border = Color(0xFF1A1A1A);     // chip/border dark
const _muted = Color(0xFF7A8490);      // muted labels
const _neuLight = Colors.white;
const _neuDark = Color(0xFFCDD4DA);    // neumorphic dark shadow

// ─── Screen ───────────────────────────────────────────────────────────────────
class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final firstName = (user?.fullName ?? 'Student').split(' ').first.toUpperCase();

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Label('GOOD MORNING'),
                          const SizedBox(height: 4),
                          Text(
                            firstName,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showMenu(context, ref),
                      child: _NeuCircle(
                        size: 44,
                        child: Text(
                          user?.initials ?? 'S',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _ink,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Hero neumorphic card ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                child: _HeroCard(),
              ),
            ),

            // ── Subject chip row ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 0, 0),
                child: _ChipRow(),
              ),
            ),

            // ── Divider ──────────────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Divider(color: Color(0xFFD8DFE6), thickness: 1, height: 1),
              ),
            ),

            // ── Showcase strip ───────────────────────────────────────────────
            SliverToBoxAdapter(child: _ShowcaseStrip()),

            // ── Description ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'YOUR ACADEMIC SYSTEM. A REAL-TIME VIEW OF\n'
                      'PERFORMANCE, ATTENDANCE, AND PROGRESS.',
                      style: TextStyle(
                        fontSize: 11,
                        color: _muted,
                        letterSpacing: 0.8,
                        height: 1.6,
                      ),
                    ),
                    SizedBox(height: 8),
                    _Label('CLASS 10-A  •  ROLL NO 15'),
                  ],
                ),
              ),
            ),

            // ── Divider ──────────────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Divider(color: Color(0xFFD8DFE6), thickness: 1, height: 1),
              ),
            ),

            // ── Today's schedule ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label("TODAY'S SCHEDULE"),
                    const SizedBox(height: 20),
                    _ScheduleList(),
                  ],
                ),
              ),
            ),

            // ── Divider ──────────────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Divider(color: Color(0xFFD8DFE6), thickness: 1, height: 1),
              ),
            ),

            // ── Upcoming ─────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label('UPCOMING'),
                    const SizedBox(height: 20),
                    _UpcomingList(),
                  ],
                ),
              ),
            ),

            // ── Study tips entry ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: GestureDetector(
                onTap: () => context.push(AppRoutes.studyRecommendations),
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(24, 28, 24, 0),
                  child: _StudyTipsStrip(),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  void _showMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
              decoration: BoxDecoration(color: _neuDark, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            _MenuTile(label: 'PROFILE', onTap: () => Navigator.pop(context)),
            const SizedBox(height: 12),
            _MenuTile(label: 'SETTINGS', onTap: () => Navigator.pop(context)),
            const SizedBox(height: 12),
            _MenuTile(
              label: 'SIGN OUT',
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authNotifierProvider.notifier).signOut();
                if (context.mounted) context.go(AppRoutes.login);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hero neumorphic card ──────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _neu,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(color: _neuLight, offset: Offset(-8, -8), blurRadius: 20),
          BoxShadow(color: _neuDark, offset: Offset(8, 8), blurRadius: 20),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Inset number (the "09°" equivalent)
          Expanded(
            child: _InsetNumberBox(value: '94', unit: '%', label: 'ATTENDANCE'),
          ),
          const SizedBox(width: 16),
          // Right column — score + rank stacked
          Column(
            children: [
              _MiniInsetBox(value: '87%', label: 'AVG SCORE'),
              const SizedBox(height: 12),
              _MiniInsetBox(value: '#5', label: 'RANK'),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsetNumberBox extends StatelessWidget {
  final String value;
  final String unit;
  final String label;

  const _InsetNumberBox({
    required this.value,
    required this.unit,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: _neu,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          // Inset effect — reversed shadows
          BoxShadow(color: _neuDark, offset: Offset(4, 4), blurRadius: 10,
              spreadRadius: 1),
          BoxShadow(color: _neuLight, offset: Offset(-4, -4), blurRadius: 10,
              spreadRadius: 1),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Blurred hero number
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 0.8, sigmaY: 0.8),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                    height: 1,
                    letterSpacing: -3,
                  ),
                ),
                Positioned(
                  top: 6,
                  right: -2,
                  child: Text(
                    unit,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _Label(label),
        ],
      ),
    );
  }
}

class _MiniInsetBox extends StatelessWidget {
  final String value;
  final String label;

  const _MiniInsetBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: _neu,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: _neuDark, offset: Offset(3, 3), blurRadius: 8),
          BoxShadow(color: _neuLight, offset: Offset(-3, -3), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _ink,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          _Label(label, size: 8),
        ],
      ),
    );
  }
}

// ─── Subject chip row ──────────────────────────────────────────────────────────
class _ChipRow extends StatelessWidget {
  static const _subjects = [
    ('10-A', true),
    ('MATHEMATICS', false),
    ('PHYSICS', false),
    ('CHEMISTRY', false),
    ('ENGLISH', false),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _subjects.map((s) {
          final isCircle = s.$1.length <= 4 && !s.$1.contains(' ');
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: isCircle && s.$2
                ? _CircleBadge(label: s.$1)
                : _PillChip(label: s.$1),
          );
        }).toList(),
      ),
    );
  }
}

class _CircleBadge extends StatelessWidget {
  final String label;

  const _CircleBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _border, width: 1.5),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _ink,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _PillChip extends StatelessWidget {
  final String label;

  const _PillChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: _border, width: 1),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _ink,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─── Showcase strip ────────────────────────────────────────────────────────────
class _ShowcaseStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: _strip,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD0DBE5), width: 1),
      ),
      child: Stack(
        children: [
          // Dashed corner brackets (design-tool aesthetic)
          const Positioned(top: 10, left: 10, child: _DashedCorner()),
          const Positioned(
            top: 10, right: 10,
            child: _DashedCorner(flipH: true),
          ),
          // Metrics
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            child: Row(
              children: const [
                Expanded(
                  child: _ShowcaseMetric(value: '94%', label: 'ATTENDANCE'),
                ),
                _VerticalDivider(),
                Expanded(
                  child: _ShowcaseMetric(value: '87%', label: 'AVG SCORE'),
                ),
                _VerticalDivider(),
                Expanded(
                  child: _ShowcaseMetric(value: '#5', label: 'CLASS RANK'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShowcaseMetric extends StatelessWidget {
  final String value;
  final String label;

  const _ShowcaseMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: _ink,
              letterSpacing: -1,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 6),
        _Label(label, size: 9),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 48,
      color: const Color(0xFFCDD4DA),
    );
  }
}

class _DashedCorner extends StatelessWidget {
  final bool flipH;

  const _DashedCorner({this.flipH = false});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scaleX: flipH ? -1 : 1,
      child: SizedBox(
        width: 14,
        height: 14,
        child: CustomPaint(painter: _CornerPainter()),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _muted
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Top-left corner bracket
    canvas.drawLine(Offset(0, size.height), Offset(0, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(size.width, 0), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Schedule list ─────────────────────────────────────────────────────────────
class _ScheduleList extends StatelessWidget {
  static const _classes = [
    ('08:30', 'MATHEMATICS', 'Mr. Kumar · Room 101', true),
    ('09:30', 'PHYSICS', 'Mrs. Sharma · Room 102', false),
    ('10:30', 'CHEMISTRY', 'Dr. Patel · Lab 1', false),
    ('11:30', 'ENGLISH', 'Ms. Wilson · Room 103', false),
    ('12:30', 'HISTORY', 'Mr. Singh · Room 104', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _classes.asMap().entries.map((e) {
        final i = e.key;
        final c = e.value;
        return Column(
          children: [
            _ScheduleRow(
              time: c.$1,
              subject: c.$2,
              detail: c.$3,
              isCurrent: c.$4,
            ),
            if (i < _classes.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(color: Color(0xFFDDE3E9), height: 1, thickness: 1),
              ),
          ],
        );
      }).toList(),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  final String time;
  final String subject;
  final String detail;
  final bool isCurrent;

  const _ScheduleRow({
    required this.time,
    required this.subject,
    required this.detail,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Time
        SizedBox(
          width: 52,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                time,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isCurrent ? _ink : _muted,
                  letterSpacing: 0.2,
                ),
              ),
              if (isCurrent)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: _ink, width: 1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'NOW',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Line connector
        Container(
          width: 1,
          height: 36,
          color: isCurrent ? _ink : const Color(0xFFDDE3E9),
          margin: const EdgeInsets.symmetric(horizontal: 16),
        ),
        // Subject + detail
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subject,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                  color: _ink,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: const TextStyle(
                  fontSize: 11,
                  color: _muted,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Upcoming list ─────────────────────────────────────────────────────────────
class _UpcomingList extends StatelessWidget {
  static const _items = [
    ('PHYSICS ASSIGNMENT DUE', 'Chapter 5 — Wave Optics', 'TOMORROW'),
    ('CHEMISTRY QUIZ', 'Organic Chemistry', 'IN 3 DAYS'),
    ('PARENT-TEACHER MEETING', 'Annual Review', 'NEXT WEEK'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _items.asMap().entries.map((e) {
        final i = e.key;
        final item = e.value;
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$1,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.$2,
                        style: const TextStyle(
                          fontSize: 11,
                          color: _muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFCDD4DA), width: 1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.$3,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: _muted,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            if (i < _items.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(color: Color(0xFFDDE3E9), height: 1, thickness: 1),
              ),
          ],
        );
      }).toList(),
    );
  }
}

// ─── Study tips strip ──────────────────────────────────────────────────────────
class _StudyTipsStrip extends StatelessWidget {
  const _StudyTipsStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: _strip,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD0DBE5), width: 1),
      ),
      child: Row(
        children: const [
          Icon(Icons.auto_awesome_outlined, size: 16, color: _muted),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Label('AI STUDY TIPS'),
                SizedBox(height: 2),
                Text(
                  'Personalized recommendations just for you',
                  style: TextStyle(fontSize: 11, color: _muted),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 11, color: _muted),
        ],
      ),
    );
  }
}

// ─── Shared widgets ────────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  final double size;

  const _Label(this.text, {this.size = 10});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: _muted,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _NeuCircle extends StatelessWidget {
  final double size;
  final Widget child;

  const _NeuCircle({required this.size, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: _neu,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: _neuLight, offset: Offset(-3, -3), blurRadius: 8),
          BoxShadow(color: _neuDark, offset: Offset(3, 3), blurRadius: 8),
        ],
      ),
      child: Center(child: child),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _MenuTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: _neu,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: _neuLight, offset: Offset(-3, -3), blurRadius: 8),
            BoxShadow(color: _neuDark, offset: Offset(3, 3), blurRadius: 8),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _ink,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
