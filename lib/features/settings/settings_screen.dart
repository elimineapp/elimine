import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';
import '../analytics/labels.dart';
import '../backup/backup_format.dart';
import '../backup/backup_service.dart';

/// Each interface language by its own name, so it reads the same whatever
/// language the interface is in.
const _languageNames = {'en': 'English', 'ru': 'Русский'};

/// App settings: the language, the theme, the first day of the week, the
/// backup (export to a file and import from one) and the installed version.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.clock = DateTime.now});

  final DateTime Function() clock;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;

  /// Shows progress while [work] runs, but not while dialogs wait for the
  /// user.
  Future<T> _run<T>(Future<T> Function() work) async {
    setState(() => _busy = true);
    try {
      return await work();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final json = await _run(ref.read(backupServiceProvider).export);
    final date = DateFormat('yyyy-MM-dd').format(widget.clock());
    final saved = await ref
        .read(backupFilesProvider)
        .save('elimine-$date.json', json);
    if (saved) messenger.showSnackBar(SnackBar(content: Text(l.exportDone)));
  }

  Future<void> _import() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final service = ref.read(backupServiceProvider);
    final text = await ref.read(backupFilesProvider).open();
    if (text == null || !mounted) return;

    final ImportPlan plan;
    try {
      plan = await _run(
        () => service.plan(decodeBackup(text, now: widget.clock())),
      );
    } on BackupVersionException {
      return _showError(l.importNewerVersion);
    } on BackupFormatException catch (e) {
      return _showError('$e');
    }
    if (!mounted || !await _confirm(plan)) return;

    await _run(() => service.apply(plan));
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          l.importDone(
            l.substancesCount(plan.newSubstances),
            l.intakesCount(plan.newIntakes),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirm(ImportPlan plan) async {
    final l = AppLocalizations.of(context);
    final present = plan.presentSubstances + plan.presentIntakes > 0
        ? l.importPresent(
            l.substancesCount(plan.presentSubstances),
            l.intakesCount(plan.presentIntakes),
          )
        : null;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.importPreviewTitle),
        content: Text(
          plan.addsNothing
              ? l.importNothingNew
              : [
                  l.importWillAdd(
                    l.substancesCount(plan.newSubstances),
                    l.intakesCount(plan.newIntakes),
                  ),
                  ?present,
                ].join('\n\n'),
        ),
        actions: plan.addsNothing
            ? [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l.ok),
                ),
              ]
            : [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l.cancel),
                ),
                TextButton(
                  key: const Key('confirmImport'),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l.importAction),
                ),
              ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _showError(String message) {
    final l = AppLocalizations.of(context);
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.importErrorTitle),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.ok),
          ),
        ],
      ),
    );
  }

  /// Offers [options] with their [labels] and saves the one the user picks,
  /// unless it is [current] or the dialog is dismissed. Options are picked
  /// by position, since null can be one of them.
  Future<void> _choose<T>({
    required String title,
    required String key,
    required T current,
    required List<T> options,
    required String Function(T) labels,
    required Future<void> Function(T) save,
  }) async {
    final chosen = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(title),
        children: [
          RadioGroup<int>(
            groupValue: options.indexOf(current),
            onChanged: (i) => Navigator.pop(context, i),
            child: Column(
              children: [
                for (final (i, option) in options.indexed)
                  RadioListTile<int>(
                    key: Key('$key-$option'),
                    value: i,
                    title: Text(labels(option)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (chosen != null && options[chosen] != current) {
      await save(options[chosen]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = ref.read(settingsServiceProvider);
    final initial = ref.watch(initialPreferencesProvider);
    final localeValue = ref.watch(localeProvider);
    final locale = localeValue.hasValue ? localeValue.value : initial.locale;
    final themeMode = ref.watch(themeModeProvider).value ?? initial.themeMode;
    final weekStart = ref.watch(weekStartProvider).value ?? DateTime.monday;
    String languageLabel(Locale? locale) => locale == null
        ? l.languageSystem
        : _languageNames[locale.languageCode]!;
    String themeLabel(ThemeMode mode) => switch (mode) {
      ThemeMode.system => l.themeSystem,
      ThemeMode.light => l.themeLight,
      ThemeMode.dark => l.themeDark,
    };
    Widget section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(l.settingsTitle),
        bottom: _busy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: ListView(
        children: [
          section(l.generalSection),
          ListTile(
            key: const Key('language'),
            leading: const Icon(Icons.language),
            title: Text(l.language),
            subtitle: Text(languageLabel(locale)),
            onTap: () => _choose<Locale?>(
              title: l.language,
              key: 'language',
              current: locale,
              options: [null, ...AppLocalizations.supportedLocales],
              labels: languageLabel,
              save: settings.setLocale,
            ),
          ),
          ListTile(
            key: const Key('theme'),
            leading: const Icon(Icons.brightness_6_outlined),
            title: Text(l.theme),
            subtitle: Text(themeLabel(themeMode)),
            onTap: () => _choose(
              title: l.theme,
              key: 'theme',
              current: themeMode,
              options: [ThemeMode.system, ThemeMode.light, ThemeMode.dark],
              labels: themeLabel,
              save: settings.setThemeMode,
            ),
          ),
          ListTile(
            key: const Key('weekStart'),
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text(l.weekStart),
            subtitle: Text(l.weekdayTitle(weekStart)),
            onTap: () => _choose(
              title: l.weekStart,
              key: 'weekStart',
              current: weekStart,
              options: [DateTime.monday, DateTime.sunday],
              labels: l.weekdayTitle,
              save: settings.setWeekStart,
            ),
          ),
          section(l.backupSection),
          ListTile(
            key: const Key('export'),
            enabled: !_busy,
            leading: const Icon(Icons.upload_file_outlined),
            title: Text(l.exportTitle),
            subtitle: Text(l.exportSubtitle),
            onTap: _export,
          ),
          ListTile(
            key: const Key('import'),
            enabled: !_busy,
            leading: const Icon(Icons.download_outlined),
            title: Text(l.importTitle),
            subtitle: Text(l.importSubtitle),
            onTap: _import,
          ),
          const Divider(),
          ListTile(
            key: const Key('version'),
            leading: const Icon(Icons.info_outline),
            title: Text(l.version),
            subtitle: Text(ref.watch(appVersionProvider).value ?? ''),
          ),
        ],
      ),
    );
  }
}
