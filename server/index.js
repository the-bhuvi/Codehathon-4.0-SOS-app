require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { createClient } = require('@supabase/supabase-js');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// Initialize Supabase Client
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY; // Use Service Role Key for backend bypass of RLS policies
const supabase = createClient(supabaseUrl, supabaseKey);

// --------------------------------------------------------------------------
// API ENDPOINTS
// --------------------------------------------------------------------------

// Health Check
app.get('/api/health', (req, res) => {
    res.status(200).json({ status: 'OK', message: 'SOS Backend acts as intermediate server layer' });
});

// Create a new SOS Incident via API (Useful if integrating hardware IoT buttons or external mobile apps)
app.post('/api/incidents', async (req, res) => {
    try {
        const { lat, lng, severity, message } = req.body;

        // Basic validation
        if (!lat || !lng || !severity) {
            return res.status(400).json({ error: 'Latitude, longitude, and severity are required fields.' });
        }

        const newIncident = {
            lat,
            lng,
            severity: severity.toUpperCase(),
            message: message || '',
            status: 'active'
        };

        const { data, error } = await supabase
            .from('incidents')
            .insert([newIncident])
            .select();

        if (error) throw error;

        // Optional: Add logic to trigger SMS alerts via Twilio, push notifications, or email here!

        res.status(201).json({ success: true, incident: data[0] });

    } catch (err) {
        console.error('Error creating incident:', err.message);
        res.status(500).json({ error: 'Failed to create emergency incident.' });
    }
});

// Custom endpoint to resolve an incident requiring complex backend validation
app.patch('/api/incidents/:id/resolve', async (req, res) => {
    try {
        const { id } = req.params;

        // Add any complex logic here (e.g., verifying user permissions, logging resolution time)

        const { data, error } = await supabase
            .from('incidents')
            .update({ status: 'resolved' })
            .eq('id', id)
            .select();

        if (error) throw error;

        res.status(200).json({ success: true, updated: data[0] });
    } catch (err) {
        console.error('Error resolving incident:', err.message);
        res.status(500).json({ error: 'Failed to resolve emergency.' });
    }
});

app.listen(PORT, () => {
    console.log(`🚀 SOS Backend API running on port ${PORT}`);
});
