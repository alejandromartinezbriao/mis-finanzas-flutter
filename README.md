# Mis Finanzas - Gestión de Gastos y Cobertura (v2.0)

Una aplicación de finanzas personales desarrollada en Flutter, diseñada para ofrecer un control total sobre los gastos mensuales, la gestión de deudas y la liquidez real del usuario.

## 🚀 Características Principales (v2.0)

- **Gestión Bimonetaria Nativa:** Manejo nativo y simultáneo de Pesos Uruguayos (UYU) y Dólares (USD) en cuentas, tarjetas, presupuestos y suscripciones.
- **Análisis de Cobertura Inteligente:** Compara tu **disponible libre** contra tus **deudas** en el mes actual, visualiza el **cierre de mes** (superávit/déficit) en el pasado, o proyecta tu salud financiera en meses **futuros**.
- **Mantenimiento y Calidad de Datos:** Suite de utilidades interactivas para corregir errores aritméticos (error 100x), normalizar formatos de texto y sincronizar cuotas mediante aprobación manual.
- **Sincronización Inteligente de Tarjetas:** Las tarjetas bimonetarias mantienen sus atributos (vencimiento, logo, categoría) sincronizados automáticamente entre Pesos y Dólares.
- **Registro de Efectivo Directo:** Opción para registrar pagos de bolsillo sin necesidad de vincularlos a una cuenta bancaria desde el primer paso.
- **Suscripciones Automatizadas:** Módulo para gestionar pagos recurrentes (Netflix, Spotify, servicios) con vinculación inteligente a tarjetas de crédito.
- **Entrada de Datos Blindada:** Regla de oro del punto decimal (`.`) estricto. La interfaz oculta comas de miles para evitar ambigüedades aritméticas.
- **Registro de Tarjetas Flexible:** Permite registrar compras financiadas empezando desde una cuota específica ("Cuota Próxima") para facilitar la migración de deudas existentes.
- **Metas de Ahorro Inteligentes:** Define metas y vincula cuentas reales. El dinero ahorrado se "reserva" y se resta del disponible para gastos.
- **Ingresos con Auto-saldo:** Asigna tus ingresos directamente a cuentas bancarias para mantener tus balances actualizados al instante.
- **UX Optimizada:** Rediseño minimalista, visualización estandarizada de 2 decimales y selector unificado de iconografía con logos de bancos de Uruguay.
- **Modo Offline:** Persistencia de datos local con sincronización automática a Firebase.

## 📄 Documentación del Proyecto

Para más detalles sobre la visión, uso y futuro del proyecto:
- [Manual del Usuario](USER_MANUAL.md): Guía detallada de todas las funcionalidades.
- [Acerca de la App](ABOUT_APP.md): Misión, capacidades y detalles técnicos.
- [Plan de Monetización](MONETIZATION_PLAN.md): Estrategia de negocio y proyecciones.
- [Log de Proyecto](PROJECT_LOG.md): Historial técnico y hoja de ruta.

## 🛠️ Stack Tecnológico

- **Framework:** Flutter (Android, iOS, Web PWA)
- **Backend:** Firebase (Auth & Cloud Firestore)
- **Gráficos:** fl_chart
- **Localización:** intl (Uruguay/EE.UU. - Punto Decimal Estricto)

---
Desarrollado con ❤️ para mejorar la salud financiera.
