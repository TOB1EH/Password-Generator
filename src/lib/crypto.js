// Web Crypto API utility for symmetric encryption
const SALT_KEY = 'pg-master-salt-v1'
const ITERATIONS = 100000

export async function deriveKey(password) {
  const enc = new TextEncoder()
  const keyMaterial = await window.crypto.subtle.importKey(
    'raw',
    enc.encode(password),
    { name: 'PBKDF2' },
    false,
    ['deriveBits', 'deriveKey']
  )

  return window.crypto.subtle.deriveKey(
    {
      name: 'PBKDF2',
      salt: enc.encode(SALT_KEY),
      iterations: ITERATIONS,
      hash: 'SHA-256'
    },
    keyMaterial,
    { name: 'AES-GCM', length: 256 },
    false,
    ['encrypt', 'decrypt']
  )
}

export async function encryptData(key, text) {
  const enc = new TextEncoder()
  const iv = window.crypto.getRandomValues(new Uint8Array(12))
  const encrypted = await window.crypto.subtle.encrypt(
    { name: 'AES-GCM', iv },
    key,
    enc.encode(text)
  )

  const combined = new Uint8Array(iv.length + encrypted.byteLength)
  combined.set(iv, 0)
  combined.set(new Uint8Array(encrypted), iv.length)

  return btoa(String.fromCharCode.apply(null, combined))
}

export async function decryptData(key, base64Str) {
  const combinedStr = atob(base64Str)
  const combined = new Uint8Array(combinedStr.length)
  for (let i = 0; i < combinedStr.length; i++) {
    combined[i] = combinedStr.charCodeAt(i)
  }

  const iv = combined.slice(0, 12)
  const data = combined.slice(12)

  const decrypted = await window.crypto.subtle.decrypt(
    { name: 'AES-GCM', iv },
    key,
    data
  )
  const dec = new TextDecoder()
  return dec.decode(decrypted)
}
