# 🐱‍👤 Billince

**Visión experta para tus finanzas.**

Billince es una aplicación móvil de gestión financiera personal de nivel profesional desarrollada en **Flutter** con backend en **Supabase**. Su nombre nace de la fusión entre *Bill* (factura en inglés) y *Lince* (animal con visión aguda), representando el control preciso, la rapidez y la claridad absoluta que ofrece sobre tus finanzas diarias.

> 🚀 **Estado Actual:** Versión de alta seguridad con autenticación real, almacenamiento persistente en la nube mediante PostgreSQL con RLS, arquitectura de IA delegada al servidor mediante Supabase Edge Functions y un sofisticado asesor financiero inteligente.

---

## 📸 Identidad Visual

| Elemento | Valor |
|---|---|
| **Color Primario** | Azul Medianoche `#0F172A` |
| **Color Acento** | Ámbar / Ojo de Lince `#F59E0B` |
| **Color Secundario** | Verde Esmeralda `#10B981` |
| **Color Fondo** | Crema Ámbar `#FEF3C7` |
| **Icono** | Ojo estilizado (visión del lince) sobre fondo ámbar |
| **Tipografía** | Roboto / Inter |

---

## ✨ Funcionalidades Destacadas

### 1. Autenticación Robusta con Supabase
- **Login / Registro con Email y Contraseña** con validación estricta de formatos en tiempo real y retroalimentación de errores sumamente amigable.
- Carga dinámica de configuraciones (como el símbolo de moneda de preferencia del usuario) y datos (gastos, listas) desde la nube inmediatamente tras la autenticación.
- Cierre de sesión seguro con limpieza de caché y datos locales temporales para proteger la privacidad.

### 2. Gestión de Gastos y Tickets con IA Segura (Server-Side)
- **Escaneo Inteligente**: La IA analiza de manera asíncrona imágenes de tickets (cámara o galería) extrayendo el comercio, el importe total y el desglose de productos comprados.
- **Automatización Cruzada**: Un único escaneo genera un registro de gasto en tu panel financiero y crea de forma automática una lista de la compra de verificación con los ítems extraídos.
- **Arquitectura Segura**: Ningún dato de API ni claves privadas reside en el cliente. La comunicación se realiza mediante una Edge Function en el servidor, garantizando seguridad impenetrable.

### 3. Listas de la Compra Inteligentes
- **Checklist Dinámico**: Creación de listas de compras previas a tu visita al supermercado con posibilidad de marcar o desmarcar ítems en tiempo real.
- **Digitalización de Listas**: Convierte listas manuscritas o impresas en listas interactivas digitales gracias al escaneo inteligente de Gemini.

### 4. Lince IA Advisor (Análisis Financiero Avanzado)
- Análisis exhaustivo de tus hábitos de consumo directo en el panel de **Shopping Insights**.
- **Consejos Personalizados Reales**: Evaluando métricas como volumen de compras, frecuencia por día de la semana, tasa de completado y productos recurrentes, la IA te provee recomendaciones prácticas orientadas al ahorro y optimización presupuestaria.

### 5. Agenda y Gastos Compartidos
- Calendario completo para planificación de vencimientos, cobros o eventos personales con códigos de colores temáticos.
- Grupos de gastos compartidos con un potente algoritmo de **Liquidación de Deudas** para saldar cuentas comunes con el mínimo de transacciones posibles.

---

## 🤖 Arquitectura y Uso de Inteligencia Artificial (Gemini)

Para cumplir con estándares profesionales de seguridad, Billince **no expone API keys en la aplicación cliente**. Toda interacción con Google Gemini se realiza delegando la lógica al backend.

```
📱 CLip/App (Flutter)
     │
     │ 1. Envía prompt, imagen y JWT token de sesión
     ▼
🌐 Supabase Edge Function (Deno) ── [Valida JWT del usuario]
     │
     │ 2. Adjunta GEMINI_API_KEY (Guardada segura como Secreto de Servidor)
     ▼
🧠 Google Gemini API (gemini-2.0-flash)
     │
     │ 3. Procesa y devuelve JSON estructurado
     ▼
📱 App recibe datos limpios y seguros
```

### Reglas de Acceso e IA Gated
*   **Gated AI**: Las funciones de IA consumen recursos del servidor. Para evitar abusos y costos innecesarios, **las operaciones de escaneo IA están bloqueadas para usuarios invitados**. Si intentas acceder sin cuenta, la aplicación mostrará una ventana emergente explicativa con candado para invitarte a iniciar sesión.
*   **Manejo Inteligente de Errores**: Se interpretan de forma avanzada los códigos de respuesta del servidor (como el límite de cuota superado o error de red 429) proporcionando advertencias claras al usuario en español en lugar de colapsos inesperados.

---

## 🛠️ Stack Tecnológico

| Componente | Tecnología | Propósito |
|---|---|---|
| **Frontend** | Flutter 3.x / Dart | Aplicación móvil multiplataforma fluida con Material 3. |
| **Backend** | Supabase | Proveedor de Backend-as-a-Service (BaaS). |
| **Base de Datos** | PostgreSQL | Almacenamiento seguro relacional con políticas de RLS. |
| **Serverless IA** | Supabase Edge Functions (Deno) | Middleware seguro para interactuar con la API de Gemini. |
| **Inteligencia Artificial** | Google Gemini (2.0 Flash) | Procesamiento multimodal de imágenes y análisis cognitivo de datos. |
| **Gestión de Estado** | Provider | Control dinámico del flujo de configuraciones de accesibilidad. |

---

## 🔒 Directrices de Seguridad Aplicadas

1.  **Cero Exposición de Keys**: Las API keys de Gemini y de servicio no existen en el código compilado.
2.  **Políticas RLS en PostgreSQL**: Cada consulta a la base de datos está protegida a nivel de fila (`Row Level Security`), asegurando que ningún usuario pueda visualizar ni alterar la información de otra persona.
3.  **Validación de JWT**: La Edge Function requiere el token de portador (Bearer Token) del usuario firmante para dar acceso a Gemini.
4.  **Sanitización de Consultas**: Uso exclusivo del SDK oficial parametrizado de Supabase para erradicar cualquier riesgo de SQL Injection.

---

## 📋 Estado del Proyecto y Roadmap

### ✅ Completado
- [x] Arquitectura de IA 100% segura mediante Edge Functions en el servidor.
- [x] Ocultación total de la API Key de Gemini del código cliente móvil.
- [x] Validación del token de sesión (JWT) en el servidor de IA para evitar abusos.
- [x] Diálogos de bloqueo interactivos (Gated AI) para usuarios sin sesión.
- [x] Conversión del Lince IA Advisor a consumos reales e interactivos a través del proxy.
- [x] Gestión inteligente de respuestas de error de API y Rate Limits (429).
- [x] Autenticación real por Email y Contraseña (Supabase Auth).
- [x] Políticas de Row Level Security (RLS) habilitadas en producción.

### 🔴 Prioridad Alta (Próximamente)
- [ ] **[UX]** Incorporación de banner instructivo persistente en el dashboard principal sobre limitaciones funcionales para usuarios no registrados.
- [ ] **[Auth]** Habilitar acceso con Google (Google Sign-In).
- [ ] **[Auth]** Acceso con huella dactilar (Biometría) una vez iniciada la sesión, para evitar introducir credenciales cada vez que se abre la app.
- [ ] **[UX]** Dar funcionalidad completa al icono de "Mi Perfil" al iniciar la aplicación.
- [ ] **[Branding]** Corregir la discrepancia del icono de lanzamiento de la app (launcher icon) en el móvil para que coincida con el ojo de lince de la interfaz.
- [ ] **[IA]** Diseñar e implementar soluciones frente al límite de peticiones (429 Rate Limit) de la IA (ej. cola asíncrona, caché de respuestas o rotación de claves).
- [ ] **[Gastos]** Operaciones de edición (UPDATE) de gastos directamente sincronizados con la nube.

---

> *Billince — Gestiona tu dinero con la precisión y la agudeza visual de un lince.* 🐱‍👤
