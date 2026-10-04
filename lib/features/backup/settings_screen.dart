import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';
import '../analytics/labels.dart';
import 'backup_format.dart';
import 'backup_service.dart';

/// App settings: the first day of the week, the backup (export to a file and
/// import from one) and the installed version.
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

  Future<void> _chooseWeekStart(int current) async {
    final l = AppLocalizations.of(context);
    final chosen = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l.weekStart),
        children: [
          RadioGroup<int>(
            groupValue: current,
            onChanged: (day) => Navigator.pop(context, day),
            child: Column(
              children: [
                for (final day in [DateTime.monday, DateTime.sunday])
                  RadioListTile<int>(
                    key: Key('weekStart-$day'),
                    value: day,
                    title: Text(l.weekdayTitle(day)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (chosen != null && chosen != current) {
      await ref.read(settingsServiceProvider).setWeekStart(chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final weekStart = ref.watch(weekStartProvider).value ?? DateTime.monday;
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
            key: const Key('weekStart'),
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text(l.weekStart),
            subtitle: Text(l.weekdayTitle(weekStart)),
            onTap: () => _chooseWeekStart(weekStart),
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
