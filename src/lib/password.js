function getCrypto() {
  // Browser only (GitHub Pages). If not available, fail loudly.
  const c = globalThis.crypto
  if (!c || typeof c.getRandomValues !== 'function') {
    throw new Error('crypto.getRandomValues no esta disponible')
  }
  return c
}

export function randomInt(maxExclusive) {
  if (!Number.isInteger(maxExclusive) || maxExclusive <= 0) {
    throw new Error('maxExclusive invalido')
  }

  // Rejection sampling to avoid modulo bias.
  const crypto = getCrypto()
  const range = 0x100000000
  const limit = range - (range % maxExclusive)
  const buf = new Uint32Array(1)

  while (true) {
    crypto.getRandomValues(buf)
    const x = buf[0]
    if (x < limit) return x % maxExclusive
  }
}

export function buildCharset({ lower, upper, numbers, symbols }) {
  const sets = {
    lower: 'abcdefghijklmnopqrstuvwxyz',
    upper: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
    numbers: '0123456789',
    // Similar to Bitwarden defaults; avoids spaces.
    symbols: '!@#$%^&*()-_=+[]{};:,.<>?/',
  }

  let charset = ''
  if (lower) charset += sets.lower
  if (upper) charset += sets.upper
  if (numbers) charset += sets.numbers
  if (symbols) charset += sets.symbols

  return charset
}

export function generatePassword({ length, charset }) {
  if (!Number.isInteger(length) || length < 8 || length > 128) {
    throw new Error('longitud fuera de rango')
  }
  if (!charset || charset.length < 2) {
    throw new Error('charset invalido')
  }

  let out = ''
  for (let i = 0; i < length; i++) {
    out += charset[randomInt(charset.length)]
  }
  return out
}

export function estimateStrengthBits({ length, charsetSize }) {
  if (!Number.isFinite(length) || !Number.isFinite(charsetSize)) return 0
  if (length <= 0 || charsetSize <= 1) return 0
  return length * Math.log2(charsetSize)
}
