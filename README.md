# ????? Billince

**Visión experta para tus finanzas (100% Offline-First).**

Billince es una aplicación móvil de gestión financiera personal de nivel profesional desarrollada en **Flutter** con backend opcional en **Supabase**. Su nombre nace de la fusión entre *Bill* (factura en inglés) y *Lince* (animal con visión aguda), representando el control preciso y la visión impecable sobre tus finanzas diarias.

> ?? **Estado Actual:** Aplicación 100% Offline-First. Todas las funciones, incluido el potente escaneo de tickets mediante Machine Learning local (NLP + Geometría), funcionan **sin internet** y **sin consumir APIs en la nube**. El inicio de sesión es opcional y sirve únicamente para respaldo en la nube y gastos compartidos.

---

## ? Funcionalidades Destacadas

### 1. 100% Offline-First por diseño
- Los datos personales, gastos y listas de la compra se procesan y almacenan en bases de datos locales ultrarrápidas (`SQLite` / en caché).
- **Protección Máxima a la Privacidad:** Si no inicias sesión, tus datos nunca abandonan tu dispositivo.

### 2. Escaneo de Tickets Local (Visión Espacial)
- **Cero APIs, Cero Coste:** En lugar de depender de GPT o Gemini gastando tokens, Billince emplea un modelo avanzado que fusiona **Google ML Kit Text Recognition** con heurística espacial (Bounding Boxes) y Natural Language Processing local para extraer comercios, precios totales e ítems con asombrosa precisión directamente desde la cámara o galería.

### 3. Sincronización Opcional y Cloud (Supabase)
- **Inicio de sesión opcional:** Útil si temes perder tu móvil o cambiar de dispositivo. Todos tus datos se respaldan en Supabase (PostgreSQL) protegido con políticas RLS.
- **Gastos Compartidos (Cloud):** Solo si estás autenticado podrás crear grupos de gastos con amigos y sincronizarlos en tiempo real.

### 4. Accesibilidad y Experiencia Premium (UI/UX)
- Interfaces limpias, modo oscuro y claro automatizado.
- Ajustes de accesibilidad (tipografía ampliable, filtros para daltonismo).
- Diseños modernos inspirados en *glassmorphism* y patrones financieros de élite.

---

## ??? Stack Tecnológico
| Componente | Tecnología | Propósito |
|---|---|---|
| **Frontend** | Flutter 3.x / Dart | Aplicación móvil multiplataforma fluida con Material 3. |
| **Backend Opcional** | Supabase (PostgreSQL) | Almacenamiento seguro, autenticación y base para colaboración. |
| **BBDD Local** | SQLite | Motor principal Offline-First. |
| **Visión e IA Local** | Google ML Kit + Spatial NLP | Escaneo de tickets seguro y gratuito sin servidores de terceros. |

---

> *Billince — Gestiona tu dinero con la precisión y la agudeza visual de un lince.* ?????
