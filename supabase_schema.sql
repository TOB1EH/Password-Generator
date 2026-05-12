-- Script para crear la tabla de historial de contraseñas en Supabase

-- 1. Crear la tabla
CREATE TABLE IF NOT EXISTS public.password_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    label TEXT NOT NULL,
    kind TEXT NOT NULL,
    encrypted_value TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Habilitar Row Level Security (RLS)
ALTER TABLE public.password_history ENABLE ROW LEVEL SECURITY;

-- 3. Crear politicas de seguridad para que cada usuario solo vea/modifique lo suyo
CREATE POLICY "Los usuarios pueden ver su propio historial"
    ON public.password_history
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Los usuarios pueden insertar en su propio historial"
    ON public.password_history
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Los usuarios pueden eliminar su propio historial"
    ON public.password_history
    FOR DELETE
    USING (auth.uid() = user_id);
