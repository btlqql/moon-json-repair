// One fail-fast entry point; prints the exact failed command for review reports.
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const args = process.argv.slice(2);
const target = args.length === 0 ? 'js' : args[1];
if (args.length !== 0 && (args.length !== 2 || args[0] !== '--target') ||
    !['js', 'wasm', 'wasm-gc', 'native'].includes(target)) {
  console.error('Usage: node scripts/verify.mjs [--target js|wasm|wasm-gc|native]');
  process.exit(2);
}
const cwd = fileURLToPath(new URL('../', import.meta.url));
function run(command, argv) {
  console.log(`\n> ${command} ${argv.join(' ')}`);
  const result = spawnSync(command, argv, { cwd, stdio: 'inherit', shell: false });
  if (result.error || result.status !== 0) {
    console.error(`FAILED: ${command} ${argv.join(' ')}`);
    if (result.error) console.error(result.error.message);
    process.exit(result.status ?? 1);
  }
}
console.log(`Verification target: ${target}; Node ${process.version}`);
run('moon', ['version', '--all']);
run('moon', ['fmt', '--check']);
for (const stage of ['check', 'build', 'test']) {
  run('moon', [stage, '--target', target, '--deny-warn']);
}
for (const example of ['examples/basic', 'examples/audit']) {
  run('moon', ['run', example, '--target', target]);
}
if (target === 'js') {
  run(process.execPath, ['scripts/test-cli.mjs']);
  run(process.execPath, ['scripts/test-import-scenario.mjs']);
}
console.log(`Verification passed: ${target}`);
