// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Elimine';

  @override
  String get newSubstanceTile => 'New';

  @override
  String get recentTitle => 'Recent';

  @override
  String get historyTitle => 'History';

  @override
  String get emptyIntakes => 'Nothing logged yet';

  @override
  String get neverLogged => 'Not logged yet';

  @override
  String get relativeToday => 'today';

  @override
  String get relativeYesterday => 'yesterday';

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '$count day ago',
    );
    return '$_temp0';
  }

  @override
  String relativeMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months ago',
      one: '$count month ago',
    );
    return '$_temp0';
  }

  @override
  String relativeYearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years ago',
      one: '$count year ago',
    );
    return '$_temp0';
  }

  @override
  String get dayToday => 'Today';

  @override
  String get dayYesterday => 'Yesterday';

  @override
  String get dayBeforeYesterday => 'Day before';

  @override
  String get timeNow => 'Now';

  @override
  String timeNowAt(String time) {
    return 'Now (today, $time)';
  }

  @override
  String get doseTitle => 'Dose';

  @override
  String get customDose => 'Custom';

  @override
  String get customDoseTitle => 'Custom dose';

  @override
  String get logButton => 'Log';

  @override
  String intakeLogged(String dose) {
    return 'Logged $dose';
  }

  @override
  String get intakeDeleted => 'Entry deleted';

  @override
  String get undo => 'Undo';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get createSubstanceTitle => 'New substance';

  @override
  String get editSubstanceTitle => 'Edit substance';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldUnit => 'Unit';

  @override
  String get unitSuggestions => 'mg,g,ml,pcs,tab';

  @override
  String get fieldColor => 'Color';

  @override
  String get fieldIcon => 'Icon';

  @override
  String get fieldDoses => 'Dosage';

  @override
  String get addDoseHint => 'Add dose';

  @override
  String get requiredField => 'Required';

  @override
  String get save => 'Save';

  @override
  String get archive => 'Archive';

  @override
  String archiveConfirm(String name) {
    return 'Archive $name? It disappears from the home screen; its history is kept.';
  }

  @override
  String get unitChangedTitle => 'Change unit?';

  @override
  String get unitChangedBody =>
      'History is not recalculated: existing entries keep their numbers under the new unit.';

  @override
  String get change => 'Change';
}
