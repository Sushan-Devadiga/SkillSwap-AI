-- ==============================================================================
-- SkillSwap AI Complete Database Migration Script
-- This script is non-destructive. It adds missing columns, consolidates skills,
-- creates missing tables, and sets up robust Row Level Security (RLS).
-- ==============================================================================

-- 1. PROFILES: Safe alteration to add missing fields
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS username text UNIQUE,
  ADD COLUMN IF NOT EXISTS bio text,
  ADD COLUMN IF NOT EXISTS location text,
  ADD COLUMN IF NOT EXISTS timezone text,
  ADD COLUMN IF NOT EXISTS experience_level text,
  ADD COLUMN IF NOT EXISTS learning_goals text[],
  ADD COLUMN IF NOT EXISTS availability text,
  ADD COLUMN IF NOT EXISTS fcm_token text,
  ADD COLUMN IF NOT EXISTS updated_at timestamp with time zone default timezone('utc'::text, now());

-- 2. SKILLS: Safe alteration
ALTER TABLE public.skills
  ADD COLUMN IF NOT EXISTS category text,
  ADD COLUMN IF NOT EXISTS description text,
  ADD COLUMN IF NOT EXISTS created_at timestamp with time zone default timezone('utc'::text, now());

-- 3. USER_SKILLS: Consolidation
CREATE TABLE IF NOT EXISTS public.user_skills (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  skill_id uuid references public.skills(id) on delete cascade not null,
  type text check (type in ('TEACH', 'LEARN')) not null,
  proficiency_level text check (proficiency_level in ('Beginner', 'Intermediate', 'Advanced', 'Expert')),
  created_at timestamp with time zone default timezone('utc'::text, now()),
  unique(user_id, skill_id, type)
);

-- Migrate existing split tables into unified table (safe operation)
INSERT INTO public.user_skills (user_id, skill_id, type)
SELECT user_id, skill_id, 'TEACH' FROM public.user_skills_teach
ON CONFLICT DO NOTHING;

INSERT INTO public.user_skills (user_id, skill_id, type)
SELECT user_id, skill_id, 'LEARN' FROM public.user_skills_learn
ON CONFLICT DO NOTHING;

-- Note: We will keep user_skills_teach and user_skills_learn for now 
-- until the backend RPC is updated to use the unified table.

-- 4. MATCHES
CREATE TABLE IF NOT EXISTS public.matches (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  matched_user_id uuid references public.profiles(id) on delete cascade not null,
  teach_skill_id uuid references public.skills(id) on delete cascade,
  learn_skill_id uuid references public.skills(id) on delete cascade,
  score float not null,
  created_at timestamp with time zone default timezone('utc'::text, now()),
  unique(user_id, matched_user_id)
);

-- 5. CONNECTIONS
CREATE TABLE IF NOT EXISTS public.connections (
  id uuid default gen_random_uuid() primary key,
  requester_id uuid references public.profiles(id) on delete cascade not null,
  receiver_id uuid references public.profiles(id) on delete cascade not null,
  status text check (status in ('pending', 'accepted', 'declined', 'cancelled')) default 'pending',
  created_at timestamp with time zone default timezone('utc'::text, now()),
  updated_at timestamp with time zone default timezone('utc'::text, now()),
  check (requester_id != receiver_id)
);

CREATE UNIQUE INDEX IF NOT EXISTS connections_unique_idx ON public.connections (least(requester_id, receiver_id), greatest(requester_id, receiver_id));

-- 6. CONVERSATIONS
CREATE TABLE IF NOT EXISTS public.conversations (
  id uuid default gen_random_uuid() primary key,
  participant1_id uuid references public.profiles(id) on delete cascade not null,
  participant2_id uuid references public.profiles(id) on delete cascade not null,
  created_at timestamp with time zone default timezone('utc'::text, now()),
  updated_at timestamp with time zone default timezone('utc'::text, now()),
  check (participant1_id != participant2_id)
);

CREATE UNIQUE INDEX IF NOT EXISTS conversations_unique_idx ON public.conversations (least(participant1_id, participant2_id), greatest(participant1_id, participant2_id));

-- 7. MESSAGES
CREATE TABLE IF NOT EXISTS public.messages (
  id uuid default gen_random_uuid() primary key,
  conversation_id uuid references public.conversations(id) on delete cascade not null,
  sender_id uuid references public.profiles(id) on delete cascade not null,
  content text not null,
  read_at timestamp with time zone,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

-- 8. NOTIFICATIONS
CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  type text check (type in ('connection_request', 'connection_accepted', 'new_message', 'session_invitation', 'session_reminder', 'match_recommendation')) not null,
  content text not null,
  related_entity_id uuid,
  is_read boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

-- 9. SESSIONS
CREATE TABLE IF NOT EXISTS public.sessions (
  id uuid default gen_random_uuid() primary key,
  organizer_id uuid references public.profiles(id) on delete cascade not null,
  skill_id uuid references public.skills(id) on delete set null,
  title text not null,
  description text,
  scheduled_time timestamp with time zone not null,
  duration_minutes int not null,
  meeting_link text,
  status text check (status in ('scheduled', 'in_progress', 'completed', 'cancelled')) default 'scheduled',
  created_at timestamp with time zone default timezone('utc'::text, now()),
  updated_at timestamp with time zone default timezone('utc'::text, now())
);

-- 10. SESSION_PARTICIPANTS
CREATE TABLE IF NOT EXISTS public.session_participants (
  session_id uuid references public.sessions(id) on delete cascade not null,
  participant_id uuid references public.profiles(id) on delete cascade not null,
  joined_at timestamp with time zone,
  primary key (session_id, participant_id)
);

-- 11. EXCHANGE_HISTORY
CREATE TABLE IF NOT EXISTS public.exchange_history (
  id uuid default gen_random_uuid() primary key,
  session_id uuid references public.sessions(id) on delete set null,
  provider_id uuid references public.profiles(id) on delete cascade not null,
  receiver_id uuid references public.profiles(id) on delete cascade not null,
  skill_id uuid references public.skills(id) on delete set null,
  hours_exchanged numeric(5,2) not null,
  feedback text,
  rating int check (rating >= 1 and rating <= 5),
  created_at timestamp with time zone default timezone('utc'::text, now())
);

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS) SETUP
-- ==============================================================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.session_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exchange_history ENABLE ROW LEVEL SECURITY;

-- 1. Profiles: Anyone can read, only owner can update
DROP POLICY IF EXISTS "Profiles are viewable by everyone." ON profiles;
CREATE POLICY "Profiles are viewable by everyone." 
  ON profiles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert their own profile." ON profiles;
CREATE POLICY "Users can insert their own profile." 
  ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile." ON profiles;
CREATE POLICY "Users can update own profile." 
  ON profiles FOR UPDATE USING (auth.uid() = id);

-- 2. Skills: Anyone can read, anyone authenticated can insert new skills
DROP POLICY IF EXISTS "Skills are viewable by everyone." ON skills;
CREATE POLICY "Skills are viewable by everyone." 
  ON skills FOR SELECT USING (true);

DROP POLICY IF EXISTS "Authenticated users can create skills." ON skills;
CREATE POLICY "Authenticated users can create skills." 
  ON skills FOR INSERT TO authenticated WITH CHECK (true);

-- 3. User Skills: Anyone can read, owner can modify
DROP POLICY IF EXISTS "User skills are viewable by everyone." ON user_skills;
CREATE POLICY "User skills are viewable by everyone." 
  ON user_skills FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can manage their own skills." ON user_skills;
CREATE POLICY "Users can manage their own skills." 
  ON user_skills FOR ALL USING (auth.uid() = user_id);

-- 4. Matches: Owner can view their own matches
DROP POLICY IF EXISTS "Users can view their own matches." ON matches;
CREATE POLICY "Users can view their own matches." 
  ON matches FOR SELECT USING (auth.uid() = user_id);

-- 5. Connections: Viewable by requester or receiver. Modifiable by parties involved.
DROP POLICY IF EXISTS "Users can view their connections." ON connections;
CREATE POLICY "Users can view their connections." 
  ON connections FOR SELECT USING (auth.uid() = requester_id OR auth.uid() = receiver_id);

DROP POLICY IF EXISTS "Users can insert connections." ON connections;
CREATE POLICY "Users can insert connections." 
  ON connections FOR INSERT WITH CHECK (auth.uid() = requester_id);

DROP POLICY IF EXISTS "Users can update their connections." ON connections;
CREATE POLICY "Users can update their connections." 
  ON connections FOR UPDATE USING (auth.uid() = requester_id OR auth.uid() = receiver_id);

-- 6. Conversations: Viewable by participants
DROP POLICY IF EXISTS "Users can view their conversations." ON conversations;
CREATE POLICY "Users can view their conversations." 
  ON conversations FOR SELECT USING (auth.uid() = participant1_id OR auth.uid() = participant2_id);

DROP POLICY IF EXISTS "Users can create conversations." ON conversations;
CREATE POLICY "Users can create conversations." 
  ON conversations FOR INSERT WITH CHECK (auth.uid() = participant1_id OR auth.uid() = participant2_id);

-- 7. Messages: Viewable by participants of the conversation. Senders can insert.
DROP POLICY IF EXISTS "Users can view messages in their conversations." ON messages;
CREATE POLICY "Users can view messages in their conversations." 
  ON messages FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM conversations c 
      WHERE c.id = messages.conversation_id 
      AND (c.participant1_id = auth.uid() OR c.participant2_id = auth.uid())
    )
  );

DROP POLICY IF EXISTS "Users can insert messages." ON messages;
CREATE POLICY "Users can insert messages." 
  ON messages FOR INSERT WITH CHECK (auth.uid() = sender_id);

DROP POLICY IF EXISTS "Users can update message read status." ON messages;
CREATE POLICY "Users can update message read status." 
  ON messages FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM conversations c 
      WHERE c.id = messages.conversation_id 
      AND (c.participant1_id = auth.uid() OR c.participant2_id = auth.uid())
    )
  );

-- 8. Notifications: Owner only
DROP POLICY IF EXISTS "Users can manage their notifications." ON notifications;
CREATE POLICY "Users can manage their notifications." 
  ON notifications FOR ALL USING (auth.uid() = user_id);

-- Helper function to break infinite recursion between sessions and session_participants
CREATE OR REPLACE FUNCTION public.is_session_participant(check_session_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM session_participants 
    WHERE session_id = check_session_id 
    AND participant_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Sessions: Organizers and participants can view. Organizers can manage.
DROP POLICY IF EXISTS "Users can view their sessions." ON sessions;
CREATE POLICY "Users can view their sessions." 
  ON sessions FOR SELECT USING (
    auth.uid() = organizer_id OR 
    public.is_session_participant(id)
  );

DROP POLICY IF EXISTS "Organizers can manage their sessions." ON sessions;
CREATE POLICY "Organizers can manage their sessions." 
  ON sessions FOR ALL USING (auth.uid() = organizer_id);

-- 10. Session Participants: Viewable by session members. Participants can join/leave.
DROP POLICY IF EXISTS "Users can view participants of their sessions." ON session_participants;
CREATE POLICY "Users can view participants of their sessions." 
  ON session_participants FOR SELECT USING (
    public.is_session_participant(session_id) OR
    EXISTS (SELECT 1 FROM sessions WHERE id = session_id AND organizer_id = auth.uid())
  );

DROP POLICY IF EXISTS "Users can manage their participation." ON session_participants;
CREATE POLICY "Users can manage their participation." 
  ON session_participants FOR ALL USING (
    auth.uid() = participant_id OR
    EXISTS (SELECT 1 FROM sessions WHERE id = session_id AND organizer_id = auth.uid())
  );

-- 11. Exchange History: Viewable by provider or receiver
DROP POLICY IF EXISTS "Users can view their exchange history." ON exchange_history;
CREATE POLICY "Users can view their exchange history." 
  ON exchange_history FOR SELECT USING (auth.uid() = provider_id OR auth.uid() = receiver_id);

DROP POLICY IF EXISTS "Users can insert into exchange history." ON exchange_history;
CREATE POLICY "Users can insert into exchange history." 
  ON exchange_history FOR INSERT WITH CHECK (auth.uid() = provider_id OR auth.uid() = receiver_id);

-- ==============================================================================
-- UPDATE BACKEND RPC FUNCTION
-- ==============================================================================
-- We must update the existing match_users function to use the new unified 
-- user_skills table instead of user_skills_teach.

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
  join public.user_skills us on u.id = us.user_id
  join public.skills s on us.skill_id = s.id
  where us.type = 'TEACH' 
    and 1 - (s.embedding <=> query_embedding) > match_threshold
  order by s.embedding <=> query_embedding
  limit match_count;
$$;

-- ==============================================================================
-- 10. STORAGE CONFIGURATION
-- ==============================================================================

-- Create a bucket for avatars
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('avatars', 'avatars', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp'])
ON CONFLICT (id) DO UPDATE SET public = true;

-- Allow public read access
CREATE POLICY "Public Read Access"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

-- Allow authenticated users to upload files to their own folder
CREATE POLICY "Users can upload their own avatar"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Allow authenticated users to update their own avatar
CREATE POLICY "Users can update their own avatar"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Allow authenticated users to delete their own avatar
CREATE POLICY "Users can delete their own avatar"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);

-- ==============================================================================
-- 11. SESSION PLANS (Multi-Agent System)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.session_plans (
  id uuid default gen_random_uuid() primary key,
  match_id uuid references public.matches(id) on delete cascade,
  session_order int not null,
  title text not null,
  description text not null,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

ALTER TABLE public.session_plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view session plans for their matches"
  ON public.session_plans FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.matches m
      WHERE m.id = session_plans.match_id
      AND (m.user_id = auth.uid() OR m.matched_user_id = auth.uid())
    )
  );

CREATE POLICY "Users can insert session plans for their matches"
  ON public.session_plans FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.matches m
      WHERE m.id = match_id
      AND (m.user_id = auth.uid() OR m.matched_user_id = auth.uid())
    )
  );

-- ==============================================================================
-- 12. TIME TOKEN ECONOMY & LEDGER (1 Hour = 1 Token)
-- ==============================================================================

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS time_tokens int DEFAULT 3,
  ADD COLUMN IF NOT EXISTS learning_style text DEFAULT 'Visual';

CREATE TABLE IF NOT EXISTS public.token_transactions (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  amount int not null, -- positive for earned/bonus, negative for spent
  transaction_type text check (transaction_type in ('welcome_bonus', 'earned_teaching', 'spent_learning', 'swap_reward', 'adjustment')) not null,
  description text not null,
  session_id uuid references public.sessions(id) on delete set null,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

ALTER TABLE public.token_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own token transactions"
  ON public.token_transactions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own token transactions"
  ON public.token_transactions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- ==============================================================================
-- 13. BLOCKCHAIN-BACKED VERIFIED CREDENTIALS (BADGES)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.verified_credentials (
  id uuid default gen_random_uuid() primary key,
  learner_id uuid references public.profiles(id) on delete cascade not null,
  mentor_id uuid references public.profiles(id) on delete set null,
  session_id uuid references public.sessions(id) on delete set null,
  skill_name text not null,
  hours_completed numeric(4,1) default 1.0,
  verification_hash text not null, -- Cryptographic SHA-256 tamper-proof credential hash
  badge_tier text default 'Verified Novice' check (badge_tier in ('Verified Novice', 'Intermediate Practitioner', 'Advanced Specialist', 'Master Mentor')),
  metadata jsonb default '{}'::jsonb,
  issued_at timestamp with time zone default timezone('utc'::text, now())
);

ALTER TABLE public.verified_credentials ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view verified credentials"
  ON public.verified_credentials FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can create verified credentials"
  ON public.verified_credentials FOR INSERT
  WITH CHECK (auth.uid() = learner_id OR auth.uid() = mentor_id);

