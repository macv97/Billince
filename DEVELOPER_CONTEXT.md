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
   → Puede iniciar sesión (Email/contraseña) o registrarse con validación avanzada de errores
   → Tras login: se cargan ajustes del usuario y datos de Supabase
   → Opción: Continuar sin sesión (datos volátiles, funciones de IA deshabilitadas)

2. LISTA DE LA COMPRA
   → El usuario crea una lista antes de ir a comprar
   → Añade productos manualmente o escaneando una foto con IA (requiere inicio de sesión)
   → En el supermercado, va tachando los productos que compra
   → ⚠️ NO se registra ningún importe aquí. Es solo un checklist.

3. GESTIÓN DE GASTOS
   → Tras la compra, el usuario escanea el TICKET con la cámara o galería (requiere inicio de sesión)
   → La IA (Gemini multimodal en el servidor) extrae: nombre del comercio + importe TOTAL + lista de productos
   → El gasto se guarda automáticamente en Supabase (tabla expenses)
   → Los productos del ticket se crean como nueva ShoppingList en Supabase (items con is_done=true)
   → Si la IA no detecta el total, se abre formulario manual pre-rellenado
   → También se pueden añadir gastos manuales sin ticket

4. RESUMEN Y GRÁFICOS
   → Lee de AppData.expenses (cargados desde Supabase al iniciar sesión)
   │ Muestra: total acumulado, media, nº transacciones
   └→ Desglose por categorías con barras + últimos gastos

5. ANÁLISIS DE COMPRAS (Shopping Insights)
   → Lee de AppData.shoppingLists (cargados desde Supabase)
   → Muestra: productos más repetidos, día favorito, tasa de completado
   → Gráfico de distribución semanal
   └→ Lince IA Advisor: Envía estadísticas reales de usuario a la Edge Function para generar consejos personalizados en tiempo real
```

---

## 🤖 Integración con IA Segura (Server-Side Architecture)

### ¿Qué modelo se usa y cómo se accede?
*   **Modelo de Servidor:** `gemini-2.0-flash` (a través de Supabase Edge Functions).
*   **Seguridad de la API Key:** La API Key de Gemini (`GEMINI_API_KEY`) reside **únicamente** como secreto encriptado en el backend de Supabase (`supabase secrets set`). **Se ha eliminado por completo del código cliente (.env, pubspec) para evitar ingeniería inversa en el APK.**
*   **Middleware (Edge Function):** Se ha desarrollado la función `gemini-proxy` en Deno (Supabase) encargada de centralizar todas las peticiones a la API de Gemini.
*   **Validación de JWT:** La Edge Function verifica la firma del token de autenticación (JWT) de Supabase antes de ejecutar cualquier llamada a Gemini. Esto **impide** el consumo no autorizado de cuota por usuarios no autenticados o llamadas externas maliciosas.

### Gated AI (Protección de Recursos)
El acceso a funciones de IA está protegido en el cliente:
*   Si un usuario no autenticado intenta realizar un escaneo en `expenses_screen.dart` o `shopping_list_detail_screen.dart`, se le muestra el modal `_showLoginRequiredDialog()` bloqueando el acceso de forma amigable.
*   En `shopping_insights_screen.dart`, el panel "Lince IA Advisor" muestra un estado informativo indicando que requiere inicio de sesión para habilitar el análisis de comportamiento.

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

### Capa de datos: `SupabaseRepository`
Archivo: `lib/data/supabase_repository.dart`

| Método | Acción |
|---|---|
| `signIn(email, password)` | Login con email |
| `signUp(email, password)` | Registro de nuevo usuario |
| `signOut()` | Cierre de sesión y limpieza total de la caché `AppData` local |
| `loadUserSettings()` | Carga moneda del usuario desde BD |
| `loadInitialData()` | Carga expenses + shoppingLists del usuario |
| `addExpense(expense)` | Inserta gasto en Supabase o AppData (fallback) |
| `createShoppingListWithItems(title, items)` | Crea lista + items en Supabase o AppData (fallback) |
| `callGemini(prompt, imageBytes)` | Llama a la Edge Function de manera segura adjuntando token JWT y controlando de manera robusta los errores del servidor (como rate limits 429) |

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
| **WelcomeScreen** | `welcome_screen.dart` | Auth (Login/Registro Email), selector de moneda, Ajustes y Accesibilidad. Mensaje visual claro de limitación sin inicio de sesión. |
| **Gestión de Gastos** | `expenses_screen.dart` | Escaneo IA de tickets seguro (Edge Function), gastos manuales, categorías, adjuntos, persistencia Supabase. |
| **Gastos Compartidos** | `shared_expenses_screen.dart` | Grupos/eventos con liquidación inteligente de deudas. |
| **Lista de la Compra** | `checklist_screen.dart` → `shopping_list_detail_screen.dart` | Multi-lista checklist con escaneo de productos por Edge Function, persistencia Supabase. |
| **Análisis de Compras** | `shopping_insights_screen.dart` | Lince IA Advisor conectado al proxy server-side con prompts personalizados de hábitos y fallback robusto. |
| **Resumen y Gráficos** | `summary_screen.dart` | Dashboard financiero con barras y últimos gastos. |
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
- **Arquitectura de IA 100% segura**: Integración mediante Supabase Edge Functions (`gemini-proxy`).
- **API Key oculta**: Reside únicamente como secreto de entorno del servidor.
- **Validación server-side de JWT**: Solo los usuarios con sesión activa pueden realizar llamadas de IA.
- **Protección de recursos en la interfaz (Gated AI)**: Diálogo descriptivo con candado en Gastos e Ítems si se intenta escanear sin estar autenticado.
- **Análisis de Compras con IA real**: Lince IA Advisor ahora procesa estadísticas de compras reales de usuario mediante el proxy seguro.
- **Control robusto de errores**: Parsing y mensajes claros para errores de cuota superada (429) y caídas de servicio.
- Supabase Auth con Email (Login/Registro + validación de errores amigable).
- Control de errores de Auth (formato de email, contraseña corta, credenciales inválidas, etc.).

### 🔴 Pendiente (Prioridad Alta)
- **[UX]** Finalizar el texto de aviso en la pantalla de inicio sobre la imposibilidad de usar escaneo de IA en modo offline/invitado.
- **[Auth]** Implementar Google Sign-In real (actualmente muestra snack "en desarrollo").
- **[Gastos]** Soporte para actualización (UPDATE) de gastos en Supabase (actualmente solo en local).

### 🟡 Pendiente (Roadmap)
- **Clasificación Automática:** IA que categorice gastos según el nombre del comercio.
- **Widget de Escritorio:** Android/iOS Home Screen Widget para eventos y presupuesto diario.
- **Lince IA Predictivo:** Análisis avanzado para predecir quedarse sin saldo.
- **Gastos Compartidos:** Sincronización en tiempo real vía Supabase Realtime.
