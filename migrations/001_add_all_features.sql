-- Migration: Add all new feature columns to incidents table
-- Run this in Supabase SQL Editor AFTER all code changes are deployed

-- ============================================
-- STEP 1: Extend incidents table
-- ============================================
ALTER TABLE public.incidents ADD COLUMN IF NOT EXISTS severity_score double precision DEFAULT 0.0;
ALTER TABLE public.incidents ADD COLUMN IF NOT EXISTS original_message text DEFAULT '';
ALTER TABLE public.incidents ADD COLUMN IF NOT EXISTS translated_message text DEFAULT '';
ALTER TABLE public.incidents ADD COLUMN IF NOT EXISTS detected_language varchar(10) DEFAULT 'en';
ALTER TABLE public.incidents ADD COLUMN IF NOT EXISTS emergency_type varchar(40) DEFAULT 'general';
ALTER TABLE public.incidents ADD COLUMN IF NOT EXISTS agency varchar(30) DEFAULT 'police';
ALTER TABLE public.incidents ADD COLUMN IF NOT EXISTS audio_url text DEFAULT '';
ALTER TABLE public.incidents ADD COLUMN IF NOT EXISTS video_url text DEFAULT '';
ALTER TABLE public.incidents ADD COLUMN IF NOT EXISTS voice_transcript text DEFAULT '';
ALTER TABLE public.incidents ADD COLUMN IF NOT EXISTS user_name text DEFAULT '';
ALTER TABLE public.incidents ADD COLUMN IF NOT EXISTS user_phone text DEFAULT '';
ALTER TABLE public.incidents ADD COLUMN IF NOT EXISTS emergency_contact_name text DEFAULT '';
ALTER TABLE public.incidents ADD COLUMN IF NOT EXISTS emergency_contact_phone text DEFAULT '';
ALTER TABLE public.incidents ADD COLUMN IF NOT EXISTS blood_group varchar(10) DEFAULT '';
ALTER TABLE public.incidents ADD COLUMN IF NOT EXISTS medical_conditions text DEFAULT '';

-- ============================================
-- STEP 2: Create user_profiles table
-- ============================================
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    device_id TEXT UNIQUE,
    full_name TEXT NOT NULL DEFAULT '',
    phone TEXT DEFAULT '',
    emergency_contact_name TEXT DEFAULT '',
    emergency_contact_phone TEXT DEFAULT '',
    blood_group VARCHAR(10) DEFAULT '',
    medical_conditions TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profiles_all" ON public.user_profiles
    FOR ALL USING (true) WITH CHECK (true);

-- ============================================
-- STEP 3: Risk zones view (for heatmap)
-- ============================================
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

-- ============================================
-- STEP 4: Storage bucket for audio/video uploads
-- ============================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('sos-media', 'sos-media', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Allow public uploads" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'sos-media');

CREATE POLICY "Allow public reads" ON storage.objects
    FOR SELECT USING (bucket_id = 'sos-media');

-- ============================================
-- DONE! Reload schema cache in Settings → API
-- ============================================
