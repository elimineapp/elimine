import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import 'providers.dart';
import 'router.dart';
import 'theme.dart';

class ElimineApp extends ConsumerStatefulWidget {
  const ElimineApp({super.key});

  @override
  ConsumerState<ElimineApp> createState() => _ElimineAppState();
}

class _ElimineAppState extends ConsumerState<ElimineApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // The home-screen widget writes through its own connection, which Drift
    // streams here cannot see. Re-query everything when the app comes back.
    _lifecycle = AppLifecycleListener(
      onResume: () {
        final db = ref.read(databaseProvider);
        db.markTablesUpdated(db.allTables);
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initial = ref.watch(initialPreferencesProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Until the streams emit, what main read before the first frame.
      locale: locale.hasValue ? locale.value : initial.locale,
      themeMode: themeMode.value ?? initial.themeMode,
      theme: ThemeData(colorScheme: inkLight),
      darkTheme: ThemeData(colorScheme: inkDark),
      routerConfig: router,
    );
  }
}
