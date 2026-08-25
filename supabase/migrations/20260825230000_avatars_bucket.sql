-- Bucket de Storage para fotos de perfil de agentes (Historia 1.2, "subida
-- de foto de perfil" — ver ARCHITECTURE.md §3: `AgentProfile.fotoPath`
-- guarda la RUTA dentro del bucket, nunca una URL completa, tal como ya
-- documenta `public.profiles.foto_path` en el schema inicial).
--
-- Convención de path: {agent_id}/foto.<ext> — el primer segmento del path
-- es el propio agent_id, así `storage.foldername(name)` alcanza para que
-- las policies garanticen "un agente solo sube/lee/reemplaza SU propia
-- foto", sin necesitar una tabla de metadatos aparte.
--
-- Privado (public = false): se sirve vía URL firmada / download autenticado
-- desde el cliente, nunca por URL pública directa.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', false, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

create policy avatars_select_own on storage.objects
  for select to authenticated
  using (bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]);

create policy avatars_insert_own on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]);

create policy avatars_update_own on storage.objects
  for update to authenticated
  using (bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1])
  with check (bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]);

create policy avatars_delete_own on storage.objects
  for delete to authenticated
  using (bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]);
