# 🧠 Billince: Contexto de Desarrollo y Snapshot del Proyecto

Este archivo sirve como memoria técnica y manual de identidad para Billince. Su objetivo es optimizar la carga de contexto para el asistente de IA y asegurar la continuidad del desarrollo sin redundancias.

---

## 🛠️ Metodología de Trabajo y Filosofía de Desarrollo (UX & Arquitectura)
Como desarrollador principal de aplicaciones móviles con enfoque experto en **Arquitectura de Software** y **Experiencia de Usuario (UX)**, todo trabajo realizado en Billince debe regirse por los siguientes pilares:

1. **Entendimiento Absoluto del Flujo de Negocio**: Antes de tocar una sola línea de código para cualquier funcionalidad, el agente debe comprender el ciclo de vida de los datos, el estado global (`AppData`, `SettingsProvider`), y cómo impacta el cambio a los módulos relacionados. No se permite programar de forma aislada.
2. **UX Fluida y Resiliencia en Casos de Uso**: Queda estrictamente prohibido introducir flujos que provoquen un bloqueo ("parón") o confusión en la experiencia de usuario. 
   - Cualquier pantalla debe manejar estados de carga (`CircularProgressIndicator`), estados vacíos informativos (`empty states` ilustrados) y capturas controladas de excepciones con mensajes amigables al usuario (nada de errores técnicos crudos o pantallas congeladas).
   - Ante fallos de conexión (como límites de cuota de IA superados o desconexión de red), la app debe responder de manera elegante con un fallback inmediato (ej. permitir entrada manual o datos locales autogenerados) sin interrumpir la experiencia de usuario.
3. **Robustez Arquitectónica (Clean Code)**: Separación clara entre la UI (Widgets), lógica de estado (Providers/Stateful) y la capa de acceso a datos (`SupabaseRepository`, `AppData`). Evitar mezclar lógica de negocio directamente en los métodos `build`.

---

## 💎 Identidad de Marca y Branding
*   **Nombre:** Billince (Fusión de *Bill* -factura- y *Lince* -animal de visión aguda-).
*   **Concepto:** Visión experta y precisión en las finanzas personales.
*   **Moneda por defecto:** `€` (Euro). Configurable en la WelcomeScreen (€, $, £). La moneda del usuario autenticado se carga desde `user_settings` en Supabase. Se usa `AppData.currency` en TODA la app.
*   **Paleta de Colores (Elegancia y Tecnología):**
    *   **Fondo (Midnight Blue):** `#0F172A` (Superficie principal y fondo).
    *   **Tarjetas/Superficie (Slate Blue):** `#1E293B` (Tarjetas y menús).
    *   **Texto Principal (Ice White):** `#F8FAFC` (Títulos y texto primario).
    *   **Texto Secundario (Blue Grey):** `#94A3B8` (Párrafos y subtítulos).
    *   **Acento Interactivo (Cyan/Amber):** `#38BDF8` (Cian brillante) y `#F59E0B` (Amber).
    *   **Éxito (Emerald):** `#10B981` (Saldos positivos y confirmaciones).
*   **Iconografía:** El logo principal es un **ojo de lince** minimalista.

---

## 🔄 Flujo Principal de la Aplicación

```
1. BIENVENIDA Y AUTENTICACIÓN
   → WelcomeScreen: El usuario selecciona su moneda global.
   → Autenticación Múltiple: Puede iniciar sesión/registrarse mediante Email y Contraseña o con Google Sign-In (Integración Nativa).
   → Protección de Privacidad: Soporte para Biometría (Huella Dactilar/FaceID) como capa de seguridad al arrancar la app si se configura en ajustes.
   → Tras login: se cargan ajustes del usuario y datos de Supabase.
   → Opción: Continuar sin sesión (datos volátiles, funciones colaborativas y backup nube deshabilitadas).

2. LISTA DE LA COMPRA
   → El usuario crea una lista antes de ir a comprar (personal o compartida).
   → Añade productos manualmente o escaneando una foto de una lista escrita (100% Offline-First mediante OCR local, incluyendo paso de recorte interactivo con image_cropper para mayor precisión).
   → En el supermercado, va tachando los productos que compra.
   → ⚠️ NO se registra ningún importe aquí. Es solo un checklist.

3. GESTIÓN DE GASTOS
   → Tras la compra, el usuario escanea el TICKET con la cámara o galería (100% Offline-First, no requiere internet).
   → El motor local `TicketScanner` (Google ML Kit + Algoritmo geométrico) extrae: comercio, importe TOTAL y productos.
   → El gasto se guarda localmente en SQLite y, si hay sesión iniciada, se respalda en Supabase (tabla user_expenses).
   → Los productos del ticket se pueden añadir automáticamente como una ShoppingList en SQLite/Supabase.
   → Si el escaneo automático no es seguro, se presenta un carrusel de burbujas interactivas con todos los importes detectados en el ticket para corrección instantánea con un toque.
   → También se pueden añadir gastos manuales sin ticket.

4. RESUMEN Y GRÁFICOS
   → Lee de `LocalDatabase` / `AppData.expenses`.
   │ Muestra: total acumulado, media, nº transacciones.
   └→ Desglose por categorías con barras + últimos gastos.

5. ANÁLISIS DE COMPRAS (Shopping Insights)
   → Lee de `LocalDatabase` / `AppData.shoppingLists`.
   → Muestra: productos más repetidos, día favorito, tasa de completado y gráfico de distribución semanal.
   └→ Lince IA Advisor (Análisis Local): Genera consejos de compra automatizados directamente en el dispositivo analizando estadísticas y comportamiento del usuario, sin consumir APIs externas.
```

---

## 🤖 Inteligencia On-Device y Visión Local (Offline-First Architecture)

### ¿Cómo funciona el escaneo y reconocimiento?
*   **Motor Local:** Google ML Kit Text Recognition (`google_mlkit_text_recognition`).
*   **Algoritmo Espacial y NLP Local:** `TicketScanner` (en `lib/services/ticket_scanner.dart`) procesa la geometría de los bloques de texto (Bounding Boxes), agrupándolos por líneas horizontales para relacionar productos y precios, aplicando expresiones regulares defensivas y lógica difusa.
*   **UX de Selección Rápida (Bubble Carousel):** En lugar de depender de llamadas lentas a la nube, la app extrae todos los posibles precios del ticket y los presenta en burbujas. Si el importe total detectado automáticamente no es el deseado, el usuario lo corrige seleccionando la burbuja correcta de un toque.
*   **Privacidad y Rendimiento:** Cero APIs en la nube para procesamiento de imagen o texto. Todo el escaneo se ejecuta 100% de manera local y con latencia cero en el dispositivo. No se requiere inicio de sesión para escanear tickets ni listas.

---

## 🗄️ Backend: Supabase

### Configuración
- **URL:** `https://dafpcatzleflcwhzndao.supabase.co`
- **Claves:** En `.env` del cliente (`SUPABASE_URL`, `SUPABASE_ANON_KEY`).
- **Edge Function:** `gemini-proxy` desplegada y configurada en producción.

### Tablas PostgreSQL

| Tabla | Propósito | RLS |
|---|---|---|
| `user_settings` | Moneda y preferencias del usuario | `auth.uid() = id` |
| `expenses` | Gastos personales con módulo y adjunto | `auth.uid() = user_id` |
| `shopping_lists` | Cabecera de listas de la compra | `auth.uid() = user_id` |
| `checklist_items` | Ítems de cada lista (relación FK con CASCADE) | `auth.uid() = user_id` |

### Capa de datos y Backup: `SupabaseRepository`
Archivo: `lib/data/supabase_repository.dart`

| Método | Acción |
|---|---|
| `signIn(email, password)` | Login con email |
| `signUp(email, password)` | Registro de nuevo usuario |
| `signInWithGoogle()` | Inicio de sesión OAuth con Google Sign-In |
| `signOut()` | Cierre de sesión del cliente de Supabase |
| `deleteUserAccount()` | Ejecuta el RPC `delete_user_account` asegurando borrado en cascada |
| `joinSharedGroup(groupId)` | Une al usuario actual a un grupo compartido mediante su UUID |
| `syncExpense(expense)` | Sincroniza gasto personal en la tabla `user_expenses` si está autenticado |
| `deleteExpense(expenseId)` | Elimina el gasto en el backup de Supabase si está autenticado |
| `fetchUserExpenses()` | Carga los gastos respaldados en la nube para poblar la app local |
| `syncShoppingList(list)` | Respalda la lista y sus ítems en la nube si está autenticado |
| `deleteShoppingList(listId)` | Elimina la lista de la compra de la nube si está autenticado |
| `fetchUserShoppingLists()` | Carga las listas de la compra respaldadas en la nube |
| `syncSharedExpense(expense, groupId)` | Sincroniza los gastos de grupos colaborativos en la nube |

---

## 🛠️ Arquitectura Técnica (Flutter)

*   **Framework:** Flutter con Material 3.
*   **Estado Global:**
    *   **Datos de la App:** `lib/data/app_data.dart` — caché local de expenses, listas y eventos. Los datos se cargan desde Supabase al iniciar sesión.
    *   **Ajustes de Usuario:** `SettingsProvider` (paquete `provider`) con persistencia en `shared_preferences` para ajustes de UI (tema, accesibilidad). La moneda se sincroniza con Supabase.
*   **Seguridad:** Eliminados todos los SDKs e integraciones directas con Gemini en el cliente. Cero secretos de IA expuestos.
*   **Estructura de Carpetas:**
    *   `lib/models/`: `Expense`, `SharedGroup`, `ChecklistItem`, `ShoppingList`, `CalendarEvent`.
    *   `lib/screens/`: Vistas de la aplicación.
    *   `lib/data/`: `AppData` (caché), `SettingsProvider` (UI settings), `SupabaseRepository` (backend).
    *   `supabase/functions/gemini-proxy/`: Código fuente de la Edge Function en Deno TypeScript.

---

## 📱 Módulos Principales

| Módulo | Archivo | Propósito |
|---|---|---|
| **WelcomeScreen** | `welcome_screen.dart` | Auth (Login/Registro Email y Google), selector de moneda global, Ajustes y Accesibilidad. Permite usar toda la app sin registrarse. |
| **Gestión de Gastos** | `expenses_screen.dart` | Escaneo local de tickets (ML Kit), gastos manuales, categorías, selección rápida por carrusel de burbujas, persistencia SQLite y backup Supabase. |
| **Gastos Compartidos** | `shared_expenses_screen.dart` | Grupos/eventos colaborativos con liquidación inteligente de deudas. |
| **Lista de la Compra** | `checklist_screen.dart`, `shopping_list_detail_screen.dart`, `shared_checklist_detail_screen.dart` | Multi-lista checklist (personal y compartida) con escaneo local por OCR + image_cropper, persistencia SQLite y backup Supabase. |
| **Análisis de Compras** | `shopping_insights_screen.dart` | Lince IA Advisor con consejos automáticos generados localmente analizando patrones semanales y de consumo. |
| **Resumen y Gráficos** | `summary_screen.dart` y `main_menu_screen.dart` | Dashboard financiero con barras, desglose de gastos y navegación vertical moderna de tarjetas anchas. |
| **Calendario y Eventos** | `calendar_screen.dart` | Agenda personal con calendario mensual y categorías. |

---

## ♿ Accesibilidad y UX
*   **Modos de Daltonismo:** Protanopia, Deuteranopia, Tritanopia (`ColorFiltered` en `main.dart`).
*   **Tamaño de Texto:** Ajustable globalmente (1.0 a 1.5) con `textScaleFactor`.
*   **Temas:** Claro, Oscuro, Automático.
*   **Colores de Interfaz:** Personalización del color semilla del `ThemeData`.
*   **FABs:** En módulos de listas se usa un bottom sheet con opciones (manual / cámara / galería).
*   **Gestos:** Swipe para eliminar en listas, cards y eventos.
*   **Border Radius estándar:** 14px cards, 20px dialogs, 12px inputs.

---

## 🐙 Gestión de Repositorio (GitHub)
*   **Repositorio:** `https://github.com/macv97/Billince.git`
*   **Ramas:** `main` (producción) / `dev` (desarrollo activo).
*   **Compilación:** APK en `build/app/outputs/flutter-apk/app-release.apk`.

---

## 🚧 Estado Actual y Gestión de Tareas (Linear Lifecycle Workflow)

La gestión de tareas y el roadmap activo se sincronizan y administran de forma dinámica a través de **Linear** (Team Key: `BIL`) como única fuente de verdad.

### 📋 Regla Estricta de Desarrollo y Ciclo de Vida de Tareas
1. **Detección de Tareas:** El asistente de IA leerá activamente las tareas ubicadas en la columna **TODO** de Linear. **Únicamente** se deben implementar las tareas que el usuario mueva o asigne a la columna **TODO**. Las tareas en *Backlog* quedan en espera hasta ser priorizadas por el usuario.
2. **Lectura Detallada de Tarjetas (Comentarios y Adjuntos):** Al iniciar cualquier tarea en **TODO**, el asistente debe inspeccionar obligatoriamente el interior de la tarjeta en Linear para comprobar si contiene comentarios, enlaces o imágenes que describan detalladamente la funcionalidad a implementar o el error a solucionar.
3. **Ciclo de Vida Automatizado (Movimiento de Columnas):**
   - **In Progress:** Al iniciar el desarrollo de una tarea de la columna **TODO**, el asistente debe actualizar inmediatamente su estado en Linear a **In Progress** (`6c379fe3-2259-4e6d-bdb8-c000b3cb9826`).
   - **In Review:** Tras completar la implementación y pasar con éxito los tests/QA ("Dry-Run mental"), el asistente debe actualizar su estado en Linear a **In Review** (`1dd5016a-78d3-4609-acee-d5208d979fe3`) para que el usuario la valide.
4. **Tablero Local:** La vista Kanban en `linear_board.md` debe regenerarse con el script `linear_generate_board.py` para reflejar el estado real de Linear.

