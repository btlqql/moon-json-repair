// Deterministic synthetic import scenario. It is deliberately labelled as
// synthetic: no production-user or real-data claim is made by this test.
import { spawnSync } from 'node:child_process';
import assert from 'node:assert/strict';
import { mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const root = fileURLToPath(new URL('../', import.meta.url));
const work = join(root, '_build', 'import-scenario');
const inputPath = join(work, 'mixed-events.jsonl');
const cli = join(root, '_build', 'js', 'debug', 'build', 'cmd', 'main', 'main.js');
rmSync(work, {recursive: true, force: true});
mkdirSync(work, {recursive: true});

const sources = [];
for (let i = 1; i <= 2000; i++) {
  if (i === 1000) {
    // Exceeds the default per-line limit and crosses many 64 KiB read chunks.
    sources.push(`{"id":${i},"payload":"${'x'.repeat(1_048_576)}"}`);
  } else if (i % 100 === 0) {
    sources.push(`{"id":${i},"id":${i + 1}}`);
  } else if (i % 100 === 1) {
    sources.push(`{"id":${i},"label":}`);
  } else if (i % 3 === 0) {
    sources.push(JSON.stringify({id:i, label:'事件😀', active:true}));
  } else {
    sources.push(`{id:${i}, label:'事件😀', active:true,}`);
  }
}
writeFileSync(inputPath, sources.join('\n') + '\n', 'utf8');

const start = process.hrtime.bigint();
const result = spawnSync(process.execPath, [cli, '--jsonl', '--summary', inputPath], {
  encoding: 'utf8', maxBuffer: 32 * 1024 * 1024,
});
const elapsedMs = Number(process.hrtime.bigint() - start) / 1e6;
assert.equal(result.error, undefined);
assert.equal(result.status, 1, result.stderr);
const rows = result.stdout.trim().split('\n').map(JSON.parse);
assert.equal(rows.length, sources.length, 'every physical record must produce one result');
const summary = JSON.parse(result.stderr.trim());
assert.deepEqual(summary, {
  lines: 2000, accepted: 1960, repaired: 1306, unchanged: 654,
  rejected: 40, edits: 6530,
});

function replay(source, edits) {
  let out = source;
  for (let i = edits.length - 1; i >= 0; i--) {
    const e = edits[i];
    out = out.slice(0, e.start) + e.replacement + out.slice(e.end);
  }
  return out;
}
for (let i = 0; i < rows.length; i++) {
  const row = rows[i];
  assert.equal(row.line, i + 1);
  if (row.output !== undefined) {
    assert.doesNotThrow(() => JSON.parse(row.output));
    assert.equal(replay(sources[i], row.edits), row.output);
    if (row.edits.length === 0) assert.equal(row.output, sources[i]);
  }
}
assert.equal(rows[999].error_code, 'LINE_INPUT_LIMIT');
assert.equal(rows[1001].output !== undefined, true, 'processing must continue after an oversized line');

const mib = Buffer.byteLength(sources.join('\n') + '\n') / 1048576;
const recordsPerSecond = Math.round(sources.length / (elapsedMs / 1000));
console.log(JSON.stringify({
  scenario: 'synthetic-mixed-jsonl-import', records: sources.length,
  inputMiB: Number(mib.toFixed(2)), elapsedMs: Number(elapsedMs.toFixed(1)),
  recordsPerSecond, ...summary,
}));
