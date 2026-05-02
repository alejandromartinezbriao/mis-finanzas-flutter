# Log de Desarrollo - Cuentas Personales

## Estado Actual (Última actualización: 02/05/2026)
- **Interfaz**: Profesional y minimalista, optimizada para Web y Móvil. Nuevo AppBar con logo adaptativo.
- **Fuentes**: Tipografía monocromática de alta legibilidad (Negro/Blanco dinámico).
- **Arquitectura**: Código desacoplado mediante extracción de Widgets, Diálogos y Repositorios lógicos.
- **Funcionalidad**: 
    - Arqueo de saldos reales y cobertura de deuda dinámica.
    - **Pagos Vinculados**: Soporte para descontar saldos automáticamente y reversión de pagos.
    - **Ingresos Inteligentes**: Asignación directa a cuentas bancarias al momento del registro.
    - **Validación de Datos**: Política de "Cero Tolerancia" en entrada de montos (coma decimal obligatoria).
    - Gestión avanzada de Tarjetas de Crédito, Presupuestos y Metas de Ahorro.
    - Documentación y manual de usuario integrados en la app.
- **Infraestructura**: Firebase (Auth/Firestore), QuickActions, fl_chart y persistencia local activa.

## Decisiones Arquitectónicas Tomadas
1. **Desacoplamiento (Widgets)**: Extracción de componentes visuales clave a `lib/widgets/`.
2. **Modularización de Diálogos**: Traslado de formularios complejos a `lib/dialogs/` para mejorar la mantenibilidad.
3. **Utilidades Centralizadas**: Creación de `IconUtils` con selector unificado de iconos Material y logos locales.
4. **Inteligencia Temporal**: Implementación de lógica dinámica para el cuadro de cobertura (Pasado/Presente/Futuro).

## Hoja de Ruta (Roadmap) - Estado de Situación

### ✅ Fase 1: Estabilización y Arquitectura (Completado)
- [x] Refactorización de `HomePage` y separación de componentes.
- [x] Soporte para Quick Actions y visualización con `fl_chart`.

### 🚀 Fase 2: Robustez de Datos (Completado)
- [x] **Modo Offline**: Persistencia de Firestore habilitada.
- [x] **Validación Estricta**: Formateo de coma decimal y bloqueo de puntos.
- [x] **Presupuestos**: Control de límites mensuales por categoría.

### 📊 Fase 3: Análisis y Reportes (Completado)
- [x] **Exportación**: Generación de reportes CSV (Excel).
- [x] **Metas y Transferencias**: Sistema de ahorro vinculado a cuentas reales.
- [x] **Cierre de Mes**: Cálculo automático de Superávit/Déficit en el historial.

### 💎 Fase 4: Monetización y Multi-usuario (Siguiente Paso)
- [ ] **Modo Familiar**: Compartir "Hogares" entre varios usuarios.
- [ ] **Modelo Premium**: Persistencia en la nube vs local para usuarios gratuitos.

## Últimos Avances (02/05/2026)
- **Ingresos Inteligentes**: El registro de ingresos ahora permite seleccionar la cuenta de destino (o efectivo), actualizando el saldo de forma automática y atómica en Firebase.
- **Identidad Visual**: Implementación de un código de colores intuitivo: **Verde** para ingresos/completados y **Naranja Rojizo (DeepOrange)** para egresos/pendientes, aplicado globalmente por sugerencia de usuario (Vero).
- **Inteligencia Temporal**: El cuadro de cobertura ahora es dinámico (Cierre de Mes con resultado exacto en pasado, Cobertura en presente, oculto en futuro).

## Historial de Hitos Recientes
- **Documentación In-App**: Integración de las pantallas "Acerca de" y "Manual del Usuario" con diseño responsivo.
- **Estrategia de Negocio**: Elaboración del plan detallado de monetización y proyecciones.
- **Pagos Automáticos**: Lógica para descontar saldos bancarios al completar transacciones.
- **Robustez de Montos**: Implementación de formateadores estrictos y visualización de 2 decimales.
- **Gestión de Ahorros**: Metas vinculadas a cuentas reales con reserva de saldo automática.
- **Multiplataforma**: Contenedores con ancho controlado para visualización web impecable.

---
*Desarrollado con enfoque en modularidad y escalabilidad.*
