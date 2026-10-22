// Generate Localizable.strings from a prototype's string tables.
//   node scripts/extract-strings.mjs <prototype-dir> <Resources-dir>
//        [--tables SHELL_STRINGS:shell.js,STRINGS:index.html] [--allow key1,key2]
// Reads each `const NAME = { en: {…}, th: {…} }` object literal (later tables override earlier ones, like t() does),
// converts {0} {1} → %1$@ %2$@ (named {usd} → next free %n$@), and writes <Resources>/<lang>.lproj/Localizable.strings.
// Stops when a key is defined in two tables with different text: in the prototype the later table silently wins,
// so the earlier text never shows (e.g. a "Remove from History" button reading "Deleted scene {0}"). A deliberate
// override (an app retitling a shared panel) goes in --allow; same text in both tables is fine.
import fs from 'node:fs';
import path from 'node:path';

const [dir, out, ...rest] = process.argv.slice(2);
if (!dir || !out) {
  console.error('usage: extract-strings.mjs <prototype-dir> <Resources-dir> [--tables NAME:file,…] [--allow key,…]');
  process.exit(2);
}
const flag = name => { const i = rest.indexOf(name); return i >= 0 ? rest[i + 1] : undefined; };
const tables = (flag('--tables') ?? 'SHELL_STRINGS:shell.js,STRINGS:index.html').split(',').map(s => s.split(':'));
const allowed = new Set((flag('--allow') ?? '').split(',').filter(Boolean));

/** The object literal after `const NAME =`, evaluated (it's your own prototype source — trusted). */
function grab(file, name) {
  const file_ = path.join(dir, file);
  if (!fs.existsSync(file_)) fail(`${file_} not found — pass --tables NAME:file,… for this prototype's layout`);
  const src = fs.readFileSync(file_, 'utf8');
  const start = src.indexOf(`const ${name} = {`);
  if (start < 0) fail(`const ${name} = {…} not found in ${file}`);
  let depth = 0, quote = null;
  for (let i = src.indexOf('{', start); i < src.length; i++) {
    const c = src[i];
    if (quote) { if (c === '\\') i++; else if (c === quote) quote = null; continue; }
    if (c === "'" || c === '"' || c === '`') quote = c;
    else if (c === '{') depth++;
    else if (c === '}' && --depth === 0) return eval('(' + src.slice(src.indexOf('{', start), i + 1) + ')');
  }
  fail(`unbalanced ${name} in ${file}`);
}
function fail(message) { console.error(message); process.exit(1); }

const loaded = tables.map(([name, file]) => ({ name, table: grab(file, name) }));
const langs = [...new Set(loaded.flatMap(t => Object.keys(t.table)))];
const clashes = new Set();
for (const lang of langs) {
  const seen = new Map();   // key → { table, text }
  for (const { name, table } of loaded) for (const [key, text] of Object.entries(table[lang] ?? {})) {
    const before = seen.get(key);
    if (before && before.text !== text && !allowed.has(key)) {
      clashes.add(`${key}: ${before.table} "${before.text}" ← ${name} "${text}"`);
    }
    seen.set(key, { table: name, text });
  }
}
if (clashes.size) {
  fail('Same key, different text in two tables (the later one wins in the prototype too).\n' +
       'Rename one, or --allow the key if the override is deliberate:\n  ' + [...clashes].join('\n  '));
}

const toFormat = v => {
  let next = 1; const names = {};
  return v.replace(/\{(\w+)\}/g, (_, k) => {
    names[k] ??= /^\d+$/.test(k) ? Number(k) + 1 : next;
    next = Math.max(next, names[k] + 1);
    return `%${names[k]}$@`;
  }).replace(/%(?!\d+\$@)/g, '%%').replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/\n/g, '\\n');
};
for (const lang of langs) {
  const merged = Object.assign({}, ...loaded.map(t => t.table[lang] ?? {}));
  const body = Object.entries(merged).map(([k, v]) => `"${k}" = "${toFormat(v)}";`).join('\n');
  fs.mkdirSync(path.join(out, `${lang}.lproj`), { recursive: true });
  fs.writeFileSync(path.join(out, `${lang}.lproj`, 'Localizable.strings'),
    `/* Generated from the prototype by extract-strings.mjs — edit by hand from here on. */\n${body}\n`);
  console.log(`${lang}: ${Object.keys(merged).length} keys`);
}
