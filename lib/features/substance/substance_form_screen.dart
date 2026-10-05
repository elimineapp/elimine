import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/motion/motion.dart';
import '../../app/providers.dart';
import '../../app/sheet_page.dart';
import '../../core/appearance.dart';
import '../../core/db/queries.dart';
import '../../core/l10n/format.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/substance_badge.dart';
import 'delete_substance.dart';

/// Creates a substance, or edits one when [substanceId] is set.
class SubstanceFormScreen extends ConsumerStatefulWidget {
  const SubstanceFormScreen({super.key, this.substanceId});

  final String? substanceId;

  @override
  ConsumerState<SubstanceFormScreen> createState() =>
      _SubstanceFormScreenState();
}

class _SubstanceFormScreenState extends ConsumerState<SubstanceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _unit = TextEditingController();
  final _newDose = TextEditingController();
  late String _color = _unusedColor();
  String _icon = substanceIcons.keys.first;
  List<double> _doses = [];
  String? _originalUnit;

  /// The saved name, for the delete dialog even while the field is edited.
  String _originalName = '';
  bool _loading = false;

  /// The new substance's id once it is saved.
  String? _savedId;

  /// Set while leaving after archiving or deleting, to ignore taps.
  bool _leaving = false;

  bool get _editing => widget.substanceId != null;

  @override
  void initState() {
    super.initState();
    if (!_editing) return;
    // The substance screen below has it already: the header shows its
    // color and icon from the first frame, while the rest loads.
    final cached = ref.read(substanceProvider(widget.substanceId!)).value;
    if (cached != null) {
      _color = cached.color;
      _icon = cached.icon;
    }
    _load(widget.substanceId!);
  }

  /// First palette color no active substance uses, so new ones stay apart
  /// on charts.
  String _unusedColor() {
    final used = {
      for (final item in ref.read(substancesProvider).value ?? const [])
        item.substance.color,
    };
    return substanceColors.keys.firstWhere(
      (k) => !used.contains(k),
      orElse: () => substanceColors.keys.first,
    );
  }

  Future<void> _load(String id) async {
    setState(() => _loading = true);
    final db = ref.read(databaseProvider);
    final substance = await db.watchSubstance(id).first;
    final doses = await db.dosesFor(id);
    if (!mounted || substance == null) return;
    setState(() {
      _name.text = substance.name;
      _unit.text = substance.unit;
      _originalUnit = substance.unit;
      _originalName = substance.name;
      _color = substance.color;
      _icon = substance.icon;
      _doses = [for (final d in doses) d.amount];
      _loading = false;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _unit.dispose();
    _newDose.dispose();
    super.dispose();
  }

  void _addDose() {
    final value = parseAmount(_newDose.text);
    if (value == null) return;
    setState(() {
      if (!_doses.contains(value)) _doses = [..._doses, value]..sort();
      _newDose.clear();
    });
  }

  Future<bool> _confirm(String title, String body, String action) async {
    final l = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    _addDose();

    final id = widget.substanceId;
    final service = ref.read(substanceServiceProvider);
    final draft = (
      name: _name.text,
      unit: _unit.text,
      color: _color,
      icon: _icon,
      doses: _doses,
    );

    if (id == null) {
      final newId = await service.create(draft);
      if (!mounted) return;
      // The badge now carries the new substance's tag, so it flies into
      // its sheet.
      setState(() => _savedId = newId);
      context.pushReplacement(
        '/substance/$newId',
        extra: SheetEntrance.fromFullScreen,
      );
      return;
    }

    final unitChanged = _unit.text.trim() != _originalUnit;
    if (unitChanged &&
        await ref.read(databaseProvider).hasIntakes(id) &&
        !await _confirm(l.unitChangedTitle, l.unitChangedBody, l.change)) {
      return;
    }
    await service.update(id, draft);
    if (mounted) context.pop();
  }

  Future<void> _archive() async {
    final l = AppLocalizations.of(context);
    if (!await _confirm(l.archive, l.archiveConfirm(_name.text), l.archive)) {
      return;
    }
    await ref.read(substanceServiceProvider).archive(widget.substanceId!);
    if (mounted) await _leave();
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final name = _originalName;
    final deleted = await confirmAndDeleteSubstance(
      context,
      ref,
      id: widget.substanceId!,
      name: name,
      report: false,
    );
    if (!deleted || !mounted) return;
    await _leave();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l.substanceDeleted(name))));
  }

  /// Leaves with the substance gone: shrinks back into its sheet first, then
  /// closes the sheet onto Home, as one motion.
  Future<void> _leave() async {
    final router = GoRouter.of(context);
    // Opened without a sheet below, as from a link: straight to Home.
    final animation = context.canPop()
        ? ModalRoute.of(context)?.animation
        : null;
    setState(() => _leaving = true);
    if (animation != null && !animation.isDismissed) {
      context.pop();
      final dismissed = Completer<void>();
      void onStatus(AnimationStatus status) {
        if (status.isDismissed && !dismissed.isCompleted) dismissed.complete();
      }

      animation.addStatusListener(onStatus);
      await dismissed.future;
      animation.removeStatusListener(onStatus);
    }
    router.go('/');
    // Until the sheet has slid away.
    await Future<void>.delayed(Motion.short);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = context.substanceColorOf(_color);

    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(title, style: theme.textTheme.titleSmall),
    );

    return AbsorbPointer(
      absorbing: _leaving,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              SubstanceIconHero(
                tag: switch (widget.substanceId ?? _savedId) {
                  final id? => substanceIconTag(id),
                  null => newSubstanceIconTag,
                },
                child: SubstanceBadge(
                  key: const Key('formBadge'),
                  color: _color,
                  icon: _icon,
                  filled: true,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  _editing ? l.editSubstanceTitle : l.createSubstanceTitle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              key: const Key('saveButton'),
              onPressed: _loading ? null : _save,
              child: Text(l.save),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    TextFormField(
                      key: const Key('nameField'),
                      controller: _name,
                      autofocus: !_editing,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(labelText: l.fieldName),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? l.requiredField
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('unitField'),
                      controller: _unit,
                      // Optional: some substances are tracked without doses.
                      decoration: InputDecoration(labelText: l.fieldUnit),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final unit in l.unitSuggestionList)
                          ActionChip(
                            label: Text(unit),
                            onPressed: () => setState(() => _unit.text = unit),
                          ),
                      ],
                    ),
                    section(l.fieldDoses),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final dose in _doses)
                          InputChip(
                            label: Text(l.dose(dose, _unit.text.trim())),
                            onDeleted: () => setState(
                              () => _doses = [..._doses]..remove(dose),
                            ),
                          ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('doseField'),
                            controller: _newDose,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              hintText: l.addDoseHint,
                              suffixText: _unit.text.trim(),
                            ),
                            onSubmitted: (_) => _addDose(),
                          ),
                        ),
                        IconButton(
                          key: const Key('addDoseButton'),
                          icon: const Icon(Icons.add),
                          onPressed: _addDose,
                        ),
                      ],
                    ),
                    section(l.fieldColor),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final key in substanceColors.keys)
                          InkWell(
                            key: Key('color_$key'),
                            customBorder: const CircleBorder(),
                            onTap: () => setState(() => _color = key),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: context.substanceColorOf(key),
                                shape: BoxShape.circle,
                                border: key == _color
                                    ? Border.all(
                                        color: theme.colorScheme.onSurface,
                                        width: 3,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                      ],
                    ),
                    section(l.fieldIcon),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (final MapEntry(:key, :value)
                            in substanceIcons.entries)
                          IconButton(
                            isSelected: key == _icon,
                            style: IconButton.styleFrom(
                              foregroundColor: color,
                              backgroundColor: key == _icon
                                  ? color.withValues(alpha: 0.16)
                                  : null,
                            ),
                            icon: Icon(value),
                            onPressed: () => setState(() => _icon = key),
                          ),
                      ],
                    ),
                    if (_editing) ...[
                      const SizedBox(height: 40),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.archive_outlined),
                        label: Text(l.archive),
                        onPressed: _archive,
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        key: const Key('deleteButton'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: Text(l.delete),
                        onPressed: _delete,
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
