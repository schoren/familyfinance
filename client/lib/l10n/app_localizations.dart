import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('es'),
  ];

  /// No description provided for @settings.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get language;

  /// No description provided for @spanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get spanish;

  /// No description provided for @english.
  ///
  /// In es, this message translates to:
  /// **'Inglés'**
  String get english;

  /// No description provided for @logout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar Sesión'**
  String get logout;

  /// No description provided for @versionInfo.
  ///
  /// In es, this message translates to:
  /// **'Información de Versión'**
  String get versionInfo;

  /// No description provided for @clientVersion.
  ///
  /// In es, this message translates to:
  /// **'Version Cliente'**
  String get clientVersion;

  /// No description provided for @serverVersion.
  ///
  /// In es, this message translates to:
  /// **'Versión Servidor'**
  String get serverVersion;

  /// No description provided for @loading.
  ///
  /// In es, this message translates to:
  /// **'Cargando...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In es, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @home.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get home;

  /// No description provided for @accounts.
  ///
  /// In es, this message translates to:
  /// **'Cuentas'**
  String get accounts;

  /// No description provided for @members.
  ///
  /// In es, this message translates to:
  /// **'Miembros'**
  String get members;

  /// No description provided for @expenses.
  ///
  /// In es, this message translates to:
  /// **'Gastos'**
  String get expenses;

  /// No description provided for @noExpenses.
  ///
  /// In es, this message translates to:
  /// **'No hay gastos recientes'**
  String get noExpenses;

  /// No description provided for @addExpense.
  ///
  /// In es, this message translates to:
  /// **'Agregar Gasto'**
  String get addExpense;

  /// No description provided for @categories.
  ///
  /// In es, this message translates to:
  /// **'Categorías'**
  String get categories;

  /// No description provided for @editExpense.
  ///
  /// In es, this message translates to:
  /// **'Editar Gasto'**
  String get editExpense;

  /// No description provided for @newExpense.
  ///
  /// In es, this message translates to:
  /// **'Nuevo Gasto'**
  String get newExpense;

  /// No description provided for @deleteExpense.
  ///
  /// In es, this message translates to:
  /// **'Eliminar Gasto'**
  String get deleteExpense;

  /// No description provided for @deleteExpenseConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas eliminar este gasto?'**
  String get deleteExpenseConfirm;

  /// No description provided for @updateExpense.
  ///
  /// In es, this message translates to:
  /// **'ACTUALIZAR GASTO'**
  String get updateExpense;

  /// No description provided for @systemDefault.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get systemDefault;

  /// No description provided for @deleteCategory.
  ///
  /// In es, this message translates to:
  /// **'Eliminar Categoría'**
  String get deleteCategory;

  /// No description provided for @deleteCategoryConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas eliminar \"{name}\"?'**
  String deleteCategoryConfirm(String name);

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get delete;

  /// No description provided for @viewDetail.
  ///
  /// In es, this message translates to:
  /// **'Ver Detalle'**
  String get viewDetail;

  /// No description provided for @edit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get edit;

  /// No description provided for @allExpenses.
  ///
  /// In es, this message translates to:
  /// **'Todos los Gastos'**
  String get allExpenses;

  /// No description provided for @noExpensesThisMonth.
  ///
  /// In es, this message translates to:
  /// **'No hay gastos este mes'**
  String get noExpensesThisMonth;

  /// No description provided for @noNote.
  ///
  /// In es, this message translates to:
  /// **'Sin nota'**
  String get noNote;

  /// No description provided for @createdBy.
  ///
  /// In es, this message translates to:
  /// **'Creado por: {name}'**
  String createdBy(String name);

  /// No description provided for @errorLoadingCategories.
  ///
  /// In es, this message translates to:
  /// **'Error cargando categorías'**
  String get errorLoadingCategories;

  /// No description provided for @errorLoadingAccounts.
  ///
  /// In es, this message translates to:
  /// **'Error cargando cuentas'**
  String get errorLoadingAccounts;

  /// No description provided for @errorLoadingExpenses.
  ///
  /// In es, this message translates to:
  /// **'Error cargando gastos'**
  String get errorLoadingExpenses;

  /// No description provided for @pleaseSelectAccount.
  ///
  /// In es, this message translates to:
  /// **'Por favor selecciona una cuenta'**
  String get pleaseSelectAccount;

  /// No description provided for @categoryNotFound.
  ///
  /// In es, this message translates to:
  /// **'Categoría no encontrada'**
  String get categoryNotFound;

  /// No description provided for @pleaseSelectCategory.
  ///
  /// In es, this message translates to:
  /// **'Por favor selecciona una categoría'**
  String get pleaseSelectCategory;

  /// No description provided for @remaining.
  ///
  /// In es, this message translates to:
  /// **'QUEDAN {amount}'**
  String remaining(String amount);

  /// No description provided for @amount.
  ///
  /// In es, this message translates to:
  /// **'MONTO'**
  String get amount;

  /// No description provided for @enterAmount.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un monto'**
  String get enterAmount;

  /// No description provided for @invalidAmount.
  ///
  /// In es, this message translates to:
  /// **'Monto inválido'**
  String get invalidAmount;

  /// No description provided for @account.
  ///
  /// In es, this message translates to:
  /// **'CUENTA'**
  String get account;

  /// No description provided for @addNewAccount.
  ///
  /// In es, this message translates to:
  /// **'Añadir nueva cuenta...'**
  String get addNewAccount;

  /// No description provided for @noAccountsCreated.
  ///
  /// In es, this message translates to:
  /// **'No tienes cuentas creadas.'**
  String get noAccountsCreated;

  /// No description provided for @createFirstAccount.
  ///
  /// In es, this message translates to:
  /// **'Crear mi primera cuenta'**
  String get createFirstAccount;

  /// No description provided for @noteOptional.
  ///
  /// In es, this message translates to:
  /// **'NOTA (OPCIONAL)'**
  String get noteOptional;

  /// No description provided for @saveExpense.
  ///
  /// In es, this message translates to:
  /// **'GUARDAR GASTO'**
  String get saveExpense;

  /// No description provided for @selectAnAccount.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una cuenta'**
  String get selectAnAccount;

  /// No description provided for @manageAccounts.
  ///
  /// In es, this message translates to:
  /// **'Administrar Cuentas'**
  String get manageAccounts;

  /// No description provided for @card.
  ///
  /// In es, this message translates to:
  /// **'Tarjeta'**
  String get card;

  /// No description provided for @bankAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta Bancaria'**
  String get bankAccount;

  /// No description provided for @cash.
  ///
  /// In es, this message translates to:
  /// **'Efectivo'**
  String get cash;

  /// No description provided for @deleteAccount.
  ///
  /// In es, this message translates to:
  /// **'Eliminar Cuenta'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Deseas eliminar la cuenta \"{name}\"?'**
  String deleteAccountConfirm(String name);

  /// No description provided for @editAccount.
  ///
  /// In es, this message translates to:
  /// **'Editar Cuenta'**
  String get editAccount;

  /// No description provided for @newAccount.
  ///
  /// In es, this message translates to:
  /// **'Nueva Cuenta'**
  String get newAccount;

  /// No description provided for @type.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get type;

  /// No description provided for @brand.
  ///
  /// In es, this message translates to:
  /// **'Marca'**
  String get brand;

  /// No description provided for @bank.
  ///
  /// In es, this message translates to:
  /// **'Banco'**
  String get bank;

  /// No description provided for @accountName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la cuenta'**
  String get accountName;

  /// No description provided for @enterBank.
  ///
  /// In es, this message translates to:
  /// **'Ingresa el banco'**
  String get enterBank;

  /// No description provided for @enterName.
  ///
  /// In es, this message translates to:
  /// **'Ingresa el nombre'**
  String get enterName;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'GUARDAR'**
  String get save;

  /// No description provided for @accountNotFound.
  ///
  /// In es, this message translates to:
  /// **'Cuenta no encontrada'**
  String get accountNotFound;

  /// No description provided for @saveError.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar: {error}'**
  String saveError(String error);

  /// No description provided for @removeMember.
  ///
  /// In es, this message translates to:
  /// **'Eliminar Miembro'**
  String get removeMember;

  /// No description provided for @removeMemberConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que quieres eliminar a {name} del hogar?'**
  String removeMemberConfirm(String name);

  /// No description provided for @memberRemoved.
  ///
  /// In es, this message translates to:
  /// **'Miembro eliminado'**
  String get memberRemoved;

  /// No description provided for @inviteLinkCopied.
  ///
  /// In es, this message translates to:
  /// **'Enlace de invitación copiado al portapapeles'**
  String get inviteLinkCopied;

  /// No description provided for @inviteMember.
  ///
  /// In es, this message translates to:
  /// **'Invitar Miembro'**
  String get inviteMember;

  /// No description provided for @invitationSent.
  ///
  /// In es, this message translates to:
  /// **'Invitación enviada con éxito'**
  String get invitationSent;

  /// No description provided for @invitePending.
  ///
  /// In es, this message translates to:
  /// **'Este usuario ya tiene una invitación pendiente'**
  String get invitePending;

  /// No description provided for @inviteError.
  ///
  /// In es, this message translates to:
  /// **'Error al enviar invitación: {error}'**
  String inviteError(String error);

  /// No description provided for @send.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get send;

  /// No description provided for @householdMembers.
  ///
  /// In es, this message translates to:
  /// **'Miembros del Hogar'**
  String get householdMembers;

  /// No description provided for @inviteTooltip.
  ///
  /// In es, this message translates to:
  /// **'Invitar'**
  String get inviteTooltip;

  /// No description provided for @youSuffix.
  ///
  /// In es, this message translates to:
  /// **' (Tú)'**
  String get youSuffix;

  /// No description provided for @pendingSuffix.
  ///
  /// In es, this message translates to:
  /// **' (Pendiente)'**
  String get pendingSuffix;

  /// No description provided for @copyLinkTooltip.
  ///
  /// In es, this message translates to:
  /// **'Copiar enlace'**
  String get copyLinkTooltip;

  /// No description provided for @categorySaved.
  ///
  /// In es, this message translates to:
  /// **'Categoría guardada exitosamente'**
  String get categorySaved;

  /// No description provided for @editCategory.
  ///
  /// In es, this message translates to:
  /// **'Editar Categoría'**
  String get editCategory;

  /// No description provided for @newCategory.
  ///
  /// In es, this message translates to:
  /// **'Nueva Categoría'**
  String get newCategory;

  /// No description provided for @name.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get name;

  /// No description provided for @monthlyBudget.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto Mensual'**
  String get monthlyBudget;

  /// No description provided for @enterNamePlease.
  ///
  /// In es, this message translates to:
  /// **'Por favor ingresa un nombre'**
  String get enterNamePlease;

  /// No description provided for @enterBudgetPlease.
  ///
  /// In es, this message translates to:
  /// **'Por favor ingresa un presupuesto'**
  String get enterBudgetPlease;

  /// No description provided for @invalidNumber.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un número válido'**
  String get invalidNumber;

  /// No description provided for @errorWithDetails.
  ///
  /// In es, this message translates to:
  /// **'Error: {error}'**
  String errorWithDetails(String error);

  /// No description provided for @errorInitializingGoogleSignIn.
  ///
  /// In es, this message translates to:
  /// **'Error al inicializar Google Sign In: {error}'**
  String errorInitializingGoogleSignIn(String error);

  /// No description provided for @historyThisMonth.
  ///
  /// In es, this message translates to:
  /// **'Historial (Este mes)'**
  String get historyThisMonth;

  /// No description provided for @unknownAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta desconocida'**
  String get unknownAccount;

  /// No description provided for @budget.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto'**
  String get budget;

  /// No description provided for @spent.
  ///
  /// In es, this message translates to:
  /// **'Gastado'**
  String get spent;

  /// No description provided for @remainingLabel.
  ///
  /// In es, this message translates to:
  /// **'Restante'**
  String get remainingLabel;

  /// No description provided for @exceededBy.
  ///
  /// In es, this message translates to:
  /// **'EXCEDIDO POR {amount}'**
  String exceededBy(String amount);

  /// No description provided for @serverUrl.
  ///
  /// In es, this message translates to:
  /// **'URL del Servidor'**
  String get serverUrl;

  /// No description provided for @setServerUrl.
  ///
  /// In es, this message translates to:
  /// **'Configurar URL del servidor'**
  String get setServerUrl;

  /// No description provided for @serverUrlDescription.
  ///
  /// In es, this message translates to:
  /// **'Esta es la URL del servidor que la aplicación usará para conectarse.'**
  String get serverUrlDescription;

  /// No description provided for @invalidUrl.
  ///
  /// In es, this message translates to:
  /// **'URL no válida'**
  String get invalidUrl;

  /// No description provided for @date.
  ///
  /// In es, this message translates to:
  /// **'FECHA'**
  String get date;

  /// No description provided for @prevMonth.
  ///
  /// In es, this message translates to:
  /// **'Mes anterior'**
  String get prevMonth;

  /// No description provided for @nextMonth.
  ///
  /// In es, this message translates to:
  /// **'Mes siguiente'**
  String get nextMonth;

  /// No description provided for @recommendationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Sugerencias de Presupuesto'**
  String get recommendationsTitle;

  /// No description provided for @recommendationsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Basado en tus gastos del mes pasado, tenemos algunas recomendaciones para ajustar tus categorías.'**
  String get recommendationsSubtitle;

  /// No description provided for @viewSuggestions.
  ///
  /// In es, this message translates to:
  /// **'Ver Sugerencias'**
  String get viewSuggestions;

  /// No description provided for @recommendationDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Recomendaciones de Ajuste'**
  String get recommendationDialogTitle;

  /// No description provided for @applySelected.
  ///
  /// In es, this message translates to:
  /// **'Aplicar Seleccionados'**
  String get applySelected;

  /// No description provided for @currentBudget.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto Actual'**
  String get currentBudget;

  /// No description provided for @newBudget.
  ///
  /// In es, this message translates to:
  /// **'Nuevo Presupuesto'**
  String get newBudget;

  /// No description provided for @totalBudgetChange.
  ///
  /// In es, this message translates to:
  /// **'Cambio Total de Presupuesto'**
  String get totalBudgetChange;

  /// No description provided for @increaseTo.
  ///
  /// In es, this message translates to:
  /// **'Aumentar a {amount}'**
  String increaseTo(String amount);

  /// No description provided for @decreaseTo.
  ///
  /// In es, this message translates to:
  /// **'Disminuir a {amount}'**
  String decreaseTo(String amount);

  /// No description provided for @addDetails.
  ///
  /// In es, this message translates to:
  /// **'AGREGAR DETALLES'**
  String get addDetails;

  /// No description provided for @chooseAccount.
  ///
  /// In es, this message translates to:
  /// **'ELEGIR CUENTA'**
  String get chooseAccount;

  /// No description provided for @nextStep.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get nextStep;

  /// No description provided for @prevStep.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get prevStep;

  /// No description provided for @stepXofY.
  ///
  /// In es, this message translates to:
  /// **'Paso {current} de {total}'**
  String stepXofY(Object current, Object total);

  /// No description provided for @addNote.
  ///
  /// In es, this message translates to:
  /// **'Agrega una nota...'**
  String get addNote;
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
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
