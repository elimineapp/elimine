import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Elimine'**
  String get appTitle;

  /// No description provided for @newSubstanceTile.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newSubstanceTile;

  /// No description provided for @recentTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recentTitle;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @emptyIntakes.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged yet'**
  String get emptyIntakes;

  /// No description provided for @neverLogged.
  ///
  /// In en, this message translates to:
  /// **'Not logged yet'**
  String get neverLogged;

  /// No description provided for @relativeToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get relativeToday;

  /// No description provided for @relativeYesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get relativeYesterday;

  /// No description provided for @relativeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} day ago} other{{count} days ago}}'**
  String relativeDaysAgo(int count);

  /// No description provided for @relativeMonthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} month ago} other{{count} months ago}}'**
  String relativeMonthsAgo(int count);

  /// No description provided for @relativeYearsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} year ago} other{{count} years ago}}'**
  String relativeYearsAgo(int count);

  /// No description provided for @dayToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dayToday;

  /// No description provided for @dayYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dayYesterday;

  /// No description provided for @dayBeforeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Day before'**
  String get dayBeforeYesterday;

  /// No description provided for @timeNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get timeNow;

  /// No description provided for @timeNowAt.
  ///
  /// In en, this message translates to:
  /// **'Now (today, {time})'**
  String timeNowAt(String time);

  /// No description provided for @doseTitle.
  ///
  /// In en, this message translates to:
  /// **'Dose'**
  String get doseTitle;

  /// No description provided for @customDose.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customDose;

  /// No description provided for @noDose.
  ///
  /// In en, this message translates to:
  /// **'No dose'**
  String get noDose;

  /// No description provided for @customDoseTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom dose'**
  String get customDoseTitle;

  /// No description provided for @logButton.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get logButton;

  /// No description provided for @intakeLogged.
  ///
  /// In en, this message translates to:
  /// **'Logged {dose}'**
  String intakeLogged(String dose);

  /// No description provided for @intakeLoggedNoDose.
  ///
  /// In en, this message translates to:
  /// **'Logged'**
  String get intakeLoggedNoDose;

  /// No description provided for @intakeDeleted.
  ///
  /// In en, this message translates to:
  /// **'Entry deleted'**
  String get intakeDeleted;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @createSubstanceTitle.
  ///
  /// In en, this message translates to:
  /// **'New substance'**
  String get createSubstanceTitle;

  /// No description provided for @editSubstanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit substance'**
  String get editSubstanceTitle;

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldName;

  /// No description provided for @fieldUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get fieldUnit;

  /// Comma-separated unit suggestions shown under the unit field.
  ///
  /// In en, this message translates to:
  /// **'mg,g,ml,pcs,tab'**
  String get unitSuggestions;

  /// No description provided for @fieldColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get fieldColor;

  /// No description provided for @fieldIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get fieldIcon;

  /// No description provided for @fieldDoses.
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get fieldDoses;

  /// No description provided for @addDoseHint.
  ///
  /// In en, this message translates to:
  /// **'Add dose'**
  String get addDoseHint;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @archiveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Archive {name}? It disappears from the home screen; its history is kept.'**
  String archiveConfirm(String name);

  /// No description provided for @unitChangedTitle.
  ///
  /// In en, this message translates to:
  /// **'Change unit?'**
  String get unitChangedTitle;

  /// No description provided for @unitChangedBody.
  ///
  /// In en, this message translates to:
  /// **'History is not recalculated: existing entries keep their numbers under the new unit.'**
  String get unitChangedBody;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get navAnalytics;

  /// No description provided for @analyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analyticsTitle;

  /// No description provided for @rangeTwoWeeks.
  ///
  /// In en, this message translates to:
  /// **'2 wk'**
  String get rangeTwoWeeks;

  /// No description provided for @rangeMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get rangeMonth;

  /// No description provided for @rangeYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get rangeYear;

  /// No description provided for @rangeAllYears.
  ///
  /// In en, this message translates to:
  /// **'All years'**
  String get rangeAllYears;

  /// No description provided for @intakesChartTitle.
  ///
  /// In en, this message translates to:
  /// **'Intakes'**
  String get intakesChartTitle;

  /// No description provided for @doseChartPerDay.
  ///
  /// In en, this message translates to:
  /// **'Per day, {unit}'**
  String doseChartPerDay(String unit);

  /// No description provided for @doseChartDailyAverage.
  ///
  /// In en, this message translates to:
  /// **'Daily average, {unit}'**
  String doseChartDailyAverage(String unit);

  /// No description provided for @doseChartPerDayNoUnit.
  ///
  /// In en, this message translates to:
  /// **'Per day'**
  String get doseChartPerDayNoUnit;

  /// No description provided for @doseChartDailyAverageNoUnit.
  ///
  /// In en, this message translates to:
  /// **'Daily average'**
  String get doseChartDailyAverageNoUnit;

  /// No description provided for @tooltipWithoutDose.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} without dose}}'**
  String tooltipWithoutDose(int count);

  /// No description provided for @metricTotal.
  ///
  /// In en, this message translates to:
  /// **'Total intakes'**
  String get metricTotal;

  /// No description provided for @metricActiveDays.
  ///
  /// In en, this message translates to:
  /// **'Days with intakes'**
  String get metricActiveDays;

  /// No description provided for @metricActiveDaysValue.
  ///
  /// In en, this message translates to:
  /// **'{active} of {total}'**
  String metricActiveDaysValue(int active, int total);

  /// No description provided for @metricMaxDay.
  ///
  /// In en, this message translates to:
  /// **'Most in a day'**
  String get metricMaxDay;

  /// No description provided for @metricMaxDayValue.
  ///
  /// In en, this message translates to:
  /// **'{count} ({date})'**
  String metricMaxDayValue(int count, String date);

  /// No description provided for @metricBusiestWeekday.
  ///
  /// In en, this message translates to:
  /// **'Busiest weekday'**
  String get metricBusiestWeekday;

  /// No description provided for @metricBusiestMonth.
  ///
  /// In en, this message translates to:
  /// **'Busiest month'**
  String get metricBusiestMonth;

  /// No description provided for @metricShare.
  ///
  /// In en, this message translates to:
  /// **'Share of intakes'**
  String get metricShare;

  /// No description provided for @noDataInRange.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged in this period'**
  String get noDataInRange;

  /// No description provided for @archivedSuffix.
  ///
  /// In en, this message translates to:
  /// **'{name} (archived)'**
  String archivedSuffix(String name);

  /// No description provided for @tooltipIntakes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} intake} other{{count} intakes}}'**
  String tooltipIntakes(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
