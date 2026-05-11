import { randomInt } from './password.js'

const WORDS_ES = [
  'arbol',
  'cielo',
  'cambio',
  'camino',
  'campo',
  'carta',
  'casa',
  'clave',
  'cobre',
  'cometa',
  'cuadro',
  'dado',
  'delta',
  'diente',
  'dragon',
  'eco',
  'faro',
  'fuego',
  'gato',
  'hielo',
  'isla',
  'jardin',
  'lago',
  'luna',
  'marea',
  'metal',
  'nube',
  'norte',
  'olivo',
  'oro',
  'piano',
  'piedra',
  'puente',
  'raiz',
  'rio',
  'sombra',
  'sol',
  'tierra',
  'torre',
  'trueno',
  'valle',
  'viento',
  'zorro',
]

function capitalizeFirst(word) {
  if (!word) return word
  return word[0].toUpperCase() + word.slice(1)
}

export function generatePassphrase({ wordsCount, separator = '-', capitalize = false }) {
  if (!Number.isInteger(wordsCount) || wordsCount < 2 || wordsCount > 10) {
    throw new Error('cantidad de palabras fuera de rango')
  }

  const out = []
  for (let i = 0; i < wordsCount; i++) {
    const w = WORDS_ES[randomInt(WORDS_ES.length)]
    out.push(capitalize ? capitalizeFirst(w) : w)
  }

  return out.join(separator)
}
