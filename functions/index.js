const { onRequest } = require("firebase-functions/v2/https");
const { GoogleGenerativeAI } = require("@google/generative-ai");

exports.analizarGastosMensuales = onRequest(
  { secrets: ["GEMINI_API_KEY"], cors: true },
  async (req, res) => {
    if (req.method !== 'POST') return res.status(405).send('Method Not Allowed');

    const { presupuestoTotal, gastos } = req.body;
    if (presupuestoTotal === undefined || !gastos) {
      return res.status(400).json({ error: "Faltan datos de presupuesto o gastos." });
    }

    try {
      const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

      // CAMBIO CLAVE: Usamos 'gemini-1.5-flash-latest' que es el alias más compatible
      const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash-latest" });

      const prompt = `
        Actúas como un asesor financiero experto.
        Presupuesto: $${presupuestoTotal}.
        Gastos: ${JSON.stringify(gastos)}.

        Responde SOLO un objeto JSON (sin markdown):
        {
          "alerta_critica": "texto breve o null",
          "categoria_mayor_gasto": "nombre",
          "consejo_ahorro": "consejo concreto max 15 palabras"
        }
      `;

      const result = await model.generateContent(prompt);
      const text = result.response.text().trim();

      // Limpieza ultra-robusta de JSON
      const start = text.indexOf('{');
      const end = text.lastIndexOf('}') + 1;
      const cleanedText = text.substring(start, end);

      return res.status(200).json(JSON.parse(cleanedText));

    } catch (error) {
      console.error("Error Gemini:", error);
      return res.status(500).json({
        error: "Error del motor de IA",
        details: error.message
      });
    }
  }
);
