import { spawnSync } from 'node:child_process';
import assert from 'node:assert/strict';

const cli = '_build/js/debug/build/cmd/main/main.js';
let checks = 0;
function run(args, input = '') {
  const r = spawnSync(process.execPath, [cli, ...args], {input, encoding:'utf8'});
  assert.equal(r.error, undefined);
  checks++;
  return r;
}
let r = run([], '{name: \'Moon\',}');
assert.equal(r.status, 0);
assert.deepEqual(JSON.parse(r.stdout), {name:'Moon'});
r = run(['--report'], "{name:'Moon'}");
assert.equal(JSON.parse(r.stdout).edits.length, 2);
assert.equal(run(['--strict'], '{a:1}').status, 1);
assert.equal(run(['--close-containers'], '[1').status, 0);
assert.equal(run(['--close-containers'], '[1,').status, 1);
assert.equal(run(['--strict', '--close-containers']).status, 2);
assert.equal(run(['--unknown']).status, 2);
assert.equal(run(['missing-file-7edb363a.json']).status, 2);
assert.equal(run([], Buffer.from([0xff])).status, 2);
assert.equal(run([], 'x'.repeat(4194305)).status, 2);
r = run(['--jsonl'], '{a:1}\n{b:}\n');
assert.equal(r.status, 1);
const rows = r.stdout.trim().split('\n').map(JSON.parse);
assert.equal(rows.length, 2);
assert.equal(rows[0].line, 1);
assert.equal(rows[1].output, undefined);
assert.equal(typeof rows[1].error_code, 'string');
assert.equal(rows[1].line, 2);
r = run([], '{secret:');
assert.equal(r.status, 1);
assert.equal(r.stderr.includes('secret'), false);
assert.equal(run(['--help']).status, 0);
console.log(`CLI integration: ${checks} checks passed`);
