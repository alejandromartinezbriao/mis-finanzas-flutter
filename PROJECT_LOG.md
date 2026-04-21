# Log de Desarrollo - Cuentas Personales

## Estado Actual (Última actualización: hoy)
- **Interfaz**: Profesional, responsiva (Web/Móvil) con tema Teal.
- **Fuentes**: Ajustadas para alta legibilidad (Saldos 32px, títulos 18px).
- **Funcionalidad**: Arqueo de saldos reales, cobertura de deuda, carga inteligente de plantillas (evita duplicados con cuotas de tarjetas).
- **Infraestructura**: Código en GitHub (`main`), Despliegue en Firebase Hosting.

## Decisiones Arquitectónicas Tomadas
1. **Lógica de Plantillas**: El sistema verifica la existencia de títulos antes de generar fijos mensuales para permitir convivencia con cuotas de tarjetas cargadas por adelantado.
2. **Navegación**: Menú superior (AppBar) para acciones de gestión (Cargar plantillas, Limpiar mes) para mantener la interfaz limpia.

## Hoja de Ruta Futura (Roadmap)
1. **Modelo de Negocio (Híbrido)**:
   - **Fase Local**: Uso offline con base de datos interna (SQLite/Isar) para privacidad y velocidad.
   - **Fase Cloud (Suscripción)**: Sincronización con Firebase, acceso Web y respaldo.
2. **Funcionalidades Pro**:
   - **Modo Familiar**: Creación de "Hogares" compartidos con múltiples perfiles y sincronización en tiempo real.
   - **Exportación**: Generación de reportes en PDF (resumen ejecutivo) y Excel (datos crudos para contadores).
3. **Análisis**: Integración de `fl_chart` para visualización de gastos por categoría.

## Datos de Mercado Estimados
- **Precio sugerido**: USD 2.99/mes o USD 24.99/año.
- **Estrategia**: "Offline First" para generar confianza y "Cloud" para valor añadido y comodidad familiar.
- **Punto de equilibrio**: ~5 usuarios pagos cubren costos operativos fijos.
