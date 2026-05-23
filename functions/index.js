const { onRequest } = require("firebase-functions/v2/https");
const { GoogleGenAI } = require("@google/genai");

// Cliente unificado con tecnología 2026
const client = new GoogleGenAI({
  vertexai: true,
  project: "cuentaspersonales-36328",
  location: "us-central1"
});

// 1. Auditoría Mensual de Gastos
exports.analizarGastosMensuales = onRequest(
  { cors: true, maxInstances: 10 },
  async (req, res) => {
    if (req.method === 'OPTIONS') return res.status(204).send('');
    if (req.method !== 'POST') return res.status(405).send('Method Not Allowed');

    const { presupuestoTotal, gastos, userName, saldosActuales, pagadoTotal, pendienteTotal, ingresoTotal, tipoCambio } = req.body;

    try {
      const prompt = `
        Eres Finanz-IA, el asesor bimonetario de ${userName}.
        Usa segunda persona (Tú/Vos).
        Tipo de cambio oficial hoy: 1 USD = ${tipoCambio || 'Consultar'} UYU.

        DATOS DEL MES:
        - Ingresos Totales: ${JSON.stringify(ingresoTotal)}
        - Gastos Totales (Pagado + Pendiente): ${JSON.stringify(pagadoTotal + pendienteTotal)}
        - Ya pagado: ${JSON.stringify(pagadoTotal)}
        - Pendiente de pago: ${JSON.stringify(pendienteTotal)}
        - Liquidez en cuentas: ${JSON.stringify(saldosActuales)}
        - Cuentas consideradas en el análisis: ${JSON.stringify(req.body.cuentasActivas || "Resumen total")}
        - Gastos por categoría: ${JSON.stringify(gastos)}

        ANÁLISIS OBLIGATORIO:
        - Compara Ingresos vs Gastos en cada moneda. Menciona si detectas nuevas fuentes de liquidez o cambios en la estrategia de cobertura.
        - Si GASTOS > INGRESOS: Menciona que se están usando AHORROS PREVIOS (Erosión de capital). Esto es vital para el análisis de sostenibilidad.
        - Si Pendiente > Liquidez: Alerta de riesgo de deuda.

        Responde SOLO JSON:
        {
          "score": número (1-100),
          "score_label": "Excelente/Bueno/Regular/Crítico",
          "alerta_critica": "Texto sobre balances y ahorros.",
          "categoria_mayor_gasto": "Nombre de categoría",
          "consejo_ahorro": "Consejo técnico de max 15 palabras",
          "meta_sugerida": "Propuesta basada en sobrante"
        }
      `;

      const response = await client.models.generateContent({
        model: 'gemini-2.5-flash', // RESTAURADO A TU MODELO ÉXITOSO
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
        config: { temperature: 0.1, responseMimeType: 'application/json' }
      });

      // Extraer y limpiar el JSON por si la IA envía markdown
      const text = response.text;
      const jsonMatch = text.match(/\{[\s\S]*\}/);
      const cleanedJson = jsonMatch ? JSON.parse(jsonMatch[0]) : JSON.parse(text);

      return res.status(200).json(cleanedJson);
    } catch (error) {
      console.error("Error IA Auditoría:", error);
      return res.status(500).json({ error: "Error en el análisis mensual" });
    }
  }
);

// 2. Planificación Estratégica (Sostenibilidad)
exports.analizarSostenibilidadPlan = onRequest(
  { cors: true, maxInstances: 10 },
  async (req, res) => {
    if (req.method === 'OPTIONS') return res.status(204).send('');
    if (req.method !== 'POST') return res.status(405).send('Method Not Allowed');

    const { presupuestos, ingresosPrevistos, userName, saldosActuales } = req.body;

    try {
      const prompt = `
        Eres Finanz-IA, el estratega de ${userName}. Habla en segunda persona.
        Analiza si tus ingresos previstos ${JSON.stringify(ingresosPrevistos)} cubren tus presupuestos de gasto ${JSON.stringify(presupuestos)}.
        Evalúa tu liquidez actual: ${JSON.stringify(saldosActuales)}.
        Dime cómo estarás en 6 meses si mantienes este ritmo.

        Responde SOLO JSON:
        {
          "viabilidad": "Viable / Arriesgada / Inviable",
          "analisis_detalle": "Explicación técnica en segunda persona.",
          "ahorro_proyectado": "Monto que sobrará cada mes.",
          "recomendaciones": ["R1", "R2", "R3"],
          "proyeccion_6_meses": "Estado futuro proyectado."
        }
      `;

      const response = await client.models.generateContent({
        model: 'gemini-2.5-flash', // RESTAURADO A TU MODELO ÉXITOSO
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
        config: { temperature: 0.1, responseMimeType: 'application/json' }
      });

      const text = response.text;
      const jsonMatch = text.match(/\{[\s\S]*\}/);
      const cleanedJson = jsonMatch ? JSON.parse(jsonMatch[0]) : JSON.parse(text);

      return res.status(200).json(cleanedJson);
    } catch (error) {
      console.error("Error IA Planificación:", error);
      return res.status(500).json({ error: "Error en el análisis de plan" });
    }
  }
);

// 3. Cotización del Dólar en Tiempo Real
exports.obtenerCotizacionDolar = onRequest(
  { cors: true },
  async (req, res) => {
    try {
      const response = await fetch('https://open.er-api.com/v6/latest/USD');
      const data = await response.json();
      const tasaVenta = data.rates.UYU;
      const tasaCompra = tasaVenta - 2.0;
      const hoy = new Date();
      const fechaStr = `${hoy.getDate()}/${hoy.getMonth() + 1}/${hoy.getFullYear()}`;

      return res.status(200).json({
        'compra': tasaCompra,
        'venta': tasaVenta,
        'fecha': fechaStr
      });
    } catch (error) {
      return res.status(500).json({ error: "Error cotización" });
    }
  }
);
