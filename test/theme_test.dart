import 'dart:math';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:elimine/app/app.dart';
import 'package:elimine/app/providers.dart';
import 'package:elimine/core/db/database.dart';
import 'package:elimine/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Whether [color] shows no visible hue: its RGB channels are within 16 of
/// each other, and green is not stronger than both others, as with the old
/// green seed.
bool _neutral(Color color) {
  final [r, g, b] = [
    color.r,
    color.g,
    color.b,
  ].map((c) => (c * 255).round()).toList();
  final spread = [r, g, b].reduce(max) - [r, g, b].reduce(min);
  return spread <= 16 && g <= max(r, b);
}

/// The WCAG contrast ratio between [a] and [b].
double _contrast(Color a, Color b) {
  final [dark, light] = [a.computeLuminance(), b.computeLuminance()]..sort();
  return (light + 0.05) / (dark + 0.05);
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
  });

  tearDown(() => db.close());

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      'the ${mode.name} theme has neutral surfaces and an ink accent',
      (tester) async {
        final settings = SettingsService(db);
        await tester.runAsync(() => settings.setThemeMode(mode));
        final initial = await tester.runAsync(settings.readPreferences);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              initialPreferencesProvider.overrideWithValue(initial!),
            ],
            child: const ElimineApp(),
          ),
        );
        // Unmount even when an expectation fails, so the database can close.
        addTearDown(() => tester.pumpWidget(const SizedBox()));
        final theme = Theme.of(tester.element(find.byType(NavigationBar)));
        final scheme = theme.colorScheme;

        expect(
          theme.brightness,
          mode == ThemeMode.dark ? Brightness.dark : Brightness.light,
        );
        expect(scheme.primaryContainer, const Color(0xFF1B2638));
        // Text on a selected segment or chip is as strong as in Material's
        // standard schemes (about 7:1), not the 4.5:1 minimum that made it
        // fainter than unselected labels.
        for (final (name, on, container) in [
          ('Primary', scheme.onPrimaryContainer, scheme.primaryContainer),
          ('Secondary', scheme.onSecondaryContainer, scheme.secondaryContainer),
          ('Tertiary', scheme.onTertiaryContainer, scheme.tertiaryContainer),
          ('Error', scheme.onErrorContainer, scheme.errorContainer),
        ]) {
          expect(
            _contrast(on, container),
            greaterThanOrEqualTo(6.5),
            reason: 'on${name}Container on ${name.toLowerCase()}Container',
          );
        }
        for (final (name, color) in [
          ('surface', scheme.surface),
          ('surfaceContainerLowest', scheme.surfaceContainerLowest),
          ('surfaceContainerLow', scheme.surfaceContainerLow),
          ('surfaceContainer', scheme.surfaceContainer),
          ('surfaceContainerHigh', scheme.surfaceContainerHigh),
          ('surfaceContainerHighest', scheme.surfaceContainerHighest),
          ('outlineVariant', scheme.outlineVariant),
        ]) {
          expect(_neutral(color), isTrue, reason: '$name is $color');
        }
      },
    );
  }
}
