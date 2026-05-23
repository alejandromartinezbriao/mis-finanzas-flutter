# Log de Desarrollo - Mis Finanzas (v2.0.0)

## Estado Actual (Última actualización: 10/05/2026)
- **Versión**: 2.0.0 "Evolución Estructural".
- **Interfaz**: Profesional y minimalista, optimizada para Web y Móvil.
- **Aritmética**: Estandarización total de punto decimal (`.`) como único separador. Eliminación física de comas (`,`) de miles en toda la interfaz para evitar ambigüedades.
- **Usabilidad**: 
    - **Registro de Cuotas Flexible**: Nuevo campo "Cuota Próxima" para registrar deudas existentes facilitando la migración.
    - **Asistente Financiero IA**: Integración con Google AI Studio (Gemini) mediante Cloud Functions para análisis automatizado de gastos y consejos de ahorro personalizados.
    - **Mantenimiento Avanzado**: Suite interactiva para corrección de decimales (error 100x), normalización y sincronización supervisada.
    - **Presupuestos Seguros**: Flujo de confirmación manual para garantizar la persistencia de presupuestos.
    - **Control de Cobertura Selectivo**: Opción para excluir cuentas específicas del cálculo de dinero disponible.
- **Sincronización Bimonetaria Inteligente**: Las plantillas de tarjeta bimonetarias ahora se mantienen sincronizadas automáticamente.
- **Inteligencia de Datos (Caché IA)**: Implementación de un sistema de "Huella Digital de Datos" para el Asesor Financiero. La App ahora genera una firma única basada en los números del mes; si los datos no cambian, se recupera el análisis previo desde Firestore.
- **Historial de Asesoría IA**: Nueva sección dedicada para consultar todos los informes generados por Finanz-IA. Los informes se guardan permanentemente con fecha y hora, permitiendo un seguimiento evolutivo de los consejos financieros.
- **Registro de Efectivo Agilizado**: Se añadió la opción "Pago en Efectivo (Sin cuenta)" directamente en el selector de cuentas.
- **Optimización de Formularios**: Rediseño lógico del diálogo de plantillas. Se ocultan opciones irrelevantes (como "incluido en tarjeta" para las propias tarjetas) y se agrupan las opciones bimonetarias para mayor claridad.
- **Infraestructura**: Soporte PWA completo (iconos Web/iOS), Firebase, fl_chart y persistencia local.

## Decisiones Arquitectónicas Tomadas (v2.0)
1. **Regla de Oro de Datos**: El punto decimal es la verdad absoluta del sistema. Cualquier coma entrante se convierte o se ignora para proteger la integridad de Firestore.
2. **Cobertura Temporal Proyectada**: Evolución del widget de cobertura para soportar modos histórico (Cierre), actual (Disponibilidad) y futuro (Proyección).
3. **Mantenimiento Supervisado**: Filosofía de "Detección -> Propuesta -> Aprobación" para todas las herramientas de limpieza de base de datos.
4. **Optimización PWA**: Configuración de manifiestos y cabeceras para experiencia nativa en iPhone y Android.

## Hoja de Ruta (Roadmap) - Versión 2.x
- [x] **Monetización Inteligente**: Implementación de límites de uso para el asesor de IA. Usuarios gratuitos tienen 1 análisis por mes; usuarios Premium tienen acceso ilimitado.
- [ ] **Modo Familiar**: Sistema de "Hogares" para compartir gastos con visibilidad selectiva.
- [ ] **Migración de Datos Locales**: Proceso para usuarios que pasan de modo offline a nube.
- [ ] **Refactorización a Repositorios**: Abstracción total de la capa de persistencia.

## Hito: Lanzamiento Versión 2.0 (10/05/2026)
Se declara oficialmente el salto a la **Versión 2.0** debido a la reestructuración completa del núcleo de la aplicación.
- **Motor Bimonetario**: Implementación nativa en todas las cuentas y tarjetas.
- **Automatización**: Nuevo módulo de suscripciones vinculado a la lógica de tarjetas.
- **Inteligencia de Datos**: Suite de mantenimiento interactivo para asegurar la integridad aritmética.
- **Rediseño de Cobertura**: Sistema de proyecciones dinámicas (Pasado/Presente/Futuro).
- **Compatibilidad Total**: Optimización para iPhone (teclado y PWA) y Web.

## Últimos Avances (10/05/2026)
- **Estrategia de Monetización IA**: Implementación de un sistema de cuotas para el uso de Gemini a través de Vertex AI. El sistema rastrea el mes del último análisis realizado por el usuario. Si el usuario no es Premium, se bloquea el acceso tras el primer uso mensual para proteger el presupuesto de infraestructura del proyecto.
- **Integración de Inteligencia Artificial**: Implementación del módulo "Asesor Financiero IA" accesible desde el menú principal. Utiliza un modelo de lenguaje avanzado (Gemini 1.5 Flash) para analizar la salud financiera del usuario y proponer acciones concretas de ahorro basadas en sus datos reales de Firestore.
- **Registro de Tarjetas Flexible**: Introducción del campo "Cuota Próxima" para registrar deudas existentes desde un punto arbitrario.
- **Seguridad en Presupuestos**: Eliminación del guardado automático inline en favor de un flujo de confirmación supervisado para garantizar la persistencia.
- **Normalización de Formatos**: Herramienta interactiva para purificar descripciones antiguas eliminando comas de miles.
- **Soporte PWA (Web & iOS)**: Generación de iconos optimizados y metatags para visualización impecable del logo en todas las plataformas.
- **Compatibilidad iPhone (Teclado)**: El formateador acepta comas del teclado iOS y las convierte a puntos en tiempo real.
- **Control de Cobertura Selectivo**: Nueva configuración por cuenta ("Considerar para Cobertura") para cálculos más conservadores.

---
*Mis Finanzas v2.0 - Desarrollado con enfoque en integridad y usabilidad.*
