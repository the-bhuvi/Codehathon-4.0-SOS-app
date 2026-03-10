import React from 'react';
import { Clock, MapPin, CheckCircle } from 'lucide-react';

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

                    return (
                        <div
                            key={incident.id}
                            className={`incident-card ${sevClass} ${isActive ? 'active' : ''}`}
                            onClick={() => setActiveIncident(incident)}
                        >
                            <div className="incident-card-indicator"></div>

                            <div className="incident-header">
                                <span className={`incident-severity ${sevClass}`}>
                                    {incident.severity || 'UNKNOWN'}
                                </span>
                                <span className="incident-time">
                                    <Clock size={12} style={{ display: 'inline', marginRight: '4px', verticalAlign: '-1px' }} />
                                    {calculateTimeElapsed(incident.created_at)}
                                </span>
                            </div>

                            <p className="incident-message">{incident.message}</p>

                            <div className="incident-footer">
                                <div className="incident-status">
                                    <span className={`status-dot ${isResolved ? 'resolved' : ''}`}></span>
                                    {isResolved ? 'Resolved' : 'Active Emergency'}
                                </div>

                                <button
                                    className={`resolve-btn ${isResolved ? 'resolved-btn' : ''}`}
                                    onClick={(e) => {
                                        e.stopPropagation();
                                        if (!isResolved) onResolve(incident.id);
                                    }}
                                    disabled={isResolved}
                                >
                                    <CheckCircle size={14} />
                                    {isResolved ? 'Resolved' : 'Mark Resolved'}
                                </button>
                            </div>
                        </div>
                    );
                })
            )}
        </div>
    );
};

export default IncidentList;
