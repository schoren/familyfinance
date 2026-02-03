// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get spanish => 'Spanish';

  @override
  String get english => 'English';

  @override
  String get logout => 'Logout';

  @override
  String get versionInfo => 'Version Information';

  @override
  String get clientVersion => 'Client Version';

  @override
  String get serverVersion => 'Server Version';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get home => 'Home';

  @override
  String get accounts => 'Accounts';

  @override
  String get members => 'Members';

  @override
  String get expenses => 'Expenses';

  @override
  String get noExpenses => 'No recent expenses';

  @override
  String get addExpense => 'Add Expense';

  @override
  String get categories => 'Categories';

  @override
  String get editExpense => 'Edit Expense';

  @override
  String get newExpense => 'New Expense';

  @override
  String get deleteExpense => 'Delete Expense';

  @override
  String get deleteExpenseConfirm =>
      'Are you sure you want to delete this expense?';

  @override
  String get updateExpense => 'UPDATE EXPENSE';

  @override
  String get systemDefault => 'System Default';

  @override
  String get deleteCategory => 'Delete Category';

  @override
  String deleteCategoryConfirm(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get viewDetail => 'View Detail';

  @override
  String get edit => 'Edit';

  @override
  String get allExpenses => 'All Expenses';

  @override
  String get noExpensesThisMonth => 'No expenses this month';

  @override
  String get noNote => 'No note';

  @override
  String createdBy(String name) {
    return 'Created by: $name';
  }

  @override
  String get errorLoadingCategories => 'Error loading categories';

  @override
  String get errorLoadingAccounts => 'Error loading accounts';

  @override
  String get errorLoadingExpenses => 'Error loading expenses';

  @override
  String get pleaseSelectAccount => 'Please select an account';

  @override
  String get categoryNotFound => 'Category not found';

  @override
  String remaining(String amount) {
    return 'REMAINING $amount';
  }

  @override
  String get amount => 'AMOUNT';

  @override
  String get enterAmount => 'Enter an amount';

  @override
  String get invalidAmount => 'Invalid amount';

  @override
  String get account => 'ACCOUNT';

  @override
  String get addNewAccount => 'Add new account...';

  @override
  String get noAccountsCreated => 'You don\'t have any accounts created.';

  @override
  String get createFirstAccount => 'Create my first account';

  @override
  String get noteOptional => 'NOTE (OPTIONAL)';

  @override
  String get saveExpense => 'SAVE EXPENSE';

  @override
  String get selectAnAccount => 'Select an account';

  @override
  String get manageAccounts => 'Manage Accounts';

  @override
  String get card => 'Card';

  @override
  String get bankAccount => 'Bank Account';

  @override
  String get cash => 'Cash';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String deleteAccountConfirm(String name) {
    return 'Do you want to delete the account \"$name\"?';
  }

  @override
  String get editAccount => 'Edit Account';

  @override
  String get newAccount => 'New Account';

  @override
  String get type => 'Type';

  @override
  String get brand => 'Brand';

  @override
  String get bank => 'Bank';

  @override
  String get accountName => 'Account Name';

  @override
  String get enterBank => 'Enter the bank';

  @override
  String get enterName => 'Enter the name';

  @override
  String get save => 'SAVE';

  @override
  String get accountNotFound => 'Account not found';

  @override
  String saveError(String error) {
    return 'Error saving: $error';
  }

  @override
  String get removeMember => 'Remove Member';

  @override
  String removeMemberConfirm(String name) {
    return 'Are you sure you want to remove $name from the household?';
  }

  @override
  String get memberRemoved => 'Member removed';

  @override
  String get inviteLinkCopied => 'Invite link copied to clipboard';

  @override
  String get inviteMember => 'Invite Member';

  @override
  String get invitationSent => 'Invitation sent successfully';

  @override
  String get invitePending => 'This user already has a pending invitation';

  @override
  String inviteError(String error) {
    return 'Error sending invitation: $error';
  }

  @override
  String get send => 'Send';

  @override
  String get householdMembers => 'Household Members';

  @override
  String get inviteTooltip => 'Invite';

  @override
  String get youSuffix => ' (You)';

  @override
  String get pendingSuffix => ' (Pending)';

  @override
  String get copyLinkTooltip => 'Copy link';

  @override
  String get categorySaved => 'Category saved successfully';

  @override
  String get editCategory => 'Edit Category';

  @override
  String get newCategory => 'New Category';

  @override
  String get name => 'Name';

  @override
  String get monthlyBudget => 'Monthly Budget';

  @override
  String get enterNamePlease => 'Please enter a name';

  @override
  String get enterBudgetPlease => 'Please enter a budget';

  @override
  String get invalidNumber => 'Enter a valid number';

  @override
  String errorWithDetails(String error) {
    return 'Error: $error';
  }

  @override
  String errorInitializingGoogleSignIn(String error) {
    return 'Error initializing Google Sign In: $error';
  }

  @override
  String get historyThisMonth => 'History (This month)';

  @override
  String get unknownAccount => 'Unknown account';

  @override
  String get budget => 'Budget';

  @override
  String get spent => 'Spent';

  @override
  String get remainingLabel => 'Remaining';

  @override
  String exceededBy(String amount) {
    return 'EXCEEDED BY $amount';
  }

  @override
  String get serverUrl => 'Server URL';

  @override
  String get setServerUrl => 'Set server URL';

  @override
  String get serverUrlDescription =>
      'This is the server URL that the application will use to connect.';

  @override
  String get invalidUrl => 'Invalid URL';

  @override
  String get date => 'DATE';

  @override
  String get prevMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get recommendationsTitle => 'Budget Suggestions';

  @override
  String get recommendationsSubtitle =>
      'Based on your spending last month, we have some recommendations to adjust your categories.';

  @override
  String get viewSuggestions => 'View Suggestions';

  @override
  String get recommendationDialogTitle => 'Adjustment Recommendations';

  @override
  String get applySelected => 'Apply Selected';

  @override
  String get currentBudget => 'Current Budget';

  @override
  String get newBudget => 'New Budget';

  @override
  String get totalBudgetChange => 'Total Budget Change';

  @override
  String increaseTo(String amount) {
    return 'Increase to $amount';
  }

  @override
  String decreaseTo(String amount) {
    return 'Decrease to $amount';
  }
}
