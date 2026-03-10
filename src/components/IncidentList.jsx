import React from 'react';

const AGENCY_ICONS = { police: '🚔', ambulance: '🚑', fire_dept: '🚒' };
const TYPE_LABELS = {
    fire: '🔥 Fire', accident: '💥 Accident', robbery: '🔫 Robbery',
    medical: '🏥 Medical', following: '👤 Following', unsafe: '⚠️ Unsafe', general: '📍 General',
};

const IncidentList = ({ incidents, activeIncident, setActiveIncident, onResolve }) => {
    const getSeverityClass = (severity) => {
        switch (severity?.toUpperCase()) {
            case 'HIGH': return 'sev-critical';
            case 'MEDIUM': return 'sev-high';
            case 'LOW': return 'sev-medium';
            default: return 'sev-low';
        }
    };

    const getSeverityLabel = (severity) => {
        switch (severity?.toUpperCase()) {
            case 'HIGH': return 'CRITICAL';
            case 'MEDIUM': return 'HIGH';
            case 'LOW': return 'MEDIUM';
            default: return 'LOW';
        }
    };

    const getSeverityColor = (severity) => {
        switch (severity?.toUpperCase()) {
            case 'HIGH': return 'var(--red)';
            case 'MEDIUM': return 'var(--amber)';
            case 'LOW': return 'var(--blue)';
            default: return 'var(--green)';
        }
    };

    const calculateTimeElapsed = (dateString) => {
        const elapsed = Date.now() - new Date(dateString).getTime();
        const minutes = Math.floor(elapsed / 60000);
        if (minutes < 1) return 'Just now';
        if (minutes < 60) return `${minutes}m ago`;
        const hours = Math.floor(minutes / 60);
        if (hours < 24) return `${hours}h ago`;
        return `${Math.floor(hours / 24)}d ago`;
    };

    const formatTime = (dateString) => {
        return new Date(dateString).toLocaleTimeString('en-IN', {
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit'
        });
    };

    if (incidents.length === 0) {
        return (
            <div className="empty-state">
                <span style={{ fontSize: '1.5rem' }}>✅</span>
                <span>No incidents in queue</span>
            </div>
        );
    }

    return (
        <>
            {incidents.map((incident) => {
                const isResolved = incident.status === 'resolved';
                const sevClass = getSeverityClass(incident.severity);
                const isActive = activeIncident?.id === incident.id;
                const agencyIcon = AGENCY_ICONS[incident.agency] || '📍';
                const typeLabel = TYPE_LABELS[incident.emergency_type] || TYPE_LABELS.general;
                const score = Math.floor((incident.severity_score || 0.7) * 100);

                return (
                    <div
                        key={incident.id}
                        className={`incident-card ${sevClass} ${isActive ? 'active' : ''}`}
                        onClick={() => setActiveIncident(incident)}
                    >
                        <div className="inc-top">
                            <span className="inc-id">#{incident.id?.slice(-4) || '0000'} · {agencyIcon}</span>
                            <span className={`sev-badge ${sevClass}`}>
                                {getSeverityLabel(incident.severity)}
                            </span>
                        </div>

                        <div className="inc-name">{incident.user_name || 'Unknown User'}</div>

                        <div className="inc-loc">
                            📍 {incident.lat?.toFixed(4) || '—'}°N · {incident.lng?.toFixed(4) || '—'}°E
                        </div>

                        <div className="inc-ai">
                            {typeLabel} {incident.detected_language && incident.detected_language !== 'en' && `· 🌐 ${incident.detected_language.toUpperCase()}`}
                            {isResolved && ' · ✅ RESOLVED'}
                        </div>

                        <div className="inc-meta">
                            <span className="inc-time">{formatTime(incident.created_at)}</span>
                            <div className="inc-score">
                                <div className="score-bar">
                                    <div
                                        className="score-fill"
                                        style={{
                                            width: `${score}%`,
                                            background: getSeverityColor(incident.severity)
                                        }}
                                    ></div>
                                </div>
                                <span style={{
                                    color: getSeverityColor(incident.severity),
                                    fontFamily: 'var(--mono)',
                                    fontSize: '0.6rem'
                                }}>
                                    {score}
                                </span>
                            </div>
                        </div>
                    </div>
                );
            })}
        </>
    );
};

export default IncidentList;
