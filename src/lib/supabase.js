import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://eqvcitdiyfmukaiwegrs.supabase.co'
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVxdmNpdGRpeWZtdWthaXdlZ3JzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg1NzIwMDMsImV4cCI6MjA5NDE0ODAwM30.MP96P9TmQXPFojpmTSojl6N6mAazFOml3xSOxvx2WuE'

export const supabase = createClient(supabaseUrl, supabaseAnonKey)
