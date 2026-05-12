# Configuración de Supabase

Pasos obligatorios para que la persistencia en Supabase funcione correctamente. Para que la aplicación funcione, necesitas preparar tu base de datos y tu usuario administrador.

## Paso 1: Crear tu usuario administrador

Supabase gestiona la autenticación de forma nativa y segura.
1. Entra a tu dashboard de Proyecto de Supabase.
2. Ve al apartado de **Authentication** > **Users** en el menú izquierdo.
3. Haz clic arriba a la derecha en **Add User** -> **Create New User**.
4. Añade tu correo electrónico personal y una contraseña segura. 
> 💡 **Nota importante**: Esta contraseña no solo servirá para iniciar sesión, sino que **se usará para derivar la clave que cifra y descifra tu historial localmente**. Si la pierdes o la cambias desde Supabase sin re-encriptar tus datos, no podrás leer las contraseñas antiguas.

## Paso 2: Crear la tabla e inyectar seguridad (RLS)

La base de datos arranca vacía, así que debemos crear la tabla donde se guardarán las contraseñas cifradas. Ya existe un archivo llamado `supabase_schema.sql` en la raíz del proyecto, pero aquí tienes los pasos para ejecutarlo en la plataforma:

1. Ve al apartado de **SQL Editor** en tu dashboard de Supabase (icono de código `</>`).
2. Crea una nueva consulta haciendo clic en **New Query**.
3. Pega el siguiente código en la pantalla negra:

```sql
-- Script para crear la tabla de historial de contraseñas en Supabase
CREATE TABLE IF NOT EXISTS public.password_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    label TEXT NOT NULL,
    kind TEXT NOT NULL,
    encrypted_value TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Habilitar Row Level Security (RLS)
ALTER TABLE public.password_history ENABLE ROW LEVEL SECURITY;

-- Crear politicas de seguridad para que cada usuario solo vea/modifique lo suyo
CREATE POLICY "Los usuarios pueden ver su propio historial"
    ON public.password_history FOR SELECT USING (auth.uid() = user_id);
    
CREATE POLICY "Los usuarios pueden insertar en su propio historial"
    ON public.password_history FOR INSERT WITH CHECK (auth.uid() = user_id);
    
CREATE POLICY "Los usuarios pueden eliminar su propio historial"
    ON public.password_history FOR DELETE USING (auth.uid() = user_id);
```

4. Haz clic en el botón verde **Run** (abajo a la derecha) para crear la tabla de contraseñas y activar las políticas de seguridad (Row Level Security).

---

Con esto listo, ya podrás ir a la página, usar el correo y contraseña que creaste, generar nuevas contraseñas y comprobar cómo se sincronizan automáticamente entre sesiones y en GitHub Pages de forma segura (encriptadas).
