#!/usr/bin/env node

const fs = require('fs/promises');
const path = require('path');
const os = require('os');

const defaultTarget = path.join(
  os.homedir(),
  'Repositories',
  'personal',
  'lazygit',
  'pkg',
  'gui',
  'presentation',
  'icons',
  'file_icons.go',
);

const targetFile = process.argv[2] || defaultTarget;

const CATPPUCCIN = {
  // — Mocha —
  'mocha.rosewater': '#f5e0dc',
  'mocha.flamingo': '#f2cdcd',
  'mocha.pink': '#f5c2e7',
  'mocha.mauve': '#cba6f7',
  'mocha.red': '#f38ba8',
  'mocha.maroon': '#eba0ac',
  'mocha.peach': '#fab387',
  'mocha.yellow': '#f9e2af',
  'mocha.green': '#a6e3a1',
  'mocha.teal': '#94e2d5',
  'mocha.sky': '#89dceb',
  'mocha.sapphire': '#74c7ec',
  'mocha.blue': '#89b4fa',
  'mocha.lavender': '#b4befe',
  'mocha.text': '#cdd6f4',
  'mocha.subtext1': '#bac2de',
  'mocha.subtext0': '#a6adc8',
};

/**
 * Convert a hex string "#rrggbb" to an [r,g,b] array.
 */
const hexToRgb = (hex) => [
  parseInt(hex.slice(1, 3), 16),
  parseInt(hex.slice(3, 5), 16),
  parseInt(hex.slice(5, 7), 16),
];

/**
 * Return the palette hex that is closest (Euclidean distance) to `hex`.
 */
function nearestCatppuccin(hex) {
  const [r1, g1, b1] = hexToRgb(hex);
  let bestHex = hex;
  let bestDist = Infinity;

  for (const palHex of Object.values(CATPPUCCIN)) {
    const [r2, g2, b2] = hexToRgb(palHex);
    const dist = (r1 - r2) ** 2 + (g1 - g2) ** 2 + (b1 - b2) ** 2;
    if (dist < bestDist) {
      bestDist = dist;
      bestHex = palHex.toUpperCase();
    }
  }
  return bestHex;
}

function catppuccinise(content) {
  return content.replace(
    /Color\s*:\s*"(#[A-Fa-f0-9]{6})"/g,
    (_, hex) => `Color: "${nearestCatppuccin(hex.toLowerCase())}"`,
  );
}

/* ---------- 3  run ---------- */
(async () => {
  try {
    const original = await fs.readFile(targetFile, 'utf8');
    const themed = catppuccinise(original);

    if (themed === original) {
      console.log('No changes – already Catppuccin-ised 🎉');
      return;
    }

    await fs.writeFile(targetFile, themed, 'utf8');

    console.log(`✅  Colours updated in ${targetFile}`);
  } catch (err) {
    console.error('🔥  Error:', err.message);
    process.exit(1);
  }
})();
