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

---

## 🚀 Próximas Funcionalidades (Roadmap)

### Colaboración Total en Tiempo Real (Sincronización Funcional de Deep Links)
- **Invitaciones a Gastos Compartidos:** Implementar un backend en Supabase y Deep Linking nativo funcional para que el enlace o QR generado permita a cualquier amigo abrir la app, unirse al instante al evento y colaborar en la misma lista.
- **Cálculo cruzado:** Capacidad de ver quién debe qué a quién y enviar el recordatorio en directo de las deudas en ese mismo instante a todos los usuarios en la nube vinculados al grupo.

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
