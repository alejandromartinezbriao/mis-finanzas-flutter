# Log de Desarrollo - MF (v3.7.8+7)

## Estado Actual (Última actualización: 03/06/2026)
- **Versión**: 3.7.8+7 (Pre-Lanzamiento v4.0 "Círculo Familiar").
- **Identidad**: Evolución de marca de "Mis Finanzas" a **"MF"**. Título reducido para optimizar espacio en la barra superior y dar un look profesional/minimalista.
- **Hito Familiar**: Implementación del motor de colaboración familiar.
    - **Dashboard Dual**: Sistema de "Contexto de Vista".
        - *Modo Personal*: Vista total del usuario (Datos privados + Datos compartidos). Funciona 100% Offline (SQLite).
        - *Modo Familiar*: Vista filtrada (Solo datos con `familyId`). Requiere conexión obligatoria a internet (Cloud-Only) para garantizar paridad de datos.
    - **Protocolo de Invitación**: Sistema de invitaciones basado en correo electrónico con colección global `invitations` y resolución automática de UID.
    - **Soberanía Compartida**: Inclusión de switches de "Compartir con Familia" en Gastos, Ingresos, Cuentas, Metas y Suscripciones.
    - **ADN v22**: Actualización del esquema SQLite local para soportar la columna `familyId` en todas las tablas clave.
- **Admin Suite**: Consola de "Control Maestro" invisible para usuarios normales, permitiendo soporte remoto (Limpieza de comas, corrección decimal, etc.) mediante Email o UID.

## Decisiones Arquitectónicas Estratégicas
1. **Online-Only para Familia**: Se decidió no persistir datos familiares de terceros en el SQLite local del usuario invitado. El Dashboard familiar consulta directamente a Firebase para evitar conflictos de edición y simplificar la salida de un miembro del círculo.
2. **KISS en Invitaciones**: Uso del email como ID de documento en invitaciones para búsqueda instantánea y prevención de duplicados.
3. **Filtro Contextual**: El interruptor de familia solo aparece si el usuario es Admin activo (Premium + Invitación enviada) o Miembro de un círculo, manteniendo la UI limpia para usuarios individuales.

## Hoja de Ruta Inmediata (v4.0)
- [ ] **Validación de Vínculo**: Pruebas con usuarios ficticios para verificar el flujo completo Invitación -> Aceptación -> Dashboard Compartido.
- [ ] **Transferencias Familiares**: Lógica para registrar aportes individuales a metas de ahorro compartidas.
- [ ] **Cloud Functions**: Implementar el envío automático de correos con link de descarga para invitados no registrados.
- [ ] **Monetización**: Integración de la lógica de cobro al Administrador del círculo (Suscripción Familiar).

---
*MF v3.7.8 - Liderando la gestión financiera colaborativa con precisión y seguridad.*
