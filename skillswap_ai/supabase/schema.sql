-- Enable pgvector extension
create extension if not exists vector;

-- Create Profiles Table
create table public.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  full_name text not null,
  bio text,
  location text,
  avatar_url text,
  rating numeric(3,2) default 0.0,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- RLS for Profiles
alter table public.profiles enable row level security;
create policy "Public profiles are viewable by everyone." on public.profiles for select using (true);
create policy "Users can insert their own profile." on public.profiles for insert with check (auth.uid() = id);
create policy "Users can update own profile." on public.profiles for update using (auth.uid() = id);

-- Create Skills Table
create table public.skills (
  id uuid default gen_random_uuid() primary key,
  name text not null unique,
  category text,
  embedding vector(384) -- for all-MiniLM-L6-v2
);

-- Create User Teaching Skills
create table public.user_skills_teach (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  skill_id uuid references public.skills(id) on delete cascade not null,
  proficiency_level text, -- Beginner, Intermediate, Advanced, Expert
  unique(user_id, skill_id)
);

-- Create User Learning Skills
create table public.user_skills_learn (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  skill_id uuid references public.skills(id) on delete cascade not null,
  unique(user_id, skill_id)
);

-- Create Availability Table
create table public.availability (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null unique,
  days text[] not null, -- Array of days e.g., ['Mon', 'Wed']
  preferred_duration text not null -- e.g. '60 min'
);

-- Trigger to automatically create a profile when a new user signs up via Supabase Auth
create or replace function public.handle_new_user() 
returns trigger as $$
begin
  insert into public.profiles (id, full_name, avatar_url)
  values (new.id, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'avatar_url');
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
