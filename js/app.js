import { buildBlocks, blocksToText, computeTotals, formatAmount } from './receipt.js';
import { printBlocks } from './epos.js';

const SETTINGS_KEY = 'ndf.settings';
const DATA_KEY = 'ndf.data';

const DEFAULT_SETTINGS = {
  nom: 'Auberge de la Faîte',
  adresse1: '1 chemin de faîte',
  adresse2: '88600 Laval sur Vologne',
  telephone: '0659129298',
  tvaIntra: 'FR9094373114',
  siret: '94372311400014',
  devise: 'EUR',
  lineWidth: 48,
  printerUrl: 'https://192.168.1.50/cgi-bin/epos/service.cgi?devid=local_printer&timeout=10000',
};

const DEFAULT_DATA = {
  items: [{ libelle: '2 repas complets', montant: 116.0 }],
  tvaLines: [
    { taux: 20, ht: 33.33 },
    { taux: 10, ht: 69.09 },
  ],
  paiements: [
    { libelle: 'Carte de crédit', montant: 96.0 },
    { libelle: 'Espèces', montant: 20.0 },
  ],
};

const parseNum = (v) => {
  if (v === '' || v == null) return '';
  const n = parseFloat(String(v).replace(',', '.'));
  return Number.isFinite(n) ? n : '';
};

function load(key, fallback) {
  try {
    const raw = localStorage.getItem(key);
    if (!raw) return structuredClone(fallback);
    return { ...structuredClone(fallback), ...JSON.parse(raw) };
  } catch {
    return structuredClone(fallback);
  }
}
const save = (key, value) => localStorage.setItem(key, JSON.stringify(value));

let settings = load(SETTINGS_KEY, DEFAULT_SETTINGS);
let data = load(DATA_KEY, DEFAULT_DATA);

const $ = (sel) => document.querySelector(sel);

// ---- Éditeurs de listes -------------------------------------------------

function listEditor(containerId, items, columns, onChange) {
  const container = $(containerId);

  function render() {
    container.innerHTML = '';
    items.forEach((item, idx) => {
      const row = document.createElement('div');
      row.className = 'row';
      columns.forEach((col) => {
        const input = document.createElement('input');
        input.type = col.type || 'text';
        if (col.type === 'number') {
          input.inputMode = 'decimal';
          input.step = col.step || '0.01';
        }
        input.placeholder = col.placeholder || '';
        input.value = item[col.key] === '' || item[col.key] == null ? '' : item[col.key];
        input.className = col.cls || '';
        input.addEventListener('input', () => {
          item[col.key] = col.type === 'number' ? parseNum(input.value) : input.value;
          onChange();
        });
        row.appendChild(input);
      });
      const del = document.createElement('button');
      del.type = 'button';
      del.className = 'icon-btn del';
      del.textContent = '✕';
      del.title = 'Supprimer la ligne';
      del.addEventListener('click', () => {
        items.splice(idx, 1);
        render();
        onChange();
      });
      row.appendChild(del);
      container.appendChild(row);
    });
  }

  function add() {
    const blank = {};
    columns.forEach((c) => (blank[c.key] = ''));
    items.push(blank);
    render();
    onChange();
  }

  render();
  return { render, add };
}

// ---- Aperçu + totaux ----------------------------------------------------

function refresh() {
  save(DATA_KEY, data);
  const width = Number(settings.lineWidth) || 48;
  const blocks = buildBlocks(settings, data);
  $('#preview').textContent = blocksToText(blocks, width);

  const t = computeTotals(data);
  $('#sum-ht').textContent = formatAmount(t.sousTotalHT);
  $('#sum-tva').textContent = formatAmount(t.totalTVA);
  $('#sum-ttc').textContent = formatAmount(t.totalTTC) + ' ' + (settings.devise || 'EUR');
}

// ---- Réglages -----------------------------------------------------------

const SETTINGS_FIELDS = [
  'nom', 'adresse1', 'adresse2', 'telephone', 'tvaIntra', 'siret',
  'devise', 'lineWidth', 'printerUrl',
];

function fillSettingsForm() {
  SETTINGS_FIELDS.forEach((f) => {
    const el = document.getElementById('set-' + f);
    if (el) el.value = settings[f] ?? '';
  });
}

function readSettingsForm() {
  SETTINGS_FIELDS.forEach((f) => {
    const el = document.getElementById('set-' + f);
    if (!el) return;
    settings[f] = f === 'lineWidth' ? (parseInt(el.value, 10) || 48) : el.value;
  });
  save(SETTINGS_KEY, settings);
}

// ---- Impression ---------------------------------------------------------

function setStatus(msg, kind) {
  const el = $('#status');
  el.textContent = msg;
  el.className = 'status ' + (kind || '');
}

async function doPrint() {
  const btn = $('#print-btn');
  if (!settings.printerUrl) {
    setStatus("Renseignez l'adresse de l'imprimante dans Réglages.", 'err');
    return;
  }
  btn.disabled = true;
  setStatus('Impression en cours…', 'pending');
  try {
    const width = Number(settings.lineWidth) || 48;
    const blocks = buildBlocks(settings, data);
    await printBlocks(settings.printerUrl, blocks, width);
    setStatus('Ticket imprimé ✓', 'ok');
  } catch (e) {
    setStatus(
      'Échec : ' + e.message + ' — vérifiez l’IP, le Wi-Fi et le certificat de l’imprimante.',
      'err'
    );
  } finally {
    btn.disabled = false;
  }
}

// ---- Démarrage ----------------------------------------------------------

function init() {
  const editors = [
    listEditor('#items-list', data.items, [
      { key: 'libelle', placeholder: 'Désignation (ex. 2 repas complets)', cls: 'grow' },
      { key: 'montant', type: 'number', placeholder: '0,00', cls: 'amount' },
    ], refresh),
    listEditor('#tva-list', data.tvaLines, [
      { key: 'taux', type: 'number', step: '0.5', placeholder: 'Taux %', cls: 'rate' },
      { key: 'ht', type: 'number', placeholder: 'Montant HT', cls: 'grow' },
    ], refresh),
    listEditor('#paiements-list', data.paiements, [
      { key: 'libelle', placeholder: 'Moyen (ex. Carte de crédit)', cls: 'grow' },
      { key: 'montant', type: 'number', placeholder: '0,00', cls: 'amount' },
    ], refresh),
  ];

  $('#add-item').addEventListener('click', () => editors[0].add());
  $('#add-tva').addEventListener('click', () => editors[1].add());
  $('#add-paiement').addEventListener('click', () => editors[2].add());

  fillSettingsForm();
  SETTINGS_FIELDS.forEach((f) => {
    const el = document.getElementById('set-' + f);
    if (el) el.addEventListener('input', () => { readSettingsForm(); refresh(); });
  });

  const dlg = $('#settings');
  $('#open-settings').addEventListener('click', () => dlg.showModal());
  $('#close-settings').addEventListener('click', () => dlg.close());

  $('#print-btn').addEventListener('click', doPrint);

  refresh();

  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('./sw.js').catch(() => {});
  }
}

init();
