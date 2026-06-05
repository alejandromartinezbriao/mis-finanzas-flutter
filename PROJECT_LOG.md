# Log de Desarrollo - Mis Finanzas (v3.7.0 "Reloj Suizo")

## Estado Actual (Última actualización: 02/06/2026)
- **Versión**: 3.7.0 "Reloj Suizo" (Consolidación de Soberanía Local).
- **Protección Legal (BrandShield)**: Reemplazo total de logotipos de instituciones financieras y entes públicos por un sistema de **Identidad por Color e Iniciales**. Esto blinda a la aplicación contra infracciones de marca registrada, manteniendo una estética premium y profesional.
- **Arquitectura**: Migración exitosa a **SQLite-First (Offline-First)**. El teléfono es ahora la fuente de verdad primaria para máxima velocidad y funcionamiento sin internet.
- **Sincronización**:
    - **Sincronización Granular**: Implementación de botones "Sincronizar Nube" por sección (Cuentas, Categorías, Plantillas) para un control total del flujo de datos.
    - **Dashboard Dinámico**: Gesto de tirar hacia abajo (Pull-to-refresh) para bajar movimientos reales del mes y generar proyecciones instantáneamente.
- **Estabilidad y ADN**:
    - **Nativo ARGB**: Transición de colores de texto hexadecimal a Integers ARGB nativos en SQLite y Firebase, eliminando definitivamente el error de "Pantalla Gris".
    - **ID Determinístico**: Muerte al bucle 20x mediante la creación de IDs únicos basados en el tiempo para gastos recurrentes.
    - **Limpieza de Identidad**: Corrección en el agrupamiento de tarjetas de crédito (eliminación de sufijos de moneda duplicados), asegurando que los gastos se sumen correctamente a sus tarjetas dueñas.
- **Planes**: Preparado para diferenciar Gratis (Local Puro) y Premium (Cloud Sync / Backup).

---

# Historial de Versiones Anteriores

## Versión 3.4.2 (10/05/2026)
- **Interfaz**: Accesos Rápidos con iconografía circular premium, aviso de éxito y cierre optimizado.
- **Aritmética**: Respeto total a ajustes manuales en tarjetas de crédito durante la eliminación de ítems.
- **Usabilidad**: 
    - **Cierre Silencioso**: Optimización de la salida en Quick Actions para evitar parpadeos visuales del dashboard principal.
    - **Aviso de Confirmación**: Diálogo explícito de "¡Registro Exitoso!" en acciones rápidas.
    - **Herencia Visual**: Al registrar un movimiento, hereda icono y color de su categoría automáticamente.
    - **Soberanía Contable**: Al borrar un consumo de una tarjeta, el sistema resta el monto exacto del total actual respetando ajustes manuales.

## 🍎 Guía de Preparación para iOS (Quick Actions)
1. **Nombres de Recursos**: Identificadores `shortcut_simple` y `shortcut_card`.
2. **Xcode Assets**: Crear Image Sets nombrados exactamente así en `Assets.xcassets`.
3. **Mica Design**: Usar iconos circulares con transparencia.

## Hoja de Ruta (Roadmap) - Versión 3.x
- [ ] **Modo Familiar**: Sistema de "Hogares" para compartir gastos con visibilidad selectiva.
- [ ] **Análisis de Inversiones**: IA asesorando sobre dónde colocar el superávit detectado.

---
*Mis Finanzas v3.7 - La precisión de un reloj suizo con la potencia de la nube.*
