import React, { useState, useEffect, useRef, useCallback } from 'react';
import { supabase } from '../lib/supabase';
import MapView from './Map';
import IncidentList from './IncidentList';
import TopBar from './TopBar';
import BottomBar from './BottomBar';
import RightPanel from './RightPanel';

const AGENCY_LABELS = {
    all: 'All',
    police: '🚔 Police',
    ambulance: '🚑 Ambulance',
    fire_dept: '🚒 Fire',
};

const Dashboard = () => {
    const [incidents, setIncidents] = useState([]);
    const [activeIncident, setActiveIncident] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [agencyFilter, setAgencyFilter] = useState('all');
    const [showHeatmap, setShowHeatmap] = useState(false);
    const [viewTab, setViewTab] = useState('active');
    const [activities, setActivities] = useState([
        { icon: '🟢', text: 'SafeAlert Command Center initialized', time: new Date().toLocaleTimeString(), bg: 'rgba(0,230,118,0.1)' },
        { icon: '📡', text: 'Supabase Realtime connected — listening for SOS events', time: new Date().toLocaleTimeString(), bg: 'rgba(41,182,246,0.1)' },
        { icon: '🤖', text: 'AI classification engine online (FastAPI)', time: new Date().toLocaleTimeString(), bg: 'rgba(155,95,255,0.1)' },
        { icon: '🗺️', text: 'GPS tracking active — 12 responder units online', time: new Date().toLocaleTimeString(), bg: 'rgba(0,230,118,0.1)' },
    ]);
    const [alertFlash, setAlertFlash] = useState({ show: false, text: '' });

    const activeIncidentRef = useRef(activeIncident);
    useEffect(() => { activeIncidentRef.current = activeIncident; }, [activeIncident]);

    const addActivity = useCallback((icon, text, bg) => {
        setActivities(prev => [{
            icon, text, time: new Date().toLocaleTimeString(), bg, isNew: true
        }, ...prev.slice(0, 29)]);
    }, []);

    const showFlash = useCallback((text) => {
        setAlertFlash({ show: true, text });
        setTimeout(() => setAlertFlash({ show: false, text: '' }), 3000);
    }, []);

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
                    const inc = payload.new;
                    showFlash(`NEW SOS — ${inc.user_name || 'Unknown'} · ${inc.emergency_type || 'Emergency'}`);
                    addActivity('🆘', `SOS received from ${inc.user_name || 'Unknown'} (${inc.emergency_type || 'Emergency'})`, 'rgba(255,45,45,0.1)');
                    setTimeout(() => {
                        addActivity('🤖', `AI severity: ${inc.severity || 'MEDIUM'} (score ${Math.floor((inc.severity_score || 0.7) * 100)}/100)`, 'rgba(41,182,246,0.08)');
                    }, 800);
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
    }, [fetchIncidents, addActivity, showFlash]);

    const handleResolve = async (id) => {
        try {
            const inc = incidents.find(i => i.id === id);
            setIncidents(current => current.map(inc =>
                inc.id === id ? { ...inc, status: 'resolved' } : inc
            ));

            addActivity('✅', `Incident resolved — ${inc?.user_name || 'Unknown'}`, 'rgba(0,230,118,0.1)');

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
        avgResponse: null,
    };

    if (loading) {
        return (
            <div className="loading-container">
                <div className="loader"></div>
                <h2 style={{ fontFamily: 'var(--display)', letterSpacing: '0.1em', fontSize: '1rem' }}>
                    INITIALIZING COMMAND CENTER...
                </h2>
            </div>
        );
    }

    return (
        <div className="dashboard-container">
            <TopBar stats={stats} />

            <div className="main-layout">
                {/* LEFT PANEL: INCIDENT QUEUE */}
                <div className="panel">
                    <div className="panel-header">
                        <div className="panel-title">AI Priority Queue</div>
                        <div className="panel-count">{filteredIncidents.length}</div>
                    </div>

                    {/* Tabs */}
                    <div className="tabs">
                        <button
                            className={`tab ${viewTab === 'active' ? 'active' : ''}`}
                            onClick={() => setViewTab('active')}>
                            Active ({stats.active})
                        </button>
                        <button
                            className={`tab ${viewTab === 'history' ? 'active' : ''}`}
                            onClick={() => setViewTab('history')}>
                            History ({stats.resolved})
                        </button>
                    </div>

                    {/* Filters */}
                    <div className="filter-row">
                        {Object.entries(AGENCY_LABELS).map(([key, label]) => (
                            <button
                                key={key}
                                className={`filter-chip ${agencyFilter === key ? 'active' : ''}`}
                                onClick={() => setAgencyFilter(key)}>
                                {label}
                            </button>
                        ))}
                        <label className="heatmap-toggle" style={{ marginLeft: 'auto' }}>
                            <input
                                type="checkbox"
                                checked={showHeatmap}
                                onChange={(e) => setShowHeatmap(e.target.checked)}
                            />
                            🔥 Heatmap
                        </label>
                    </div>

                    {error && (
                        <div style={{
                            padding: '8px 1rem',
                            fontSize: '0.65rem',
                            color: 'var(--amber)',
                            fontFamily: 'var(--mono)',
                            borderBottom: '1px solid var(--border)'
                        }}>
                            ⚠ {error}
                        </div>
                    )}

                    <div className="panel-body">
                        <IncidentList
                            incidents={filteredIncidents}
                            activeIncident={activeIncident}
                            setActiveIncident={setActiveIncident}
                            onResolve={handleResolve}
                        />
                    </div>
                </div>

                {/* CENTER: MAP */}
                <div className="map-area">
                    <div className="map-scan"></div>
                    <div className={`alert-flash ${alertFlash.show ? 'show' : ''}`}>
                        ⚠ {alertFlash.text || 'NEW SOS INCOMING'}
                    </div>

                    <MapView
                        incidents={filteredIncidents}
                        activeIncident={activeIncident}
                        setActiveIncident={setActiveIncident}
                        onResolve={handleResolve}
                        showHeatmap={showHeatmap}
                    />

                    <div className="map-coords">
                        <div>LAT {activeIncident?.lat?.toFixed(4) || '28.6139'}°N · LNG {activeIncident?.lng?.toFixed(4) || '77.2090'}°E</div>
                        <div style={{ marginTop: '3px', color: 'rgba(208,216,228,0.25)' }}>
                            COVERAGE RADIUS: 15km · DELHI METRO
                        </div>
                    </div>

                    <div className="map-legend">
                        <div style={{
                            fontFamily: 'var(--mono)',
                            fontSize: '0.55rem',
                            color: 'var(--muted)',
                            marginBottom: '4px',
                            letterSpacing: '0.1em',
                            textTransform: 'uppercase'
                        }}>Legend</div>
                        <div className="legend-item">
                            <div className="legend-dot" style={{ background: 'var(--red)' }}></div>
                            Critical SOS
                        </div>
                        <div className="legend-item">
                            <div className="legend-dot" style={{ background: 'var(--amber)' }}></div>
                            High Severity
                        </div>
                        <div className="legend-item">
                            <div className="legend-dot" style={{ background: 'var(--blue)' }}></div>
                            Medium Severity
                        </div>
                        <div className="legend-item">
                            <div className="legend-dot" style={{ background: 'var(--green)' }}></div>
                            Responder Unit
                        </div>
                    </div>
                </div>

                {/* RIGHT PANEL */}
                <RightPanel
                    activeIncident={activeIncident}
                    onResolve={handleResolve}
                    activities={activities}
                />
            </div>

            <BottomBar connected={!error} />
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
