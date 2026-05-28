"use strict";

/* ------------------------------------------------------------------ *
 *  Note de frais — app web pour imprimante Epson TM-m30III (Wi-Fi)
 *  Impression via le SDK JavaScript Epson (epos-2.js).
 * ------------------------------------------------------------------ */

// Largeur d'une ligne en caractères (Font A, papier 80 mm).
// Ajustez si l'alignement des colonnes est décalé sur votre ticket (42 ou 48).
const LINE_WIDTH = 42;

const VAT_RATES = [
  { key: "ht55", rate: 0.055, label: "5,5 %" },
  { key: "ht10", rate: 0.10, label: "10 %" },
  { key: "ht20", rate: 0.20, label: "20 %" },
];

/* ----------------------------- Réglages --------------------------- */

const SETTINGS_KEYS = [
  "name", "address", "phone", "siret", "tva", "ip", "port",
];

function loadSettings() {
  const s = {};
  for (const k of SETTINGS_KEYS) {
    s[k] = localStorage.getItem("ndf_" + k) || "";
  }
  if (!s.port) s.port = "8008";
  return s;
}

function saveSettings(s) {
  for (const k of SETTINGS_KEYS) {
    localStorage.setItem("ndf_" + k, s[k] || "");
  }
}

/* ----------------------------- Helpers ---------------------------- */

const $ = (id) => document.getElementById(id);

function parseAmount(value) {
  if (!value) return 0;
  const normalized = String(value).replace(/\s/g, "").replace(",", ".");
  const n = parseFloat(normalized);
  return isNaN(n) ? 0 : n;
}

function formatEUR(value) {
  return value.toLocaleString("fr-FR", {
    style: "currency", currency: "EUR",
  });
}

function formatAmount(value) {
  return value.toLocaleString("fr-FR", {
    minimumFractionDigits: 2, maximumFractionDigits: 2,
  });
}

function formatDate(date) {
  return date.toLocaleString("fr-FR", {
    day: "2-digit", month: "2-digit", year: "numeric",
    hour: "2-digit", minute: "2-digit",
  });
}

function toLocalDatetimeValue(date) {
  const pad = (n) => String(n).padStart(2, "0");
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}` +
    `T${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

/* ------------------------ Modèle de ticket ------------------------ */

function buildReceiptModel() {
  const lines = VAT_RATES.map((r) => {
    const baseHT = parseAmount($(r.key).value);
    return { label: r.label, rate: r.rate, baseHT, tva: baseHT * r.rate };
  });
  const nonZero = lines.filter((l) => l.baseHT > 0);
  const totalHT = lines.reduce((a, l) => a + l.baseHT, 0);
  const totalTVA = lines.reduce((a, l) => a + l.tva, 0);

  const dateValue = $("date").value;
  const date = dateValue ? new Date(dateValue) : new Date();

  return {
    date,
    mealCount: parseInt($("mealCount").value, 10) || 0,
    lines: nonZero,
    totalHT,
    totalTVA,
    totalTTC: totalHT + totalTVA,
    settings: loadSettings(),
  };
}

function recomputeTotals() {
  const m = buildReceiptModel();
  $("totalHT").textContent = formatEUR(m.totalHT);
  $("totalTVA").textContent = formatEUR(m.totalTVA);
  $("totalTTC").textContent = formatEUR(m.totalTTC);
  $("btn-print").disabled = !(m.mealCount > 0 && m.totalHT > 0);
}

/* -------------------- Mise en forme texte ticket ------------------ */

function repeat(ch, n) { return ch.repeat(Math.max(0, n)); }
function separator() { return repeat("-", LINE_WIDTH); }

function threeCols(left, center, right) {
  const col = Math.floor(LINE_WIDTH / 3);
  const l = left.padEnd(col).slice(0, col);
  const c = center.padEnd(col).slice(0, col);
  const r = right.padStart(col).slice(0, col);
  return l + c + r;
}

function twoCols(left, right) {
  const space = Math.max(1, LINE_WIDTH - left.length - right.length);
  return left + repeat(" ", space) + right;
}

/* Génère les lignes texte communes à l'aperçu et à l'impression. */
function receiptLines(m) {
  const s = m.settings;
  const out = [];
  out.push({ text: s.name || "Restaurant", align: "center", size: 2, bold: true });
  if (s.address) out.push({ text: s.address, align: "center" });
  if (s.phone) out.push({ text: "Tél. " + s.phone, align: "center" });
  if (s.siret) out.push({ text: "SIRET : " + s.siret, align: "center" });
  if (s.tva) out.push({ text: "TVA : " + s.tva, align: "center" });
  out.push({ text: "", align: "left" });
  out.push({ text: separator(), align: "left" });
  out.push({ text: "NOTE DE FRAIS", align: "center", bold: true });
  out.push({ text: separator(), align: "left" });
  out.push({ text: "Date : " + formatDate(m.date), align: "left" });
  out.push({ text: "Prestation : " + m.mealCount + " repas", align: "left" });
  out.push({ text: "", align: "left" });
  out.push({ text: threeCols("Taux", "Base HT", "TVA"), align: "left", bold: true });
  out.push({ text: repeat("-", LINE_WIDTH), align: "left" });
  for (const l of m.lines) {
    out.push({
      text: threeCols(l.label, formatAmount(l.baseHT) + " €", formatAmount(l.tva) + " €"),
      align: "left",
    });
  }
  out.push({ text: separator(), align: "left" });
  out.push({ text: twoCols("Total HT", formatAmount(m.totalHT) + " €"), align: "left" });
  out.push({ text: twoCols("Total TVA", formatAmount(m.totalTVA) + " €"), align: "left" });
  out.push({ text: twoCols("TOTAL TTC", formatAmount(m.totalTTC) + " €"), align: "left", bold: true });
  out.push({ text: "", align: "left" });
  out.push({ text: "Merci de votre visite", align: "center" });
  return out;
}

/* ----------------------------- Aperçu ----------------------------- */

function renderPreview(m) {
  const lines = receiptLines(m);
  const html = lines.map((l) => {
    const cls = [];
    if (l.align === "center") cls.push("center");
    if (l.bold) cls.push("bold");
    const style = `text-align:${l.align};${l.bold ? "font-weight:700;" : ""}` +
      (l.size === 2 ? "font-size:1.3em;" : "");
    const safe = l.text
      .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    return `<div style="${style}">${safe || "&nbsp;"}</div>`;
  }).join("");
  $("receipt-preview").innerHTML = html;
}

/* --------------------------- Impression --------------------------- */

function setStatus(kind, message) {
  const el = $("print-status");
  el.className = "status " + kind;
  el.textContent = message;
  el.classList.remove("hidden");
}

function printReceipt(m) {
  const s = m.settings;
  if (!s.ip) {
    setStatus("error", "Aucune imprimante configurée. Ouvrez les réglages (⚙︎) et saisissez l'adresse IP.");
    return;
  }
  if (typeof epson === "undefined" || !epson.ePOSDevice) {
    setStatus("error", "SDK Epson (epos-2.js) introuvable. Placez le fichier epos-2.js dans le dossier web/ (voir README).");
    return;
  }

  setStatus("info", "Connexion à l'imprimante…");
  $("btn-do-print").disabled = true;

  const port = parseInt(s.port, 10) || 8008;
  const ePosDev = new epson.ePOSDevice();

  ePosDev.connect(s.ip, port, function (result) {
    if (result !== "OK" && result !== "SSL_CONNECT_OK") {
      $("btn-do-print").disabled = false;
      setStatus("error", "Connexion impossible (" + result + "). Vérifiez l'IP, le port, et que l'iPhone est sur le même Wi-Fi.");
      return;
    }
    ePosDev.createDevice(
      "local_printer",
      ePosDev.DEVICE_TYPE_PRINTER,
      { crypto: false, buffer: false },
      function (printer, code) {
        if (code !== "OK" || !printer) {
          $("btn-do-print").disabled = false;
          setStatus("error", "Imprimante indisponible (" + code + ").");
          ePosDev.disconnect();
          return;
        }
        sendToPrinter(printer, m, function () {
          ePosDev.disconnect();
        });
      }
    );
  });
}

function sendToPrinter(printer, m, done) {
  printer.onreceive = function (res) {
    $("btn-do-print").disabled = false;
    if (res.success) {
      setStatus("success", "Ticket envoyé à l'imprimante.");
    } else {
      setStatus("error", "Erreur d'impression : " + (res.code || "inconnue"));
    }
    if (done) done();
  };

  try {
    printer.addTextLang("fr");
    printer.addTextSmooth(true);
    printer.addTextFont(printer.FONT_A);

    for (const line of receiptLines(m)) {
      printer.addTextAlign(
        line.align === "center" ? printer.ALIGN_CENTER :
        line.align === "right" ? printer.ALIGN_RIGHT : printer.ALIGN_LEFT
      );
      const w = line.size === 2 ? 2 : 1;
      const h = line.size === 2 ? 2 : 1;
      printer.addTextSize(w, h);
      printer.addTextStyle(false, false, !!line.bold, printer.COLOR_1);
      printer.addText((line.text || "") + "\n");
    }

    printer.addTextSize(1, 1);
    printer.addTextStyle(false, false, false, printer.COLOR_1);
    printer.addFeedLine(3);
    printer.addCut(printer.CUT_FEED);
    printer.send();
  } catch (e) {
    $("btn-do-print").disabled = false;
    setStatus("error", "Erreur lors de la construction du ticket : " + e.message);
    if (done) done();
  }
}

/* --------------------------- Navigation --------------------------- */

function showView(id) {
  for (const v of ["view-main", "view-settings", "view-preview"]) {
    $(v).classList.toggle("hidden", v !== id);
  }
}

function openSettings() {
  const s = loadSettings();
  $("set-name").value = s.name;
  $("set-address").value = s.address;
  $("set-phone").value = s.phone;
  $("set-siret").value = s.siret;
  $("set-tva").value = s.tva;
  $("set-ip").value = s.ip;
  $("set-port").value = s.port;
  showView("view-settings");
}

function saveSettingsFromForm() {
  saveSettings({
    name: $("set-name").value.trim(),
    address: $("set-address").value.trim(),
    phone: $("set-phone").value.trim(),
    siret: $("set-siret").value.trim(),
    tva: $("set-tva").value.trim(),
    ip: $("set-ip").value.trim(),
    port: $("set-port").value.trim() || "8008",
  });
  recomputeTotals();
  showView("view-main");
}

/* ------------------------------ Init ------------------------------ */

function init() {
  $("date").value = toLocalDatetimeValue(new Date());

  for (const r of VAT_RATES) {
    $(r.key).addEventListener("input", recomputeTotals);
  }
  $("mealCount").addEventListener("input", recomputeTotals);

  $("btn-settings").addEventListener("click", openSettings);
  $("btn-settings-done").addEventListener("click", saveSettingsFromForm);

  $("btn-print").addEventListener("click", function () {
    const m = buildReceiptModel();
    renderPreview(m);
    $("print-status").classList.add("hidden");
    $("btn-do-print").disabled = false;
    showView("view-preview");
  });

  $("btn-back").addEventListener("click", function () { showView("view-main"); });
  $("btn-do-print").addEventListener("click", function () {
    printReceipt(buildReceiptModel());
  });

  recomputeTotals();

  // Premier lancement : pas d'imprimante configurée → ouvrir les réglages.
  const s = loadSettings();
  if (!s.name || !s.ip) openSettings();
}

document.addEventListener("DOMContentLoaded", init);
