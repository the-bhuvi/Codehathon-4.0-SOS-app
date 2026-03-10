-- Run this in your Supabase SQL Editor (SQL Query Runner)

-- 1. Create the incidents table (extended with all feature columns)
CREATE TABLE IF NOT EXISTS public.incidents (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    lat DOUBLE PRECISION NOT NULL,
    lng DOUBLE PRECISION NOT NULL,
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('HIGH', 'MEDIUM', 'LOW')),
    severity_score DOUBLE PRECISION DEFAULT 0.0,
    message TEXT NOT NULL DEFAULT '',
    original_message TEXT DEFAULT '',
    translated_message TEXT DEFAULT '',
    detected_language VARCHAR(10) DEFAULT 'en',
    emergency_type VARCHAR(40) DEFAULT 'general',
    agency VARCHAR(30) DEFAULT 'police',
    audio_url TEXT DEFAULT '',
    video_url TEXT DEFAULT '',
    voice_transcript TEXT DEFAULT '',
    user_name TEXT DEFAULT '',
    user_phone TEXT DEFAULT '',
    emergency_contact_name TEXT DEFAULT '',
    emergency_contact_phone TEXT DEFAULT '',
    blood_group VARCHAR(10) DEFAULT '',
    medical_conditions TEXT DEFAULT '',
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'resolved')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Create user_profiles table for emergency profile data
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    device_id TEXT UNIQUE,
    full_name TEXT NOT NULL DEFAULT '',
    phone TEXT DEFAULT '',
    emergency_contact_name TEXT DEFAULT '',
    emergency_contact_phone TEXT DEFAULT '',
    blood_group VARCHAR(10) DEFAULT '',
    medical_conditions TEXT DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Turn on Row Level Security (RLS)
ALTER TABLE public.incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- 4. RLS policies for incidents
CREATE POLICY "Allow anonymous select" ON public.incidents
    FOR SELECT USING (true);

CREATE POLICY "Allow anonymous insert" ON public.incidents
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow anonymous update" ON public.incidents
    FOR UPDATE USING (true) WITH CHECK (true);

CREATE POLICY "Allow anonymous delete" ON public.incidents
    FOR DELETE USING (true);

-- 5. RLS policies for user_profiles
CREATE POLICY "Allow anonymous select profiles" ON public.user_profiles
    FOR SELECT USING (true);

CREATE POLICY "Allow anonymous insert profiles" ON public.user_profiles
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow anonymous update profiles" ON public.user_profiles
    FOR UPDATE USING (true) WITH CHECK (true);

-- 6. Create a view for risk zone aggregation (clusters of incidents)
CREATE OR REPLACE VIEW public.risk_zones AS
SELECT
    ROUND(lat::numeric, 3) AS zone_lat,
    ROUND(lng::numeric, 3) AS zone_lng,
    COUNT(*) AS incident_count,
    COUNT(*) FILTER (WHERE severity = 'HIGH') AS high_count,
    COUNT(*) FILTER (WHERE severity = 'MEDIUM') AS medium_count,
    COUNT(*) FILTER (WHERE status = 'active') AS active_count,
    MAX(created_at) AS latest_incident
FROM public.incidents
GROUP BY ROUND(lat::numeric, 3), ROUND(lng::numeric, 3)
HAVING COUNT(*) >= 2;

-- 7. Enable Realtime on the table
-- Go to Database -> Replication -> Toggle 'incidents' on.
alter publication supabase_realtime add table public.incidents;

-- 8. Create storage bucket for SOS media (audio recordings, photos)
-- Run this in the Supabase SQL editor:
INSERT INTO storage.buckets (id, name, public) VALUES ('sos-media', 'sos-media', true)
ON CONFLICT (id) DO NOTHING;

-- Allow public read access to sos-media bucket
CREATE POLICY "Public read access" ON storage.objects FOR SELECT
USING (bucket_id = 'sos-media');

-- Allow anonymous uploads to sos-media bucket
CREATE POLICY "Allow anonymous uploads" ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'sos-media');
