import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webroulette/bloc/storage_bloc.dart';
import 'package:webroulette/data/markdown_items.dart';
import 'package:webroulette/l10n/app_localizations.dart';
import 'package:webroulette/screens/roulette_screen.dart';

import 'test_helpers.dart';

Widget _app(StorageCubit cubit) => BlocProvider<StorageCubit>.value(
  value: cubit,
  child: const MaterialApp(
    localizationsDelegates: [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      AppLocalizations.delegate,
    ],
    supportedLocales: [Locale('en')],
    locale: Locale('en'),
    home: RouletteScreen(),
  ),
);

Future<void> _openAndType(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.byKey(const ValueKey('paste_from_llm_button')));
  await tester.tap(find.byKey(const ValueKey('paste_from_llm_button')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const ValueKey('markdown_import_field')), text);
  await tester.pump();
}

void main() {
  setUpAll(() async {
    await initHydratedStorage();
  });

  testWidgets('buttons disabled until something parses, preview shows count and items', (tester) async {
    final cubit = StorageCubit();
    await tester.pumpWidget(_app(cubit));
    await _openAndType(tester, 'just prose');

    expect(find.text('No list items found'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const ValueKey('markdown_import_replace'))).onPressed, isNull);

    await tester.enterText(find.byKey(const ValueKey('markdown_import_field')), '## H\n- one\n2. two\n* three');
    await tester.pump();
    expect(find.text('3 items found'), findsOneWidget);
    expect(find.text('• one'), findsOneWidget);
    expect(find.text('• three'), findsOneWidget);
  });

  testWidgets('Replace overwrites existing items', (tester) async {
    final cubit = StorageCubit()..saveItems(['old']);
    await tester.pumpWidget(_app(cubit));
    await _openAndType(tester, '- a\n- b');
    await tester.tap(find.byKey(const ValueKey('markdown_import_replace')));
    await tester.pumpAndSettle();
    expect(cubit.state.items, ['a', 'b']);
  });

  testWidgets('Add to existing appends', (tester) async {
    final cubit = StorageCubit()..saveItems(['old']);
    await tester.pumpWidget(_app(cubit));
    await _openAndType(tester, '- a\n- b');
    await tester.tap(find.byKey(const ValueKey('markdown_import_add')));
    await tester.pumpAndSettle();
    expect(cubit.state.items, ['old', 'a', 'b']);
  });

  testWidgets('Cancel leaves items untouched', (tester) async {
    final cubit = StorageCubit()..saveItems(['old']);
    await tester.pumpWidget(_app(cubit));
    await _openAndType(tester, '- a');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(cubit.state.items, ['old']);
  });

  testWidgets('Copy for LLM puts markdown on the clipboard', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    final cubit = StorageCubit()..saveItems(['x', 'y']);
    await tester.pumpWidget(_app(cubit));
    await tester.ensureVisible(find.byKey(const ValueKey('copy_for_llm_button')));
    await tester.tap(find.byKey(const ValueKey('copy_for_llm_button')));
    await tester.pump();
    expect(copied, formatItemsAsMarkdown(['x', 'y']));
  });
}
