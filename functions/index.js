const { onRequest } = require("firebase-functions/v2/https");
const { VertexAI } = require("@google-cloud/vertexai");

// Inicializa Vertex AI apuntando directamente a tu ID de proyecto de Google Cloud
// Esto asocia el consumo al plan Blaze pospago y consume tus $300 USD de regalo
const vertexAI = new VertexAI({
  project: "cuentaspersonales-36328",
  location: "us-central1"
});

exports.analizarGastosMensuales = onRequest(
  { cors: true }, // Permite que tu app de Flutter Web se conecte sin bloqueos de navegador
  async (req, res) => {
    // Manejo de peticiones preflight CORS de los navegadores web
    if (req.method === 'OPTIONS') {
      return res.status(204).send('');
    }

    if (req.method !== 'POST') {
      return res.status(405).send('Method Not Allowed');
    }

    const { presupuestoTotal, gastos } = req.body;
    if (presupuestoTotal === undefined || !gastos) {
      return res.status(400).json({ error: "Faltan datos de presupuesto o gastos." });
    }

    try {
      // Consumimos el modelo Gemini 2.5 Flash de grado empresarial en Vertex AI
      const generativeModel = vertexAI.getGenerativeModel({
        model: "gemini-2.5-flash",
      });

      const prompt = `
        Actúas como un asesor financiero experto y analista de datos.
        Presupuesto Mensual Total: $${presupuestoTotal}.
        Lista de Gastos por Categoría: ${JSON.stringify(gastos)}.

        Reglas estrictas de respuesta:
        1. Debes responder EXCLUSIVAMENTE en formato JSON válido.
        2. No incluyas textos de introducción, saludos ni bloques markdown (\`\`\`json).
        3. Sé muy breve y directo con los textos.

        Estructura exacta del JSON que debes devolver:
        {
          "alerta_critica": "un texto breve de alerta si gastó de más, o null si todo está bajo control",
          "categoria_mayor_gasto": "nombre de la categoría con mayor egreso",
          "consejo_ahorro": "un consejo financiero concreto de máximo 15 palabras"
        }
      `;

      // Llamada al motor de Vertex AI
      const resp = await generativeModel.generateContent({
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
      });

      // Extracción limpia del texto del candidato de respuesta
      const text = resp.response.candidates[0].content.parts[0].text.trim();

      // Limpieza robusta de marcas JSON
      const start = text.indexOf('{');
      const end = text.lastIndexOf('}') + 1;

      if (start === -1 || end === 0) {
        throw new Error("La IA de Vertex no devolvió un formato JSON válido.");
      }

      const cleanedText = text.substring(start, end);
      return res.status(200).json(JSON.parse(cleanedText));

    } catch (error) {
      console.error("Error en Vertex AI:", error);
      return res.status(500).json({
        error: "Error del motor de IA empresarial",
        details: error.message
      });
    }
  }
);
