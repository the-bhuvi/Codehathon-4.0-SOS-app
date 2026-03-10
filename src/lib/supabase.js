import { createClient } from '@supabase/supabase-js';

const isUrlValid = (url) => {
    try {
        new URL(url);
        return true;
    } catch (e) {
        return false;
    }
};

const envUrl = import.meta.env.VITE_SUPABASE_URL;
const envKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

const supabaseUrl = isUrlValid(envUrl) ? envUrl : 'https://placeholder.supabase.co';
const supabaseAnonKey = envKey && envKey !== 'your_supabase_anon_key' ? envKey : 'placeholder-key';

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
