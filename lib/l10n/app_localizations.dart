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
  String get home => isRu ? 'Домой' : 'Home';
  String get activity => isRu ? 'Активность' : 'Activity';
  String get plan => isRu ? 'План' : 'Plan';
  String get income => isRu ? 'Доход' : 'Income';
  String get expense => isRu ? 'Расход' : 'Expense';
  String get overview => isRu ? 'Обзор' : 'Overview';
  String get settings => isRu ? 'Настройки' : 'Settings';
  String get log => isRu ? 'Записать' : 'Log';
  String get quickLog => isRu ? 'Быстрая запись' : 'Quick log';
  String get recentExpenses => isRu ? 'Недавние траты' : 'Recent expenses';
  String get incomeEntries => isRu ? 'Доходы' : 'Income entries';
  String get addFirstIncome =>
      isRu ? 'Добавьте первый доход' : 'Add first income';
  String get editIncome => isRu ? 'Изменить доход' : 'Edit income';
  String get deleteIncome => isRu ? 'Удалить доход' : 'Delete income';
  String get createThisMonth =>
      isRu ? 'Создать этот месяц' : 'Create this month';
  String get howAreWeDoing =>
      isRu
          ? 'Как мы с бюджетом в этом месяце?'
          : 'How are we doing this month?';
  String get startNextMonth =>
      isRu
          ? 'Начать следующий месяц из этого плана'
          : 'Start next month from this plan';
  String get stepPickMonth => isRu ? 'Выберите месяц' : 'Pick a month';
  String get stepCategoriesOrCopy =>
      isRu ? 'Категории или копия' : 'Categories or copy';
  String get continueLabel => isRu ? 'Далее' : 'Continue';
  String get done => isRu ? 'Готово' : 'Done';
  String get plannedLabel => isRu ? 'План' : 'Planned';
  String get spentLabel => isRu ? 'Потрачено' : 'Spent';

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
  String get installmentHint => isRu ? 'Например, 1/12' : 'For example, 1/12';
  String get installmentHelper =>
      isRu ? 'Введите текущий и общий номер платежа через /' : 'Enter current and total payment number separated by /';
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
          ? 'Категорий пока нет. Добавьте при записи траты или из списка.'
          : 'No categories yet. Add one when you log a spend, or from the list.';
  String get emptyIncome =>
      isRu ? 'Добавьте источник дохода и суммы.' : 'Add an income source and amounts.';
  String get emptyMonths =>
      isRu
          ? 'Месяцев пока нет. Создайте первый месяц, чтобы начать.'
          : 'No months yet. Create your first month to get started.';
  String get addMonth => isRu ? 'Добавить месяц' : 'Add month';
  String get createMonth => isRu ? 'Создать месяц' : 'Create month';
  String get addDefaultCategories =>
      isRu ? 'Добавить категории по умолчанию' : 'Add default categories';
  String get defaultsAdded =>
      isRu ? 'Категории по умолчанию добавлены' : 'Default categories added';
  String get defaultsAlreadyPresent =>
      isRu ? 'Все категории по умолчанию уже есть' : 'Default categories already present';
  String get createEmptyMonth =>
      isRu ? 'Новый месяц без копирования' : 'New month (no copy)';
  String get selectCategories =>
      isRu ? 'Выберите категории' : 'Select categories';
  String get selectAll => isRu ? 'Выбрать все' : 'Select all';
  String get selectNone => isRu ? 'Снять все' : 'Select none';
  String get copyFromPrevious =>
      isRu ? 'Копировать из предыдущего' : 'Copy from previous month';
  String get selectMonthToCopy =>
      isRu ? 'Месяц для копирования' : 'Month to copy';
  String get noMonthSelected =>
      isRu ? 'Сначала выберите или создайте месяц' : 'Select or create a month first';
  String get subcategory => isRu ? 'Подкатегория' : 'Subcategory';
  String get addSubcategory =>
      isRu ? 'Добавить подкатегорию' : 'Add subcategory';
  String get subcategoryName =>
      isRu ? 'Название подкатегории' : 'Subcategory name';
  String get editPlan => isRu ? 'Изменить план' : 'Edit plan';
  String get date => isRu ? 'Дата' : 'Date';
  String get noSubcategories =>
      isRu
          ? 'Подкатегорий пока нет. Добавьте, например, топливо или страховку.'
          : 'No subcategories yet. Add one, for example fuel or insurance.';
  String get addCategory =>
      isRu ? 'Добавить категорию' : 'Add category';
  String get chooseFromList =>
      isRu ? 'Выбрать из списка' : 'Choose from list';
  String get customCategory =>
      isRu ? 'Своя категория' : 'Custom category';
  String get categoryAlreadyAdded =>
      isRu ? 'Эта категория уже есть' : 'Category already added';
  String get noSuggestionsLeft =>
      isRu
          ? 'Все предложенные категории уже добавлены'
          : 'All suggested categories are already added';
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
      ? 'Присоединяйся к бюджету «$householdName» в SyncMonth. Код: $code'
      : 'Join "$householdName" on SyncMonth. Invite code: $code';

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
