# MF (Antes Mis Finanzas) - El Reloj Suizo de las Finanzas Familiares

MF es una aplicación de gestión financiera de alto rendimiento, diseñada bajo el paradigma **Offline-First** (Soberanía Local) y extendida con capacidades de **Colaboración Familiar** en tiempo real.

## 🏛️ Arquitectura del Sistema

### 1. Motor Local (Reloj Suizo)
- **Tecnología**: SQLite v22.
- **Soberanía**: El teléfono es la fuente de verdad primaria. La App es totalmente funcional sin internet (Modo Avión).
- **ADN Nativo**: Uso de Integers ARGB para colores y gestión exacta de decimales para evitar errores aritméticos.

### 2. Círculo Familiar (v4.0 Ready)
- **Ecosistema**: Permite unir a múltiples usuarios bajo un mismo paraguas económico.
- **Privacidad**: Cada usuario decide, elemento por elemento (gastos, cuentas, metas), qué desea compartir con su familia y qué desea mantener privado.
- **Online-Only**: Mientras los datos personales son locales, la vista familiar es una ventana directa a la nube, garantizando que todos los miembros vean exactamente lo mismo al mismo tiempo.

### 3. Centro de Inteligencia (Finanz-IA)
- Auditoría de gastos y proyecciones estratégicas a 6 meses.
- Sincronización transparente entre Web, PC y Móvil.

## 🚀 Guía para Desarrolladores / Agentes

### Estado de la Sincronización
- **Pull-to-refresh**: En el Dashboard, este gesto actualiza Movimientos, Balances, Metas y Categorías simultáneamente.
- **Granularidad**: Cada sección del Panel de Control tiene su propio botón de "Sincronizar Nube".

### Administración Remota
La App incluye una **Suite de Control Maestro** accesible únicamente para el UID de administración (`M8DdrH5YCtS8lVzaUh93Fx1DoF63`). Desde aquí se puede:
- Resolver correos electrónicos a UID.
- Ejecutar limpiezas de datos remotos sobre cualquier cuenta de usuario.

### Próximos pasos técnicos
El foco actual es la validación del flujo de **Círculo Familiar**:
1. Envío de invitación (Colección `invitations`).
2. Aceptación de vínculo (Campo `familyId` en `users`).
3. Filtrado dinámico en `HomePage` basado en `_isFamilyMode`.

---
*Desarrollado para transformar la economía doméstica mediante ingeniería de software de precisión.*
