# Guía de Usuario - Mis Finanzas (v2.0)

Esta guía detalla el funcionamiento de la aplicación y las herramientas de gestión avanzada disponibles en la versión 2.0.

---

## 1. PANTALLA PRINCIPAL (Gestión Temporal)
Es el centro de control donde monitoreas tu salud financiera mes a mes.
*   **Selector de Mes:** Navega al **pasado** para ver cierres reales, al **presente** para el día a día, o al **futuro** para ver proyecciones.
*   **Tarjeta de Cobertura Inteligente:**
    *   **Modo Cierre (Pasado):** Compara ingresos vs egresos reales y muestra el **Superávit/Déficit**.
    *   **Modo Disponibilidad (Presente):** Dinero libre en cuentas (excluyendo ahorros) vs deudas pendientes.
    *   **Modo Proyección (Futuro):** Ingresos previstos vs gastos fijos cargados.
*   **Saldos de Cuentas:** Lista horizontal de tus bancos y efectivo. Si ves un icono de **ojo tachado**, significa que esa cuenta está excluida del cálculo de cobertura (ej: ahorros).
*   **Lista de Movimientos:** Organizada por ingresos y egresos. Elimina cualquier registro deslizando hacia la **derecha**.

---

## 2. HERRAMIENTAS DE MANTENIMIENTO E IA (Menú lateral)
Suite interactiva para garantizar que tus datos sean exactos y recibir consejos inteligentes.

*   **Asesor Financiero IA:** Analiza tus gastos mensuales mediante Gemini AI. Ofrece alertas de exceso de gasto, identifica la categoría de mayor egreso y brinda consejos de ahorro personalizados.
*   **Historial de Asesoría:** Nueva sección donde puedes consultar todos los informes previos generados por Finanz-IA. Cada informe se guarda con su fecha, hora y el puntaje obtenido, permitiéndote ver cómo ha evolucionado tu salud financiera.
*   **Normalizar Formatos (Quitar Comas):** Purifica la base de datos eliminando comas de miles en las descripciones de consumos.
*   **Corregir Error 100x (Decimales):** Detecta montos que se guardaron 100 veces más grandes por errores de coma/punto (ej: registra 52700 en lugar de 527.00). Te muestra la lista de sospechosos y tú marcas cuáles arreglar.
*   **Sincronizar Montos de Cuotas:** Compara los mismos consumos en distintos meses. Si un mes tiene un valor distinto, la app te propone corregirlo basándose en la mayoría estadística.
*   **Mantenimiento Automático (Reconexión):** Identifica gastos que no están vinculados a sus plantillas originales y te permite reconectarlos para un mejor historial.
*   **Reparación de Emergencia:** Elimina ítems duplicados accidentalmente dentro de una misma tarjeta y recalcula el total automáticamente.
*   **Recuperar Cuotas Perdidas:** Restaura cuotas que faltan en meses pasados basándose en el historial de consumos futuros.
*   **Unificación Global:** Permite unificar variaciones de nombres de tarjetas o comercios en toda la historia de la cuenta.

---

## 3. CONFIGURACIÓN Y AUTOMATIZACIÓN (Menú > Configuración)
*   **Gastos y Tarjetas:** Define tus pagos fijos. 
    *   **Bimonetaria:** Si una tarjeta opera en UYU y USD, actívalo. Al editar una (vencimiento, logo), la app sincroniza su "gemela" automáticamente.
*   **Suscripciones:** Registra servicios recurrentes (Netflix, Spotify, etc.) y vincúlalos a una tarjeta para que se carguen solos cada mes.
*   **Mis Cuentas:** Gestiona tus bancos. Usa el switch **"Considerar para Cobertura"** para decidir si el saldo de esa cuenta debe sumarse al dinero disponible para pagar deudas.
*   **Presupuestos:** Define topes de gasto. Ahora requiere **confirmación manual** para asegurar que los cambios se guarden correctamente.
*   **Categorías:** Personaliza tus iconos y colores para clasificar tus movimientos. Una buena categorización es clave para las estadísticas.
*   **Metas de Ahorro:** Crea fondos específicos (ej: Vacaciones). Puedes vincular una cuenta real a una meta; el dinero se "reservará" visualmente y no se contará como dinero disponible para gastos corrientes, protegiendo tus ahorros.

---

## 4. OPERACIONES CLAVE
*   **Registro de Efectivo:** Al crear un gasto, selecciona la cuenta **"Pago en Efectivo (Sin cuenta)"** para marcarlo como pagado sin afectar tus balances bancarios.
*   **Compras en Cuotas (Inicio Flexible):** Al registrar una compra, indica el total de cuotas y cuál es la **"Cuota Próxima"**. Útil para empezar a usar la app cuando ya vienes pagando algo de antes.
*   **Instalación en iPhone:** En Safari, usa el botón "Compartir" > "Añadir a pantalla de inicio" para tener el logo real y experiencia de app nativa.

---

## 5. REGLAS DE ORO PARA EL ÉXITO
*   **El Punto manda:** Utiliza siempre el **punto (.)** para decimales. Si tu teclado (en iPhone) solo tiene coma, la app la convertirá a punto automáticamente por ti.
*   **Sin Comas de Miles:** No separes los miles con comas ni puntos. La app los oculta visualmente para evitar confusiones aritméticas.
*   **Confirmaciones:** Siempre lee el cuadro de confirmación antes de registrar un movimiento; allí se resume qué estás guardando y por qué monto.

---
*Mis Finanzas v2.0 - Tu salud financiera en control profesional.*
