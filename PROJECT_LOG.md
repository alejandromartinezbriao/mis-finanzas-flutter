# Log de Desarrollo - Mis Finanzas (v3.5.1)

## HITO: Versión 3.5.1 "Seguridad y Accesibilidad" (27/05/2026)
- **Recuperación de Cuenta**: Implementación de la función "¿Olvidaste tu contraseña?" en la pantalla de inicio de sesión. Utiliza el motor nativo de Firebase Auth para enviar correos electrónicos de restablecimiento de contraseña.
- **Consistencia Visual**: Corrección del nombre de la aplicación en la pantalla de bienvenida ("Mis Finanzas").

## HITO: Versión 3.5.0 "Arquitectura Híbrida Indestructible" (27/05/2026)
Esta versión marca el cambio estructural más profundo del proyecto hasta la fecha, transformando la aplicación en una solución **Offline-First** y estableciendo las bases técnicas y comerciales para la monetización futura.

### 1. Estrategia de Datos Híbrida (La "Regla Ale")
Se ha implementado una arquitectura de repositorio dual diseñada para segmentar el valor del producto y garantizar la continuidad operativa:
- **Configuración Universal (Nube + Local):** Las Categorías (con diseños de Mica), Cuentas, Metas, Suscripciones y Plantillas se sincronizan **siempre** en Firebase para todos los usuarios. Esto asegura que la identidad y estructura financiera del usuario lo sigan a cualquier dispositivo desde el inicio.
- **Movimientos Segmentados (Local por defecto):** Los Gastos e Ingresos se guardan prioritariamente en el almacenamiento local del teléfono (`SQLite`). La sincronización con Firebase se activa **únicamente** si el perfil del usuario tiene el campo `isPremium: true`.
- **Sincronización Agresiva Inicial:** Al abrir la v3.5.0 por primera vez, la App realiza un barrido total de Firebase para "clonar" toda la configuración existente hacia el teléfono, garantizando que el usuario tenga su App lista para usar sin internet en menos de un minuto.

### 2. Motor de Base de Datos Local
- **Tecnología:** `sqflite` (SQLite nativo) para Android e iOS.
- **Servicio:** `LocalDbService` implementado como Singleton con soporte para operaciones CRUD (Create, Read, Update, Delete) atómicas.
- **Tablas:** Estructura espejo de Firestore para `transactions`, `categories`, `balances`, `goals`, `subscriptions` y `templates`.
- **Compatibilidad Web:** Blindaje técnico mediante `kIsWeb` para asegurar que la versión de navegador siga operando directamente contra Firebase sin intentar acceder al motor SQLite inexistente en navegadores.

### 3. Experiencia del Usuario (Mimo al Tester)
- **Aviso de Blindaje Personalizado:** Al completar la primera sincronización híbrida, la App presenta un diálogo elegante que saluda al usuario por su nombre (ej: "¡Hola, Alejandro!").
- **Comunicación de Valor:** El aviso informa al usuario que sus datos ya están "blindados" en modo local (offline) y le recuerda su estatus Premium con respaldo en la nube y acceso desde PC.

---

## HITO: Versión 3.4.x "Identidad y Refinamiento UX"
Consolidación de la imagen de marca de Mica y optimización del registro diario.

### 4. Registro Relámpago (Quick Actions)
- **Funcionalidad:** Menú contextual nativo al mantener presionado el icono de la App.
- **Etiqueta Unificada:** Cambio de "Gasto Simple" a "Ingreso / Gasto" para mayor precisión funcional.
- **Modo Foco:** Interfaz de carga minimalista que prioriza la velocidad y la privacidad de los saldos totales durante el registro rápido.
- **Cierre Silencioso:** Optimización de salida (`SystemNavigator.pop()`) con un reset de estado diferido (500ms) para evitar parpadeos visuales del dashboard principal.

### 5. Identidad Visual Premium (Mica)
- **Iconografía Circular:** Implementación de nuevos diseños circulares que aprovechan el 100% del área del icono.
- **Arquitectura XML Android:** Uso de `layer-list` en `shortcut_simple.xml` y `shortcut_card.xml` para garantizar la visibilidad en dispositivos con capas de personalización estrictas (Xiaomi/MIUI).
- **Herencia Visual:** Persistencia automática del **icono y color** de categoría en cada nuevo registro, eliminando la necesidad de ediciones manuales posteriores.

### 6. Soberanía Contable en Tarjetas
- **Lógica de Sustracción Pura:** Al eliminar consumos, el sistema resta el monto exacto del total actual. Se respeta cualquier ajuste manual previo realizado por el usuario, evitando recalculados totales que sobrescriban ediciones personalizadas.

---

## HITO: Versión 3.2.x - 3.3.x "Cerebro Centralizado"
### 7. IA Server-Side (Cloud Functions)
- **Centralización:** El cálculo de firmas (Hash) y recolección de datos se realiza en Firebase Functions (Node.js).
- **Eficiencia:** Sincronización perfecta de informes entre móvil y PC, optimizando costes y garantizando coherencia en el asesoramiento de Finanz-IA.

---
*Mis Finanzas v3.5 - Potencia local, inteligencia en la nube y trato personal.*
