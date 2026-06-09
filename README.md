# MF (Evolución de Mis Finanzas) - El Reloj Suizo Polimórfico

MF es una plataforma de gestión financiera de precisión diseñada bajo el concepto de **Arquitectura Unificada**. Un solo código que se adapta dinámicamente tanto para el uso **Individual Premium** como para el **Círculo Familiar Colaborativo**.

## 🚀 Hito v4.0: El Motor Unificado (Universal Engine)

A partir de la versión 4.0.0, MF implementa una infraestructura de sincronización de grado industrial que resuelve los problemas clásicos de pérdida de datos en entornos móviles.

### 🛡️ Pilares de Integridad
1. **Soberanía Local (Offline-First)**: El dispositivo del usuario es la fuente de verdad primaria. MF protege los datos locales y prohíbe que la nube los sobreescriba si el dato local es más reciente (`Integridad por Timestamps`).
2. **Latencia Cero**: Gracias al cacheo inteligente del perfil de usuario, las escrituras en la nube son instantáneas, eliminando el lag que suele causar desincronización entre dispositivos y Web.
3. **Ruteo Inteligente**: Un sistema de GPS de datos interno (`getDocRef`) detecta automáticamente si el usuario está operando en su carpeta privada o en el círculo compartido, garantizando que el dinero siempre se descuente de la cuenta correcta.
4. **ADN Estructurado**: Las tarjetas de crédito ahora utilizan objetos JSON internos para manejar cuotas con IDs únicos (`PID`), permitiendo borrados en cadena infalibles sin colisión de nombres.

## 🏛️ Arquitectura Técnica
- **Frontend**: Flutter (Material 3).
- **Base de Datos Local**: SQLite v22 (Esquema Protegido).
- **Backend**: Firebase Firestore con ruteo polimórfico.
- **Sincronización**: Protocolo de comparación temporal y estados de protección `pending`/`synced`.

## 🛠️ Guía para el Desarrollador
El código está diseñado para ser **agnóstico al tipo de usuario**. No se deben crear versiones ad-hoc. Cualquier mejora en la lógica de datos beneficia tanto al usuario solitario como a la familia.

### Administración
La Suite de **Control Maestro** (UID: `M8DdrH5YCtS8lVzaUh93Fx1DoF63`) permite el soporte remoto y la auditoría de integridad para resolver incidencias de usuarios Premium de forma transparente.

---
*MF v4.0.0 - Ingeniería de software aplicada a la libertad financiera.*
