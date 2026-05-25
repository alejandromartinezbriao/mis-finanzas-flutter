const { GoogleGenAI } = require("@google/genai");
const admin = require("firebase-admin");
const crypto = require("crypto");

// Mantenemos tu modelo Gemini 2.5 Flash exitoso
const client = new GoogleGenAI({
  vertexai: true,
  project: "cuentaspersonales-36328",
  location: "us-central1"
});

/**
 * LÓGICA DE AUDITORÍA MENSUAL (SERVER-SIDE)
 * Mueve todo el peso de recolección de datos a la nube
 */
async function realizarAnalisisMensualServidor(db, uid, month, year, userName) {
  const monthId = `${month}_${year}`;

  const [txsSnap, budgetsSnap, subsSnap, templatesSnap, balancesSnap, rateRes] = await Promise.all([
    db.collection('users').doc(uid).collection('transactions').where('month', '==', month).where('year', '==', year).get(),
    db.collection('users').doc(uid).collection('budgets').where('month', '==', month).where('year', '==', year).get(),
    db.collection('users').doc(uid).collection('subscriptions').get(),
    db.collection('users').doc(uid).collection('templates').where('type', '==', 'INCOME').get(),
    db.collection('users').doc(uid).collection('balances').get(),
    fetch('https://open.er-api.com/v6/latest/USD')
  ]);

  const rateData = await rateRes.json();
  const tipoCambio = rateData.rates.UYU;

  const pagado = { UYU: 0, USD: 0 };
  const pendiente = { UYU: 0, USD: 0 };
  const ingresos = { UYU: 0, USD: 0 };
  const gastosMap = { UYU: {}, USD: {} };
  const saldosActuales = {};

  txsSnap.docs.forEach(doc => {
    const t = doc.data();
    if (t.type === 'EXPENSE') {
      gastosMap[t.currency][t.category] = (gastosMap[t.currency][t.category] || 0) + (t.amount || 0);
      if (t.isCompleted) pagado[t.currency] += t.amount;
      else pendiente[t.currency] += t.amount;
    } else if (t.type === 'INCOME') {
      ingresos[t.currency] += t.amount;
    }
  });

  balancesSnap.docs.forEach(doc => {
    const b = doc.data();
    if (b.includeInCoverage !== false) {
      saldosActuales[b.currency] = (saldosActuales[b.currency] || 0) + (b.amount || 0);
    }
  });

  const budgets = budgetsSnap.docs.map(d => d.data());
  const subscriptions = subsSnap.docs.map(d => d.data());
  const incomeTemplates = templatesSnap.docs.map(d => d.data());

  const fingerprint = generarHash({
    budgets, gastosMap, pagado, pendiente, ingresos, saldosActuales, subscriptions, incomeTemplates, userName
  });

  const cacheKey = `${monthId}_latest`;
  const cacheSnap = await db.collection('users').doc(uid).collection('ai_reports')
    .where('monthId', '==', cacheKey).where('dataHash', '==', fingerprint).get();

  if (!cacheSnap.empty) {
    return { report: cacheSnap.docs[0].data().report, fromCache: true };
  }

  // EL PROMPT QUE YA FUNCIONABA (Mejorado para Server-Side)
  const prompt = `
    Eres Finanz-IA, el consultor bimonetario de ${userName}. Habla siempre en segunda persona (Tú/Vos).
    Tipo de cambio: 1 USD = ${tipoCambio} UYU.

    PANORAMA DEL MES:
    - Ingresos: ${JSON.stringify(ingresos)}
    - Gastos (Pagado + Pendiente): ${JSON.stringify({pagado, pendiente})}
    - Liquidez en cuentas: ${JSON.stringify(saldosActuales)}
    - Suscripciones: ${JSON.stringify(subscriptions)}

    REGLAS:
    1. Si Gastos > Ingresos, menciona "Erosión de ahorros".
    2. Si hay deudas en USD pero sobra en UYU, sugiere cambio de moneda.
    3. RESUMEN EJECUTIVO: Un párrafo de 60-80 palabras analizando el performance.

    Responde SOLO JSON:
    {
      "score": número, "score_label": "Texto", "resumen_ejecutivo": "Análisis profundo",
      "alerta_critica": "null o texto", "categoria_mayor_gasto": "Texto",
      "consejo_ahorro": "Texto max 15 palabras", "meta_sugerida": "Propuesta"
    }
  `;

  const generativeModel = client.getGenerativeModel({ model: "gemini-2.5-flash" });
  const result = await generativeModel.generateContent({
    contents: [{ role: 'user', parts: [{ text: prompt }] }],
    config: { temperature: 0.5, responseMimeType: 'application/json' }
  });

  const aiResponse = JSON.parse(result.text);

  await db.collection('users').doc(uid).collection('ai_reports').add({
    monthId: cacheKey,
    dataHash: fingerprint,
    report: aiResponse,
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });

  return { report: aiResponse, fromCache: false };
}

/**
 * LÓGICA DE PLANIFICACIÓN ESTRATÉGICA (SERVER-SIDE)
 */
async function realizarPlanificacionServidor(db, uid, userName) {
  const now = new DateTime.now(); // Nota: En JS es diferente, usaremos Date()
  const today = new Date();
  const currentMonth = today.getMonth() + 1;
  const currentYear = today.getFullYear();

  const [budgetsSnap, templatesSnap, subsSnap, balancesSnap, actualTxsSnap] = await Promise.all([
    db.collection('users').doc(uid).collection('budgets').where('month', '==', currentMonth).where('year', '==', currentYear).get(),
    db.collection('users').doc(uid).collection('templates').where('type', '==', 'INCOME').get(),
    db.collection('users').doc(uid).collection('subscriptions').get(),
    db.collection('users').doc(uid).collection('balances').get(),
    db.collection('users').doc(uid).collection('transactions').where('month', '==', currentMonth).where('year', '==', currentYear).get()
  ]);

  const budgets = budgetsSnap.docs.map(d => d.data());
  const incomes = templatesSnap.docs.map(d => d.data());
  const subs = subsSnap.docs.map(d => d.data());

  const saldos = {};
  balancesSnap.docs.forEach(d => {
    const b = d.data();
    if (b.includeInCoverage !== false) saldos[b.currency] = (saldos[b.currency] || 0) + (b.amount || 0);
  });

  const gastosActuales = { UYU: {}, USD: {} };
  actualTxsSnap.docs.forEach(d => {
    const t = d.data();
    if (t.type === 'EXPENSE') gastosActuales[t.currency][t.category] = (gastosActuales[t.currency][t.category] || 0) + t.amount;
  });

  const fingerprint = generarHash({ budgets, incomes, subs, saldos, gastosActuales, type: 'PLAN' });
  const cacheKey = `plan_${currentMonth}_${currentYear}_latest`;

  const cacheSnap = await db.collection('users').doc(uid).collection('ai_reports')
    .where('monthId', '==', cacheKey).where('dataHash', '==', fingerprint).get();

  if (!cacheSnap.empty) return { report: cacheSnap.docs[0].data().report };

  const prompt = `
    Eres el estratega de ${userName}. Analiza la viabilidad futura.
    - Gastos reales hoy: ${JSON.stringify(gastosActuales)}
    - Metas (Presupuestos): ${JSON.stringify(budgets)}
    - Ingresos previstos: ${JSON.stringify(incomes)}
    - Liquidez: ${JSON.stringify(saldos)}

    Habla en segunda persona. Proyecta a 6 meses.
    Responde SOLO JSON:
    {
      "viabilidad": "Texto", "analisis_detalle": "Análisis profundo",
      "ahorro_proyectado": "Monto neto", "recomendaciones": ["R1", "R2"], "proyeccion_6_meses": "Texto"
    }
  `;

  const generativeModel = client.getGenerativeModel({ model: "gemini-2.5-flash" });
  const result = await generativeModel.generateContent({
    contents: [{ role: 'user', parts: [{ text: prompt }] }],
    config: { temperature: 0.1, responseMimeType: 'application/json' }
  });

  const aiResponse = JSON.parse(result.text);

  await db.collection('users').doc(uid).collection('ai_reports').add({
    monthId: cacheKey,
    dataHash: fingerprint,
    report: aiResponse,
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });

  return { report: aiResponse };
}

function generarHash(data) {
  const sorted = sortObject(data);
  return crypto.createHash('md5').update(JSON.stringify(sorted)).digest('hex');
}

function sortObject(obj) {
  if (obj === null || typeof obj !== 'object') return obj;
  if (Array.isArray(obj)) return obj.map(sortObject);
  return Object.keys(obj).sort().reduce((result, key) => {
    result[key] = sortObject(obj[key]);
    return result;
  }, {});
}

module.exports = { realizarAnalisisMensualServidor, realizarPlanificacionServidor };
