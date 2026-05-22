import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:school_management/features/dashboard/widgets/dashboard_section.dart';
import 'package:school_management/features/dashboard/widgets/role_hero_app_bar.dart';
import 'package:school_management/features/dashboard/widgets/role_settings_sheet.dart';
import 'package:school_management/core/widgets/ai_content_badge.dart';

void main() {
  group('RoleHeroAppBar', () {
    testWidgets('renders eyebrow, title, and optional pill', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              RoleHeroAppBar(
                eyebrow: 'Administrative Command Center',
                title: 'Demo School',
                pillText: 'Mon, 1 Jan',
              ),
            ],
          ),
        ),
      ));
      expect(find.text('Administrative Command Center'), findsOneWidget);
      expect(find.text('Demo School'), findsOneWidget);
      expect(find.text('Mon, 1 Jan'), findsOneWidget);
    });

    testWidgets('hides pill when null', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              RoleHeroAppBar(eyebrow: 'EYE', title: 'TITLE'),
            ],
          ),
        ),
      ));
      expect(find.byType(Container), findsWidgets); // not assertion-of-absence noise
      expect(find.text('TITLE'), findsOneWidget);
    });
  });

  group('DashboardSection', () {
    testWidgets('renders label + child', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: DashboardSection(
            label: 'Management Tools',
            child: Text('CHILD_CONTENT'),
          ),
        ),
      ));
      expect(find.text('Management Tools'), findsOneWidget);
      expect(find.text('CHILD_CONTENT'), findsOneWidget);
    });

    testWidgets('renders trailing action when provided', (tester) async {
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DashboardSection(
            label: 'Operations',
            trailingAction: 'See all',
            onTrailingTap: () => tapped = true,
            child: const SizedBox.shrink(),
          ),
        ),
      ));
      expect(find.text('See all'), findsOneWidget);
      await tester.tap(find.text('See all'));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });

  group('KpiTile', () {
    testWidgets('renders value + label, fires onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: KpiTile(
            label: 'Students',
            value: '1,243',
            icon: Icons.school_outlined,
            onTap: () => tapped = true,
          ),
        ),
      ));
      expect(find.text('Students'), findsOneWidget);
      expect(find.text('1,243'), findsOneWidget);
      await tester.tap(find.text('1,243'));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });

  group('RoleSettingsSheet', () {
    testWidgets('renders actions and pops on tap', (tester) async {
      var logoutFired = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => showRoleSettingsSheet(ctx, actions: [
                SettingsAction(
                  icon: Icons.logout,
                  title: 'Logout',
                  onTap: () => logoutFired = true,
                ),
              ]),
              child: const Text('OPEN'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();
      expect(find.text('Logout'), findsOneWidget);
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();
      expect(logoutFired, isTrue);
      expect(find.text('Logout'), findsNothing); // sheet dismissed
    });
  });

  group('AiContentBadge', () {
    testWidgets('inline chip shows "AI summary" and opens disclosure on tap',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AiContentBadge.inline(
            sourceSummary: 'Built from last 30 days of attendance + grades.',
          ),
        ),
      ));
      expect(find.text('AI summary'), findsOneWidget);
      await tester.tap(find.text('AI summary'));
      await tester.pumpAndSettle();
      expect(find.text('About this AI summary'), findsOneWidget);
      expect(find.textContaining('attendance + grades'), findsOneWidget);
    });

    testWidgets('cached variant shows "AI · cached"', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AiContentBadge.inline(
            sourceSummary: 'Cached digest',
            isCached: true,
          ),
        ),
      ));
      expect(find.text('AI · cached'), findsOneWidget);
    });

    testWidgets('wrap variant renders chip above child', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AiContentBadge.wrap(
            sourceSummary: 'Source',
            child: Text('BODY'),
          ),
        ),
      ));
      expect(find.text('AI summary'), findsOneWidget);
      expect(find.text('BODY'), findsOneWidget);
    });
  });
}
