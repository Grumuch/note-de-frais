// Calculs TVA + mise en forme du ticket.
// Produit une liste de "blocs" consommée à la fois par l'aperçu (HTML)
// et par l'imprimante (XML ePOS-Print). Aucune dépendance navigateur ici.

export function round2(n) {
  return Math.round((Number(n) + Number.EPSILON) * 100) / 100;
}

// 116.5 -> "116,50" ; 1234.5 -> "1 234,50"
export function formatAmount(n) {
  const v = round2(n);
  const neg = v < 0;
  const [intPart, decPart] = Math.abs(v).toFixed(2).split('.');
  const withSep = intPart.replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
  return (neg ? '-' : '') + withSep + ',' + decPart;
}

// Ligne "libellé .... montant" calée sur la largeur du ticket.
export function padLine(left, right, width) {
  left = String(left);
  right = String(right);
  const max = width - right.length - 1;
  if (left.length > max && max > 0) left = left.slice(0, max);
  const spaces = Math.max(1, width - left.length - right.length);
  return left + ' '.repeat(spaces) + right;
}

// a, b, c, ... attribué par taux croissant.
function letterMap(tvaLines) {
  const rates = [...new Set(tvaLines.map((l) => Number(l.taux)))].sort((a, b) => a - b);
  const map = new Map();
  rates.forEach((r, i) => map.set(r, String.fromCharCode(97 + i)));
  return map;
}

export function computeTotals(data) {
  const lines = (data.tvaLines || [])
    .filter((l) => l.taux !== '' && l.ht !== '')
    .map((l) => {
      const ht = round2(l.ht);
      const taux = Number(l.taux);
      const tva = round2((ht * taux) / 100);
      return { taux, ht, tva, ttc: round2(ht + tva) };
    });
  const sousTotalHT = round2(lines.reduce((s, l) => s + l.ht, 0));
  const totalTVA = round2(lines.reduce((s, l) => s + l.tva, 0));
  const totalTTC = round2(sousTotalHT + totalTVA);
  return { lines, sousTotalHT, totalTVA, totalTTC };
}

// Construit les blocs d'impression. Types : text | rule | feed.
export function buildBlocks(settings, data) {
  const W = Number(settings.lineWidth) || 48;
  const devise = settings.devise || 'EUR';
  const blocks = [];
  const text = (t, opts = {}) => blocks.push({ type: 'text', text: t, ...opts });

  // En-tête
  if (settings.nom) text(settings.nom, { align: 'center', bold: true, size: 2 });
  if (settings.adresse1) text(settings.adresse1, { align: 'center' });
  if (settings.adresse2) text(settings.adresse2, { align: 'center' });
  if (settings.telephone) text(settings.telephone, { align: 'center' });
  if (settings.tvaIntra) text('TVA intra : ' + settings.tvaIntra, { align: 'center' });
  if (settings.siret) text('Siret : ' + settings.siret, { align: 'center' });

  // Total calculé en amont : il sert de montant aux lignes de désignation.
  const totals = computeTotals(data);

  blocks.push({ type: 'rule' });

  // Lignes de désignation. Le montant n'est pas saisi : c'est le TOTAL TTC,
  // affiché sur la dernière ligne (ex. "2 repas complets" ... 116,00).
  const itemLabels = (data.items || [])
    .map((it) => (it.libelle || '').trim())
    .filter((l) => l !== '');
  itemLabels.forEach((label, i) => {
    const isLast = i === itemLabels.length - 1;
    text(isLast ? padLine(label, formatAmount(totals.totalTTC), W) : label);
  });

  blocks.push({ type: 'rule' });
  blocks.push({ type: 'feed', lines: 1 });

  // Récap TVA
  text(padLine('Sous total HT', formatAmount(totals.sousTotalHT), W));
  const letters = letterMap(totals.lines);
  totals.lines.forEach((l) => {
    const label = `(${letters.get(l.taux)}) ${formatAmount(l.taux)} %`;
    text(padLine(label, formatAmount(l.tva), W));
  });
  text(padLine(`TOTAL TTC ${devise}`, formatAmount(totals.totalTTC), W), { bold: true });

  // Paiements
  const paiements = (data.paiements || []).filter(
    (p) => (p.libelle || '').trim() !== '' || p.montant !== ''
  );
  if (paiements.length) {
    blocks.push({ type: 'feed', lines: 1 });
    paiements.forEach((p) =>
      text(padLine(p.libelle || '', formatAmount(p.montant || 0), W))
    );
  }

  blocks.push({ type: 'feed', lines: 3 });
  return blocks;
}

// Rendu texte brut (aperçu).
export function blocksToText(blocks, width) {
  const W = width || 48;
  const out = [];
  for (const b of blocks) {
    if (b.type === 'rule') out.push('-'.repeat(W));
    else if (b.type === 'feed') for (let i = 0; i < (b.lines || 1); i++) out.push('');
    else if (b.type === 'text') {
      let t = b.text;
      if (b.align === 'center') {
        const pad = Math.max(0, Math.floor((W - t.length) / 2));
        t = ' '.repeat(pad) + t;
      }
      out.push(t);
    }
  }
  return out.join('\n');
}
