# Log de Desarrollo - MF (v4.0.0+10)

## Hito: Motor Unificado de Sincronización (v4.1.2) - 04/06/2026
- **Versión**: 4.0.0+10.
- **Arquitectura**: Implementación del **Universal Engine**. El sistema ahora detecta y rutea datos automáticamente entre uso Individual y Familiar sin cambios de código.
- **Blindaje de Integridad (Anti-Regresión)**:
    - **Soberanía Temporal**: Se implementó lógica de comparación por `updatedAt`. El teléfono ahora protege los datos locales más recientes y rechaza datos antiguos de la nube durante el "Pull-to-refresh".
    - **Estado de Protección**: Los registros en estado `pending` tienen prohibido ser sobreescritos por la sincronización.
- **Identidad con Latencia Cero**:
    - Se implementó un cacheo de perfil en `AuthService`. La App ya no consulta la red para verificar el estado Premium antes de escribir, eliminando el lag en las transacciones.
- **GPS de Datos Inteligente**: Refactorización de `FirebaseBase` para un ruteo transparente. Una sola línea de código decide si el dato viaja a la carpeta personal o a la del administrador del círculo familiar.
- **Consolidación Contable**:
    - Confirmación obligatoria para ajustes de saldo al editar montos.
    - Devolución de dinero confirmada al eliminar gastos pagados.
    - Borrado atómico por `PurchaseID` (PID) para tarjetas, permitiendo eliminar series de cuotas específicas sin afectar a otros ítems con el mismo nombre.

## Decisiones Estratégicas de Ingeniería
1. **Unificación de Código**: Se rechazó la creación de versiones ad-hoc. La App es ahora un producto de ingeniería polimórfico.
2. **Prioridad Local**: En caso de conflicto de red, la verdad reside en el dispositivo del usuario hasta que se confirme la subida exitosa.
3. **ADN Estructurado**: El campo de descripción de tarjetas ahora usa JSON para mantener la integridad de los metadatos (IDs de compra, fechas originales, etc.).

## Hoja de Ruta (Hacia v4.1)
- [ ] Implementar índices en Firebase para optimizar consultas de `collectionGroup` en modo familiar a gran escala.
- [ ] Refinar las gráficas de estadísticas para soportar la comparativa "Mis Gastos" vs "Gastos del Hogar".
- [ ] Iniciar pruebas de carga con múltiples miembros familiares sincronizando simultáneamente.

---
*MF v4.0.0 - Ingeniería de precisión para la soberanía económica.*
