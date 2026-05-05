# 🧠 Billince: Contexto de Desarrollo y Snapshot del Proyecto

Este archivo sirve como memoria técnica y manual de identidad para Billince. Su objetivo es optimizar la carga de contexto para el asistente de IA y asegurar la continuidad del desarrollo sin redundancias.

---

## 💎 Identidad de Marca y Branding
*   **Nombre:** Billince (Fusión de *Bill* -factura- y *Lince* -animal de visión aguda-).
*   **Concepto:** Visión experta y precisión en las finanzas personales.
*   **Moneda por defecto:** `€` (Euro). Configurable en la WelcomeScreen (€, $, £). Se usa `AppData.currency` en TODA la app.
*   **Paleta de Colores (Lynx Palette):**
    *   **Primario (Midnight Blue):** `#0F172A` (Elegancia y seguridad).
    *   **Acento (Amber/Lynx Eye):** `#F59E0B` (Agudeza visual y llamadas a la acción).
    *   **Éxito (Emerald):** `#10B981` (Saldos positivos y confirmaciones).
    *   **Fondo/Soft (Cream Amber):** `#FEF3C7` (Superficies secundarias y AppBars).
*   **Iconografía:** El logo principal es un **ojo de lince** minimalista.

---

## 🔄 Flujo Principal de la Aplicación

```
1. LISTA DE LA COMPRA
   → El usuario crea una lista antes de ir a comprar
   → Añade productos (manualmente, escaneando foto, o desde galería)
   → En el supermercado, va tachando los productos que compra
   → ⚠️ NO se registra ningún importe aquí. Es solo un checklist.

2. GESTIÓN DE GASTOS
   → Tras la compra, el usuario escanea el TICKET con la cámara o galería
   → La IA (ML Kit) extrae: nombre del comercio + importe TOTAL
   → El gasto se añade automáticamente a la lista de gastos
   → Si la IA no detecta el total, se abre formulario manual pre-rellenado
   → También se pueden añadir gastos manuales sin ticket

3. RESUMEN Y GRÁFICOS
   → Lee de AppData.expenses (solo gastos confirmados)
   → Muestra: total acumulado, media, nº transacciones
   → Desglose por categorías con barras + últimos gastos

4. ANÁLISIS DE COMPRAS (Shopping Insights)
   → Lee de AppData.shoppingLists (solo hábitos de compra, sin €)
   → Muestra: productos más repetidos, día favorito, tasa de completado
   → Gráfico de distribución semanal
   → IA Advisor da consejos basados en patrones de comportamiento
```

---

## 🛠️ Arquitectura Técnica (Flutter)
*   **Framework:** Flutter con Material 3.
*   **Estado Global:**
    *   **Datos de la App:** `lib/data/app_data.dart` — gastos, listas, grupos, eventos de calendario.
    *   **Ajustes de Usuario:** `SettingsProvider` (paquete `provider`) con persistencia en `shared_preferences`.
*   **OCR / IA:** `google_mlkit_text_recognition` + `image_picker` para escaneo real de tickets.
    *   Estrategia de doble pasada: primero busca líneas con TOTAL/IMPORTE, luego fallback al número más grande.
*   **Estructura de Carpetas:**
    *   `lib/models/`: `Expense`, `SharedGroup`, `ChecklistItem`, `ShoppingList`, `CalendarEvent`.
    *   `lib/screens/`: Vistas de la aplicación.
    *   `lib/data/`: `AppData` (datos volátiles) y `SettingsProvider` (configuración persistente).

## 📱 Módulos Principales

| Módulo | Archivo | Propósito |
|---|---|---|
| **WelcomeScreen** | `welcome_screen.dart` | Selector de moneda, login simulado, Ajustes y Accesibilidad |
| **Gestión de Gastos** | `expenses_screen.dart` | Escaneo OCR de tickets, gastos manuales, categorías, adjuntos |
| **Gastos Compartidos** | `shared_expenses_screen.dart` | Grupos/eventos con liquidación inteligente de deudas |
| **Lista de la Compra** | `checklist_screen.dart` → `shopping_list_detail_screen.dart` | Multi-lista checklist puro (sin importes) |
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
*   **Persistencia de Datos:** Ajustes se guardan (`shared_preferences`). Gastos y listas son volátiles. Pendiente: `sqflite` o `Hive`.
*   **IA avanzada:** ML Kit funciona para OCR. Pendiente: clasificación automática de gastos por tipo de comercio.
*   **Sincronización:** Pendiente backend para compartir eventos.
*   **Widget de Calendario:** Implementar Android Home Screen Widget para eventos del día.

---

**Nota para el Agente:** Priorizar siempre la paleta `#0F172A` y `#F59E0B`. Los ajustes globales se inyectan en `main.dart` mediante `ChangeNotifierProvider`. La moneda SIEMPRE debe leerse de `AppData.currency`, nunca hardcodear `$` o `€`.
