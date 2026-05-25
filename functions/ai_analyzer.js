const { GoogleGenAI } = require("@google/genai");

// Inicialización con el SDK 2026 correcto
const client = new GoogleGenAI({
  vertexai: true,
  project: "cuentaspersonales-36328",
  location: "us-central1"
});

/**
 * Genera el análisis mensual profundo
 */
async function generarAnalisisMensualIA(data, userName, tipoCambio) {
  const prompt = `
    Eres Finanz-IA, el consultor financiero bimonetario de ${userName}. Tu trato es experto y humano.
    IMPORTANTE: Habla siempre en SEGUNDA PERSONA (Tú/Vos).

    PANORAMA REAL DE ESTE MES:
    - Ingresos: ${JSON.stringify(data.ingresos)}
    - Gastos Pagados: ${JSON.stringify(data.pagado)}
    - Deuda Pendiente: ${JSON.stringify(data.pendiente)}
    - Liquidez en Cuentas: ${JSON.stringify(data.saldos)}
    - Suscripciones: ${JSON.stringify(data.subs)}
    - Tipo de cambio: 1 USD = ${tipoCambio} UYU.

    REGLAS DE AUDITORÍA:
    1. BALANCE GLOBAL: Si Gastos (Pagado + Pendiente) > Ingresos, menciona la erosión de ahorros seriamente.
    2. COMPENSACIÓN: Si falta poco USD pero sobran pesos, sugiere el cambio de moneda para proteger su capital.
    3. RESUMEN EJECUTIVO: Un párrafo profundo de 60-80 palabras analizando el performance de ${userName}.

    Responde SOLO JSON:
    {
      "score": número (1-100),
      "score_label": "Excelente/Bueno/Regular/Crítico",
      "resumen_ejecutivo": "Análisis profundo para TI.",
      "alerta_critica": "Solo si es grave (Deuda > Liquidez), sino null.",
      "categoria_mayor_gasto": "Nombre de categoría real",
      "consejo_ahorro": "Consejo técnico de max 15 palabras",
      "meta_sugerida": "Propuesta basada en sobrante"
    }
  `;

  // Cambio a sintaxis correcta de SDK 2026
  const response = await client.models.generateContent({
    model: 'gemini-2.5-flash',
    contents: [{ role: 'user', parts: [{ text: prompt }] }],
    config: { temperature: 0.5, responseMimeType: 'application/json' }
  });

  return JSON.parse(response.text);
}

/**
 * Genera el análisis de planificación estratégica
 */
async function generarAnalisisPlanIA(data, userName) {
  const prompt = `
    Eres el estratega de ${userName}. Analiza la viabilidad de su vida financiera a futuro.

    BASE REAL DE HOY:
    - Gastos reales de este mes: ${JSON.stringify(data.gastosMap)}
    - Liquidez de respaldo: ${JSON.stringify(data.saldos)}

    TU PLAN FUTURO:
    - Presupuestos (Metas de gasto): ${JSON.stringify(data.budgets)}
    - Ingresos previstos: ${JSON.stringify(data.incomeTemplates)}
    - Suscripciones fijas: ${JSON.stringify(data.subs)}

    INSTRUCCIONES:
    - Compara tus gastos reales (hoy) vs tus presupuestos (mañana) vs tus ingresos.
    - Proyecta a 6 meses. Explica si el plan es viable basándote en la realidad del mes actual.

    Responde SOLO JSON:
    {
      "viabilidad": "Viable / Arriesgada / Inviable",
      "analisis_detalle": "Explicación profunda para TI en segunda persona.",
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

  return JSON.parse(response.text);
}

module.exports = { generarAnalisisMensualIA, generarAnalisisPlanIA };
