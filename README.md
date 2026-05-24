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
- **Localización (i18n):** Poner la app en Inglés e implementar la funcionalidad dinámica de cambio de idioma.
- **Rebranding:** Cambiar el título y enfoque de la app, ajustando el concepto ya que no es una app de finanzas estrictamente hablando.
- **Ingeniería de Requisitos y Testing:** Revisar el diagrama de flujo de la aplicación para pasar por todas las casuísticas posibles (desde modo daltónico hasta escaneo de gastos) para hacer simulacros y corregir fallos ocultos.
- **Gestión de Borrado en la Nube:** Estudiar la casuística del borrado de elementos en Supabase.
- **Escaneo Avanzado:** Optimizar la lectura y precisión del escaneo de tickets mediante la cámara.
- **Exportación e Importación:** Añadir soporte para exportar balances a `.xlsx` o `.csv`.

### 🐛 Bugs Conocidos (Próximas Correcciones)
- **Listas Compartidas:** El nombre de la lista compartida no se actualiza en la vista principal tras guardarlo en los ajustes. Falta asegurar que se refresque el estado al volver hacia atrás.


---

## ✅ Bugs Solucionados (Testeo Móvil)
- **Registro de cuentas (`Sign Up`):** Se añadió validación de cuenta creada con confirmación pendiente sin forzar inicio de sesión automático fallido.
- **Problema de Visibilidad de UI en Modos de Color (Claro/Oscuro):** Se ajustó el contraste del botón de registro en el modo oscuro.
- **Botón de Escaneo QR:** Implementada lectura de QR funcional mediante cámara nativa (`mobile_scanner`).
- **Compartir Listas y Selector de Identidad:** Corregidos problemas de asiganción de identidad y persistencia en checklists.
- **Asignación e Inmutabilidad en Eventos Compartidos:** Añadida etiqueta `(Tú)` dinámica y botón de borrado de participante deshabilitado para sí mismo.
- **Borrado Persistente de Eventos y Listas:** Al eliminar un evento o lista compartida (Swipe to Delete), ahora se desvincula el usuario realizando un borrado físico de su registro en la tabla de miembros en Supabase. Esto soluciona por completo el bug de apariciones fantasmas tras hacer "Pull to Refresh".
- **Refresco Individual de Eventos:** Añadida la funcionalidad *Pull-to-Refresh* (deslizar hacia abajo) dentro de las pestañas internas de cada evento compartido (Gastos, Saldos, Archivos) para poder recargar el contenido específico sin tener que salir a la pantalla principal.
- **Renombrado de Módulos UI:** "Facturación" a "Gastos", "Checklist" a "Listas" y "Grupos" a "Eventos", simplificando descripciones en el Menú Principal.
- **Armonización de Borrado UX:** Se implementó `Swipe to Delete` (deslizar para borrar) tanto en Eventos como Listas Compartidas, eliminando el antiguo `onLongPress` para que concuerde con las Listas Personales.
- **Edición en Listas Compartidas:** Implementada la rueda de ajustes en Listas Compartidas para añadir/eliminar miembros y editar el título de forma dinámica.
- **Optimización de Snackbars:** Se implementó `clearSnackBars()` globalmente antes de mostrar mensajes (`showSnackBar`), previniendo apilamientos infinitos de alertas por clicks rápidos.
- **Persistencia de Títulos en Listas Compartidas:** Añadida espera asíncrona (`await`) para garantizar que los cambios de nombre en las listas se guarden en Supabase antes de refrescar la UI.
- **Mensaje de Éxito en Registro:** Se cambió el contenedor de error rojo por uno verde de éxito al crear la cuenta.
- **Redirección de Confirmación de Correo:** Se solucionó el error de redirección a `localhost` configurando explícitamente el parámetro `emailRedirectTo: 'https://billince.app'` en la autenticación de Supabase.
- **Rueda de Ajustes en Eventos:** Se eliminó la acción de dejar pulsado y se añadió un botón de ajustes en cada evento para gestionar nombre, moneda y participantes, asegurando que los cambios se sincronicen en la nube.
- **Ajustes en Menú Principal y Tema:** Se añadió el icono de ajustes de accesibilidad en el menú principal y se corrigió el color de fondo del Modo Oscuro a Midnight Blue (`#0F172A`).

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
