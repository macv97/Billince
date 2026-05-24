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
   → WelcomeScreen: El usuario selecciona su moneda
   → Puede iniciar sesión (Email/contraseña) o registrarse con validación avanzada de errores
   → Tras login: se cargan ajustes del usuario y datos de Supabase
   → Opción: Continuar sin sesión (datos volátiles, funciones de IA deshabilitadas)

2. LISTA DE LA COMPRA
   → El usuario crea una lista antes de ir a comprar.
   → Añade productos manualmente o escaneando una foto de una lista escrita (100% Offline-First mediante OCR local).
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
| `signOut()` | Cierre de sesión del cliente de Supabase |
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
| **WelcomeScreen** | `welcome_screen.dart` | Auth (Login/Registro Email), selector de moneda global, Ajustes y Accesibilidad. Permite usar toda la app sin registrarse. |
| **Gestión de Gastos** | `expenses_screen.dart` | Escaneo local de tickets (ML Kit), gastos manuales, categorías, selección rápida por carrusel de burbujas, persistencia SQLite y backup Supabase. |
| **Gastos Compartidos** | `shared_expenses_screen.dart` | Grupos/eventos colaborativos con liquidación inteligente de deudas. |
| **Lista de la Compra** | `checklist_screen.dart` → `shopping_list_detail_screen.dart` | Multi-lista checklist con escaneo local de listas escritas por OCR, persistencia SQLite y backup Supabase. |
| **Análisis de Compras** | `shopping_insights_screen.dart` | Lince IA Advisor con consejos automáticos generados localmente analizando patrones semanales y de consumo. |
| **Resumen y Gráficos** | `summary_screen.dart` | Dashboard financiero con barras y desglose de gastos. |
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

## 🚧 Estado Actual y Pendientes (Roadmap)

### ✅ Completado
- **Escaneo 100% local y offline**: Google ML Kit y parseo geométrico local de tickets implementados con total fluidez.
- **Carrusel Burbuja UX**: Selección y corrección instantánea de importes detectados en el ticket.
- **Persistencia SQLite**: `LocalDatabase` almacena localmente gastos, listas de compra y checklist items.
- **Sincronización híbrida a la nube**: Backup automático en Supabase de gastos y listas si la sesión está iniciada.
- **Análisis de Compras Local**: Lince IA Advisor integrado con generación local de recomendaciones sobre hábitos financieros.
- **Supabase Auth**: Soporte completo para inicio de sesión y registro de cuentas de usuario mediante correo electrónico.

### ✅ Bugs Solucionados (Testeo Móvil)
- **[Auth]** **Registro de cuentas (`Sign Up`):** Se añadió validación en `welcome_screen` que requiere confirmación por email en vez de forzar entrada anónima.
- **[UI/UX]** **Problemas de Contraste/Visibilidad:** Corregido el color `primaryColor` a `Colors.amber` del botón de registro en modo oscuro.
- **[QR]** **Escaneo de QR inoperativo:** Implementado `mobile_scanner` con su pantalla nativa tanto en Checklists como en Eventos compartidos.
- **[Checklist]** **Identidad:** Resuelto mediante la llamada persistente de `_showIdentityDialog` y asignación correcta de `(Tú)`.
- **[Eventos]** **Identidad e Inmutabilidad en Eventos Compartidos:** Añadida inmutabilidad al botón de eliminar integrante si el usuario a eliminar es el mismo usuario (`isMe`).
- **[Eventos]** **Borrado Persistente:** Se implementó `leaveSharedGroup` en `SupabaseRepository` para eliminar la entrada en `group_members` en lugar de borrar solo la caché local.

### 🔴 Pendiente (Prioridad Alta)
- **[UX]** Finalizar el texto de aviso en la pantalla de inicio aclarando el modo offline/invitado e incentivar el inicio de sesión.
- **[Auth]** Implementar Google Sign-In real.
- **[Auth]** Integrar inicio de sesión biométrico / huella dactilar tras la primera autenticación.
- **[UX]** Activar funcionalidad completa en el botón "Mi Perfil" al iniciar la aplicación.
- **[Branding]** Homologar el icono de lanzamiento de la app (launcher icon) en dispositivos con el logo circular del ojo de lince de la UI.
- **[Gastos]** Soporte para actualización (UPDATE) de gastos en Supabase (actualmente solo en local).

### 🟡 Pendiente (Roadmap)
- **Clasificación Automática:** IA que categorice gastos según el nombre del comercio.
- **Widget de Escritorio:** Android/iOS Home Screen Widget para eventos y presupuesto diario.
- **Lince IA Predictivo:** Análisis avanzado para predecir quedarse sin saldo.
- **Gastos Compartidos:** Sincronización en tiempo real vía Supabase Realtime.
