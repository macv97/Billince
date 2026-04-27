# 🐱‍👤 Billince

**Visión experta para tus finanzas.**

Billince es una aplicación móvil de gestión financiera personal desarrollada en **Flutter**. Su nombre nace de la fusión entre *Bill* (factura en inglés) y *Lince* (animal con visión aguda), representando el control preciso y la claridad que ofrece sobre tus finanzas.

> 🚧 **Estado:** En desarrollo activo — versión local funcional.

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

### 1. Pantalla de Bienvenida
- Inicio de sesión (preparado para futura integración con backend).
- Opción de **continuar sin iniciar sesión** para uso local.
- **Selector de moneda global** (€ EUR, $ USD, £ GBP) antes de acceder a la app.
- Acceso a **Perfil** y **Ajustes** desde iconos inferiores:
  - Idioma
  - Tema (claro / oscuro)
  - Colores de interfaz
  - **Accesibilidad visual**: modo daltonismo (Protanopia, Deuteranopia, Tritanopia) y ajuste de contraste.

### 2. Gestión de Gastos
- Añadir gastos de forma **manual** o mediante **escaneo de tickets con IA** (simulado).
- Opciones de escaneo: hacer foto, subir desde galería o adjuntar PDF.
- Organización por **módulos/categorías** (General, Compras, Transporte, Ocio, etc.).
- Filtros por **categoría** y por **rango de fechas**.
- CRUD completo: crear, editar y eliminar gastos.
- Indicador visual de archivos adjuntos (icono de clip 📎).
- Eliminación por deslizamiento horizontal (swipe) o icono de papelera.

### 3. Gastos Compartidos
- Crear **eventos/grupos** temáticos (ej. "Viaje a Asturias", "Piso Compartido").
- **Iconos inteligentes** automáticos según el nombre del evento:
  - ✈️ Viaje → avión
  - 🍽️ Restaurante → cubiertos
  - 🏠 Piso → casa
  - 🎁 Regalo → paquete
  - 🛒 Compras → carrito
  - 🚗 Transporte → coche
- **Moneda independiente por evento** (€ o $), seleccionable al crear el grupo.
- Gestionar integrantes y editar nombre del grupo desde menú contextual (⋮).
- Añadir gastos compartidos indicando **quién pagó** y **para quién** es el gasto.
- Adjuntar facturas/tickets (foto, galería o PDF) con **límite de seguridad de 5 MB**.
- Editar o eliminar gastos con **long press** o **swipe horizontal**.
- **Tres pestañas** dentro de cada evento:
  - **Gastos**: listado completo de gastos del grupo.
  - **Saldos**: balance por persona y algoritmo de **liquidación inteligente** que minimiza el número de transferencias.
  - **Archivos**: repositorio de facturas y tickets adjuntados.
- Pestaña de ayuda **"¿Cómo funciona?"** con explicación del algoritmo de cuadre de cuentas.

### 4. Lista de la Compra
- Checklist interactiva con checkboxes.
- Añadir elementos manualmente.
- **Escaneo con IA**: hacer foto o subir imagen de una lista para que se extraigan los elementos automáticamente (simulado).
- Eliminación por swipe o icono de papelera.

### 5. Resumen y Gráficos
- Visualización del **gasto total** con filtro por fecha.
- **Gráfico de barras por categoría** con porcentaje y colores corporativos.
- Ordenado de mayor a menor gasto.

---

## 🏗️ Arquitectura del Proyecto

```
lib/
├── main.dart                          # Punto de entrada, tema global
├── data/
│   └── app_data.dart                  # Estado global en memoria
├── models/
│   ├── expense.dart                   # Modelo de gasto individual
│   ├── checklist_item.dart            # Modelo de elemento de checklist
│   ├── shared_expense.dart            # Modelo de gasto compartido
│   ├── shared_group.dart              # Modelo de grupo/evento compartido
│   └── shared_file.dart               # Modelo de archivo adjunto
└── screens/
    ├── welcome_screen.dart            # Pantalla de bienvenida / login
    ├── main_menu_screen.dart          # Menú principal con acceso a módulos
    ├── expenses_screen.dart           # Gestión de gastos individuales
    ├── shared_expenses_screen.dart    # Lista de eventos compartidos
    ├── shared_group_detail_screen.dart # Detalle de un evento compartido
    ├── checklist_screen.dart          # Lista de la compra
    └── summary_screen.dart            # Resumen y gráficos
```

---

## 🛠️ Stack Tecnológico

| Tecnología | Uso |
|---|---|
| **Flutter 3.8+** | Framework multiplataforma |
| **Dart** | Lenguaje de programación |
| **Material Design 3** | Sistema de diseño UI |
| **image_picker** | Acceso a cámara y galería |
| **flutter_launcher_icons** | Generación de iconos de app |

---

## 🚀 Cómo Ejecutar

```bash
# Clonar el repositorio
git clone <url-del-repositorio>
cd AICOUNT

# Instalar dependencias
flutter pub get

# Ejecutar en emulador o dispositivo
flutter run
```

---

## 📋 Hoja de Ruta (Próximas Funcionalidades)

- [ ] **Persistencia de datos**: base de datos local con `sqflite` o `hive`.
- [ ] **Modo oscuro**: implementación completa del tema dark.
- [ ] **Accesibilidad**: filtros de color para daltonismo funcionales.
- [ ] **Sincronización en la nube**: Firebase/Supabase para compartir eventos entre usuarios.
- [ ] **Compartir eventos**: mediante código QR o enlace de invitación.
- [ ] **OCR real**: integración con API de IA para lectura de tickets y listas reales.
- [ ] **Notificaciones**: recordatorios de pagos pendientes.
- [ ] **Exportar datos**: generar informes en PDF o CSV.
- [ ] **Multiidioma**: soporte para inglés y otros idiomas.

---

## 📄 Licencia

Proyecto privado. Todos los derechos reservados.

---

> *Billince — Porque gestionar tu dinero requiere la agudeza de un lince.* 🐱‍👤
