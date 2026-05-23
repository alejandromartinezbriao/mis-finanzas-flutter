const { onRequest } = require("firebase-functions/v2/https");
const { VertexAI } = require("@google-cloud/vertexai");

const vertexAI = new VertexAI({
  project: "cuentaspersonales-36328",
  location: "us-central1"
});

exports.analizarGastosMensuales = onRequest(
  { cors: true, maxInstances: 10 },
  async (req, res) => {
    if (req.method === 'OPTIONS') return res.status(204).send('');
    if (req.method !== 'POST') return res.status(405).send('Method Not Allowed');

    const { presupuestoTotal, gastos, userName, saldosActuales, pagadoTotal, pendienteTotal, ingresoTotal } = req.body;

    try {
      const generativeModel = vertexAI.getGenerativeModel({
        model: "gemini-2.5-flash",
        generationConfig: { temperature: 0.1, responseMimeType: "application/json" }
      });

      const prompt = `
        Eres Finanz-IA, un auditor financiero de élite. Tu análisis debe ser bimonetario y matemáticamente exacto.
        Usuario: ${userName}.

        DATOS CRUDOS POR MONEDA (UYU y USD):
        - Ingresos (Entradas): ${JSON.stringify(ingresoTotal)}
        - Ya pagado: ${JSON.stringify(pagadoTotal)}
        - Pendiente (Deuda actual): ${JSON.stringify(pendienteTotal)}
        - Liquidez en cuentas: ${JSON.stringify(saldosActuales)}
        - Gastos por categoría: ${JSON.stringify(gastos)}
        - Presupuesto objetivo (Referencia en UYU): $${presupuestoTotal}

        PROCESO DE AUDITORÍA OBLIGATORIO:
        1. ANALIZA CADA MONEDA POR SEPARADO:
           - Calcula Balance (Ingresos - Gastos Totales) para UYU y para USD.
           - Si (Gastos > Ingresos) en cualquiera de las dos: Identifícalo como "Erosión de Ahorros".
           - Si todo está pagado (Pendiente=0) pero el Balance es negativo: Felicita el cumplimiento, pero advierte que el ahorro previo está financiando el mes.
        2. CAPACIDAD DE PAGO: Compara Pendiente vs Liquidez en cada moneda.
        3. DISCIPLINA: Compara Gasto Total (UYU) vs Presupuesto.

        INSTRUCCIONES DE RESPUESTA:
        - Si hubo erosión de ahorros en Pesos o Dólares, el Score NO puede ser mayor a 75.
        - Menciona específicamente en qué moneda se detectó el desequilibrio.
        - Usa lenguaje técnico y motivador.

        Responde SOLO JSON:
        {
          "score": número (1-100),
          "score_label": "Excelente/Bueno/Regular/Crítico",
          "alerta_critica": "Análisis sobre balances mensuales por moneda y uso de reservas.",
          "categoria_mayor_gasto": "Nombre de la categoría real",
          "consejo_ahorro": "Consejo técnico de max 15 palabras para ${userName}",
          "meta_sugerida": "Acción para frenar la erosión de ahorro o mejorar liquidez"
        }
      `;

      const resp = await generativeModel.generateContent({
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
      });

      const text = resp.response.candidates[0].content.parts[0].text.trim();
      return res.status(200).json(JSON.parse(text));

    } catch (error) {
      console.error("Error IA:", error);
      return res.status(500).json({ error: "Error del motor de análisis" });
    }
  }
);
