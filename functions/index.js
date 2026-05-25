const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

// Inicializamos Admin antes que nada
if (admin.apps.length === 0) {
  admin.initializeApp();
}
const db = admin.firestore();

// Piezas de lógica modular
const { recolectarDatosUsuario, generarFirmaEstado } = require("./data_processor");
const { generarAnalisisMensualIA, generarAnalisisPlanIA } = require("./ai_analyzer");

// 1. AUDITORÍA MENSUAL
exports.analizarGastosMensuales = onRequest(
  { cors: true, maxInstances: 10 },
  async (req, res) => {
    if (req.method === 'OPTIONS') return res.status(204).send('');
    const { uid, month, year, userName } = req.body;
    if (!uid || !month || !year) return res.status(400).send("Faltan parámetros");

    try {
      const data = await recolectarDatosUsuario(db, uid, month, year);
      const firmaActual = generarFirmaEstado({ ...data.raw, userName });
      const cacheKey = `audit_${data.monthId}_latest`;

      const cacheSnap = await db.collection('users').doc(uid).collection('ai_reports')
        .where('monthId', '==', cacheKey).where('dataHash', '==', firmaActual).get();

      if (!cacheSnap.empty) {
        return res.status(200).json(cacheSnap.docs[0].data().report);
      }

      const rateRes = await fetch('https://open.er-api.com/v6/latest/USD');
      const rateData = await rateRes.json();
      const report = await generarAnalisisMensualIA(data.raw, userName, rateData.rates.UYU);

      await db.collection('users').doc(uid).collection('ai_reports').add({
        monthId: cacheKey,
        dataHash: firmaActual,
        report: report,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      return res.status(200).json(report);
    } catch (error) {
      console.error(error);
      return res.status(500).json({ error: error.message });
    }
  }
);

// 2. PLANIFICACIÓN ESTRATÉGICA
exports.analizarSostenibilidadPlan = onRequest(
  { cors: true, maxInstances: 10 },
  async (req, res) => {
    if (req.method === 'OPTIONS') return res.status(204).send('');
    const { uid, userName } = req.body;
    if (!uid) return res.status(400).send("UID requerido");

    try {
      const today = new Date();
      const data = await recolectarDatosUsuario(db, uid, today.getMonth() + 1, today.getFullYear());
      const firmaActual = generarFirmaEstado({ ...data.raw, userName, type: 'PLAN' });
      const cacheKey = `plan_latest`;

      const cacheSnap = await db.collection('users').doc(uid).collection('ai_reports')
        .where('monthId', '==', cacheKey).where('dataHash', '==', firmaActual).get();

      if (!cacheSnap.empty) {
        return res.status(200).json(cacheSnap.docs[0].data().report);
      }

      const report = await generarAnalisisPlanIA(data.raw, userName);

      await db.collection('users').doc(uid).collection('ai_reports').add({
        monthId: cacheKey,
        dataHash: firmaActual,
        report: report,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      return res.status(200).json(report);
    } catch (error) {
      console.error(error);
      return res.status(500).json({ error: error.message });
    }
  }
);

// 3. COTIZACIÓN
exports.obtenerCotizacionDolar = onRequest({ cors: true }, async (req, res) => {
  try {
    const response = await fetch('https://open.er-api.com/v6/latest/USD');
    const data = await response.json();
    return res.status(200).json({ 'compra': data.rates.UYU - 2, 'venta': data.rates.UYU, 'fecha': new Date().toLocaleDateString() });
  } catch (error) { return res.status(500).json({ error: "Error" }); }
});
