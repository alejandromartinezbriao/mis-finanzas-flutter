# Log de Desarrollo - Mis Finanzas (v3.3.0)

## Estado Actual (Última actualización: 10/05/2026)
- **Versión**: 3.3.1 "Identidad Multiplataforma".
- **Interfaz**: Soporte para Accesos Rápidos (Quick Actions) con iconos adaptativos y modo de carga enfocado.
- **Aritmética**: Respeto total a ajustes manuales en tarjetas de crédito durante la eliminación de ítems.
- **Usabilidad**: 
    - **Registro Relámpago (v3.3.1)**: Menú de acceso rápido (mantener presionado el icono). Utiliza iconos "estilo Billetera de Google" (capas XML con fondo circular) para garantizar visibilidad en capas de personalización como MIUI/Xiaomi.
    - **Modo Foco**: Al abrir vía Quick Action, la App se cierra automáticamente tras el registro o cancelación (`SystemNavigator.pop()`).

## 🍎 Guía de Preparación para iOS (Quick Actions)
Para asegurar que los iconos personalizados funcionen en iPhone cuando se realice la compilación en macOS:
1. **Nombres de Recursos**: El código Flutter ya busca los identificadores `shortcut_simple` y `shortcut_card`.
2. **Xcode Assets**: Abrir `Runner.xcworkspace` -> `Assets.xcassets`.
3. **Creación**: Crear dos nuevos "Image Set" nombrados exactamente `shortcut_simple` y `shortcut_card`.
4. **Formato**: Arrastrar los iconos de Mica (PNG con transparencia). *Nota: iOS suele aplicar un efecto de máscara; se recomienda usar imágenes contrastadas.*
5. **Consistencia**: No es necesario tocar `main.dart`, ya que el puente de comunicación es idéntico al de Android.

## Decisiones Arquitectónicas Tomadas (v3.3)
1. **Modo Foco**: Al abrir la App vía Quick Action, se omite la carga del Dashboard completo para priorizar la velocidad de registro y la privacidad de los saldos totales.
2. **Cierre Atómico**: La App invoca `SystemNavigator.pop()` tras un registro rápido para integrarse perfectamente con el flujo de uso del smartphone.

## Hoja de Ruta (Roadmap) - Versión 3.x
- [ ] **Modo Familiar**: Sistema de "Hogares" para compartir gastos con visibilidad selectiva.
- [ ] **Análisis de Inversiones**: IA asesorando sobre dónde colocar el superávit detectado.

---
*Mis Finanzas v3.3 - Velocidad y precisión en el control de tu capital.*
