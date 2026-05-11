import { randomInt } from './password.js'

const WORDS_ES = [
  'arbol', 'cielo', 'cambio', 'camino', 'campo',
  'carta', 'casa', 'clave', 'cobre', 'cometa',
  'cuadro', 'dado', 'delta', 'diente', 'dragon',
  'eco', 'faro', 'fuego', 'gato', 'hielo',
  'isla', 'jardin', 'lago', 'luna', 'marea',
  'metal', 'nube', 'norte', 'olivo', 'oro',
  'piano', 'piedra', 'puente', 'raiz', 'rio',
  'sombra', 'sol', 'tierra', 'torre', 'trueno',
  'valle', 'viento', 'zorro',
]

const WORDS_EN = [
  'apple', 'beach', 'cloud', 'dance', 'eagle',
  'flame', 'grape', 'house', 'ivory', 'jewel',
  'knife', 'lemon', 'mango', 'night', 'ocean',
  'piano', 'queen', 'river', 'stone', 'tiger',
  'umbra', 'vivid', 'whale', 'xenon', 'yacht',
  'zebra', 'bloom', 'crane', 'drift', 'ember',
  'frost', 'grove', 'humor', 'image', 'jolly',
  'kayak', 'lilac', 'magic', 'noble', 'olive',
  'pearl', 'quest', 'radar', 'solar', 'trail',
  'ultra', 'vocal', 'wheat',
]

function capitalizeFirst(word) {
  if (!word) return word
  return word[0].toUpperCase() + word.slice(1)
}

export function generatePassphrase({ wordsCount, separator = '-', capitalize = false, lang = 'es' }) {
  if (!Number.isInteger(wordsCount) || wordsCount < 2 || wordsCount > 20) {
    throw new Error('cantidad de palabras fuera de rango')
  }

  const dict = lang === 'en' ? WORDS_EN : WORDS_ES
  const out = []
  for (let i = 0; i < wordsCount; i++) {
    const w = dict[randomInt(dict.length)]
    out.push(capitalize ? capitalizeFirst(w) : w)
  }

  return out.join(separator)
}
