import React from 'react';
import { Clock, MapPin, CheckCircle, Mic, Video, Globe } from 'lucide-react';

const AGENCY_ICONS = { police: '🚔', ambulance: '🚑', fire_dept: '🚒' };
const TYPE_LABELS = {
    fire: '🔥 Fire', accident: '💥 Accident', robbery: '🔫 Robbery',
    medical: '🏥 Medical', following: '👤 Following', unsafe: '⚠️ Unsafe', general: '📍 General',
};

const IncidentList = ({ incidents, activeIncident, setActiveIncident, onResolve }) => {
    const getSeverityClass = (severity) => {
        switch (severity?.toUpperCase()) {
            case 'HIGH': return 'high';
            case 'MEDIUM': return 'medium';
            case 'LOW': return 'low';
            default: return 'low';
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

    return (
        <div className="incident-list">
            {incidents.length === 0 ? (
                <p style={{ color: 'var(--text-secondary)', textAlign: 'center', marginTop: '40px' }}>
                    No incidents reported. All clear!
                </p>
            ) : (
                incidents.map((incident) => {
                    const isResolved = incident.status === 'resolved';
                    const sevClass = getSeverityClass(incident.severity);
                    const isActive = activeIncident?.id === incident.id;
                    const agencyIcon = AGENCY_ICONS[incident.agency] || '📍';
                    const typeLabel = TYPE_LABELS[incident.emergency_type] || TYPE_LABELS.general;

                    return (
                        <div key={incident.id}
                            className={`incident-card ${sevClass} ${isActive ? 'active' : ''}`}
                            onClick={() => setActiveIncident(incident)}>
                            <div className="incident-card-indicator"></div>

                            <div className="incident-header">
                                <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                                    <span className={`incident-severity ${sevClass}`}>
                                        {incident.severity || 'UNKNOWN'}
                                    </span>
                                    <span className="agency-badge">{agencyIcon}</span>
                                    <span className="incident-time">
                                        <Clock size={12} style={{ display: 'inline', marginRight: '4px', verticalAlign: '-1px' }} />
                                        {calculateTimeElapsed(incident.created_at)}
                                    </span>
                                </div>
                                <button
                                    className={`resolve-btn ${isResolved ? 'resolved-btn' : ''}`}
                                    onClick={(e) => { e.stopPropagation(); if (!isResolved) onResolve(incident.id); }}
                                    disabled={isResolved}>
                                    <CheckCircle size={14} />
                                    {isResolved ? 'Resolved' : 'Resolve'}
                                </button>
                            </div>

                            {/* Emergency type + user info */}
                            <div className="incident-meta">
                                <span className="type-badge">{typeLabel}</span>
                                {incident.user_name && <span className="user-badge">👤 {incident.user_name}</span>}
                                {incident.detected_language && incident.detected_language !== 'en' && (
                                    <span className="lang-badge"><Globe size={10} /> {incident.detected_language.toUpperCase()}</span>
                                )}
                            </div>

                            <p className="incident-message">{incident.message}</p>

                            {/* Original message if translated */}
                            {incident.original_message && incident.detected_language !== 'en' && (
                                <p className="incident-original">
                                    Original: {incident.original_message}
                                </p>
                            )}

                            {/* Media indicators */}
                            <div className="media-indicators">
                                {incident.audio_url && (
                                    <span className="media-badge"><Mic size={12} /> Audio</span>
                                )}
                                {incident.video_url && (
                                    <span className="media-badge"><Video size={12} /> Video</span>
                                )}
                                {incident.blood_group && (
                                    <span className="media-badge">🩸 {incident.blood_group}</span>
                                )}
                                {incident.severity_score > 0 && (
                                    <span className="media-badge">Score: {incident.severity_score}</span>
                                )}
                            </div>

                            {/* Audio player inline */}
                            {incident.audio_url && isActive && (
                                <audio controls style={{ width: '100%', height: '28px', marginTop: '6px' }} src={incident.audio_url} />
                            )}

                            <div className="incident-footer">
                                <div className="incident-status">
                                    <span className={`status-dot ${isResolved ? 'resolved' : ''}`}></span>
                                    {isResolved ? 'Resolved' : 'Active Emergency'}
                                </div>
                            </div>
                        </div>
                    );
                })
            )}
        </div>
    );
};

export default IncidentList;
