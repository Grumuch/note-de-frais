// Impression via l'API ePOS-Print de l'imprimante Epson (POST XML).
// Aucun SDK propriétaire requis : on parle directement au service
// /cgi-bin/epos/service.cgi de la TM-m30III.

function xmlEscape(s) {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

// Convertit les blocs (cf. receipt.js) en commandes ePOS-Print.
export function blocksToEposXml(blocks) {
  const NS = 'http://www.epson-pos.com/schemas/2011/03/epos-print';
  const parts = [`<epos-print xmlns="${NS}">`];

  for (const b of blocks) {
    if (b.type === 'feed') {
      parts.push(`<feed line="${b.lines || 1}"/>`);
      continue;
    }
    if (b.type === 'rule') {
      parts.push('<text align="left"/>');
      parts.push(`<text>${'-'.repeat(b.width || 48)}&#10;</text>`);
      continue;
    }
    // type === 'text'
    parts.push(`<text align="${b.align === 'center' ? 'center' : 'left'}"/>`);
    const w = b.size === 2 ? 2 : 1;
    parts.push(`<text width="${w}" height="${w}"/>`);
    parts.push(`<text em="${b.bold ? 'true' : 'false'}"/>`);
    parts.push(`<text>${xmlEscape(b.text)}&#10;</text>`);
    // reset
    parts.push('<text em="false"/><text width="1" height="1"/><text align="left"/>');
  }

  parts.push('<cut type="feed"/>');
  parts.push('</epos-print>');
  return parts.join('');
}

function soapEnvelope(eposXml) {
  return (
    '<?xml version="1.0" encoding="utf-8"?>' +
    '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"><s:Body>' +
    eposXml +
    '</s:Body></s:Envelope>'
  );
}

// Envoie l'impression. Renvoie { success, code, status, raw }.
export async function printBlocks(printerUrl, blocks, width) {
  const enriched = blocks.map((b) => (b.type === 'rule' ? { ...b, width } : b));
  const body = soapEnvelope(blocksToEposXml(enriched));

  const res = await fetch(printerUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'text/xml; charset=utf-8',
      SOAPAction: '""',
    },
    body,
  });

  const raw = await res.text();
  if (!res.ok) {
    throw new Error(`Imprimante: HTTP ${res.status}. ${raw.slice(0, 200)}`);
  }
  const success = /success\s*=\s*"true"/i.test(raw);
  const code = (raw.match(/code\s*=\s*"([^"]*)"/i) || [])[1] || '';
  const status = (raw.match(/status\s*=\s*"([^"]*)"/i) || [])[1] || '';
  if (!success) {
    throw new Error(`Impression refusée par l'imprimante (code ${code || '?'}).`);
  }
  return { success, code, status, raw };
}
