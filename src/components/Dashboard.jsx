import React, { useState, useEffect, useRef, useCallback } from 'react';
import { supabase } from '../lib/supabase';
import MapView from './Map';
import IncidentList from './IncidentList';
import { ShieldAlert, Flame, Siren, Activity, Filter } from 'lucide-react';

const AGENCY_LABELS = {
    all: 'All Agencies',
    police: '🚔 Police',
    ambulance: '🚑 Ambulance',
    fire_dept: '🚒 Fire Dept',
};

const Dashboard = () => {
    const [incidents, setIncidents] = useState([]);
    const [activeIncident, setActiveIncident] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [agencyFilter, setAgencyFilter] = useState('all');
    const [showHeatmap, setShowHeatmap] = useState(false);
    const [viewTab, setViewTab] = useState('active');

    const activeIncidentRef = useRef(activeIncident);
    useEffect(() => { activeIncidentRef.current = activeIncident; }, [activeIncident]);

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

        const channel = supabase
            .channel('sos-incidents-realtime')
            .on('postgres_changes', { event: '*', schema: 'public', table: 'incidents' }, payload => {
                if (payload.eventType === 'INSERT') {
                    fetchIncidents();
                } else if (payload.eventType === 'UPDATE') {
                    setIncidents(current => current.map(inc => inc.id === payload.new.id ? payload.new : inc));
                    const current = activeIncidentRef.current;
                    if (current && current.id === payload.new.id) setActiveIncident(payload.new);
                } else if (payload.eventType === 'DELETE') {
                    setIncidents(current => current.filter(inc => inc.id !== payload.old.id));
                    const current = activeIncidentRef.current;
                    if (current && current.id === payload.old.id) setActiveIncident(null);
                }
            })
            .subscribe();

        const pollInterval = setInterval(() => fetchIncidents(), 15000);
        return () => { supabase.removeChannel(channel); clearInterval(pollInterval); };
    }, [fetchIncidents]);

    const handleResolve = async (id) => {
        try {
            setIncidents(current => current.map(inc =>
                inc.id === id ? { ...inc, status: 'resolved' } : inc
            ));

            const isUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id);
            if (!isUUID) return;

            const { error } = await supabase
                .from('incidents')
                .update({ status: 'resolved' })
                .eq('id', id);

            if (error) console.warn('Could not update in DB:', error);
        } catch (err) {
            console.error('Attempt to resolve failed', err);
        }
    };

    // Apply agency filter
    const agencyFiltered = agencyFilter === 'all'
        ? incidents
        : incidents.filter(inc => (inc.agency || 'police') === agencyFilter);

    // Apply active/history tab filter
    const filteredIncidents = viewTab === 'active'
        ? agencyFiltered.filter(inc => inc.status !== 'resolved')
        : agencyFiltered.filter(inc => inc.status === 'resolved');

    // Stats
    const stats = {
        total: incidents.length,
        active: incidents.filter(i => i.status !== 'resolved').length,
        resolved: incidents.filter(i => i.status === 'resolved').length,
        high: incidents.filter(i => i.severity === 'HIGH' && i.status === 'active').length,
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

                    {/* Stats bar */}
                    <div className="stats-bar">
                        <div className="stat-item">
                            <span className="stat-value">{stats.total}</span>
                            <span className="stat-label">Total</span>
                        </div>
                        <div className="stat-item stat-active">
                            <span className="stat-value">{stats.active}</span>
                            <span className="stat-label">Active</span>
                        </div>
                        <div className="stat-item stat-high">
                            <span className="stat-value">{stats.high}</span>
                            <span className="stat-label">Critical</span>
                        </div>
                    </div>

                    {/* Agency filter */}
                    <div className="filter-bar">
                        {Object.entries(AGENCY_LABELS).map(([key, label]) => (
                            <button
                                key={key}
                                className={`filter-btn ${agencyFilter === key ? 'active' : ''}`}
                                onClick={() => setAgencyFilter(key)}
                            >
                                {label}
                            </button>
                        ))}
                    </div>

                    {/* Heatmap toggle */}
                    <label className="heatmap-toggle">
                        <input type="checkbox" checked={showHeatmap} onChange={(e) => setShowHeatmap(e.target.checked)} />
                        <span>🔥 Show Risk Zone Heatmap</span>
                    </label>

                    {/* Active / History tabs */}
                    <div className="view-tabs">
                        <button
                            className={`view-tab ${viewTab === 'active' ? 'active' : ''}`}
                            onClick={() => setViewTab('active')}>
                            <Siren size={14} /> Active ({stats.active})
                        </button>
                        <button
                            className={`view-tab ${viewTab === 'history' ? 'active' : ''}`}
                            onClick={() => setViewTab('history')}>
                            <Activity size={14} /> History ({stats.resolved})
                        </button>
                    </div>
                </div>

                <IncidentList
                    incidents={filteredIncidents}
                    activeIncident={activeIncident}
                    setActiveIncident={setActiveIncident}
                    onResolve={handleResolve}
                />
            </div>

            <div className="map-container">
                <MapView
                    incidents={filteredIncidents}
                    activeIncident={activeIncident}
                    setActiveIncident={setActiveIncident}
                    onResolve={handleResolve}
                    showHeatmap={showHeatmap}
                />
            </div>
        </div>
    );
};

export default Dashboard;

function getMockIncidents() {
    return [
        {
            id: 'mock-0001-0000-0000-000000000001', lat: 28.6139, lng: 77.2090,
            severity: 'HIGH', message: 'Fire reported in residential building.', status: 'active',
            emergency_type: 'fire', agency: 'fire_dept', detected_language: 'en',
            user_name: 'Rahul Kumar', severity_score: 0.92,
            created_at: new Date(Date.now() - 1000 * 60 * 5).toISOString()
        },
        {
            id: 'mock-0002-0000-0000-000000000002', lat: 28.6448, lng: 77.2167,
            severity: 'MEDIUM', message: 'Road accident, person injured.', status: 'active',
            emergency_type: 'accident', agency: 'ambulance', detected_language: 'en',
            user_name: 'Priya Singh', severity_score: 0.75,
            created_at: new Date(Date.now() - 1000 * 60 * 15).toISOString()
        },
        {
            id: 'mock-0003-0000-0000-000000000003', lat: 28.5672, lng: 77.2100,
            severity: 'LOW', message: 'Feeling unsafe, someone following.', status: 'active',
            emergency_type: 'following', agency: 'police', detected_language: 'en',
            user_name: 'Anita Sharma', severity_score: 0.45,
            created_at: new Date(Date.now() - 1000 * 60 * 60).toISOString()
        },
        {
            id: 'mock-0004-0000-0000-000000000004', lat: 28.6329, lng: 77.2195,
            severity: 'HIGH', message: 'Robbery in progress, need police.', status: 'resolved',
            emergency_type: 'robbery', agency: 'police', detected_language: 'hi',
            original_message: 'डकैती हो रही है, पुलिस भेजो',
            user_name: 'Vikram Patel', severity_score: 0.88,
            created_at: new Date(Date.now() - 1000 * 60 * 120).toISOString()
        }
    ];
}
