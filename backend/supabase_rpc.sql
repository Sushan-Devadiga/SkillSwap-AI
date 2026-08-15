create or replace function match_users (
  query_embedding vector(384),
  match_threshold float,
  match_count int
)
returns table (
  user_id uuid,
  full_name text,
  avatar_url text,
  skill_name text,
  similarity float
)
language sql stable
as $$
  select
    u.id as user_id,
    u.full_name,
    u.avatar_url,
    s.name as skill_name,
    1 - (s.embedding <=> query_embedding) as similarity
  from public.profiles u
  join public.user_skills_teach ust on u.id = ust.user_id
  join public.skills s on ust.skill_id = s.id
  where 1 - (s.embedding <=> query_embedding) > match_threshold
  order by s.embedding <=> query_embedding
  limit match_count;
$$;
