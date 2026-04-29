# Log de Desarrollo - Cuentas Personales

## Estado Actual (Última actualización: 29/04/2026)
- **Interfaz**: Profesional y minimalista, optimizada para Web y Móvil. Nuevo AppBar con logo adaptativo.
- **Fuentes**: Tipografía monocromática de alta legibilidad (Negro/Blanco dinámico).
- **Arquitectura**: Código desacoplado mediante extracción de Widgets, Diálogos y Repositorios lógicos.
- **Funcionalidad**: 
    - Arqueo de saldos reales y cobertura de deuda.
    - **Pagos Vinculados**: Al marcar un gasto como pago, se puede seleccionar la cuenta de origen y descontar el saldo automáticamente.
    - Carga inteligente de plantillas con soporte para suscripciones fijas.
    - Control de Presupuestos mensuales por categoría.
    - Gestión avanzada de Tarjetas de Crédito (cuotas automáticas y mínimos).
    - Metas de ahorro inteligentes con reserva de fondos.
    - Manual de Usuario y sección informativa integrados en la app.
- **Infraestructura**: Firebase (Auth/Firestore), QuickActions, fl_chart y persistencia local activa.

## Decisiones Arquitectónicas Tomadas
1. **Desacoplamiento (Widgets)**: Extracción de componentes visuales clave (`DebtCoverageCard`, `SummaryBalanceCard`, `AccountBalanceDisplay`, `TransactionItemTile`) a la carpeta `lib/widgets/`.
2. **Modularización de Diálogos**: Traslado de formularios complejos a `lib/dialogs/transaction_dialogs.dart` para reducir el tamaño de `HomePage` y mejorar la mantenibilidad.
3. **Utilidades Centralizadas**: Creación de `IconUtils` con selector unificado de iconos Material y logos de empresas locales (BROU, Itaú, Santander, UTE, OSE, etc.).
4. **Quick Actions**: Implementación de accesos directos ("Nuevo Gasto" y "Compra con Tarjeta") para agilizar el registro desde el escritorio del móvil.

## Hoja de Ruta (Roadmap) - Estado de Situación

### ✅ Fase 1: Estabilización y Arquitectura (Completado)
- [x] Refactorización de `HomePage` (de 1000+ a 370 líneas).
- [x] Separación de diálogos y widgets.
- [x] Soporte para Quick Actions.
- [x] Visualización con `fl_chart`.
- [x] Pantalla de Estadísticas Históricas (Gráfico de barras 6 meses).

### 🚀 Fase 2: Robustez de Datos (Completado)
- [x] **Modo Offline**: Persistencia de Firestore habilitada (Cache ilimitado).
- [x] **Validación de Formularios**: Formateo automático de moneda y validaciones de campos.
- [x] **Categorización Flexible**: Soporte para movimientos sin categoría obligatoria.
- [x] **Presupuestos**: Control de límites de gasto mensual por categoría.

### 📊 Fase 3: Análisis y Reportes (Completado)
- [x] **Exportación**: Generación de reportes en CSV (Excel compatible) con opción de compartir.
- [x] **Análisis Avanzado**: Comparativa de categorías mes a mes integrada en Estadísticas.
- [x] **Metas y Transferencias**: Sistema de ahorro vinculado a cuentas reales.

### 💎 Fase 4: Monetización y Multi-usuario (Siguiente Paso)
- [ ] **Modo Familiar**: Compartir "Hogares" entre varios usuarios.
- [ ] **Modelo Premium**: Definición de límites para usuarios gratuitos vs pagos.

## Últimos Avances (29/04/2026)
- **UX/UI**: Rediseño de la barra de navegación superior con un logo minimalista y optimización de espacio para iconos de acción.
- **Documentación In-App**: Creación e integración de las pantallas "Acerca de" y "Manual del Usuario" con diseño responsivo y tipografía monocromática.
- **Estrategia de Negocio**: Elaboración de un plan detallado de monetización (Fase 4) incluyendo proyecciones de costos de infraestructura y dominios web.
- **Gestión de Ahorros**: Implementación de metas vinculadas a cuentas reales con reserva de saldo automática.
- **Transferencias**: Nuevo sistema de movimientos de fondos entre cuentas y hacia metas.
- **Presupuestos**: Pantalla dedicada para asignar límites mensuales y visualizar cumplimiento.
- **Multiplataforma**: Mejoras en la visualización web mediante el uso de contenedores con ancho controlado.
- **Pagos Automáticos**: Integración de lógica para descontar saldos de cuentas bancarias al completar transacciones.

---
*Desarrollado con enfoque en modularidad y escalabilidad.*
