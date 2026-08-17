import 'package:flutter/material.dart';

/// Simple bilingual strings with EN/RU toggle (no gen-l10n codegen required).
class AppLocalizations {
  AppLocalizations(this.localeCode);

  final String localeCode;

  bool get isRu => localeCode == 'ru';

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String get appTitle => isRu ? 'SyncMonth' : 'SyncMonth';
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
  String get orContinueWith => isRu ? 'или' : 'or';
  String get continueWithGoogle =>
      isRu ? 'Продолжить с Google' : 'Continue with Google';
  String get continueWithApple =>
      isRu ? 'Продолжить с Apple' : 'Continue with Apple';

  String get createHousehold =>
      isRu ? 'Создать семью' : 'Create household';
  String get joinHousehold => isRu ? 'Присоединиться' : 'Join household';
  String get householdName => isRu ? 'Название семьи' : 'Household name';
  String get inviteCode => isRu ? 'Код приглашения' : 'Invite code';
  String get invitePartner =>
      isRu ? 'Пригласить партнёра' : 'Invite partner';
  String get shareInvite =>
      isRu ? 'Поделиться приглашением' : 'Share invite';
  String get inviteCopied =>
      isRu ? 'Код скопирован' : 'Invite code copied';
  String get exportCsv =>
      isRu ? 'Экспорт CSV' : 'Export CSV';
  String get exportDone =>
      isRu ? 'CSV готов к отправке' : 'CSV ready to share';
  String get typeSavings => isRu ? 'Накопления' : 'Savings';
  String get typeExpense => isRu ? 'Расход' : 'Expense';
  String get typeDebt => isRu ? 'Долг / карта' : 'Debt / card';
  String get emptyCategories =>
      isRu
          ? 'Категорий пока нет. Добавьте свою первую категорию.'
          : 'No categories yet. Add your first category.';
  String get emptyIncome =>
      isRu ? 'Добавьте источник дохода и суммы.' : 'Add an income source and amounts.';
  String get emptyMonths =>
      isRu
          ? 'Месяцев пока нет. Создайте первый месяц, чтобы начать.'
          : 'No months yet. Create your first month to get started.';
  String get addMonth => isRu ? 'Добавить месяц' : 'Add month';
  String get createMonth => isRu ? 'Создать месяц' : 'Create month';
  String get createEmptyMonth =>
      isRu ? 'Пустой месяц' : 'Empty month';
  String get copyFromPrevious =>
      isRu ? 'Копировать из предыдущего' : 'Copy from previous month';
  String get selectMonthToCopy =>
      isRu ? 'Месяц для копирования' : 'Month to copy';
  String get noMonthSelected =>
      isRu ? 'Сначала выберите или создайте месяц' : 'Select or create a month first';
  String get addCategory =>
      isRu ? 'Добавить категорию' : 'Add category';
  String get categoryName =>
      isRu ? 'Название категории' : 'Category name';
  String get categoryType => isRu ? 'Тип' : 'Type';
  String get categoryColor => isRu ? 'Цвет' : 'Color';
  String get monthCreated =>
      isRu ? 'Месяц создан' : 'Month created';
  String get selectMonth => isRu ? 'Выбрать месяц' : 'Select month';
  String get yearLabel => isRu ? 'Год' : 'Year';
  String get monthLabel => isRu ? 'Месяц' : 'Month';
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
  String get tryAgain => isRu ? 'Повторить' : 'Try again';

  String inviteShareMessage(String code, String householdName) => isRu
      ? 'Присоединяйся к бюджету «$householdName» в SimpleBudget. Код: $code'
      : 'Join "$householdName" on SimpleBudget. Invite code: $code';

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
