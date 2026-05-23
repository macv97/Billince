# 🐆 Billince

**Tu control de gastos, simple y claro (100% Offline-First & Glassmorphism UI).**

Billince es una aplicación móvil de gestión financiera personal de nivel profesional desarrollada en **Flutter** con backend opcional en **Supabase**. Su nombre nace de la fusión entre *Bill* (factura en inglés) y *Lince* (animal con visión aguda), representando el control preciso y la visión impecable sobre tus finanzas diarias.

> 🛡️ **Estado Actual:** Aplicación 100% Offline-First. Todas las funciones, incluido el potente escaneo de tickets mediante Machine Learning local (NLP + Geometría), funcionan **sin internet** y **sin consumir APIs en la nube**. El inicio de sesión es opcional y sirve únicamente para respaldo en la nube y gastos compartidos.

---

## ✨ Funcionalidades Destacadas

### 1. 100% Offline-First por diseño
- Los datos personales, gastos y listas de la compra se procesan y almacenan en bases de datos locales ultrarrápidas (`SQLite` / en caché).
- **Protección Máxima a la Privacidad:** Si no inicias sesión, tus datos nunca abandonan tu dispositivo.

### 2. Escaneo de Tickets Local con Carrusel Inteligente (Visión Espacial)
- **Cero APIs, Cero Coste:** En lugar de depender de servicios IA gastando tokens, Billince emplea un modelo avanzado que fusiona **Google ML Kit Text Recognition** con heurística espacial (Bounding Boxes) y procesamiento local para extraer comercios, precios totales e ítems con asombrosa precisión directamente desde la cámara o galería.
- **Carrusel Inteligente UX:** Al escanear una factura, el sistema propone el importe final, y presenta todos los demás números detectados en un elegante carrusel de burbujas. Si el modelo falla, un solo *Toque* corrige el importe al instante, eliminando el tecleo manual.

### 3. Sincronización Opcional y Cloud (Supabase)
- **Inicio de sesión opcional:** Útil si temes perder tu móvil o cambiar de dispositivo. Todos tus datos se respaldan en Supabase (PostgreSQL) protegido con políticas RLS.
- **Grupos (Cloud):** Solo si estás autenticado podrás acceder a este módulo para crear gastos con amigos.

### 4. Accesibilidad y Experiencia Premium (Glassmorphism)
- Rediseño arquitectónico enfocado en una **UI Glassmorphism** hiper-moderna y corporativa en toda la app (Inicio, Listas, Gastos).
- Ajustes de accesibilidad (tipografía ampliable, filtros para daltonismo) y menús perfectamente alineados.
- Transiciones fluidas, modales redondeados y una coherencia visual absoluta basándose en colores corporativos limpios y elegantes.

### 5. Listas Compartidas en Tiempo Real y Registro de Actividad
- **Listas Dinámicas:** Comparte listas de la compra mediante enlace o QR. Los cambios (añadir, editar, completar o eliminar productos y etiquetas) se sincronizan en **tiempo real** para todos los integrantes.
- **Historial de Acciones Compartido:** Un registro detallado de quién añadió, modificó o eliminó qué, visible para todos.
- **Calendario Integrado:** Registro automático de la actividad de la app (uniones a listas, gastos creados) como eventos visuales en el módulo Calendario.

---

## 🚀 Próximas Funcionalidades (Roadmap)

### Optimización y Nuevas Features
- **Gestión de Borrado en la Nube:** Estudiar la casuística del borrado de elementos en Supabase. ¿Si un elemento se borra en la app, debe aplicarse un borrado lógico o físico en la base de datos?
- **Escaneo Avanzado:** Optimizar la lectura y precisión del escaneo de tickets mediante la cámara.
- **Exportación e Importación:** Añadir soporte para leer y exportar datos a formatos `.xlsx` o `.csv`, facilitando la visualización de balances en plataformas como Google Drive.
- **Ingeniería de Requisitos y Testing:** Crear diagramas de flujo y diagramas de casos de uso de la aplicación para tener claro todo el recorrido general y preparar las bases para testing automatizado.
- **Exploración Continua:** Seguir analizando nuevas ideas y requerimientos de usuario para futuras actualizaciones de la app.

---

## 🔴 Bugs y Funcionalidades Críticas a Corregir (Testeo en Móviles Reales)

- **Registro de cuentas (`Sign Up`):** Actualmente la aplicación no permite registrar nuevos usuarios o no registra de manera correcta las nuevas cuentas en Supabase.
- **Problema de Visibilidad de UI en Modos de Color (Claro/Oscuro):** En modo oscuro, el botón para registrar una nueva cuenta se camufla por completo en la pantalla de bienvenida, volviéndose invisible. Se requiere revisar exhaustivamente la visibilidad de los botones y textos interactivos en modo claro, oscuro y con las diferentes paletas y temas de accesibilidad.
- **Botón de Escaneo QR inoperativo:** El botón para escanear códigos QR en la aplicación no activa la cámara ni realiza ninguna acción. Debe implementarse su funcionamiento tanto en el módulo de checklists como en el de eventos compartidos.
- **Compartir Listas en Tiempo Real:** En el módulo de checklists (lista compartida), la funcionalidad para compartir listas con otras cuentas no es operativa. Al ingresar el enlace o invitar, la lista compartida debe aparecer y sincronizarse de manera correcta en la cuenta del usuario que ingresa el enlace.
- **Identificación en Checklist Compartido:** Al unirse o crear una lista compartida, lo primero que debe hacer la aplicación es solicitar o permitir al usuario elegir quién es dentro de la lista de integrantes del checklist.
- **Asignación y Visualización de Identidad en Eventos Compartidos:**
  - El usuario creador o participante de un evento compartido no debería poder eliminarse a sí mismo.
  - La aplicación debe permitir asignar un nombre personalizado a quien crea el evento (ej: "Pepe") y mostrarlo en la lista como `"Nombre (Tú)"` (ej: `"Pepe (Tú)"`). A cada participante respectivo se le debe mostrar el sufijo `(Tú)` en su propio nombre para identificar claramente su identidad en el evento.
- **Borrado Persistente de Eventos Compartidos:** Arreglar el flujo de eliminación de eventos compartidos. Actualmente, al eliminar un evento compartido y recargar la pantalla, el evento vuelve a aparecer (posiblemente debido a que se recargan directamente todos los datos desde Supabase/SQLite sin validar el estado de borrado o sin aplicar la eliminación en la base de datos). Los botones de borrado deben ser 100% funcionales y persistentes.

---

## 🛠️ Stack Tecnológico
| Componente | Tecnología | Propósito |
|---|---|---|
| **Frontend** | Flutter 3.x / Dart | Aplicación móvil multiplataforma fluida. |
| **Backend Opcional** | Supabase (PostgreSQL) | Almacenamiento seguro, autenticación y base para colaboración. |
| **BBDD Local** | SQLite | Motor principal Offline-First. |
| **Visión e Inteligencia Local** | Google ML Kit + Spatial NLP | Escaneo de facturas 100% en dispositivo con UX Híbrida Inteligente. |

---

> *Billince — Gestiona tu dinero con la precisión y la agudeza visual de un lince.* 🐆
