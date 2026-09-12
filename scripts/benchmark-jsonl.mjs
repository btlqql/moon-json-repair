// Reproducible single-process throughput check, not a universal performance claim.
import { spawnSync } from 'node:child_process';
import assert from 'node:assert/strict';
import { fileURLToPath } from 'node:url';
import { join } from 'node:path';

const root = fileURLToPath(new URL('../', import.meta.url));
const cli = join(root, '_build', 'js', 'debug', 'build', 'cmd', 'main', 'main.js');
const sizes = process.argv.length > 2
  ? process.argv.slice(2).map(Number)
  : [1000, 10000, 50000];
for (const records of sizes) {
  assert.equal(Number.isSafeInteger(records) && records > 0, true);
  const lines = Array.from({length: records}, (_, i) =>
    `{id:${i + 1}, label:'Moon JSON Repair', active:true,}`);
  const input = lines.join('\n') + '\n';
  const start = process.hrtime.bigint();
  const result = spawnSync(process.execPath, [cli, '--jsonl', '--summary'], {
    input, encoding: 'utf8', maxBuffer: 256 * 1024 * 1024,
  });
  const elapsedMs = Number(process.hrtime.bigint() - start) / 1e6;
  assert.equal(result.error, undefined);
  assert.equal(result.status, 0, result.stderr);
  const summary = JSON.parse(result.stderr);
  assert.equal(summary.lines, records);
  assert.equal(summary.accepted, records);
  assert.equal(summary.repaired, records);
  assert.equal(result.stdout.trim().split('\n').length, records);
  const inputMiB = Buffer.byteLength(input) / 1048576;
  console.log(JSON.stringify({
    records,
    inputMiB: Number(inputMiB.toFixed(2)),
    elapsedMs: Number(elapsedMs.toFixed(1)),
    recordsPerSecond: Math.round(records / (elapsedMs / 1000)),
    inputMiBPerSecond: Number((inputMiB / (elapsedMs / 1000)).toFixed(2)),
  }));
}
