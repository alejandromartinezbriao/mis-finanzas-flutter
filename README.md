# Mis Finanzas - Gestión de Gastos y Cobertura

Una aplicación de finanzas personales desarrollada en Flutter, diseñada para ofrecer un control total sobre los gastos mensuales, la gestión de deudas y la liquidez real del usuario.

## 🚀 Características Principales

- **Gestión Bimonetaria:** Manejo nativo y simultáneo de Pesos Uruguayos (UYU) y Dólares (USD).
- **Análisis de Cobertura Dinámico:** Compara tu **disponible libre** contra tus **deudas** en el mes actual, o visualiza el **cierre de mes** (superávit/déficit exacto) al consultar meses pasados.
- **Ingresos con Auto-saldo:** Asigna tus ingresos directamente a cuentas bancarias al registrarlos para mantener tus balances actualizados sin esfuerzo.
- **Identidad Visual Intuitiva:** Código de colores estandarizado (**Verde** para ingresos, **Naranja Rojizo** para egresos) para una interpretación inmediata del estado financiero.
- **Presupuestos Mensuales:** Define límites de gasto por categoría y monitorea el cumplimiento en tiempo real.
- **Metas de Ahorro Inteligentes:** Define metas y vincula cuentas reales. El dinero ahorrado se "reserva" y se resta del disponible para gastos, evitando el uso accidental de ahorros.
- **Transferencias y Movimientos:** Gestión fluida de fondos entre cuentas y hacia metas de ahorro.
- **Gestión de Tarjetas de Crédito:** Registro de compras en cuotas con distribución automática, manejo de pagos mínimos y soporte para suscripciones fijas dentro del estado de cuenta.
- **Modo Offline:** Persistencia de datos local para trabajar sin conexión; sincronización automática al recuperar señal.
- **Plantillas y Automatización:** Carga rápida de gastos e ingresos fijos. Posibilidad de convertir cualquier transacción en una plantilla recurrente.
- **Análisis Histórico y Exportación:** Gráficos de evolución de los últimos 6 meses, filtros por categoría y exportación de reportes a CSV (compatible con Excel).
- **UX Optimizada e Identidad Visual:** Rediseño minimalista con logo adaptativo, visualización estandarizada de 2 decimales y selector unificado de iconografía con más de 50 iconos de Material y logos personalizados para bancos y servicios de Uruguay.
- **Entrada de Datos Blindada:** Sistema de validación estricto para montos (uso de punto decimal) y redondeo automático a 2 decimales en toda la aplicación.
- **Organización Flexible:** Capacidad de reordenar tus plantillas y cuentas bancarias con un simple gesto de arrastrar.
- **Documentación y Ayuda:** Manual de usuario y sección informativa integrados directamente en la aplicación para facilitar el aprendizaje de nuevas funciones.

## 📄 Documentación del Proyecto

Para más detalles sobre la visión, uso y futuro del proyecto, consulta los siguientes archivos:
- [Manual del Usuario](USER_MANUAL.md): Guía detallada de todas las funcionalidades.
- [Acerca de la App](ABOUT_APP.md): Misión, capacidades y detalles técnicos.
- [Plan de Monetización](MONETIZATION_PLAN.md): Estrategia de negocio, proyecciones y costos de infraestructura.
- [Log de Proyecto](PROJECT_LOG.md): Historial de cambios y hoja de ruta técnica.

## 🛠️ Stack Tecnológico

- **Framework:** [Flutter](https://flutter.dev/)
- **Backend:** [Firebase](https://firebase.google.com/) (Authentication & Cloud Firestore)
- **Gráficos:** [fl_chart](https://pub.dev/packages/fl_chart)
- **Formateo Local:** [intl](https://pub.dev/packages/intl) para moneda y fechas de Uruguay/EE.UU.

## 📥 Inicio y Configuración

La aplicación está diseñada bajo el concepto de **lienzo en blanco**:
1. **Registro:** Cada nuevo usuario inicia con una cuenta totalmente vacía.
2. **Personalización:** El usuario define sus propias categorías, cuentas bancarias y plantillas de gastos según su necesidad.
3. **Privacidad:** Los datos están aislados por usuario mediante Firebase Auth.

### Requisitos de Desarrollo
Para correr este proyecto localmente, necesitas:
- Flutter SDK instalado.
- Un proyecto en Firebase con Firestore y Auth habilitados.
- Descargar y colocar el archivo `google-services.json` en `android/app/`.

## 📸 Capturas de Pantalla
*(Próximamente)*

---
Desarrollado con ❤️ para mejorar la salud financiera.
