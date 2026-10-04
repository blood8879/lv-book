import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/app.dart';
import 'package:lv_book/features/benchmark/data/benchmark_providers.dart';
import 'package:lv_book/features/benchmark/domain/benchmark.dart';
import 'package:lv_book/features/fieldbook/data/fieldbook_providers.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/features/project/domain/project.dart';
import 'package:lv_book/features/project/presentation/project_detail_screen.dart';
import 'package:lv_book/l10n/l10n.dart';

void main() {
  Future<void> pumpShell(WidgetTester tester, Locale deviceLocale) async {
    tester.platformDispatcher.localesTestValue = [deviceLocale];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const ProviderScope(child: LvBookApp()));
    await tester.pump();
  }

  String appTitle(WidgetTester tester) =>
      tester.widget<Title>(find.byType(Title).first).title;

  String materialBackTooltip(WidgetTester tester) => MaterialLocalizations.of(
    tester.element(find.byType(Navigator).first),
  ).backButtonTooltip;

  testWidgets('app shell on an English device is English', (tester) async {
    await pumpShell(tester, const Locale('en', 'US'));
    expect(appTitle(tester), 'Lv Book');
    expect(materialBackTooltip(tester), 'Back');
  });

  testWidgets('app shell on a non-ko/en device falls back to English', (
    tester,
  ) async {
    await pumpShell(tester, const Locale('de', 'DE'));
    expect(appTitle(tester), 'Lv Book');
  });

  testWidgets('app shell on a Korean device is Korean', (tester) async {
    await pumpShell(tester, const Locale('ko', 'KR'));
    expect(appTitle(tester), '레벨 야장');
    expect(materialBackTooltip(tester), '뒤로');
  });

  Widget detail(Locale locale) => ProviderScope(
    overrides: [
      fieldBookListProvider.overrideWith(_NoFieldBooks.new),
      benchmarkListProvider.overrideWith(_NoBenchmarks.new),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ProjectDetailScreen(project: Project(id: 1, name: 'Site A')),
    ),
  );

  testWidgets('project detail tabs are localized (en)', (tester) async {
    await tester.pumpWidget(detail(const Locale('en')));
    await tester.pump();
    expect(find.widgetWithText(Tab, 'Level books'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Benchmarks'), findsOneWidget);
  });

  testWidgets('project detail tabs are localized (ko)', (tester) async {
    await tester.pumpWidget(detail(const Locale('ko')));
    await tester.pump();
    expect(find.widgetWithText(Tab, '야장'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'BM 관리'), findsOneWidget);
  });
}

class _NoFieldBooks extends FieldBookListNotifier {
  @override
  Future<List<FieldBook>> build(int projectId) async => const [];
}

class _NoBenchmarks extends BenchmarkListNotifier {
  @override
  Future<List<BenchMark>> build(int projectId) async => const [];
}
