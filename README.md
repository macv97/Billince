# 🐱‍👤 Billince

**Visión experta para tus finanzas.**

Billince es una aplicación móvil de gestión financiera personal desarrollada en **Flutter**. Su nombre nace de la fusión entre *Bill* (factura en inglés) y *Lince* (animal con visión aguda), representando el control preciso y la claridad que ofrece sobre tus finanzas.

> 🚀 **Estado:** Versión con OCR real, Calendario y Análisis de hábitos por IA.

---

## 📸 Identidad Visual

| Elemento | Valor |
|---|---|
| **Color Primario** | Azul Medianoche `#0F172A` |
| **Color Acento** | Ámbar / Ojo de Lince `#F59E0B` |
| **Color Secundario** | Verde Esmeralda `#10B981` |
| **Color Fondo** | Crema Ámbar `#FEF3C7` |
| **Icono** | Ojo estilizado (visión del lince) sobre fondo ámbar |
| **Tipografía** | Roboto |

---

## ✨ Funcionalidades Principales

### 1. Gestión de Gastos con OCR Real
- **Escaneo Inteligente**: Integración con **Google ML Kit** para lectura real de tickets y facturas.
- **Automatización**: La IA detecta automáticamente el nombre del comercio y el **importe total** (priorizando líneas de TOTAL/IMPORTE), registrando el gasto al instante sin intervención manual si la detección es precisa.
- **Soporte de Adjuntos**: Posibilidad de añadir imágenes de la galería o fotos en vivo a cada gasto.
- **Moneda Dinámica**: Todo el sistema se adapta a la moneda global escogida (€, $, £).

### 2. Lista de la Compra y Análisis de IA
- **Checklist Puro**: Módulo enfocado en la organización previa a la compra. Permite tachar productos en tiempo real.
- **Escaneo de Listas**: Captura listas escritas a mano o impresas para digitalizarlas rápidamente.
- **Lince IA Advisor**: Un motor de análisis que estudia tus hábitos (día de compra favorito, productos recurrentes, tasa de completado) y ofrece consejos personalizados para mejorar tu eficiencia en el supermercado.

### 3. Calendario y Agenda Personal
- **Gestión de Eventos**: Calendario mensual completo para agendar tareas, pagos o eventos personales.
- **Categorización**: Clasifica tus eventos (Personal, Trabajo, Finanzas, Salud, Otro) con iconos y colores dinámicos.
- **Indicadores Visuales**: Sistema de puntos para identificar rápidamente qué días tienen actividades pendientes.

### 4. Gastos Compartidos (Eventos)
- Crear grupos para viajes o cenas comunes.
- **Liquidación Inteligente**: Algoritmo que calcula quién debe a quién y sugiere el número mínimo de transferencias para saldar deudas.

### 5. Resumen, Gráficos y Accesibilidad
- **Dashboard Premium**: Visualización de gasto total, media diaria y número de transacciones con una estética profesional y limpia.
- **Accesibilidad Total**: Modos para daltonismo (Protanopia, Deuteranopia, Tritanopia) y ajuste de escala de texto dinámico.
- **Ajustes Personalizados**: Cambio de idioma, temas (Claro/Oscuro) y colores de acento.

---

## 🏗️ Arquitectura del Proyecto

```
lib/
├── main.dart                          # Punto de entrada y configuración de temas
├── data/
│   ├── app_data.dart                  # Almacenamiento global de datos y modelos
│   └── settings_provider.dart         # Persistencia de ajustes (Shared Preferences)
├── models/
│   ├── expense.dart                   # Modelo de gasto personal
│   ├── checklist_item.dart            # Modelos de listas de compra
│   ├── calendar_event.dart            # Modelo de eventos de agenda
│   └── shared_group.dart              # Modelos de gastos compartidos
└── screens/
    ├── expenses_screen.dart           # Gestión de gastos + OCR
    ├── shopping_list_detail_screen.dart # Checklist inteligente
    ├── shopping_insights_screen.dart  # Análisis de hábitos por IA
    ├── calendar_screen.dart           # Agenda y calendario
    ├── summary_screen.dart            # Dashboard de estadísticas
    └── welcome_screen.dart            # Bienvenida, Moneda y Ajustes
```

---

## 🛠️ Stack Tecnológico

| Tecnología | Uso |
|---|---|
| **Flutter 3.x** | Framework móvil multiplataforma |
| **Google ML Kit** | Reconocimiento de texto (OCR) real |
| **Provider** | Gestión de estado y ajustes |
| **Shared Preferences** | Persistencia de configuraciones |
| **Image Picker** | Acceso a cámara y galería de fotos |

---

## 📋 Hoja de Ruta (Futuras Implementaciones)

- [ ] **Persistencia Total**: Migración a `sqflite` o `Hive` para que los gastos y listas no se borren al cerrar la app.
- [ ] **Clasificación Automática**: IA que aprenda a categorizar gastos automáticamente según el nombre del comercio (ej. "Mercadona" → Compras).
- [ ] **Widget de Escritorio**: Widget para Android/iOS que muestre los eventos del calendario y el presupuesto diario.
- [ ] **Sincronización Cloud**: Firebase/Supabase para compartir grupos y listas en tiempo real entre usuarios.
- [ ] **Lince IA Predictivo**: Análisis avanzado para predecir cuándo te quedarás sin saldo basándose en meses anteriores.

---

> *Billince — Porque gestionar tu dinero requiere la agudeza de un lince.* 🐱‍👤
