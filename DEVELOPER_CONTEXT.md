# 🧠 Billince: Contexto de Desarrollo y Snapshot del Proyecto

Este archivo sirve como memoria técnica y manual de identidad para Billince. Su objetivo es optimizar la carga de contexto para el asistente de IA y asegurar la continuidad del desarrollo sin redundancias.

---

## 💎 Identidad de Marca y Branding
*   **Nombre:** Billince (Fusión de *Bill* -factura- y *Lince* -animal de visión aguda-).
*   **Concepto:** Visión experta y precisión en las finanzas personales.
*   **Moneda por defecto:** `€` (Euro). Configurable en la WelcomeScreen (€, $, £). La moneda del usuario autenticado se carga desde `user_settings` en Supabase. Se usa `AppData.currency` en TODA la app.
*   **Paleta de Colores (Lynx Palette):**
    *   **Primario (Midnight Blue):** `#0F172A` (Elegancia y seguridad).
    *   **Acento (Amber/Lynx Eye):** `#F59E0B` (Agudeza visual y llamadas a la acción).
    *   **Éxito (Emerald):** `#10B981` (Saldos positivos y confirmaciones).
    *   **Fondo/Soft (Cream Amber):** `#FEF3C7` (Superficies secundarias y AppBars).
*   **Iconografía:** El logo principal es un **ojo de lince** minimalista.

---

## 🔄 Flujo Principal de la Aplicación

```
1. BIENVENIDA Y AUTENTICACIÓN
   → WelcomeScreen: El usuario selecciona su moneda
   → Puede iniciar sesión (Email/contraseña) o registrarse
   → Tras login: se cargan ajustes del usuario y datos de Supabase
   → Opción: Continuar sin sesión (datos volátiles, sin escaneo IA)

2. LISTA DE LA COMPRA
   → El usuario crea una lista antes de ir a comprar
   → Añade productos (manualmente, escaneando foto, o desde galería)
   → En el supermercado, va tachando los productos que compra
   → ⚠️ NO se registra ningún importe aquí. Es solo un checklist.

3. GESTIÓN DE GASTOS
   → Tras la compra, el usuario escanea el TICKET con la cámara o galería
   → La IA (Gemini multimodal) extrae: nombre del comercio + importe TOTAL + lista de productos
   → El gasto se guarda automáticamente en Supabase (tabla expenses)
   → Los productos del ticket se crean como nueva ShoppingList en Supabase (items con is_done=true)
   → Si la IA no detecta el total, se abre formulario manual pre-rellenado
   → También se pueden añadir gastos manuales sin ticket

4. RESUMEN Y GRÁFICOS
   → Lee de AppData.expenses (cargados desde Supabase al iniciar sesión)
   → Muestra: total acumulado, media, nº transacciones
   → Desglose por categorías con barras + últimos gastos

5. ANÁLISIS DE COMPRAS (Shopping Insights)
   → Lee de AppData.shoppingLists (cargados desde Supabase)
   → Muestra: productos más repetidos, día favorito, tasa de completado
   → Gráfico de distribución semanal
   → IA Advisor da consejos basados en patrones de comportamiento
```

---

## 🤖 Integración con IA (Google Gemini)

### ¿Qué modelo se usa?
- **Modelo:** `gemini-flash-latest` — Apunta automáticamente al modelo Flash más reciente disponible, evitando errores por modelos obsoletos.
- **Librería:** `google_generative_ai: ^0.4.7`
- **Clave:** Cargada desde `.env` mediante `flutter_dotenv`. Variable: `GEMINI_API_KEY`. **Nunca hardcodeada en código fuente.**

### ¿Cuándo y cómo se usa la IA?

| Módulo | Trigger | Prompt | Output |
|---|---|---|---|
| **Gestión de Gastos** | Botón "Escanear ticket" (cámara/galería) | Extrae `storeName`, `totalAmount` y `items[]` del ticket | JSON → gasto + lista de compra en Supabase |
| **Lista de la Compra** | Botón "Escanear lista" (cámara/galería) | Extrae nombres de productos de una lista escrita | Array JSON → items del checklist |

### Flujo técnico del escaneo de ticket:
```
1. Usuario pulsa "Escanear ticket"
2. image_picker abre cámara o galería
3. La imagen se convierte a bytes (Uint8List)
4. Se construye un Content multimodal: [TextPart(prompt), DataPart('image/jpeg', bytes)]
5. GenerativeModel.generateContent() llama a la API de Gemini
6. La respuesta viene en texto → se limpia de markdown y se parsea como JSON
7. Si totalAmount > 0:
   - SupabaseRepository.addExpense() → guarda en tabla `expenses`
   - SupabaseRepository.createShoppingListWithItems() → guarda en tabla `shopping_lists` + `checklist_items`
8. setState() → refresca la UI
```

### ⚠️ Requisito de autenticación para IA
Las funciones de escaneo IA funcionan en modo anónimo con un fallback local, pero los datos NO persisten entre sesiones. **Sin iniciar sesión, el usuario pierde todos sus datos al cerrar la app.**

---

## 🗄️ Backend: Supabase

### Configuración
- **URL:** `https://dafpcatzleflcwhzndao.supabase.co`
- **Claves:** En `.env` (no en código fuente). Archivo `.env` en `.gitignore`.
- **Inicialización:** `main.dart` → `Supabase.initialize()` con valores de `dotenv`.

### Tablas PostgreSQL

| Tabla | Propósito | RLS |
|---|---|---|
| `user_settings` | Moneda y preferencias del usuario | `auth.uid() = id` |
| `expenses` | Gastos personales con módulo y adjunto | `auth.uid() = user_id` |
| `shopping_lists` | Cabecera de listas de la compra | `auth.uid() = user_id` |
| `checklist_items` | Ítems de cada lista (relación FK con CASCADE) | `auth.uid() = user_id` |

### Capa de datos: `SupabaseRepository`
Archivo: `lib/data/supabase_repository.dart`

| Método | Acción |
|---|---|
| `signIn(email, password)` | Login con email |
| `signUp(email, password)` | Registro de nuevo usuario |
| `signOut()` | Cierre de sesión |
| `loadUserSettings()` | Carga moneda del usuario desde BD |
| `loadInitialData()` | Carga expenses + shoppingLists del usuario |
| `addExpense(expense)` | Inserta gasto en Supabase o AppData (fallback) |
| `createShoppingListWithItems(title, items)` | Crea lista + items en Supabase o AppData (fallback) |

---

## 🛠️ Arquitectura Técnica (Flutter)

*   **Framework:** Flutter con Material 3.
*   **Estado Global:**
    *   **Datos de la App:** `lib/data/app_data.dart` — caché local de expenses, listas y eventos. Los datos se cargan desde Supabase al iniciar sesión.
    *   **Ajustes de Usuario:** `SettingsProvider` (paquete `provider`) con persistencia en `shared_preferences` para ajustes de UI (tema, accesibilidad). La moneda se sincroniza con Supabase.
*   **Seguridad:** API Keys en `.env` (excluido de Git). Sin secrets hardcodeados en el código.
*   **OCR / IA:** `google_generative_ai` + `image_picker`. Estrategia multimodal: imagen + prompt → JSON estructurado.
*   **Estructura de Carpetas:**
    *   `lib/models/`: `Expense`, `SharedGroup`, `ChecklistItem`, `ShoppingList`, `CalendarEvent`.
    *   `lib/screens/`: Vistas de la aplicación.
    *   `lib/data/`: `AppData` (caché), `SettingsProvider` (UI settings), `SupabaseRepository` (backend).

## 📱 Módulos Principales

| Módulo | Archivo | Propósito |
|---|---|---|
| **WelcomeScreen** | `welcome_screen.dart` | Auth (Login/Registro Email), selector de moneda, Ajustes y Accesibilidad |
| **Gestión de Gastos** | `expenses_screen.dart` | Escaneo IA de tickets, gastos manuales, categorías, adjuntos, persistencia Supabase |
| **Gastos Compartidos** | `shared_expenses_screen.dart` | Grupos/eventos con liquidación inteligente de deudas |
| **Lista de la Compra** | `checklist_screen.dart` → `shopping_list_detail_screen.dart` | Multi-lista checklist con escaneo IA, persistencia Supabase |
| **Análisis de Compras** | `shopping_insights_screen.dart` | IA Advisor, patrones, ranking de productos |
| **Resumen y Gráficos** | `summary_screen.dart` | Dashboard financiero con barras y últimos gastos |
| **Calendario y Eventos** | `calendar_screen.dart` | Agenda personal con calendario mensual y categorías |

---

## ♿ Accesibilidad y UX
*   **Modos de Daltonismo:** Protanopia, Deuteranopia, Tritanopia (`ColorFiltered` en `main.dart`).
*   **Tamaño de Texto:** Ajustable globalmente (1.0 a 1.5) con `textScaleFactor`.
*   **Temas:** Claro, Oscuro, Automático.
*   **Colores de Interfaz:** Personalización del color semilla del `ThemeData`.
*   **Botones:** Todos los botones de acción en AppBar llevan texto + icono para claridad.
*   **FABs:** En módulos de listas se usa un bottom sheet con opciones (manual / cámara / galería).
*   **Gestos:** Swipe para eliminar en listas, cards y eventos.
*   **Border Radius estándar:** 14px cards, 20px dialogs, 12px inputs.

---

## 🐙 Gestión de Repositorio (GitHub)
*   **Repositorio:** `https://github.com/macv97/Billince.git`
*   **Ramas:** `main` (producción) / `dev` (desarrollo activo).
*   **Compilación:** APK en `build/app/outputs/flutter-apk/app-release.apk`.

---

## 🚧 Estado Actual y Pendientes (Roadmap)

### ✅ Completado
- Integración Gemini API multimodal (modelo `gemini-flash-latest`)
- Supabase Auth con Email (Login/Registro + validación de errores amigable)
- Base de datos PostgreSQL con RLS (Row Level Security) por usuario
- Capa `SupabaseRepository` con CRUD de expenses y shopping lists
- Flujo de escaneo inteligente: ticket → gasto + lista productos en Supabase
- Seguridad: API Keys movidas a `.env`, excluido de Git
- Control de errores Auth: formato de email, contraseña corta, credenciales inválidas, etc.
- Toggle Login/Registro en un mismo modal

### 🔴 Pendiente (Prioridad Alta)
- **[UX]** Avisar al usuario en la WelcomeScreen que, si no inicia sesión, las funciones de escaneo con IA no podrán guardar datos entre sesiones y la información se perderá al cerrar la app.
- **[Auth]** Implementar Google Sign-In real (actualmente muestra snack "en desarrollo").
- **[Gastos]** Añadir soporte para actualización (UPDATE) de gastos en Supabase (actualmente solo en local).

### 🟡 Pendiente (Roadmap)
- **Clasificación Automática:** IA que categorice gastos según el nombre del comercio.
- **Widget de Escritorio:** Android/iOS Home Screen Widget para eventos y presupuesto diario.
- **Lince IA Predictivo:** Análisis avanzado para predecir quedarse sin saldo.
- **Gastos Compartidos:** Sincronización en tiempo real vía Supabase Realtime.
- **Edge Function Supabase:** Mover la llamada a Gemini al servidor para mayor seguridad (ocultar la API key del APK compilado).

---

**Nota para el Agente:** Priorizar siempre la paleta `#0F172A` y `#F59E0B`. Los ajustes globales se inyectan en `main.dart` mediante `ChangeNotifierProvider`. La moneda SIEMPRE debe leerse de `AppData.currency`, nunca hardcodear `$` o `€`. Al crear listas de la compra, SIEMPRE incluir `dateCreated`. Los datos de Supabase se cargan en AppData al login; AppData actúa como caché local.
