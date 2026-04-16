#!/usr/bin/env node
// report-converter.js — Convert JSON test results to JUnit XML.
//
// Usage:
//   cat results.json | node report-converter.js              # stdin → stdout
//   node report-converter.js results.json                    # file  → stdout
//   node report-converter.js results.json report.xml         # file  → file
//
// Expected JSON format:
// {
//   "testSuite": "string",
//   "timestamp": "ISO-8601 string",
//   "tests": [{
//     "id": "string",
//     "name": "string",
//     "category": "string",
//     "status": "passed" | "failed" | "skipped",
//     "duration_ms": number,
//     "error": "optional string",
//     "screenshot": "optional string"
//   }]
// }

const fs = require('fs');

function escapeXml(s) {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;');
}

function convert(data) {
  const suite = data.testSuite || 'unknown';
  const timestamp = data.timestamp || new Date().toISOString();
  const tests = Array.isArray(data.tests) ? data.tests : [];

  const failures = tests.filter(t => t.status === 'failed').length;
  const skipped = tests.filter(t => t.status === 'skipped').length;
  const totalTime = tests.reduce((sum, t) => sum + (t.duration_ms || 0), 0) / 1000;

  const lines = [
    '<?xml version="1.0" encoding="UTF-8"?>',
    `<testsuites>`,
    `  <testsuite name="${escapeXml(suite)}" tests="${tests.length}" failures="${failures}" skipped="${skipped}" time="${totalTime.toFixed(3)}" timestamp="${escapeXml(timestamp)}">`,
  ];

  for (const t of tests) {
    const id = t.id || 'unknown';
    const name = t.name || id;
    const cls = t.category || suite;
    const time = ((t.duration_ms || 0) / 1000).toFixed(3);

    lines.push(`    <testcase name="${escapeXml(name)}" classname="${escapeXml(cls)}" time="${time}">`);

    if (t.status === 'failed') {
      const msg = t.error || 'Test failed';
      lines.push(`      <failure message="${escapeXml(msg)}">${escapeXml(msg)}</failure>`);
    } else if (t.status === 'skipped') {
      lines.push('      <skipped/>');
    }

    if (t.screenshot) {
      lines.push(`      <system-out>screenshot: ${escapeXml(t.screenshot)}</system-out>`);
    }

    lines.push('    </testcase>');
  }

  lines.push('  </testsuite>');
  lines.push('</testsuites>');
  return lines.join('\n') + '\n';
}

// Main
(async () => {
  let input;
  const [inFile, outFile] = process.argv.slice(2);

  if (inFile) {
    input = fs.readFileSync(inFile, 'utf8');
  } else {
    input = fs.readFileSync('/dev/stdin', 'utf8');
  }

  if (!input.trim()) {
    process.stderr.write('ERROR: Empty input\n');
    process.exit(1);
  }

  let data;
  try {
    data = JSON.parse(input);
  } catch (e) {
    process.stderr.write(`ERROR: Invalid JSON — ${e.message}\n`);
    process.exit(1);
  }

  const xml = convert(data);

  if (outFile) {
    fs.writeFileSync(outFile, xml);
    process.stderr.write(`Wrote ${outFile}\n`);
  } else {
    process.stdout.write(xml);
  }
})();
