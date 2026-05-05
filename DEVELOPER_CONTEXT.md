# 🧠 Billince: Contexto de Desarrollo y Snapshot del Proyecto

Este archivo sirve como memoria técnica y manual de identidad para Billince. Su objetivo es optimizar la carga de contexto para el asistente de IA y asegurar la continuidad del desarrollo sin redundancias.

---

## 💎 Identidad de Marca y Branding
*   **Nombre:** Billince (Fusión de *Bill* -factura- y *Lince* -animal de visión aguda-).
*   **Concepto:** Visión experta y precisión en las finanzas personales.
*   **Paleta de Colores (Lynx Palette):**
    *   **Primario (Midnight Blue):** `#0F172A` (Elegancia y seguridad).
    *   **Acento (Amber/Lynx Eye):** `#F59E0B` (Agudeza visual y llamadas a la acción).
    *   **Éxito (Emerald):** `#10B981` (Saldos positivos y confirmaciones).
    *   **Fondo/Soft (Cream Amber):** `#FEF3C7` (Superficies secundarias y AppBars).
*   **Iconografía:** El logo principal es un **ojo de lince** minimalista. En la app se usan iconos dinámicos según el contexto (avión para viajes, cubiertos para comida, etc.).

---

## 🛠️ Arquitectura Técnica (Flutter)
*   **Framework:** Flutter con Material 3.
*   **Estado Global:** 
    *   **Datos de la App:** Gestionados en memoria vía `lib/data/app_data.dart` (Gastos, Listas, Grupos).
    *   **Ajustes de Usuario:** Gestionados mediante `SettingsProvider` (paquete `provider`) con persistencia real en `shared_preferences`.
*   **Estructura de Carpetas:**
    *   `lib/models/`: Clases de datos (`Expense`, `SharedGroup`, `ChecklistItem`, `ShoppingList`, etc.).
    *   `lib/screens/`: Vistas de la aplicación.
    *   `lib/data/`: `AppData` (datos volátiles) y `SettingsProvider` (lógica de configuración).
*   **Módulos Principales:**
    1.  **WelcomeScreen:** Selector de moneda, login simulado y acceso al modal de **Ajustes y Accesibilidad**.
    2.  **ExpensesScreen:** Gestión individual con escaneo IA simulado y soporte de adjuntos (PDF/IMG).
    3.  **SharedExpenses:** Gestión de grupos/eventos con liquidación inteligente de deudas.
    4.  **ChecklistScreen (Multi-lista):** Vista general de listas de compra guardadas. Permite crear múltiples listas (ej. "Semana", "Fiesta") y persistir sus elementos.
    5.  **SummaryScreen:** Gráficos de barras corporativos y desglose por categorías.

---

## ♿ Accesibilidad y UX (Funcional)
*   **SettingsProvider:** Controla el estado global de la interfaz.
*   **Modos de Daltonismo:** Implementado mediante matrices de color reales (`ColorFiltered`) para Protanopia, Deuteranopia y Tritanopia.
*   **Tamaño de Texto:** Ajustable dinámicamente mediante `textScaleFactor` global (de 1.0 a 1.5).
*   **Temas:** Soporte para Tema Claro, Oscuro y Automático (Sistema).
*   **Colores de Interfaz:** Personalización del color semilla del `ThemeData`.
*   **Usabilidad:** Gestos de *swipe* para eliminar listas y elementos. Límite de archivos adjuntos de **5MB**.

---

## 🐙 Gestión de Repositorio (GitHub)
*   **Repositorio:** `https://github.com/macv97/Billince.git`
*   **Estrategia de Ramas:**
    *   `main`: Rama de producción/estable.
    *   `dev`: Rama de desarrollo activo (donde se realizan los cambios actuales).
*   **Compilación:** APK en `build/app/outputs/flutter-apk/app-release.apk`.

---

## 🚧 Estado Actual y Pendientes (Roadmap)
*   **Persistencia de Datos:** Los ajustes se guardan (`shared_preferences`), pero los gastos y listas de compra siguen siendo volátiles (se pierden al cerrar la app). Pendiente migrar a `sqflite` o `Hive`.
*   **IA Real:** Los procesos de escaneo son simulados (`Future.delayed`).
*   **Sincronización:** Pendiente implementación de backend para compartir eventos en tiempo real.

---

**Nota para el Agente:** Priorizar siempre el uso de la paleta `#0F172A` y `#F59E0B`. Los ajustes globales se inyectan en `main.dart` mediante `ChangeNotifierProvider`.
