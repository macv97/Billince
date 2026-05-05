# 🐱‍👤 Billince

**Visión experta para tus finanzas.**

Billince es una aplicación móvil de gestión financiera personal desarrollada en **Flutter**. Su nombre nace de la fusión entre *Bill* (factura en inglés) y *Lince* (animal con visión aguda), representando el control preciso y la claridad que ofrece sobre tus finanzas.

> 🚧 **Estado:** En desarrollo activo — Versión con ajustes y listas persistentes.

---

## 📸 Identidad Visual

| Elemento | Valor |
|---|---|
| **Color Primario** | Azul Medianoche `#0F172A` |
| **Color Acento** | Ámbar / Ojo de Lince `#F59E0B` |
| **Color Secundario** | Verde Esmeralda `#10B981` |
| **Icono** | Ojo estilizado (visión del lince) sobre fondo ámbar |
| **Tipografía** | Roboto |

---

## ✨ Funcionalidades

### 1. Pantalla de Bienvenida y Ajustes
- **Selector de moneda global** (€ EUR, $ USD, £ GBP) con efecto inmediato en toda la app.
- **Ajustes y Accesibilidad Reales**:
  - **Cambio de Idioma**: Preparado para Español/Inglés.
  - **Tema Dinámico**: Selección entre modo Claro, Oscuro o Automático (Sistema).
  - **Personalización de Color**: Cambia el color base de la interfaz dinámicamente.
  - **Accesibilidad Visual**: Filtros activos para daltonismo (Protanopia, Deuteranopia, Tritanopia) mediante matrices de color.
  - **Tamaño de Texto**: Deslizador para ajustar la escala de fuente en toda la aplicación.
- **Persistencia de Ajustes**: Las preferencias de usuario se guardan automáticamente.

### 2. Gestión de Gastos Individuales
- Añadir gastos de forma **manual** o mediante **escaneo de tickets con IA** (simulado).
- Soporte para adjuntar archivos: foto de cámara, imagen de galería o documentos PDF.
- Organización por **categorías** con iconos personalizados.
- Filtros avanzados por categoría y rango de fechas.
- Gestión de adjuntos con **límite de seguridad de 5 MB**.

### 3. Gastos Compartidos (Eventos)
- Crear **grupos de gastos** para viajes, cenas o proyectos comunes.
- **Iconos inteligentes**: La app asigna automáticamente un icono basado en el nombre del evento (✈️, 🍽️, 🏠, 🛒, etc.).
- **Moneda por evento**: Cada grupo puede tener su propia moneda (€ o $).
- **Liquidación Inteligente**: Algoritmo que calcula el balance de saldos y sugiere el número mínimo de transferencias para saldar deudas.
- **Repositorio de Archivos**: Pestaña dedicada para ver todos los tickets y facturas subidos por el grupo.

### 4. Lista de la Compra (Multi-lista)
- **Gestión de múltiples listas**: Crea listas independientes para diferentes propósitos (ej. "Compra Semanal", "Barbacoa").
- **Persistencia de navegación**: Los productos añadidos se mantienen guardados al volver atrás.
- **Escaneo con IA**: Capacidad para extraer elementos de una lista escrita a mano mediante fotos (simulado).
- Resumen visual del progreso (ej. "3 de 10 completados") desde la pantalla principal.

### 5. Resumen y Gráficos
- Panel visual con el **gasto total acumulado**.
- **Gráfico de barras corporativo** que muestra el desglose por categorías.
- Clasificación automática para detectar los mayores focos de gasto.

---

## 🏗️ Arquitectura del Proyecto

```
lib/
├── main.dart                          # Punto de entrada, inyección de Provider
├── data/
│   ├── app_data.dart                  # Estado global de datos (volátil)
│   └── settings_provider.dart         # Gestión de ajustes y persistencia local
├── models/
│   ├── expense.dart                   # Modelo de gasto individual
│   ├── checklist_item.dart            # Modelos de Checklist y ShoppingList
│   ├── shared_expense.dart            # Modelo de gasto compartido
│   ├── shared_group.dart              # Modelo de grupo/evento compartido
│   └── shared_file.dart               # Modelo de archivo adjunto
└── screens/
    ├── welcome_screen.dart            # Bienvenida y modal de ajustes
    ├── main_menu_screen.dart          # Dashboard principal
    ├── expenses_screen.dart           # Gestión de gastos personales
    ├── shared_expenses_screen.dart    # Listado de grupos compartidos
    ├── shared_group_detail_screen.dart # Detalle, saldos y archivos del grupo
    ├── checklist_screen.dart          # Gestor de listas de compra
    ├── shopping_list_detail_screen.dart # Vista detallada de una lista específica
    └── summary_screen.dart            # Análisis gráfico de gastos
```

---

## 🛠️ Stack Tecnológico

| Tecnología | Uso |
|---|---|
| **Flutter 3.8+** | Framework principal |
| **Provider** | Gestión de estado global de ajustes |
| **Shared Preferences** | Persistencia de configuraciones de usuario |
| **Material Design 3** | Sistema de diseño y componentes UI |
| **image_picker** | Integración con cámara y archivos |

---

## 🚀 Cómo Ejecutar

1. Clonar el repositorio.
2. Ejecutar `flutter pub get` para instalar dependencias.
3. Asegurarse de tener un emulador Android o dispositivo conectado.
4. Ejecutar `flutter run`.

---

## 📋 Hoja de Ruta (Próximos Pasos)

- [ ] **Base de Datos Local**: Implementar `sqflite` para persistir gastos y listas de compra de forma permanente.
- [ ] **Sincronización en la Nube**: Integración con backend para compartir grupos entre usuarios.
- [ ] **IA Real**: Sustituir las simulaciones por procesamiento de imágenes real (Google ML Kit o similar).
- [ ] **Notificaciones**: Avisos de deudas pendientes en grupos compartidos.

---

> *Billince — Porque gestionar tu dinero requiere la agudeza de un lince.* 🐱‍👤
