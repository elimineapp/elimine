// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Elimine';

  @override
  String get newSubstanceTile => 'Новое';

  @override
  String get recentTitle => 'Последние';

  @override
  String get historyTitle => 'История';

  @override
  String get emptyIntakes => 'Записей пока нет';

  @override
  String get neverLogged => 'Ещё не было';

  @override
  String get relativeToday => 'сегодня';

  @override
  String get relativeYesterday => 'вчера';

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня назад',
      many: '$count дней назад',
      few: '$count дня назад',
      one: '$count день назад',
    );
    return '$_temp0';
  }

  @override
  String relativeMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count мес. назад',
    );
    return '$_temp0';
  }

  @override
  String relativeYearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count года назад',
      many: '$count лет назад',
      few: '$count года назад',
      one: '$count год назад',
    );
    return '$_temp0';
  }

  @override
  String get dayToday => 'Сегодня';

  @override
  String get dayYesterday => 'Вчера';

  @override
  String get dayBeforeYesterday => 'Позавчера';

  @override
  String get timeNow => 'Сейчас';

  @override
  String timeNowAt(String time) {
    return 'Сейчас (сегодня, $time)';
  }

  @override
  String get doseTitle => 'Доза';

  @override
  String get customDose => 'Своя';

  @override
  String get noDose => 'Без дозы';

  @override
  String get customDoseTitle => 'Своя доза';

  @override
  String get logButton => 'Зафиксировать';

  @override
  String intakeLogged(String dose) {
    return 'Записано: $dose';
  }

  @override
  String get intakeLoggedNoDose => 'Записано';

  @override
  String get intakeDeleted => 'Запись удалена';

  @override
  String get undo => 'Отменить';

  @override
  String get cancel => 'Отмена';

  @override
  String get ok => 'ОК';

  @override
  String get createSubstanceTitle => 'Новое вещество';

  @override
  String get editSubstanceTitle => 'Редактирование';

  @override
  String get fieldName => 'Название';

  @override
  String get fieldUnit => 'Единица';

  @override
  String get unitSuggestions => 'мг,г,мл,шт,таб';

  @override
  String get fieldColor => 'Цвет';

  @override
  String get fieldIcon => 'Иконка';

  @override
  String get fieldDoses => 'Дозировка';

  @override
  String get addDoseHint => 'Добавить дозу';

  @override
  String get requiredField => 'Обязательное поле';

  @override
  String get save => 'Сохранить';

  @override
  String get archive => 'В архив';

  @override
  String archiveConfirm(String name) {
    return 'Отправить «$name» в архив? Вещество пропадёт с главной, история сохранится.';
  }

  @override
  String get unitChangedTitle => 'Сменить единицу?';

  @override
  String get unitChangedBody =>
      'История не пересчитывается: у старых записей останутся те же числа с новой единицей.';

  @override
  String get change => 'Сменить';

  @override
  String get navHome => 'Главная';

  @override
  String get navAnalytics => 'Аналитика';

  @override
  String get analyticsTitle => 'Аналитика';

  @override
  String get rangeTwoWeeks => '2 нед';

  @override
  String get rangeMonth => 'Месяц';

  @override
  String get rangeYear => 'Год';

  @override
  String get rangeAllYears => 'Все годы';

  @override
  String get intakesChartTitle => 'Приёмов';

  @override
  String doseChartPerDay(String unit) {
    return 'За день, $unit';
  }

  @override
  String doseChartDailyAverage(String unit) {
    return 'В среднем за день, $unit';
  }

  @override
  String get doseChartPerDayNoUnit => 'За день';

  @override
  String get doseChartDailyAverageNoUnit => 'В среднем за день';

  @override
  String tooltipWithoutDose(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count без дозы',
    );
    return '$_temp0';
  }

  @override
  String get metricTotal => 'Всего приёмов';

  @override
  String get metricActiveDays => 'Дней с приёмами';

  @override
  String metricActiveDaysValue(int active, int total) {
    return '$active из $total';
  }

  @override
  String get metricMaxDay => 'Максимум за сутки';

  @override
  String metricMaxDayValue(int count, String date) {
    return '$count ($date)';
  }

  @override
  String get metricBusiestWeekday => 'Самый активный день недели';

  @override
  String get metricBusiestMonth => 'Самый активный месяц';

  @override
  String get metricShare => 'Доля приёмов';

  @override
  String get noDataInRange => 'За этот период записей нет';

  @override
  String archivedSuffix(String name) {
    return '$name (в архиве)';
  }

  @override
  String tooltipIntakes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count приёма',
      many: '$count приёмов',
      few: '$count приёма',
      one: '$count приём',
    );
    return '$_temp0';
  }
}
