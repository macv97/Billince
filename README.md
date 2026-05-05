# 🐱‍👤 Billince

**Visión experta para tus finanzas.**

Billince es una aplicación móvil de gestión financiera personal desarrollada en **Flutter** con backend en **Supabase**. Su nombre nace de la fusión entre *Bill* (factura en inglés) y *Lince* (animal con visión aguda), representando el control preciso y la claridad que ofrece sobre tus finanzas.

> 🚀 **Estado:** Versión con autenticación real (Supabase Auth), persistencia en PostgreSQL, IA multimodal (Gemini) y análisis de hábitos.

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

### 1. Autenticación con Supabase
- **Login / Registro con Email y Contraseña** con validación de formato y control de errores amigable.
- Tras el login, la app carga automáticamente las preferencias del usuario (moneda) y sus datos (gastos, listas) desde la base de datos en la nube.
- Alternancia fluida entre modo "Iniciar sesión" y "Registrarse" en un mismo modal.
- Estructura preparada para **Google Sign-In** (en desarrollo).
- Opción de continuar sin cuenta (datos volátiles, sin persistencia).

### 2. Gestión de Gastos con IA Multimodal
- **Escaneo Inteligente con Gemini**: La IA analiza la imagen del ticket y extrae automáticamente el nombre del comercio, el importe total y la lista de productos comprados.
- **Doble automatización**: Al escanear un ticket, se crea el gasto y simultáneamente una lista de la compra con todos los productos detectados, todo guardado en la nube.
- **Moneda Dinámica**: Todo el sistema se adapta a la moneda global escogida (€, $, £) y se sincroniza con la cuenta del usuario.
- Gastos manuales y soporte de adjuntos (foto del ticket).

### 3. Lista de la Compra y Análisis de IA
- **Checklist Puro**: Módulo enfocado en la organización previa a la compra. Permite tachar productos en tiempo real.
- **Escaneo de Listas**: Captura listas escritas a mano o impresas para digitalizarlas usando IA (Gemini).
- **Lince IA Advisor**: Motor de análisis que estudia tus hábitos de compra y ofrece consejos personalizados.
- Datos sincronizados con la nube para no perder ninguna lista.

### 4. Calendario y Agenda Personal
- Calendario mensual completo para agendar tareas, pagos o eventos personales.
- Categorías (Personal, Trabajo, Finanzas, Salud, Otro) con iconos y colores dinámicos.
- Indicadores visuales de actividad por día.

### 5. Gastos Compartidos
- Grupos para viajes o cenas comunes.
- **Liquidación Inteligente**: Algoritmo que calcula quién debe a quién con el mínimo de transferencias.

### 6. Resumen, Gráficos y Accesibilidad
- **Dashboard Premium**: Total acumulado, media diaria y número de transacciones.
- **Accesibilidad Total**: Modos para daltonismo (Protanopia, Deuteranopia, Tritanopia) y ajuste de escala de texto dinámico.
- Temas Claro/Oscuro/Automático y personalización de colores de acento.

---

## 🤖 Uso de Inteligencia Artificial (Gemini)

Billince integra la API de **Google Gemini** (`gemini-flash-latest`) para realizar análisis multimodal de imágenes. La IA nunca se invoca en segundo plano: **siempre es el usuario quien la activa** mediante un botón de escaneo.

### ¿Cuándo se usa?

| Acción | ¿Qué hace la IA? | Resultado |
|---|---|---|
| **Escanear ticket de compra** (en Gestión de Gastos) | Lee el ticket y extrae: nombre del comercio, importe total y lista de productos | Crea un gasto + una lista de la compra en tu cuenta |
| **Escanear lista escrita** (en Lista de la Compra) | Lee una lista escrita a mano o impresa | Digitaliza los productos como ítems del checklist |

### Flujo de un escaneo de ticket:
```
📷 Usuario escanea ticket
        ↓
🧠 Gemini analiza la imagen (modelo multimodal)
        ↓
📦 JSON: { storeName, totalAmount, items[] }
        ↓
    ┌───────────────────────────────┐
    │                               │
💶 Gasto añadido              🛒 Lista creada
   en tu cuenta                con los productos
   (Supabase)                  del ticket (Supabase)
```

> ⚠️ **Nota:** La IA requiere conexión a internet. Si usas la app sin iniciar sesión, los datos analizados se guardan solo de forma temporal y se perderán al cerrar la app.

---

## 🏗️ Arquitectura del Proyecto

```
lib/
├── main.dart                              # Punto de entrada: init dotenv + Supabase + Provider
├── data/
│   ├── app_data.dart                      # Caché local de datos (gastos, listas, eventos)
│   ├── settings_provider.dart             # Persistencia de ajustes UI (Shared Preferences)
│   └── supabase_repository.dart           # Capa de acceso a datos (Supabase Auth + DB)
├── models/
│   ├── expense.dart                       # Modelo de gasto personal
│   ├── checklist_item.dart                # Modelos de listas de compra
│   ├── calendar_event.dart                # Modelo de eventos de agenda
│   └── shared_group.dart                  # Modelos de gastos compartidos
└── screens/
    ├── welcome_screen.dart                # Auth (Login/Registro), moneda y ajustes
    ├── expenses_screen.dart               # Gastos + escaneo IA + Supabase
    ├── shopping_list_detail_screen.dart   # Checklist inteligente + escaneo IA
    ├── shopping_insights_screen.dart      # Análisis de hábitos por IA
    ├── calendar_screen.dart               # Agenda y calendario
    ├── summary_screen.dart                # Dashboard de estadísticas
    └── shared_expenses_screen.dart        # Grupos y gastos compartidos
```

---

## 🛠️ Stack Tecnológico

| Tecnología | Uso |
|---|---|
| **Flutter 3.x** | Framework móvil multiplataforma |
| **Supabase** | Autenticación, base de datos PostgreSQL y RLS |
| **Google Gemini API** | IA multimodal para análisis de tickets y listas |
| **Provider** | Gestión de estado global (ajustes UI) |
| **flutter_dotenv** | Gestión segura de variables de entorno (API Keys) |
| **Shared Preferences** | Persistencia local de configuraciones de UI |
| **Image Picker** | Acceso a cámara y galería de fotos |

---

## 🔒 Seguridad

- Las API Keys (Gemini y Supabase) se almacenan en un archivo `.env` **excluido del repositorio Git** (`.gitignore`).
- Supabase aplica **Row Level Security (RLS)** en todas las tablas: cada usuario solo puede ver y modificar sus propios datos.
- La autenticación usa **JWT tokens** gestionados automáticamente por `supabase_flutter`.

---

## 📋 Hoja de Ruta

### ✅ Completado
- [x] Autenticación real con Email/Contraseña (Supabase Auth)
- [x] Persistencia en PostgreSQL (expenses, shopping_lists, checklist_items, user_settings)
- [x] Row Level Security por usuario en todas las tablas
- [x] Integración Gemini multimodal para tickets y listas
- [x] Flujo inteligente: ticket → gasto + lista de productos automática
- [x] Control de errores de autenticación con mensajes amigables
- [x] API Keys seguras en `.env`

### 🔴 Pendiente (Prioridad Alta)
- [ ] **[UX]** Mostrar aviso en la pantalla de inicio explicando que sin cuenta las funciones de IA no persistirán los datos entre sesiones.
- [ ] **[Auth]** Implementar Google Sign-In real.
- [ ] **[Gastos]** Soporte UPDATE de gastos en Supabase.

### 🟡 Futuras Implementaciones
- [ ] **Clasificación Automática**: IA que categorice gastos según el nombre del comercio.
- [ ] **Widget de Escritorio**: Mostrar eventos del día y presupuesto en el Home Screen.
- [ ] **Lince IA Predictivo**: Predicción de saldo basada en meses anteriores.
- [ ] **Edge Function Supabase**: Mover la llamada a Gemini al servidor para seguridad máxima de la API Key.
- [ ] **Gastos Compartidos en la Nube**: Sincronización en tiempo real vía Supabase Realtime.

---

> *Billince — Porque gestionar tu dinero requiere la agudeza de un lince.* 🐱‍👤
