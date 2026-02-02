// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get settings => 'Configuración';

  @override
  String get language => 'Idioma';

  @override
  String get spanish => 'Español';

  @override
  String get english => 'Inglés';

  @override
  String get logout => 'Cerrar Sesión';

  @override
  String get versionInfo => 'Información de Versión';

  @override
  String get clientVersion => 'Version Cliente';

  @override
  String get serverVersion => 'Versión Servidor';

  @override
  String get loading => 'Cargando...';

  @override
  String get error => 'Error';

  @override
  String get home => 'Inicio';

  @override
  String get accounts => 'Cuentas';

  @override
  String get members => 'Miembros';

  @override
  String get expenses => 'Gastos';

  @override
  String get noExpenses => 'No hay gastos recientes';

  @override
  String get addExpense => 'Agregar Gasto';

  @override
  String get systemDefault => 'Sistema';

  @override
  String get deleteCategory => 'Eliminar Categoría';

  @override
  String deleteCategoryConfirm(String name) {
    return '¿Estás seguro de que deseas eliminar \"$name\"?';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get viewDetail => 'Ver Detalle';

  @override
  String get edit => 'Editar';

  @override
  String get allExpenses => 'Todos los Gastos';

  @override
  String get noExpensesThisMonth => 'No hay gastos este mes';

  @override
  String get noNote => 'Sin nota';

  @override
  String createdBy(String name) {
    return 'Creado por: $name';
  }

  @override
  String get errorLoadingCategories => 'Error cargando categorías';

  @override
  String get errorLoadingAccounts => 'Error cargando cuentas';

  @override
  String get errorLoadingExpenses => 'Error cargando gastos';

  @override
  String get pleaseSelectAccount => 'Por favor selecciona una cuenta';

  @override
  String get categoryNotFound => 'Categoría no encontrada';

  @override
  String remaining(String amount) {
    return 'QUEDAN $amount';
  }

  @override
  String get amount => 'MONTO';

  @override
  String get enterAmount => 'Ingresa un monto';

  @override
  String get invalidAmount => 'Monto inválido';

  @override
  String get account => 'CUENTA';

  @override
  String get addNewAccount => 'Añadir nueva cuenta...';

  @override
  String get noAccountsCreated => 'No tienes cuentas creadas.';

  @override
  String get createFirstAccount => 'Crear mi primera cuenta';

  @override
  String get noteOptional => 'NOTA (OPCIONAL)';

  @override
  String get saveExpense => 'GUARDAR GASTO';

  @override
  String get selectAnAccount => 'Selecciona una cuenta';

  @override
  String get manageAccounts => 'Administrar Cuentas';

  @override
  String get card => 'Tarjeta';

  @override
  String get bankAccount => 'Cuenta Bancaria';

  @override
  String get cash => 'Efectivo';

  @override
  String get deleteAccount => 'Eliminar Cuenta';

  @override
  String deleteAccountConfirm(String name) {
    return '¿Deseas eliminar la cuenta \"$name\"?';
  }

  @override
  String get editAccount => 'Editar Cuenta';

  @override
  String get newAccount => 'Nueva Cuenta';

  @override
  String get type => 'Tipo';

  @override
  String get brand => 'Marca';

  @override
  String get bank => 'Banco';

  @override
  String get accountName => 'Nombre de la cuenta';

  @override
  String get enterBank => 'Ingresa el banco';

  @override
  String get enterName => 'Ingresa el nombre';

  @override
  String get save => 'GUARDAR';

  @override
  String get accountNotFound => 'Cuenta no encontrada';

  @override
  String saveError(String error) {
    return 'Error al guardar: $error';
  }

  @override
  String get removeMember => 'Eliminar Miembro';

  @override
  String removeMemberConfirm(String name) {
    return '¿Estás seguro de que quieres eliminar a $name del hogar?';
  }

  @override
  String get memberRemoved => 'Miembro eliminado';

  @override
  String get inviteLinkCopied => 'Enlace de invitación copiado al portapapeles';

  @override
  String get inviteMember => 'Invitar Miembro';

  @override
  String get invitationSent => 'Invitación enviada con éxito';

  @override
  String get invitePending => 'Este usuario ya tiene una invitación pendiente';

  @override
  String inviteError(String error) {
    return 'Error al enviar invitación: $error';
  }

  @override
  String get send => 'Enviar';

  @override
  String get householdMembers => 'Miembros del Hogar';

  @override
  String get inviteTooltip => 'Invitar';

  @override
  String get youSuffix => ' (Tú)';

  @override
  String get pendingSuffix => ' (Pendiente)';

  @override
  String get copyLinkTooltip => 'Copiar enlace';

  @override
  String get categorySaved => 'Categoría guardada exitosamente';

  @override
  String get editCategory => 'Editar Categoría';

  @override
  String get newCategory => 'Nueva Categoría';

  @override
  String get name => 'Nombre';

  @override
  String get monthlyBudget => 'Presupuesto Mensual';

  @override
  String get enterNamePlease => 'Por favor ingresa un nombre';

  @override
  String get enterBudgetPlease => 'Por favor ingresa un presupuesto';

  @override
  String get invalidNumber => 'Ingresa un número válido';

  @override
  String errorWithDetails(String error) {
    return 'Error: $error';
  }

  @override
  String errorInitializingGoogleSignIn(String error) {
    return 'Error al inicializar Google Sign In: $error';
  }

  @override
  String get historyThisMonth => 'Historial (Este mes)';

  @override
  String get unknownAccount => 'Cuenta desconocida';

  @override
  String get budget => 'Presupuesto';

  @override
  String get spent => 'Gastado';

  @override
  String get remainingLabel => 'Restante';

  @override
  String exceededBy(String amount) {
    return 'EXCEDIDO POR $amount';
  }

  @override
  String get serverUrl => 'URL del Servidor';

  @override
  String get setServerUrl => 'Configurar URL del servidor';

  @override
  String get serverUrlDescription =>
      'Esta es la URL del servidor que la aplicación usará para conectarse.';

  @override
  String get invalidUrl => 'URL no válida';

  @override
  String get date => 'FECHA';

  @override
  String get prevMonth => 'Mes anterior';

  @override
  String get nextMonth => 'Mes siguiente';
}
