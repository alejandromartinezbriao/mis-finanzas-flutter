# Log de Desarrollo - Mis Finanzas (v3.4.2)

## Estado Actual (Última actualización: 10/05/2026)
- **Versión**: 3.4.2 "Transición Fluida".
- **Interfaz**: Accesos Rápidos con iconografía circular premium, aviso de éxito y cierre optimizado.
- **Aritmética**: Respeto total a ajustes manuales en tarjetas de crédito durante la eliminación de ítems.
- **Usabilidad**: 
    - **Cierre Silencioso (v3.4.2)**: Optimización de la salida en Quick Actions para evitar parpadeos visuales del dashboard principal. La App se cierra manteniendo el modo foco y se resetea internamente en segundo plano.
    - **Aviso de Confirmación (v3.4.1)**: Diálogo explícito de "¡Registro Exitoso!" al usar acciones rápidas, garantizando al usuario que los datos se guardaron antes de cerrar la App.
    - **Registro Relámpago (v3.4.0)**: Menú de acceso rápido (mantener presionado el icono). Utiliza diseños circulares exclusivos de Mica que ocupan todo el espacio del lanzador. Etiqueta unificada "Ingreso / Gasto".
    - **Herencia Visual (v3.4.0)**: Al registrar un movimiento, este hereda instantáneamente el **icono y el color** de su categoría, eliminando la necesidad de ediciones posteriores.
    - **Modo Foco**: Al abrir vía Quick Action, la App se cierra automáticamente tras el registro o cancelación (`SystemNavigator.pop()`).
    - **Soberanía Contable (v3.4.0)**: Al borrar un consumo de una tarjeta, el sistema resta el monto exacto del total actual en lugar de recalcular todo, respetando así los ajustes manuales (impuestos o céntimos) realizados por el usuario.

## 🍎 Guía de Preparación para iOS (Quick Actions)
Para asegurar que los iconos personalizados funcionen en iPhone cuando se realice la compilación en macOS:
1. **Nombres de Recursos**: El código Flutter ya busca los identificadores `shortcut_simple` y `shortcut_card`.
2. **Xcode Assets**: Abrir `Runner.xcworkspace` -> `Assets.xcassets`.
3. **Creación**: Crear dos nuevos "Image Set" nombrados exactamente `shortcut_simple` y `shortcut_card`.
4. **Formato**: Arrastrar los iconos de Mica (PNG con transparencia).
5. **Consistencia**: No es necesario tocar `main.dart`.

## Decisiones Arquitectónicas Tomadas (v3.1 - v3.4)
1. **Lógica Centralizada (Server-Side)**: El servidor (Firebase Functions) es la única fuente de verdad para la IA y firmas de datos, garantizando sincronización perfecta entre dispositivos.
2. **Modularización del Backend**: Código dividido en `data_processor.js`, `ai_analyzer.js` e `index.js`.
3. **UX de Refresco Nativo**: Sincronización de plantillas mediante pull-to-refresh en móvil y botón dedicado en PC.

## Hoja de Ruta (Roadmap) - Versión 3.x
- [ ] **Modo Familiar**: Sistema de "Hogares" para compartir gastos con visibilidad selectiva.
- [ ] **Análisis de Inversiones**: IA asesorando sobre dónde colocar el superávit detectado.

---
*Mis Finanzas v3.4 - La unión perfecta entre diseño industrial y lógica financiera.*
