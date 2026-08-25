import 'package:flutter/material.dart';

/// Simple bilingual strings with EN/RU toggle (no gen-l10n codegen required).
class AppLocalizations {
  AppLocalizations(this.localeCode);

  final String localeCode;

  bool get isRu => localeCode == 'ru';
  bool get isHe => localeCode == 'he';

  String _t(String en, String ru, [String? he]) {
    if (isRu) return ru;
    if (isHe) return he ?? en;
    return en;
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String get appTitle => 'SyncMonth';
  String get tagline =>
      _t('Family monthly budget', 'Семейный месячный бюджет', 'תקציב משפחתי חודשי');

  String get month => _t('Month', 'Месяц', 'חודש');
  String get home => _t('Home', 'Домой', 'בית');
  String get activity => _t('Activity', 'Активность', 'פעילות');
  String get plan => _t('Plan', 'План', 'תוכנית');
  String get income => _t('Income', 'Доход', 'הכנסה');
  String get expense => _t('Expense', 'Расход', 'הוצאה');
  String get overview => _t('Reports', 'Обзор', 'דוחות');
  String get settings => _t('Settings', 'Настройки', 'הגדרות');
  String get log => _t('Log', 'Записать', 'רישום');
  String get remaining => _t('Remaining', 'Остаток', 'יתרה');
  String get overspent => _t('Overspent', 'Перерасход', 'חריגה');
  String get forgotPassword =>
      _t('Forgot password?', 'Забыли пароль?', 'שכחתם סיסמה?');
  String get resetEmailSent => _t(
        'Check your email for a reset link.',
        'Проверьте почту — отправили ссылку.',
        'בדקו את האימייל לקישור לאיפוס.',
      );
  String get fieldRequired => _t('Required', 'Обязательно', 'שדה חובה');
  String get invalidEmail => _t('Invalid email', 'Некорректный email', 'אימייל לא תקין');
  String get minPassword => _t('Min 6 chars', 'Минимум 6 символов', 'לפחות 6 תווים');
  String get editIncomeSource =>
      _t('Edit income source', 'Изменить источник', 'עריכת מקור הכנסה');
  String get deleteIncomeSource =>
      _t('Delete income source', 'Удалить источник', 'מחיקת מקור הכנסה');
  String get quickLog => isRu ? 'Быстрая запись' : 'Quick log';
  String get recentExpenses => isRu ? 'Недавние траты' : 'Recent expenses';
  String get incomeEntries => isRu ? 'Доходы' : 'Income entries';
  String get addFirstIncome =>
      isRu ? 'Добавьте первый доход' : 'Add first income';
  String get editIncome => isRu ? 'Изменить доход' : 'Edit income';
  String get deleteIncome => isRu ? 'Удалить доход' : 'Delete income';
  String get createThisMonth =>
      isRu ? 'Создать этот месяц' : 'Create this month';
  String get howAreWeDoing => isRu
      ? 'Как мы с бюджетом в этом месяце?'
      : 'How are we doing this month?';
  String get startNextMonth => isRu
      ? 'Начать следующий месяц из этого плана'
      : 'Start next month from this plan';
  String get stepPickMonth => isRu ? 'Выберите месяц' : 'Pick a month';
  String get stepCategoriesOrCopy =>
      isRu ? 'Категории или копия' : 'Categories or copy';
  String get continueLabel => isRu ? 'Далее' : 'Continue';
  String get done => isRu ? 'Готово' : 'Done';
  String get edit => isRu ? 'Редактировать' : 'Edit';
  String get plannedLabel =>
      _t('Monthly budget', 'Бюджет на месяц', 'תקציב לחודש');
  String get spentLabel => _t('Spent', 'Потрачено', 'הוצא');

  String get budget => isRu ? 'Бюджет' : 'Budget';
  String get actual => isRu ? 'Фактически' : 'Actual';
  String get difference => isRu ? 'Разница' : 'Difference';
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
  String get categories => isRu ? 'Категории' : 'Categories';
  String get installment => isRu ? 'Рассрочка' : 'Installment';
  String get installmentHint => isRu ? 'Например, 1/12' : 'For example, 1/12';
  String get installmentHelper => isRu
      ? 'Введите текущий и общий номер платежа через /'
      : 'Enter current and total payment number separated by /';
  String get note => isRu ? 'Заметка' : 'Note';
  String get amount =>
      _t('How much', 'Сколько', 'כמה');
  String get amountSpend =>
      _t('How much spent', 'Сколько потратили', 'כמה הוצאתם');
  String get amountSave =>
      _t('How much to save', 'Сколько отложить', 'כמה לחסוך');
  String get amountIncome =>
      _t('How much earned', 'Сколько получили', 'כמה התקבלו');
  String get amountMonthly =>
      _t('Monthly payment', 'Ежемесячный платёж', 'תשלום חודשי');
  String get amountDebt =>
      _t('Payment amount', 'Сумма платежа', 'סכום תשלום');

  String get signIn => isRu ? 'Войти' : 'Sign in';
  String get signUp => isRu ? 'Регистрация' : 'Sign up';
  String get signOut => isRu ? 'Выйти' : 'Sign out';
  String get deleteHousehold => isRu ? 'Удалить семью' : 'Delete household';
  String get deleteHouseholdConfirmTitle =>
      isRu ? 'Удалить семью?' : 'Delete household?';
  String get deleteHouseholdConfirmBody => isRu
      ? 'Будут удалены все месяцы, категории и траты. Другие участники потеряют доступ. Это нельзя отменить.'
      : 'This removes every month, category, and expense. Other members will lose access. This cannot be undone.';
  String get deleteAccount => isRu ? 'Удалить аккаунт' : 'Delete account';
  String get deleteAccountConfirmTitle =>
      isRu ? 'Удалить аккаунт?' : 'Delete account?';
  String get deleteAccountConfirmBody => isRu
      ? 'Ваш вход и профиль будут удалены. Это нельзя отменить.'
      : 'Your sign-in and profile will be removed. This cannot be undone.';
  String get deleteAccountOwnerBlockedTitle =>
      isRu ? 'Сначала удалите семью' : 'Delete the household first';
  String get deleteAccountOwnerBlockedBody => isRu
      ? 'Вы владелец этой семьи. Удалите семью, прежде чем удалить аккаунт, чтобы не стереть данные других участников без отдельного подтверждения.'
      : 'You own this household. Delete the household first so other members are not wiped without that separate confirmation.';
  String get confirmDelete => isRu ? 'Удалить' : 'Delete';
  String get reauthenticateTitle =>
      isRu ? 'Подтвердите пароль' : 'Confirm your password';
  String get reauthenticateBody => isRu
      ? 'Чтобы удалить аккаунт, введите пароль ещё раз.'
      : 'Enter your password again to delete your account.';
  String get email => isRu ? 'Email' : 'Email';
  String get password => isRu ? 'Пароль' : 'Password';
  String get displayName => isRu ? 'Имя' : 'Display name';
  String get orContinueWith => isRu ? 'или' : 'or';
  String get continueWithGoogle =>
      isRu ? 'Продолжить с Google' : 'Continue with Google';
  String get continueWithApple =>
      isRu ? 'Продолжить с Apple' : 'Continue with Apple';

  String get createHousehold => isRu ? 'Создать семью' : 'Create household';
  String get joinHousehold => isRu ? 'Присоединиться' : 'Join household';
  String get householdName => isRu ? 'Название семьи' : 'Household name';
  String get editHouseholdName =>
      isRu ? 'Изменить название семьи' : 'Edit household name';
  String get inviteCode => isRu ? 'Код приглашения' : 'Invite code';
  String get invitePartner => isRu ? 'Пригласить партнёра' : 'Invite partner';
  String get shareInvite => isRu ? 'Поделиться приглашением' : 'Share invite';
  String get inviteCopied => isRu ? 'Код скопирован' : 'Invite code copied';
  String get exportCsv => isRu ? 'Экспорт CSV' : 'Export CSV';
  String get exportDone => isRu ? 'CSV готов к отправке' : 'CSV ready to share';
  String get typeSavings => isRu ? 'Накопления' : 'Savings';
  String get typeExpense => isRu ? 'Траты' : 'Spend';
  String get typeSpend => typeExpense;
  String get typeMonthly => isRu ? 'Ежемесячные' : 'Monthly';
  String get typeDebt => isRu ? 'Долг / платёж' : 'Debt / payment';
  String get emptyCategories => isRu
      ? 'Категорий пока нет. Добавьте при записи траты или из списка.'
      : 'No categories yet. Add one when you log a spend, or from the list.';
  String get emptyIncome => isRu
      ? 'Добавьте источник дохода и суммы.'
      : 'Add an income source and amounts.';
  String get emptyMonths => isRu
      ? 'Месяцев пока нет. Создайте первый месяц, чтобы начать.'
      : 'No months yet. Create your first month to get started.';
  String get addMonth => isRu ? 'Добавить месяц' : 'Add month';
  String get monthAlreadyAdded => isRu ? 'уже добавлен' : 'already added';
  String get createMonth => isRu ? 'Создать месяц' : 'Create month';
  String get addDefaultCategories =>
      isRu ? 'Добавить категории по умолчанию' : 'Add default categories';
  String get defaultsAdded =>
      isRu ? 'Категории по умолчанию добавлены' : 'Default categories added';
  String get defaultsAlreadyPresent => isRu
      ? 'Все категории по умолчанию уже есть'
      : 'Default categories already present';
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
  String get noMonthSelected => isRu
      ? 'Сначала выберите или создайте месяц'
      : 'Select or create a month first';
  String get subcategory => isRu ? 'Подкатегория' : 'Subcategory';
  String get addSubcategory =>
      isRu ? 'Добавить подкатегорию' : 'Add subcategory';
  String get subcategoryName =>
      isRu ? 'Название подкатегории' : 'Subcategory name';
  String get editPlan => isRu ? 'Изменить план' : 'Edit plan';
  String get editSubcategory =>
      isRu ? 'Изменить подкатегорию' : 'Edit subcategory';
  String get date => isRu ? 'Дата' : 'Date';
  String get noSubcategories => isRu
      ? 'Подкатегорий пока нет. Добавьте, например, топливо или страховку.'
      : 'No subcategories yet. Add one, for example fuel or insurance.';
  String get addCategory => isRu ? 'Добавить категорию' : 'Add category';
  String get chooseFromList => isRu ? 'Выбрать из списка' : 'Choose from list';
  String get customCategory => isRu ? 'Своя категория' : 'Custom category';
  String get categoryAlreadyAdded =>
      isRu ? 'Эта категория уже есть' : 'Category already added';
  String get noSuggestionsLeft => isRu
      ? 'Все предложенные категории уже добавлены'
      : 'All suggested categories are already added';
  String get categoryName => isRu ? 'Название категории' : 'Category name';
  String get categoryType => isRu ? 'Тип' : 'Type';
  String get categoryColor => isRu ? 'Цвет' : 'Color';
  String get monthCreated => isRu ? 'Месяц создан' : 'Month created';
  String get selectMonth => isRu ? 'Выбрать месяц' : 'Select month';
  String get yearLabel => isRu ? 'Год' : 'Year';
  String get monthLabel => isRu ? 'Месяц' : 'Month';
  String get members => isRu ? 'Участники' : 'Members';
  String get language => isRu ? 'Язык' : 'Language';
  String get currency => isRu ? 'Валюта' : 'Currency';
  String get duplicateMonth => isRu
      ? 'Создать следующий месяц из этого плана'
      : 'Create next month from this plan';
  String get manageCategories => isRu ? 'Категории' : 'Manage categories';
  String get household => isRu ? 'Семья' : 'Household';
  String get synced => isRu ? 'Синхронизировано' : 'Synced';

  String get savingsHighlight => isRu ? 'Отложено' : 'Set aside';
  String get addPot => isRu ? 'Добавить цель' : 'Add pot';
  String get logDeposit => isRu ? 'Отложить' : 'Log deposit';
  String get deposit => isRu ? 'Отложение' : 'Deposit';
  String get targetAmount => isRu ? 'Общая цель' : 'Savings goal';
  String get targetOptional =>
      isRu ? 'Общая цель (необязательно)' : 'Savings goal (optional)';
  String get setTarget => isRu ? 'Задать общую цель' : 'Set savings goal';
  String get clearTarget => isRu ? 'Убрать общую цель' : 'Clear savings goal';
  String get savedLabel => isRu ? 'Накоплено' : 'Saved';
  String get emptyPots => isRu
      ? 'Пока нет целей. Добавьте накопления, резерв или инвестиции.'
      : 'No pots yet. Add savings, an emergency fund, or investments.';
  String get thisMonthDeposits => isRu ? 'В этом месяце' : 'This month';
  String get noDepositsThisMonth =>
      isRu ? 'В этом месяце ещё ничего не отложено' : 'No deposits this month';
  String get editPot => isRu ? 'Изменить цель' : 'Edit pot';
  String get includeInTotal =>
      isRu ? 'Считать в «Накоплено»' : 'Count toward Saved';
  String get includeInTotalHint => isRu
      ? 'Если включено, сумма входит в общий итог сверху. Выключите для долгосрочных целей вроде пенсии — они показываются отдельно.'
      : 'When on, this pot is included in the Saved total above. Turn off for long-term pots like pension — they are listed separately.';
  String get sectionInTotal =>
      isRu ? 'Считаются в «Накоплено»' : 'Count toward Saved';
  String get sectionInTotalHint => isRu
      ? 'Суммы этих целей складываются в итог сверху'
      : 'These pots add up in the Saved total above';
  String get sectionNotInTotal =>
      isRu ? 'Ведутся отдельно' : 'Tracked separately';
  String get sectionNotInTotalHint => isRu
      ? 'Например пенсия — на экране есть, но не в общем итоге'
      : 'e.g. pension — shown here, but not in the Saved total';
  String potsTowardSaved(int count) => isRu
      ? '$count в «Накоплено»'
      : '$count toward Saved';
  String potsTrackedSeparately(int count) => isRu
      ? '$count отдельно'
      : '$count tracked separately';
  String get alreadySaved => isRu ? 'Уже накоплено' : 'Already saved';
  String get alreadySavedHint => isRu
      ? 'Сумма, которая уже была до этого месяца. Не входит в бюджет месяца.'
      : 'Cash you already had before this month. Does not count toward this month’s budget.';
  String get addPriorSavings =>
      isRu ? 'Добавить прошлые накопления' : 'Add prior savings';
  String get underspent => isRu ? 'Остаток по позициям' : 'Underspent items';
  String get noData => isRu ? 'Пока нет данных' : 'No data yet';
  String get loading => isRu ? 'Загрузка…' : 'Loading…';
  String get errorGeneric =>
      isRu ? 'Что-то пошло не так' : 'Something went wrong';
  String get tryAgain => isRu ? 'Повторить' : 'Try again';

  String get addFirstExpense => _t(
        'Add first expense',
        'Добавьте первую трату',
        'הוסיפו הוצאה ראשונה',
      );
  String get searchActivity => _t('Search', 'Поиск', 'חיפוש');
  String get filterAll => _t('All', 'Все', 'הכל');
  String get loggedBy => _t('Logged by', 'Кто записал', 'נרשם על ידי');
  String get leaveHousehold => _t('Leave household', 'Выйти из семьи', 'עזיבת המשפחה');
  String get leaveHouseholdConfirmTitle =>
      _t('Leave this household?', 'Выйти из семьи?', 'לעזוב את המשפחה?');
  String get leaveHouseholdConfirmBody => _t(
        'You will lose access to this shared budget. Your account stays.',
        'Вы потеряете доступ к общему бюджету. Аккаунт останется.',
        'תאבדו גישה לתקציב המשותף. החשבון יישאר.',
      );
  String get leaveHouseholdOwnerBlocked => _t(
        'Owners must delete the household instead of leaving.',
        'Владелец должен удалить семью, а не выйти.',
        'בעלים צריכים למחוק את המשפחה במקום לעזוב.',
      );
  String get removeMember => _t('Remove', 'Удалить', 'הסרה');
  String get roleEditor => _t('Editor', 'Редактор', 'עורך');
  String get roleViewer => _t('Can log only', 'Только записи', 'רישום בלבד');
  String get roleOwner => _t('Owner', 'Владелец', 'בעלים');
  String get recurringBills => _t('Recurring bills', 'Регулярные счета', 'חשבונות קבועים');
  String get addBill => _t('Add bill', 'Добавить счёт', 'הוספת חשבון');
  String get billDay => _t('Day of month', 'День месяца', 'יום בחודש');
  String get upcomingBills => _t('Upcoming bills', 'Ближайшие счета', 'חשבונות קרובים');
  String get splitSpend => _t('Split spend', 'Разделить трату', 'פיצול הוצאה');
  String get splitPart => _t('Part', 'Часть', 'חלק');
  String get rolloverLeftover => _t(
        'Carry leftover to next month',
        'Перенести остаток на следующий месяц',
        'העברת יתרה לחודש הבא',
      );
  String get copyPlanOnly => _t(
        'Copy plan and expense amounts',
        'Копировать план и траты',
        'העתקת סכומי תכנון והוצאות',
      );
  String get reports => _t('Reports', 'Отчёты', 'דוחות');
  String get targetDate => _t('Target date', 'Срок', 'תאריך יעד');
  String get watchlist => _t('Watchlist', 'Контроль категорий', 'מעקב קטגוריות');
  String get overspendAlert => _t(
        'Near or over plan',
        'Близко к лимиту или сверх плана',
        'קרוב לתקציב או מעליו',
      );
  String get alerts => _t('Alerts', 'Уведомления', 'התראות');
  String get seeAll => _t('See all', 'Показать все', 'הצג הכל');
  String get noExpensesYet =>
      _t('No expenses yet', 'Трат пока нет', 'אין הוצאות עדיין');
  String moreExpenses(int count) => _t(
        '+ $count more',
        '+ ещё $count',
        '+ עוד $count',
      );
  String get spendingByCategory =>
      _t('Spending by category', 'Расход по категориям', 'הוצאות לפי קטגוריה');
  String get manageCategoriesLink =>
      _t('Manage categories', 'Управление категориями', 'ניהול קטגוריות');
  String get sectionExpenses => _t('Spend', 'Траты', 'הוצאות');
  String get sectionSpend => sectionExpenses;
  String get sectionMonthly => _t('Monthly', 'Ежемесячные', 'חודשי');
  String get sectionSavings => _t('Savings', 'Накопления', 'חיסכון');
  String get sectionDebt => _t('Debt / payment', 'Долг / платёж', 'חוב / תשלום');
  String get statistics => _t('Statistics', 'Статистика', 'סטטיסטיקה');
  String get compareMonths =>
      _t('Compare months', 'Сравнение месяцев', 'השוואת חודשים');
  String get last3Months => _t('Last 3 months', '3 месяца', '3 חודשים');
  String get last6Months => _t('Last 6 months', '6 месяцев', '6 חודשים');
  String get thisVsPrev =>
      _t('This vs previous', 'Этот и прошлый', 'זה מול קודם');
  String get byCategory => _t('By category', 'По категориям', 'לפי קטגוריה');
  String get bySubcategory =>
      _t('By subcategory', 'По подкатегориям', 'לפי תת־קטגוריה');
  String get cashLeft => _t('Cash left', 'Остаток наличных', 'מזומן שנותר');
  String get unallocated => _t('Unallocated', 'Не распределено', 'לא מוקצה');
  String get logSpend => _t('Spend', 'Трата', 'הוצאה');
  String get logSave => _t('Save', 'Отложить', 'חיסכון');
  String get logDebt => _t('Debt', 'Долг', 'חוב');
  String get logFixed => _t('Monthly', 'Ежемесячно', 'חודשי');
  String get logFixedHint => _t(
        'Sets this month’s plan and repeats every new month',
        'Задаёт план на месяц и повторяется в каждом новом месяце',
        'קובע את התוכנית לחודש וחוזר בכל חודש חדש',
      );
  String get logMoreOptions => _t('More', 'Ещё', 'עוד');
  String get editLog => _t('Edit', 'Изменить', 'עריכה');
  String get editCategory =>
      _t('Edit category', 'Изменить категорию', 'עריכת קטגוריה');
  String get viewerReadOnlyPlan => _t(
        'You can log income and spends. Plan changes are for editors.',
        'Можно записывать доходы и траты. План меняют редакторы.',
        'אפשר לרשום הכנסות והוצאות. שינויי תוכנית לעורכים.',
      );
  String get hebrew => 'עברית';

  String inviteShareMessage(String code, String householdName) => isRu
      ? 'Присоединяйся к бюджету «$householdName» в SyncMonth. Код: $code'
      : isHe
          ? 'הצטרפו לתקציב "$householdName" ב-SyncMonth. קוד: $code'
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
    final monthsHe = [
      'ינואר',
      'פברואר',
      'מרץ',
      'אפריל',
      'מאי',
      'יוני',
      'יולי',
      'אוגוסט',
      'ספטמבר',
      'אוקטובר',
      'נובמבר',
      'דצמבר',
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
    final name = isRu
        ? monthsRu[date.month - 1]
        : isHe
            ? monthsHe[date.month - 1]
            : monthsEn[date.month - 1];
    return '$name ${date.year}';
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'en' ||
      locale.languageCode == 'ru' ||
      locale.languageCode == 'he';

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale.languageCode);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
