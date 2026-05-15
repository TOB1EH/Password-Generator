#!/usr/bin/env node

// Password Generator - Backup Script
// Exporta datos desde Supabase REST API (HTTPS, funciona sin IPv6)
// Uso: node backup.mjs  o  npm run backup

import { createClient } from '@supabase/supabase-js'
import { readFileSync, writeFileSync, mkdirSync, statSync, unlinkSync, createReadStream, createWriteStream } from 'fs'
import { createGzip } from 'zlib'
import { pipeline } from 'stream/promises'
import { dirname, join } from 'path'
import { fileURLToPath } from 'url'
import { createInterface } from 'readline'

const __dirname = dirname(fileURLToPath(import.meta.url))
const BACKUP_DIR = join(__dirname, 'backups')
const TS = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19)
const BACKUP_FILE = join(BACKUP_DIR, `password_generator_${TS}.sql`)
const BACKUP_GZ = `${BACKUP_FILE}.gz`

const C = { r: '\x1b[31m', g: '\x1b[32m', y: '\x1b[33m', b: '\x1b[34m', n: '\x1b[0m' }
const log = (c, m) => console.log(`${c}${m}${C.n}`)

function ask(question) {
  const rl = createInterface({ input: process.stdin, output: process.stdout })
  return new Promise(resolve => rl.question(question, a => { rl.close(); resolve(a) }))
}

async function main() {
  log(C.y, 'Password Generator - Backup Script')
  console.log('======================================\n')

  // Cargar .env.local
  let supabaseUrl, supabaseKey, email, password
  try {
    const env = readFileSync(join(__dirname, '.env.local'), 'utf-8')
    for (const line of env.split('\n')) {
      const t = line.trim()
      if (!t || t.startsWith('#')) continue
      const i = t.indexOf('=')
      if (i === -1) continue
      const k = t.slice(0, i), v = t.slice(i + 1)
      if (k === 'VITE_SUPABASE_URL') supabaseUrl = v
      if (k === 'VITE_SUPABASE_ANON_KEY') supabaseKey = v
      if (k === 'SUPABASE_AUTH_EMAIL') email = v
      if (k === 'SUPABASE_AUTH_PASSWORD') password = v
    }
  } catch {
    log(C.r, 'Error: .env.local no encontrado. Copia .env.example a .env.local')
    process.exit(1)
  }

  if (!supabaseUrl || !supabaseKey) {
    log(C.r, 'Error: VITE_SUPABASE_URL y VITE_SUPABASE_ANON_KEY requeridos en .env.local')
    process.exit(1)
  }

  // Pedir credenciales si no estan en .env.local
  if (!email) email = await ask('Email de usuario Supabase: ')
  if (!password) password = await ask('Password de usuario Supabase: ')

  log(C.b, `Conectando a: ${supabaseUrl}`)
  const supabase = createClient(supabaseUrl, supabaseKey)

  // Autenticar
  log(C.y, 'Autenticando con Supabase...')
  const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
    email, password
  })

  if (authError) {
    log(C.r, `\nError de autenticacion: ${authError.message}`)
    process.exit(1)
  }

  log(C.g, `Autenticado como: ${authData.user.email}`)
  log(C.g, `User ID: ${authData.user.id}`)

  // Obtener datos
  log(C.y, '\nObteniendo datos de password_history...')
  const { data, error } = await supabase
    .from('password_history')
    .select('*')
    .order('created_at', { ascending: false })

  if (error) {
    log(C.r, `\nError al leer datos: ${error.message}`)
    process.exit(1)
  }

  const rows = data || []
  log(C.g, `Registros encontrados: ${rows.length}`)

  if (rows.length === 0) {
    log(C.y, 'No hay datos para exportar.')
    process.exit(0)
  }

  // Generar SQL
  log(C.y, 'Generando archivo SQL...')
  let sql = ''
  sql += `-- Password Generator - Backup\n`
  sql += `-- Fecha: ${new Date().toLocaleString()}\n`
  sql += `-- Usuario: ${authData.user.email}\n`
  sql += `-- Fuente: ${supabaseUrl}\n--\n\n`
  sql += 'BEGIN;\n\n'

  const colsPresent = Object.keys(rows[0])
  const colList = colsPresent.map(c => `"${c}"`).join(', ')

  for (const row of rows) {
    const values = colsPresent.map(col => {
      const v = row[col]
      if (v === null || v === undefined) return 'NULL'
      if (typeof v === 'number') return String(v)
      if (typeof v === 'boolean') return v ? 'true' : 'false'
      return `'${String(v).replace(/'/g, "''")}'`
    }).join(', ')
    sql += `INSERT INTO password_history (${colList}) VALUES (${values});\n`
  }
  sql += '\nCOMMIT;\n'

  // Guardar y comprimir
  mkdirSync(BACKUP_DIR, { recursive: true })
  writeFileSync(BACKUP_FILE, sql)

  log(C.y, 'Comprimiendo con gzip...')
  const gzip = createGzip()
  const src = createReadStream(BACKUP_FILE)
  const dest = createWriteStream(BACKUP_GZ)
  await pipeline(src, gzip, dest)

  unlinkSync(BACKUP_FILE)
  const sizeKB = (statSync(BACKUP_GZ).size / 1024).toFixed(2)

  console.log()
  console.log('='.repeat(45))
  log(C.g, 'Backup completado exitosamente')
  log(C.g, `  Archivo: ${BACKUP_GZ}`)
  log(C.g, `  Tamano:  ${sizeKB} KB`)
  log(C.g, `  Filas:   ${rows.length}`)
  console.log('='.repeat(45))
  console.log()
}

main().catch(err => {
  console.error(`${C.r}Error: ${err.message}${C.n}`)
  process.exit(1)
})
