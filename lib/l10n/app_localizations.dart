import 'package:flutter/material.dart';

/// Simple bilingual strings with EN/RU toggle (no gen-l10n codegen required).
class AppLocalizations {
  AppLocalizations(this.localeCode);

  final String localeCode;

  bool get isRu => localeCode == 'ru';

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String get appTitle => isRu ? 'SimpleBudget' : 'SimpleBudget';
  String get tagline =>
      isRu ? 'Семейный месячный бюджет' : 'Family monthly budget';

  String get month => isRu ? 'Месяц' : 'Month';
  String get income => isRu ? 'Доход' : 'Income';
  String get overview => isRu ? 'Обзор' : 'Overview';
  String get settings => isRu ? 'Настройки' : 'Settings';

  String get budget => isRu ? 'Бюджет' : 'Budget';
  String get actual => isRu ? 'Фактически' : 'Actual';
  String get difference => isRu ? 'Разница' : 'Difference';
  String get remaining => isRu ? 'Остаток' : 'Remaining';
  String get overspent => isRu ? 'Перерасход' : 'Overspent';
  String get totalIncome => isRu ? 'Итого дохода' : 'Total income';
  String get groupTotal => isRu ? 'Сумма по группе' : 'Group total';

  String get planExceedsIncome =>
      isRu ? 'План больше дохода' : 'Plan exceeds income';
  String get addExpense => isRu ? 'Добавить трату' : 'Add expense';
  String get addIncomeSource =>
      isRu ? 'Добавить источник' : 'Add income source';
  String get addItem => isRu ? 'Добавить позицию' : 'Add item';
  String get addEntry => isRu ? 'Добавить сумму' : 'Add amount';
  String get save => isRu ? 'Сохранить' : 'Save';
  String get delete => isRu ? 'Удалить' : 'Delete';
  String get cancel => isRu ? 'Отмена' : 'Cancel';
  String get description => isRu ? 'Описание' : 'Description';
  String get category => isRu ? 'Категория' : 'Category';
  String get installment => isRu ? 'Рассрочка' : 'Installment';
  String get note => isRu ? 'Заметка' : 'Note';
  String get amount => isRu ? 'Сумма' : 'Amount';

  String get signIn => isRu ? 'Войти' : 'Sign in';
  String get signUp => isRu ? 'Регистрация' : 'Sign up';
  String get signOut => isRu ? 'Выйти' : 'Sign out';
  String get email => isRu ? 'Email' : 'Email';
  String get password => isRu ? 'Пароль' : 'Password';
  String get displayName => isRu ? 'Имя' : 'Display name';

  String get createHousehold =>
      isRu ? 'Создать семью' : 'Create household';
  String get joinHousehold => isRu ? 'Присоединиться' : 'Join household';
  String get householdName => isRu ? 'Название семьи' : 'Household name';
  String get inviteCode => isRu ? 'Код приглашения' : 'Invite code';
  String get invitePartner =>
      isRu ? 'Пригласить партнёра' : 'Invite partner';
  String get members => isRu ? 'Участники' : 'Members';
  String get language => isRu ? 'Язык' : 'Language';
  String get currency => isRu ? 'Валюта' : 'Currency';
  String get duplicateMonth =>
      isRu ? 'Создать следующий месяц из этого плана' : 'Create next month from this plan';
  String get manageCategories =>
      isRu ? 'Категории' : 'Manage categories';
  String get household => isRu ? 'Семья' : 'Household';
  String get synced => isRu ? 'Синхронизировано' : 'Synced';

  String get savingsHighlight =>
      isRu ? 'Отложено' : 'Set aside';
  String get underspent => isRu ? 'Остаток по позициям' : 'Underspent items';
  String get noData => isRu ? 'Пока нет данных' : 'No data yet';
  String get loading => isRu ? 'Загрузка…' : 'Loading…';
  String get errorGeneric =>
      isRu ? 'Что-то пошло не так' : 'Something went wrong';

  String monthTitle(DateTime date) {
    final monthsEn = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final monthsRu = [
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь',
    ];
    final name = isRu ? monthsRu[date.month - 1] : monthsEn[date.month - 1];
    return '$name ${date.year}';
  }
}

class AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'en' || locale.languageCode == 'ru';

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale.languageCode);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
