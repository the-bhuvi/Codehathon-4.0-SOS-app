-- Run this in your Supabase SQL Editor (SQL Query Runner)

-- 1. Create the incidents table
CREATE TABLE IF NOT EXISTS public.incidents (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    lat DOUBLE PRECISION NOT NULL,
    lng DOUBLE PRECISION NOT NULL,
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('HIGH', 'MEDIUM', 'LOW')),
    message TEXT NOT NULL DEFAULT '',
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'resolved')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Turn on Row Level Security (RLS)
ALTER TABLE public.incidents ENABLE ROW LEVEL SECURITY;

-- 3. Create a policy that allows anonymous read access (so the frontend works without auth)
CREATE POLICY "Allow anonymous select" ON public.incidents
    FOR SELECT USING (true);

-- 4. Create a policy that allows anonymous inserts (allow the frontend to post new SOS reports)
CREATE POLICY "Allow anonymous insert" ON public.incidents
    FOR INSERT WITH CHECK (true);

-- 5. Create a policy that allows updates on existing rows (to allow 'Resolving')
CREATE POLICY "Allow anonymous update" ON public.incidents
    FOR UPDATE USING (true) WITH CHECK (true);

-- 6. Enable Realtime on the table! (CRITICAL STEP FOR LIVE DASHBOARD!) 
-- Go to Database -> Replication -> Click 'Source' for supabase_realtime -> Toggle 'incidents' on.
-- Or run this command:
alter publication supabase_realtime add table public.incidents;
