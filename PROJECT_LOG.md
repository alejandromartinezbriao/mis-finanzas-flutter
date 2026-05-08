# Log de Desarrollo - Cuentas Personales

## Estado Actual (Última actualización: 06/05/2026)
- **Interfaz**: Profesional y minimalista, optimizada para Web y Móvil.
- **Identidad**: Proyecto renombrado formalmente a **Mis Finanzas**.
- **Aritmética**: Estandarización total de 2 decimales en toda la cadena de datos (Ingreso, Firebase, Visualización) eliminando ruido de punto flotante.
- **Usabilidad**: 
    - **Registro Instantáneo**: Capacidad de registrar un gasto y descontar el saldo de una cuenta en un solo paso.
    - **Edición Flexible**: Edición total de conceptos, categorías y montos en transacciones ya registradas.
    - **Confirmación Activa**: Diálogos de confirmación antes de guardar registros para prevenir errores accidentales.
    - **Reordenamiento Total**: Soporte para reordenar cuentas bancarias por prioridad del usuario.
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
- [ ] **Estrategia Híbrida de Datos**: 
    - Usuarios Gratuitos: Almacenamiento puramente local (sin Firebase Auth/Firestore).
    - Usuarios Premium: Sincronización completa con Firebase (Acceso Web, Multi-dispositivo).
- [ ] **Modo Familiar**: Implementación de "Hogares" para compartir gastos, con soporte para visibilidad selectiva (Privado/Compartido).
- [ ] **Proceso de Migración**: Sistema de "ascensión" de datos locales a la nube al adquirir suscripción Premium.
- [ ] **Refactorización a Repositorios**: Abstracción de la capa de datos para alternar entre DB Local y Firestore de forma transparente.

## Últimos Avances (06/05/2026)
- **Estandarización Numérica**: Implementación de redondeo a 2 decimales en el core de Firebase Service para evitar cifras con excesiva precisión decimal.
- **Registro de Gasto con Pago**: Optimización del flujo de "Nuevo Movimiento" permitiendo seleccionar la cuenta de pago al instante, eliminando la necesidad de marcar el gasto como pagado manualmente después de crearlo.
- **Edición Avanzada**: Apertura de campos "Concepto" y "Categoría" en el diálogo de edición de movimientos.
- **Cuentas Reordenables**: Extensión del sistema de drag-and-drop a la pestaña de "Mis Cuentas" en la configuración maestra.
- **Confirmación de Seguridad**: Implementación de diálogos de confirmación previa al guardado de cualquier movimiento o compra con tarjeta.
- **Robustez en Tarjetas**: Mejora en la lógica de eliminación de consumos de tarjeta; ahora el sistema recalcula el total sumando los ítems restantes para evitar errores de redondeo o pérdida de datos.
- **Gráficos Precisos**: Estandarización de los tooltips en estadísticas para mostrar cifras monetarias formateadas.

## Historial de Hitos Recientes
- **Documentación In-App**: Integración de las pantallas "Acerca de" y "Manual del Usuario" con diseño responsivo.
- **Estrategia de Negocio**: Elaboración del plan detallado de monetización y proyecciones.
- **Pagos Automáticos**: Lógica para descontar saldos bancarios al completar transacciones.
- **Robustez de Montos**: Implementación de formateadores estrictos y visualización de 2 decimales.
- **Gestión de Ahorros**: Metas vinculadas a cuentas reales con reserva de saldo automática.
- **Multiplataforma**: Contenedores con ancho controlado para visualización web impecable.

---
*Desarrollado con enfoque en modularidad y escalabilidad.*
