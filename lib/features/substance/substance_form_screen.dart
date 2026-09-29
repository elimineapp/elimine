import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/appearance.dart';
import '../../core/db/queries.dart';
import '../../core/l10n/format.dart';
import '../../l10n/app_localizations.dart';

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
  bool _loading = false;

  bool get _editing => widget.substanceId != null;

  @override
  void initState() {
    super.initState();
    if (_editing) _load(widget.substanceId!);
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
      if (mounted) context.pushReplacement('/substance/$newId');
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
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = substanceColor(_color);

    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(title, style: theme.textTheme.titleSmall),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? l.editSubstanceTitle : l.createSubstanceTitle),
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
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? l.requiredField : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('unitField'),
                    controller: _unit,
                    decoration: InputDecoration(labelText: l.fieldUnit),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? l.requiredField : null,
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
                      for (final MapEntry(:key, :value)
                          in substanceColors.entries)
                        InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => setState(() => _color = key),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: value,
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
                  ],
                ],
              ),
            ),
    );
  }
}
