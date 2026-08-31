import 'package:flutter/material.dart';

import 'app_strings.dart';
import 'locale_lookup.dart';

class AppLocalizations {
  AppLocalizations(this.localeCode);

  final String localeCode;

  String _s(String key) => AppStrings.get(key, localeCode);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String get appTitle => 'SyncMonth';
  String get tagline => _s('tagline');
  String get month => _s('month');
  String get home => _s('home');
  String get activity => _s('activity');
  String get plan => _s('plan');
  String get income => _s('income');
  String get expense => _s('expense');
  String get overview => _s('overview');
  String get settings => _s('settings');
  String get log => _s('log');
  String get remaining => _s('remaining');
  String get overspent => _s('overspent');
  String get forgotPassword => _s('forgotPassword');
  String get resetEmailSent => _s('resetEmailSent');
  String get fieldRequired => _s('fieldRequired');
  String get invalidEmail => _s('invalidEmail');
  String get minPassword => _s('minPassword');
  String get editIncomeSource => _s('editIncomeSource');
  String get deleteIncomeSource => _s('deleteIncomeSource');
  String get quickLog => _s('quickLog');
  String get recentExpenses => _s('recentExpenses');
  String get incomeEntries => _s('incomeEntries');
  String get addFirstIncome => _s('addFirstIncome');
  String get editIncome => _s('editIncome');
  String get deleteIncome => _s('deleteIncome');
  String get createThisMonth => _s('createThisMonth');
  String get howAreWeDoing => _s('howAreWeDoing');
  String get startNextMonth => _s('startNextMonth');
  String get stepPickMonth => _s('stepPickMonth');
  String get stepCategoriesOrCopy => _s('stepCategoriesOrCopy');
  String get continueLabel => _s('continueLabel');
  String get done => _s('done');
  String get edit => _s('edit');
  String get plannedLabel => _s('plannedLabel');
  String get spentLabel => _s('spentLabel');
  String get budget => _s('budget');
  String get actual => _s('actual');
  String get difference => _s('difference');
  String get totalIncome => _s('totalIncome');
  String get groupTotal => _s('groupTotal');
  String get planExceedsIncome => _s('planExceedsIncome');
  String get addExpense => _s('addExpense');
  String get addIncomeSource => _s('addIncomeSource');
  String get addItem => _s('addItem');
  String get addEntry => _s('addEntry');
  String get save => _s('save');
  String get delete => _s('delete');
  String get removeFromMonth => _s('removeFromMonth');
  String get removeFromMonthConfirm => _s('removeFromMonthConfirm');
  String get cancel => _s('cancel');
  String get description => _s('description');
  String get category => _s('category');
  String get categories => _s('categories');
  String get installment => _s('installment');
  String get installmentCurrent => _s('installmentCurrent');
  String get installmentTotal => _s('installmentTotal');
  String get installmentHelper => _s('installmentHelper');
  String get note => _s('note');
  String get amount => _s('amount');
  String get amountSpend => _s('amountSpend');
  String get amountSave => _s('amountSave');
  String get amountIncome => _s('amountIncome');
  String get amountMonthly => _s('amountMonthly');
  String get amountDebt => _s('amountDebt');
  String get signIn => _s('signIn');
  String get signUp => _s('signUp');
  String get signOut => _s('signOut');
  String get deleteHousehold => _s('deleteHousehold');
  String get deleteHouseholdConfirmTitle => _s('deleteHouseholdConfirmTitle');
  String get deleteHouseholdConfirmBody => _s('deleteHouseholdConfirmBody');
  String get deleteAccount => _s('deleteAccount');
  String get deleteAccountConfirmTitle => _s('deleteAccountConfirmTitle');
  String get deleteAccountConfirmBody => _s('deleteAccountConfirmBody');
  String get deleteAccountOwnerBlockedTitle =>
      _s('deleteAccountOwnerBlockedTitle');
  String get deleteAccountOwnerBlockedBody =>
      _s('deleteAccountOwnerBlockedBody');
  String get confirmDelete => _s('confirmDelete');
  String get reauthenticateTitle => _s('reauthenticateTitle');
  String get reauthenticateBody => _s('reauthenticateBody');
  String get email => _s('email');
  String get password => _s('password');
  String get displayName => _s('displayName');
  String get orContinueWith => _s('orContinueWith');
  String get continueWithGoogle => _s('continueWithGoogle');
  String get continueWithApple => _s('continueWithApple');
  String get authAccountExistsDifferentCredential =>
      _s('authAccountExistsDifferentCredential');
  String get authGoogleSignInFailed => _s('authGoogleSignInFailed');
  String get authAppleSignInFailed => _s('authAppleSignInFailed');

  String authErrorForCode(String code) {
    switch (code) {
      case 'wrong-password':
      case 'invalid-credential':
      case 'user-not-found':
        return _s('authWrongPassword');
      case 'invalid-email':
        return invalidEmail;
      case 'user-disabled':
        return _s('authUserDisabled');
      case 'email-already-in-use':
        return _s('authEmailAlreadyInUse');
      case 'weak-password':
        return minPassword;
      case 'too-many-requests':
        return _s('authTooManyRequests');
      case 'network-request-failed':
        return _s('authNetworkFailed');
      case 'operation-not-allowed':
        return _s('authOperationNotAllowed');
      case 'account-exists-with-different-credential':
        return authAccountExistsDifferentCredential;
      default:
        return errorGeneric;
    }
  }

  String get createHousehold => _s('createHousehold');
  String get joinHousehold => _s('joinHousehold');
  String get householdName => _s('householdName');
  String get editHouseholdName => _s('editHouseholdName');
  String get myHouseholds => _s('myHouseholds');
  String get activeHousehold => _s('activeHousehold');
  String get createAnotherHousehold => _s('createAnotherHousehold');
  String get joinAnotherHousehold => _s('joinAnotherHousehold');
  String get switchHousehold => _s('switchHousehold');
  String get noHouseholdsYet => _s('noHouseholdsYet');
  String get inviteCode => _s('inviteCode');
  String get invitePartner => _s('invitePartner');
  String get shareInvite => _s('shareInvite');
  String get inviteCopied => _s('inviteCopied');
  String get exportCsv => _s('exportCsv');
  String get exportDone => _s('exportDone');
  String get typeSavings => _s('typeSavings');
  String get typeExpense => _s('typeExpense');
  String get typeSpend => typeExpense;
  String get typeMonthly => _s('typeMonthly');
  String get typeDebt => _s('typeDebt');
  String get emptyCategories => _s('emptyCategories');
  String get emptyIncome => _s('emptyIncome');
  String get emptyMonths => _s('emptyMonths');
  String get addMonth => _s('addMonth');
  String get monthAlreadyAdded => _s('monthAlreadyAdded');
  String get createMonth => _s('createMonth');
  String get addDefaultCategories => _s('addDefaultCategories');
  String get defaultsAdded => _s('defaultsAdded');
  String get defaultsAlreadyPresent => _s('defaultsAlreadyPresent');
  String get createEmptyMonth => _s('createEmptyMonth');
  String get selectCategories => _s('selectCategories');
  String get selectAll => _s('selectAll');
  String get selectNone => _s('selectNone');
  String get copyFromPrevious => _s('copyFromPrevious');
  String get selectMonthToCopy => _s('selectMonthToCopy');
  String get noMonthSelected => _s('noMonthSelected');
  String get subcategory => _s('subcategory');
  String get addSubcategory => _s('addSubcategory');
  String get subcategoryName => _s('subcategoryName');
  String get editPlan => _s('editPlan');
  String get editSubcategory => _s('editSubcategory');
  String get date => _s('date');
  String get noSubcategories => _s('noSubcategories');
  String get addCategory => _s('addCategory');
  String get chooseFromList => _s('chooseFromList');
  String get customCategory => _s('customCategory');
  String get categoryAlreadyAdded => _s('categoryAlreadyAdded');
  String get noSuggestionsLeft => _s('noSuggestionsLeft');
  String get categoryName => _s('categoryName');
  String get categoryType => _s('categoryType');
  String get categoryColor => _s('categoryColor');
  String get categoryIcon => _s('categoryIcon');
  String get monthCreated => _s('monthCreated');
  String get selectMonth => _s('selectMonth');
  String get yearLabel => _s('yearLabel');
  String get monthLabel => _s('monthLabel');
  String get members => _s('members');
  String get language => _s('language');
  String get currency => _s('currency');
  String get duplicateMonth => _s('duplicateMonth');
  String get manageCategories => _s('manageCategories');
  String get household => _s('household');
  String get synced => _s('synced');
  String get savingsHighlight => _s('savingsHighlight');
  String get addPot => _s('addPot');
  String get logDeposit => _s('logDeposit');
  String get deposit => _s('deposit');
  String get targetAmount => _s('targetAmount');
  String get targetOptional => _s('targetOptional');
  String get setTarget => _s('setTarget');
  String get clearTarget => _s('clearTarget');
  String get savedLabel => _s('savedLabel');
  String get emptyPots => _s('emptyPots');
  String get thisMonthDeposits => _s('thisMonthDeposits');
  String get noDepositsThisMonth => _s('noDepositsThisMonth');
  String get editPot => _s('editPot');
  String get includeInTotal => _s('includeInTotal');
  String get includeInTotalHint => _s('includeInTotalHint');
  String get sectionInTotal => _s('sectionInTotal');
  String get sectionInTotalHint => _s('sectionInTotalHint');
  String get sectionNotInTotal => _s('sectionNotInTotal');
  String get sectionNotInTotalHint => _s('sectionNotInTotalHint');
  String get alreadySaved => _s('alreadySaved');
  String get alreadySavedHint => _s('alreadySavedHint');
  String get addPriorSavings => _s('addPriorSavings');
  String get underspent => _s('underspent');
  String get noData => _s('noData');
  String get loading => _s('loading');
  String get errorGeneric => _s('errorGeneric');
  String get tryAgain => _s('tryAgain');
  String get addFirstExpense => _s('addFirstExpense');
  String get searchActivity => _s('searchActivity');
  String get filterAll => _s('filterAll');
  String get loggedBy => _s('loggedBy');
  String get leaveHousehold => _s('leaveHousehold');
  String get leaveHouseholdConfirmTitle => _s('leaveHouseholdConfirmTitle');
  String get leaveHouseholdConfirmBody => _s('leaveHouseholdConfirmBody');
  String get leaveHouseholdOwnerBlocked => _s('leaveHouseholdOwnerBlocked');
  String get removeMember => _s('removeMember');
  String get roleEditor => _s('roleEditor');
  String get roleViewer => _s('roleViewer');
  String get roleOwner => _s('roleOwner');
  String get recurringBills => _s('recurringBills');
  String get loans => _s('loans');
  String get addLoan => _s('addLoan');
  String get loanTypeInstallment => _s('loanTypeInstallment');
  String get loanTypeBalance => _s('loanTypeBalance');
  String loanPaymentsProgress(int paid, int total) => _s('loanPaymentsProgress')
      .replaceAll('{paid}', '$paid')
      .replaceAll('{total}', '$total');
  String loanPaymentsLeft(int count) =>
      _s('loanPaymentsLeft').replaceAll('{count}', '$count');
  String get remainingBalance => _s('remainingBalance');
  String get remainingBalanceHint => _s('remainingBalanceHint');
  String get originalAmount => _s('originalAmount');
  String get addBill => _s('addBill');
  String get billDay => _s('billDay');
  String get upcomingBills => _s('upcomingBills');
  String get splitSpend => _s('splitSpend');
  String get splitPart => _s('splitPart');
  String get rolloverLeftover => _s('rolloverLeftover');
  String get leftoverPotHint => _s('leftoverPotHint');
  String get leftoverToggleOff => _s('leftoverToggleOff');
  String get leftoverToggleOn => _s('leftoverToggleOn');
  String get leftoverNoPreviousMonth => _s('leftoverNoPreviousMonth');
  String get copyPlanOnly => _s('copyPlanOnly');
  String get reports => _s('reports');
  String get targetDate => _s('targetDate');
  String get watchlist => _s('watchlist');
  String get overspendAlert => _s('overspendAlert');
  String get alerts => _s('alerts');
  String get seeAll => _s('seeAll');
  String get noExpensesYet => _s('noExpensesYet');
  String get spendingByCategory => _s('spendingByCategory');
  String get manageCategoriesLink => _s('manageCategoriesLink');
  String get sectionExpenses => _s('sectionExpenses');
  String get sectionSpend => sectionExpenses;
  String get sectionMonthly => _s('sectionMonthly');
  String get sectionSavings => _s('sectionSavings');
  String get sectionDebt => _s('sectionDebt');
  String get statistics => _s('statistics');
  String get compareMonths => _s('compareMonths');
  String get last3Months => _s('last3Months');
  String get last6Months => _s('last6Months');
  String get thisVsPrev => _s('thisVsPrev');
  String get byCategory => _s('byCategory');
  String get bySubcategory => _s('bySubcategory');
  String get cashLeft => _s('cashLeft');
  String get unallocated => _s('unallocated');
  String get logSpend => _s('logSpend');
  String get logSave => _s('logSave');
  String get logDebt => _s('logDebt');
  String get logFixed => _s('logFixed');
  String get logFixedHint => _s('logFixedHint');
  String get logMoreOptions => _s('logMoreOptions');
  String get editLog => _s('editLog');
  String get editCategory => _s('editCategory');
  String get viewerReadOnlyPlan => _s('viewerReadOnlyPlan');
  String get hebrew => _s('hebrew');

  String potsTowardSaved(int count) =>
      _s('potsTowardSaved').replaceAll('{count}', '$count');

  String potsTrackedSeparately(int count) =>
      _s('potsTrackedSeparately').replaceAll('{count}', '$count');

  String leftoverThroughPeriod(String monthTitle) =>
      _s('leftoverThroughPeriod').replaceAll('{monthTitle}', monthTitle);

  String moreExpenses(int count) =>
      _s('moreExpenses').replaceAll('{count}', '$count');

  String inviteShareMessage(String code, String householdName) => _s(
        'inviteShareMessage',
      )
          .replaceAll('{householdName}', householdName)
          .replaceAll('{code}', code);

  String monthTitle(DateTime date) {
    final names =
        AppStrings.monthNames[localeCode] ?? AppStrings.monthNames['en']!;
    return '${names[date.month - 1]} ${date.year}';
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      supportedLocaleCodes.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale.languageCode);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
