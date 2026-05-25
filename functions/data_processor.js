const crypto = require("crypto");

/**
 * Recolecta todos los datos del usuario desde Firestore para un mes específico
 */
async function recolectarDatosUsuario(db, uid, month, year) {
  const [txsSnap, categoriesSnap, subsSnap, templatesSnap, balancesSnap] = await Promise.all([
    db.collection('users').doc(uid).collection('transactions').where('month', '==', month).where('year', '==', year).get(),
    db.collection('users').doc(uid).collection('categories').where('type', '==', 'EXPENSE').get(),
    db.collection('users').doc(uid).collection('subscriptions').get(),
    db.collection('users').doc(uid).collection('templates').where('type', '==', 'INCOME').get(),
    db.collection('users').doc(uid).collection('balances').get()
  ]);

  // Procesamiento básico de sumas
  const saldos = {};
  balancesSnap.docs.forEach(d => {
    const b = d.data();
    if (b.includeInCoverage !== false) saldos[b.currency] = (saldos[b.currency] || 0) + (b.amount || 0);
  });

  const pagado = { UYU: 0, USD: 0 };
  const pendiente = { UYU: 0, USD: 0 };
  const ingresos = { UYU: 0, USD: 0 };
  const gastosMap = { UYU: {}, USD: {} };

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

  // Los presupuestos ahora vienen de las categorías
  const budgets = categoriesSnap.docs.map(d => {
    const cat = d.data();
    return {
      categoryName: cat.name,
      amount: cat.budgetAmount || 0.0,
      currency: cat.budgetCurrency || 'UYU'
    };
  });
  const subs = subsSnap.docs.map(d => d.data());
  const incomeTemplates = templatesSnap.docs.map(d => d.data());

  return {
    raw: { budgets, gastosMap, pagado, pendiente, ingresos, saldos, subs, incomeTemplates },
    monthId: `${month}_${year}`
  };
}

/**
 * Genera la firma única (Hash) de los datos
 */
function generarFirmaEstado(data) {
  const sorted = _sortObject(data);
  return crypto.createHash('md5').update(JSON.stringify(sorted)).digest('hex');
}

function _sortObject(obj) {
  if (obj === null || typeof obj !== 'object') return obj;
  if (Array.isArray(obj)) return obj.map(_sortObject);
  return Object.keys(obj).sort().reduce((result, key) => {
    result[key] = _sortObject(obj[key]);
    return result;
  }, {});
}

module.exports = { recolectarDatosUsuario, generarFirmaEstado };
