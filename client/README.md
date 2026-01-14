# Keda App

Una aplicación de Flutter para la gestión de finanzas familiares, centrada en el seguimiento de presupuestos y gastos diarios.

## 📋 Requisitos

*   **Flutter SDK**: `^3.10.7`
*   **Plataformas Soportadas**:
    *   **Web**: Requiere soporte de WebAssembly para SQLite (`sqlite3.wasm`).
    *   **Móvil/Desktop**: Soporte nativo a través de `sqlite3_flutter_libs`.
*   **Dependencias Clave**:
    *   `flutter_riverpod`: Gestión de estado.
    *   `go_router`: Navegación.
    *   `drift`: Base de datos local (SQLite).
    *   `json_serializable`: Serialización de modelos.

## ✅ Implementado (Lo que se hizo)

### 1. Arquitectura y Configuración
*   Inicialización del proyecto Flutter con estructura de carpetas organizada (`lib/models`, `lib/repositories`, `lib/providers`, `lib/views`).
*   Configuración de **Riverpod** para la inyección de dependencias y gestión de estado reactiva.
*   Configuración de **GoRouter** para el manejo de rutas y redirecciones (login guard).

### 2. Base de Datos Local (Drift)
*   **Persistencia Multiplataforma**:
    *   Implementación de `LocalRepository` usando **Drift**.
    *   Soporte para **Nativo** (iOS/Android/Desktop) usando `NativeDatabase`.
    *   Soporte para **Web** usando `WasmDatabase` (IndexedDB sobre OPFS) para una persistencia robusta.
*   **Esquema de Datos**:
    *   Tablas definidas para `Categories`, `FinanceAccounts` y `Expenses`.
    *   Lógica de **Seeding** para poblar la base de datos inicial si está vacía.

### 3. Interfaz de Usuario (MVP)
*   **Pantalla de Login**: Simulación de autenticación (Google Sign-In visual).
*   **Pantalla Principal (Home)**:
    *   Visualización de categorías con su presupuesto mensual.
    *   Cálculo en tiempo real del "Restante" (Presupuesto - Gastos).
*   **Pantalla de Nuevo Gasto**:
    *   Formulario optimizado para ingreso rápido.
    *   Selección automática de cuenta por defecto.
    *   Guardado asíncrono en base de datos local.

### 4. Lógica de Negocio
*   `ExpensesNotifier`: Gestión reactiva de la lista de gastos.
*   Cálculo dinámico de totales por categoría.

## 🚧 Falta (Pendiente)

### 1. Gestión de Datos (CRUD)
*   **Categorías**: UI para crear, editar y eliminar categorías (actualmente solo se leen o se crean por seed).
*   **Cuentas**: UI para gestionar cuentas bancarias o efectivo.
*   **Hogares (Households)**: Implementar la lógica para múltiples grupos familiares.

### 2. Visualización
*   **Historial de Gastos**: Una pantalla dedicada para ver la lista completa de gastos con filtros por fecha y categoría.
*   **Gráficos**: Visualización gráfica del consumo del presupuesto.

### 3. Mejoras Técnicas y Polish
*   **Manejo de Errores UX**: Mostrar mensajes amigables al usuario cuando fallan operaciones de base de datos.
*   **Animaciones**: Mejorar la experiencia de usuario con transiciones suaves.
*   **Sincronización Remota**: (Futuro) Sincronizar datos con un backend real (Firebase/Supabase).
*   **Tests**: Añadir tests unitarios y de widgets para flujos críticos.

## 🛠 Instalación y Ejecución

1.  **Instalar dependencias**:
    ```bash
    flutter pub get
    ```

2.  **Generar código (Drift/Json)**:
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```

3.  **Ejecutar en Web (con configuración de puertos para WASM)**:
    ```bash
    flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0
    ```
    *Nota: Asegúrate de que `web/sqlite3.wasm` y `web/drift_worker.js` estén presentes.*
