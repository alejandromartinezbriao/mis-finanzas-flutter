const { onRequest } = require("firebase-functions/v2/https");
const { GoogleGenAI } = require("@google/genai");

const client = new GoogleGenAI({
  vertexai: true,
  project: "cuentaspersonales-36328",
  location: "us-central1"
});

// 1. Auditoría Mensual de Gastos (El Asesor Humano)
exports.analizarGastosMensuales = onRequest(
  { cors: true, maxInstances: 10 },
  async (req, res) => {
    if (req.method === 'OPTIONS') return res.status(204).send('');
    if (req.method !== 'POST') return res.status(405).send('Method Not Allowed');

    const { presupuestoTotal, gastos, userName, saldosActuales, pagadoTotal, pendienteTotal, ingresoTotal, tipoCambio, suscripciones } = req.body;

    try {
      const prompt = `
        Eres Finanz-IA, el consultor financiero personal de ${userName}. Tu trato es experto, motivador y muy humano.
        IMPORTANTE: Habla siempre en segunda persona (Tú/Vos) en TODOS los campos. Prohibido hablar en tercera persona o referirte a ${userName} como si no estuviera presente.

        CONTEXTO DEL MES (Definiciones matemáticas):
        - Liquidez Actual: ${JSON.stringify(saldosActuales)} (Este dinero es tu SOBRANTE hoy).
        - Deuda Pendiente: ${JSON.stringify(pendienteTotal)} (Este dinero es lo que aún DEBES pagar este mes).
        - Ingresos del Mes: ${JSON.stringify(ingresoTotal)} (Lo que entró este mes).
        - Gastos Realizados (Pagado): ${JSON.stringify(pagadoTotal)} (Lo que ya salió de tus cuentas).
        - Gasto Total del Mes = Pagado + Pendiente.
        - Suscripciones: ${JSON.stringify(suscripciones || [])}

        LÓGICA DE AUDITORÍA:
        1. EROSIÓN: Si Gasto Total del Mes > Ingresos del Mes, estás usando ahorros previos. NO digas que la gestión es excelente en este caso. Llámalo "Uso de reservas" y advierte que no es sostenible.
        2. COBERTURA: Si tu Liquidez Actual es mayor que tu Deuda Pendiente, tienes una posición sólida pero verifica la erosión.
        3. ESTRATEGIA: Si tienes déficit en USD pero te sobra en UYU, sugiere cambiar pesos para no tocar tus reservas de dólares de largo plazo.

        Responde SOLO JSON:
        {
          "score": número (1-100),
          "score_label": "Excelente/Bueno/Regular/Crítico",
          "resumen_ejecutivo": "Tu párrafo profundo de mentoría financiera para TI en segunda persona.",
          "alerta_critica": "Solo si es grave, de lo contrario null.",
          "categoria_mayor_gasto": "Nombre de categoría",
          "consejo_ahorro": "Consejo técnico de max 15 palabras para TI usando tu nombre ${userName}",
          "meta_sugerida": "Propuesta motivadora para TI en segunda persona"
        }
      `;

      const response = await client.models.generateContent({
        model: 'gemini-2.5-flash',
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
        config: { temperature: 0.5, responseMimeType: 'application/json' }
      });

      return res.status(200).json(JSON.parse(response.text));
    } catch (error) {
      return res.status(500).json({ error: "Error en el análisis mensual" });
    }
  }
);

// 2. Planificación Estratégica (Sostenibilidad)
exports.analizarSostenibilidadPlan = onRequest(
  { cors: true, maxInstances: 10 },
  async (req, res) => {
    if (req.method === 'OPTIONS') return res.status(204).send('');
    const { presupuestos, ingresosPrevistos, userName, saldosActuales, gastosActuales, suscripciones } = req.body;

    try {
      const prompt = `
        Eres el estratega financiero de ${userName}. Analiza la viabilidad de su plan futuro.
        IMPORTANTE: Habla siempre en SEGUNDA PERSONA.

        DATOS REALES DE HOY:
        - Tus gastos reales este mes (por moneda): ${JSON.stringify(gastosActuales || {})}

        TU PLAN FUTURO:
        - Tus metas ideales (Presupuestos): ${JSON.stringify(presupuestos)}
        - Tus ingresos previstos: ${JSON.stringify(ingresosPrevistos)}
        - Tu liquidez de respaldo: ${JSON.stringify(saldosActuales)}

        PROCESO:
        1. Compara tus gastos reales (hoy) vs tus presupuestos (mañana) vs tus ingresos.
        2. Si tus gastos reales ya superan tus ingresos, el plan futuro es ARRIESGADO aunque tus presupuestos digan lo contrario.
        3. Proyecta a 6 meses.

        Responde SOLO JSON:
        {
          "viabilidad": "Viable / Arriesgada / Inviable",
          "analisis_detalle": "Análisis profundo para TI en segunda persona.",
          "ahorro_proyectado": "Monto neto mensual.",
          "recomendaciones": ["R1", "R2", "R3"],
          "proyeccion_6_meses": "Estado futuro detallado."
        }
      `;

      const response = await client.models.generateContent({
        model: 'gemini-2.5-flash',
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
        config: { temperature: 0.1, responseMimeType: 'application/json' }
      });

      return res.status(200).json(JSON.parse(response.text));
    } catch (error) {
      return res.status(500).json({ error: "Error Estrategia" });
    }
  }
);

// 3. Cotización del Dólar
exports.obtenerCotizacionDolar = onRequest(
  { cors: true },
  async (req, res) => {
    try {
      const response = await fetch('https://open.er-api.com/v6/latest/USD');
      const data = await response.json();
      return res.status(200).json({
        'compra': data.rates.UYU - 2.0,
        'venta': data.rates.UYU,
        'fecha': new Date().toLocaleDateString('es-ES')
      });
    } catch (error) {
      return res.status(500).json({ error: "Error cotización" });
    }
  }
);
