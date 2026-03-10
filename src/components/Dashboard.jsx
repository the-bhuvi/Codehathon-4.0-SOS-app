import React, { useState, useEffect, useRef, useCallback } from 'react';
import { supabase } from '../lib/supabase';
import MapView from './Map';
import IncidentList from './IncidentList';
import { ShieldAlert } from 'lucide-react';

const Dashboard = () => {
    const [incidents, setIncidents] = useState([]);
    const [activeIncident, setActiveIncident] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    // Keep a ref to activeIncident so realtime callbacks always see the latest value
    const activeIncidentRef = useRef(activeIncident);
    useEffect(() => {
        activeIncidentRef.current = activeIncident;
    }, [activeIncident]);

    const fetchIncidents = useCallback(async (showLoader = false) => {
        try {
            if (showLoader) setLoading(true);
            const { data, error: fetchError } = await supabase
                .from('incidents')
                .select('*')
                .order('created_at', { ascending: false });

            if (fetchError) throw fetchError;

            setIncidents(data || []);
            setError(null);
        } catch (err) {
            console.error('Error fetching incidents:', err);
            setError('Could not connect to database. Showing demo data.');
            setIncidents(getMockIncidents());
        } finally {
            if (showLoader) setLoading(false);
        }
    }, []);

    useEffect(() => {
        fetchIncidents(true);

        // Subscribe to realtime changes
        const channel = supabase
            .channel('sos-incidents-realtime')
            .on('postgres_changes', { event: '*', schema: 'public', table: 'incidents' }, payload => {
                if (payload.eventType === 'INSERT') {
                    // Do a full re-fetch to guarantee we have the latest data
                    fetchIncidents();
                } else if (payload.eventType === 'UPDATE') {
                    setIncidents(current => current.map(inc => inc.id === payload.new.id ? payload.new : inc));
                    const current = activeIncidentRef.current;
                    if (current && current.id === payload.new.id) {
                        setActiveIncident(payload.new);
                    }
                } else if (payload.eventType === 'DELETE') {
                    setIncidents(current => current.filter(inc => inc.id !== payload.old.id));
                    const current = activeIncidentRef.current;
                    if (current && current.id === payload.old.id) {
                        setActiveIncident(null);
                    }
                }
            })
            .subscribe();

        // Polling fallback: re-fetch every 15 seconds in case realtime events are missed
        const pollInterval = setInterval(() => fetchIncidents(), 15000);

        return () => {
            supabase.removeChannel(channel);
            clearInterval(pollInterval);
        };
    }, [fetchIncidents]);



    const handleResolve = async (id) => {
        try {
            // Optimistic update
            setIncidents(current => current.map(inc =>
                inc.id === id ? { ...inc, status: 'resolved' } : inc
            ));

            // Skip DB call for mock incidents (they don't have real UUID ids)
            const isUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id);
            if (!isUUID) return;

            const { error } = await supabase
                .from('incidents')
                .update({ status: 'resolved' })
                .eq('id', id);

            if (error) {
                console.warn('Could not update in DB:', error);
            }
        } catch (err) {
            console.error('Attempt to resolve failed', err);
        }
    };

    if (loading) {
        return (
            <div className="loading-container">
                <div className="loader"></div>
                <h2>Initializing SOS Dashboard...</h2>
            </div>
        );
    }

    return (
        <div className="dashboard-container">
            <div className="sidebar">
                <div className="sidebar-header">
                    <h1><ShieldAlert size={28} /> SOS Command Center</h1>
                    <p>Real-time emergency monitoring</p>
                    {error && <p style={{ color: 'var(--severity-high)', marginTop: '8px', fontSize: '12px' }}>{error}</p>}
                </div>

                <IncidentList
                    incidents={incidents}
                    activeIncident={activeIncident}
                    setActiveIncident={setActiveIncident}
                    onResolve={handleResolve}
                />
            </div>

            <div className="map-container">
                <MapView
                    incidents={incidents}
                    activeIncident={activeIncident}
                    setActiveIncident={setActiveIncident}
                    onResolve={handleResolve}
                />
            </div>
        </div>
    );
};

export default Dashboard;

// Helper to provide demo data when DB connection is not configured yet
function getMockIncidents() {
    return [
        {
            id: 'mock-0001-0000-0000-000000000001',
            lat: 40.7128,
            lng: -74.0060,
            severity: 'HIGH',
            message: 'Medical emergency at Central Park. Need ambulance immediately.',
            status: 'active',
            created_at: new Date(Date.now() - 1000 * 60 * 5).toISOString()
        },
        {
            id: 'mock-0002-0000-0000-000000000002',
            lat: 40.7580,
            lng: -73.9855,
            severity: 'MEDIUM',
            message: 'Suspicious activity reported near Times Square station.',
            status: 'active',
            created_at: new Date(Date.now() - 1000 * 60 * 15).toISOString()
        },
        {
            id: 'mock-0003-0000-0000-000000000003',
            lat: 40.7829,
            lng: -73.9654,
            severity: 'LOW',
            message: 'Noise complaint, possible minor dispute.',
            status: 'resolved',
            created_at: new Date(Date.now() - 1000 * 60 * 60 * 2).toISOString()
        },
        {
            id: 'mock-0004-0000-0000-000000000004',
            lat: 40.7306,
            lng: -73.9352,
            severity: 'HIGH',
            message: 'Fire reported in residential building. Evacuation in progress.',
            status: 'active',
            created_at: new Date(Date.now() - 1000 * 60).toISOString()
        }
    ];
}
