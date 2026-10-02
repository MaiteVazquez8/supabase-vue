--Crear la tabla productos en Supabase
--En Supabase, abrir SQL Editor, crear una consulta nueva, pegar el siguiente script y ejecutarlo.
create table public.productos (
    id uuid primary key default gen_random_uuid(),
    usuario_id uuid not null default auth.uid()
    references auth.users(id) on delete cascade,
    nombre text not null,
    descripcion text,
    precio numeric(12, 2) not null check (precio >= 0),
    stock integer not null default 0 check (stock >= 0),
    activo boolean not null default true,
    creado_en timestamptz not null default now()
);

alter table public.productos enable row level security;
grant select, insert, update, delete
on table public.productos
to authenticated;

-- Crear las políticas RLS (SQL — políticas de seguridad)
create policy "Usuarios leen sus productos"
on public.productos
for select
to authenticated
using ((select auth.uid()) = usuario_id);

create policy "Usuarios crean sus productos"
on public.productos
for insert
to authenticated
with check ((select auth.uid()) = usuario_id);

create policy "Usuarios modifican sus productos"
on public.productos
for update
to authenticated
using ((select auth.uid()) = usuario_id)
with check ((select auth.uid()) = usuario_id);

create policy "Usuarios eliminan sus productos"
on public.productos
for delete
to authenticated
using ((select auth.uid()) = usuario_id);

-- Preparar las imágenes: Agregar las columnas de imagen (SQL — columnas para URL y ruta)
alter table public.productos
add column if not exists imagen_url text;
alter table public.productos
add column if not exists imagen_ruta text;

-- Crear el bucket productos (SQL — bucket público de hasta 5 MB)
insert into storage.buckets (
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
)
values (
    'productos',
    'productos',
    true,
    5242880,
    array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = true,
file_size_limit = 5242880,
allowed_mime_types = array[
    'image/jpeg',
    'image/png',
    'image/webp'
];
--El bucket es público para que la etiqueta <img> pueda cargar las fotografías mediante URL.
--Esto no da permiso para subir o borrar archivos: esas operaciones siguen protegidas por las políticas de Storage.

--Políticas de Storage (SQL — acceso por propietario)
create policy "Usuarios suben imagenes de productos"
on storage.objects
for insert
to authenticated
with check (
    bucket_id = 'productos'
    and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Usuarios ven sus imagenes de productos"
on storage.objects
for select
to authenticated
using (
    bucket_id = 'productos'
    and owner_id = auth.uid()::text
);

create policy "Usuarios eliminan sus imagenes de productos"
on storage.objects
for delete
to authenticated
using (
    bucket_id = 'productos'
    and owner_id = auth.uid()::text
);