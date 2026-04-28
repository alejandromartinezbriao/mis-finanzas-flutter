# Mis Finanzas - Gestión de Gastos y Cobertura

Una aplicación de finanzas personales desarrollada en Flutter, diseñada para ofrecer un control total sobre los gastos mensuales, la gestión de deudas y la liquidez real del usuario.

## 🚀 Características Principales

- **Gestión Bimonetaria:** Manejo nativo y simultáneo de Pesos Uruguayos (UYU) y Dólares (USD).
- **Análisis de Cobertura de Deuda:** Compara tu **disponible libre** contra tus **obligaciones pendientes**.
- **Metas de Ahorro Inteligentes:** Define metas y vincula cuentas reales. El dinero ahorrado se "reserva" y se resta del disponible para gastos, evitando el uso accidental de ahorros.
- **Transferencias y Movimientos:** Gestión fluida de fondos entre cuentas y hacia metas de ahorro.
- **Gestión de Tarjetas de Crédito:** Registra compras en cuotas con distribución automática en meses futuros y asignación de categorías por compra.
- **Modo Offline:** Persistencia de datos local para trabajar sin conexión; sincronización automática al recuperar señal.
- **Plantillas y Automatización:** Carga rápida de gastos e ingresos fijos.
- **Análisis Histórico y Exportación:** Gráficos de evolución de los últimos 6 meses, filtros por categoría y exportación de reportes a CSV (compatible con Excel) en Web y Móvil.
- **UX Optimizada:** Formateo automático de miles mientras escribes y categorización flexible.
- **Identidad Visual:** Reconocimiento automático de logos para servicios y bancos.

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
