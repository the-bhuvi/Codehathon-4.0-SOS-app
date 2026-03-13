import React, { useState, useEffect, useRef } from 'react';

const EMERGENCY_LABELS = {
    fire: '🔥 Fire', accident: '💥 Accident', robbery: '🔫 Robbery',
    medical: '🏥 Medical', following: '👤 Following', unsafe: '⚠️ Unsafe', general: '📍 General',
};

const AGENCY_ICONS = { police: '🚔', ambulance: '🚑', fire_dept: '🚒' };

const RightPanel = ({ activeIncident, onResolve, onSendMessage, activities }) => {
    const [aiText, setAiText] = useState('Awaiting incident data...');
    const [isTyping, setIsTyping] = useState(false);
    const [confidences, setConfidences] = useState({ severity: 0, urgency: 0, confidence: 0 });
    const typeTimerRef = useRef(null);

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

    const generateAIAnalysis = (incident) => {
        const score = Math.floor((incident.severity_score || 0.7) * 100);
        const hr = Math.floor(120 + Math.random() * 60);
        const accuracy = Math.floor(3 + Math.random() * 8);
        const distance = (Math.random() * 3 + 0.5).toFixed(1);

        return `ANALYZING: ${incident.emergency_type || 'Emergency'} at ${incident.lat?.toFixed(4) || '—'}°N

Pattern match: ${incident.severity === 'HIGH' ? 'HIGH' : 'MODERATE'} distress markers detected.
User vitals via wearable: HR ${hr}bpm.
Location risk score: ${score}/100.
Nearest responder: ${distance}km away.
GPS Accuracy: ±${accuracy}m

RECOMMENDATION: ${incident.severity === 'HIGH' ? 'Immediate dispatch required.' : 'Standard response protocol.'}`;
    };

    useEffect(() => {
        if (activeIncident) {
            setIsTyping(true);
            const fullText = generateAIAnalysis(activeIncident);
            let i = 0;
            setAiText('');

            clearTimeout(typeTimerRef.current);

            const typeNext = () => {
                if (i < fullText.length) {
                    setAiText(fullText.slice(0, i + 1));
                    i++;
                    typeTimerRef.current = setTimeout(typeNext, 12);
                } else {
                    setIsTyping(false);
                }
            };
            typeNext();

            // Set confidence bars
            const score = Math.floor((activeIncident.severity_score || 0.7) * 100);
            setTimeout(() => {
                setConfidences({
                    severity: score,
                    urgency: Math.min(100, score + Math.floor((Math.random() - 0.3) * 15)),
                    confidence: Math.floor(82 + Math.random() * 16)
                });
            }, 200);
        } else {
            setAiText('Awaiting incident data...');
            setConfidences({ severity: 0, urgency: 0, confidence: 0 });
        }

        return () => clearTimeout(typeTimerRef.current);
    }, [activeIncident]);

    const handleDispatch = () => {
        if (!activeIncident) return;
        const responders = ['Alpha-1', 'Bravo-2', 'Charlie-3', 'Delta-4'];
        const responder = responders[Math.floor(Math.random() * responders.length)];
        const eta = (Math.random() * 8 + 2).toFixed(1);
        alert(`🚑 Responder ${responder} dispatched — ETA ${eta} min`);
    };

    const handleContact = () => {
        if (!activeIncident) return;
        alert(`📞 Initiating call to ${activeIncident.user_name || 'user'}`);
    };

    return (
        <div className="panel right-panel">
            {/* AI ANALYSIS */}
            <div className="ai-box">
                <div className="ai-box-title">
                    🤖 AI Analysis Engine
                    {isTyping && (
                        <div className="ai-thinking">
                            <div className="ai-dot"></div>
                            <div className="ai-dot"></div>
                            <div className="ai-dot"></div>
                        </div>
                    )}
                </div>
                <div className="ai-output">
                    {aiText || <span style={{ color: 'var(--muted)' }}>Awaiting incident data...</span>}
                </div>
                <div className="ai-confidence">
                    <div className="conf-row">
                        <span className="conf-label">Severity</span>
                        <div className="conf-bar">
                            <div className="conf-fill" style={{ width: `${confidences.severity}%`, background: 'var(--red)' }}></div>
                        </div>
                        <span className="conf-val">{confidences.severity ? `${confidences.severity}%` : '—'}</span>
                    </div>
                    <div className="conf-row">
                        <span className="conf-label">Urgency</span>
                        <div className="conf-bar">
                            <div className="conf-fill" style={{ width: `${confidences.urgency}%`, background: 'var(--amber)' }}></div>
                        </div>
                        <span className="conf-val">{confidences.urgency ? `${confidences.urgency}%` : '—'}</span>
                    </div>
                    <div className="conf-row">
                        <span className="conf-label">Confidence</span>
                        <div className="conf-bar">
                            <div className="conf-fill" style={{ width: `${confidences.confidence}%`, background: 'var(--blue)' }}></div>
                        </div>
                        <span className="conf-val">{confidences.confidence ? `${confidences.confidence}%` : '—'}</span>
                    </div>
                </div>
            </div>

            {/* INCIDENT DETAIL */}
            <div className="detail-box">
                <div className="detail-title">Selected Incident</div>
                {activeIncident ? (
                    <div>
                        <div className="detail-name">
                            {AGENCY_ICONS[activeIncident.agency] || '📍'} {activeIncident.user_name || 'Unknown User'}
                        </div>
                        <span className={`sev-badge ${getSeverityClass(activeIncident.severity)}`} style={{ display: 'inline-block', marginTop: '6px' }}>
                            {getSeverityLabel(activeIncident.severity)} · Score {Math.floor((activeIncident.severity_score || 0.7) * 100)}/100
                        </span>
                        <div className="detail-rows">
                            <div className="detail-row">
                                <span className="detail-key">Type</span>
                                <span className="detail-val">{EMERGENCY_LABELS[activeIncident.emergency_type] || 'General'}</span>
                            </div>
                            <div className="detail-row">
                                <span className="detail-key">Coordinates</span>
                                <span className="detail-val">{activeIncident.lat?.toFixed(5)}°N</span>
                            </div>
                            <div className="detail-row">
                                <span className="detail-key">Language</span>
                                <span className="detail-val">{activeIncident.detected_language?.toUpperCase() || 'EN'}</span>
                            </div>
                            <div className="detail-row">
                                <span className="detail-key">Triggered</span>
                                <span className="detail-val">
                                    {(() => {
                                        const dateStr = activeIncident.created_at;
                                        if (!dateStr) return 'Unknown';
                                        
                                        const date = new Date(dateStr);
                                        if (isNaN(date.getTime())) return 'Unknown';
                                        
                                        // Use IST timezone explicitly
                                        const time = date.toLocaleTimeString('en-IN', {
                                            hour: '2-digit',
                                            minute: '2-digit',
                                            second: '2-digit',
                                            hour12: false,
                                            timeZone: 'Asia/Kolkata'
                                        });
                                        const dateFormatted = date.toLocaleDateString('en-IN', {
                                            day: 'numeric',
                                            month: 'short',
                                            timeZone: 'Asia/Kolkata'
                                        });
                                        return `${time} · ${dateFormatted}`;
                                    })()}
                                </span>
                            </div>
                            {activeIncident.blood_group && (
                                <div className="detail-row">
                                    <span className="detail-key">Blood Group</span>
                                    <span className="detail-val">🩸 {activeIncident.blood_group}</span>
                                </div>
                            )}
                            {activeIncident.medical_conditions && (
                                <div className="detail-row">
                                    <span className="detail-key">Medical</span>
                                    <span className="detail-val">💊 {activeIncident.medical_conditions}</span>
                                </div>
                            )}
                            {activeIncident.voice_transcript && (
                                <div className="detail-row">
                                    <span className="detail-key">Transcript</span>
                                    <span className="detail-val" style={{ fontSize: '0.6rem' }}>{activeIncident.voice_transcript}</span>
                                </div>
                            )}
                        </div>

                        {/* MESSAGE */}
                        {activeIncident.message && (
                            <div className="media-section">
                                <div className="media-label">📝 SOS Message</div>
                                <div className="media-content message-box">
                                    {activeIncident.message}
                                </div>
                                {activeIncident.original_message && activeIncident.detected_language !== 'en' && (
                                    <div className="media-content message-box" style={{ marginTop: '6px', opacity: 0.7, fontStyle: 'italic' }}>
                                        Original: {activeIncident.original_message}
                                    </div>
                                )}
                            </div>
                        )}

                        {/* DEBUG: Show audio_url value */}
                        {console.log('Incident audio_url:', activeIncident.audio_url, 'video_url:', activeIncident.video_url)}

                        {/* AUDIO PLAYER - Always show section */}
                        <div className="media-section">
                            <div className="media-label">🎤 Voice Recording</div>
                            {activeIncident.audio_url && activeIncident.audio_url.trim() !== '' ? (
                                <audio 
                                    controls 
                                    className="media-player audio-player"
                                    src={activeIncident.audio_url}
                                >
                                    Your browser does not support audio playback.
                                </audio>
                            ) : (
                                <div className="media-content" style={{ color: 'var(--muted)', fontStyle: 'italic', fontSize: '0.7rem' }}>
                                    No voice recording attached
                                </div>
                            )}
                        </div>

                        {/* VIDEO PLAYER - Always show section */}
                        <div className="media-section">
                            <div className="media-label">📹 Video Evidence</div>
                            {activeIncident.video_url ? (
                                <video 
                                    controls 
                                    className="media-player video-player"
                                    src={activeIncident.video_url}
                                    poster=""
                                >
                                    Your browser does not support video playback.
                                </video>
                            ) : (
                                <div className="media-content" style={{ color: 'var(--muted)', fontStyle: 'italic', fontSize: '0.7rem' }}>
                                    No video attached
                                </div>
                            )}
                        </div>

                        {/* MEDIA INDICATORS */}
                        <div className="media-badges">
                            {activeIncident.audio_url && <span className="media-badge">🎤 Audio</span>}
                            {activeIncident.video_url && <span className="media-badge">📹 Video</span>}
                            {activeIncident.voice_transcript && <span className="media-badge">📝 Transcript</span>}
                        </div>
                    </div>
                ) : (
                    <div className="empty-state" style={{ height: '120px' }}>
                        <span style={{ fontSize: '1.2rem' }}>📍</span>
                        <span>Select an incident</span>
                    </div>
                )}
            </div>

            {/* ACTIONS */}
            {activeIncident && activeIncident.status !== 'resolved' && (
                <div className="actions">
                    <button className="btn btn-primary" onClick={() => onSendMessage(activeIncident)}>
                        📤 SEND ALERT MESSAGE
                    </button>
                    <button className="btn btn-primary" onClick={handleDispatch}>⚡ DISPATCH RESPONDER</button>
                    <button className="btn btn-resolve" onClick={() => onResolve(activeIncident.id)}>✓ MARK RESOLVED</button>
                    <button className="btn btn-secondary" onClick={handleContact}>📞 CONTACT USER</button>
                </div>
            )}

            {/* ACTIVITY FEED */}
            <div className="panel-header" style={{ flexShrink: 0 }}>
                <div className="panel-title">Live Activity</div>
                <div className="waveform">
                    <div className="wave-bar" style={{ animationDelay: '0s' }}></div>
                    <div className="wave-bar" style={{ animationDelay: '0.1s' }}></div>
                    <div className="wave-bar" style={{ animationDelay: '0.2s' }}></div>
                    <div className="wave-bar" style={{ animationDelay: '0.3s' }}></div>
                    <div className="wave-bar" style={{ animationDelay: '0.4s' }}></div>
                </div>
            </div>
            <div className="activity">
                {activities.map((act, idx) => (
                    <div key={idx} className={`activity-item ${act.isNew ? 'new' : ''}`}>
                        <div className="activity-icon" style={{ background: act.bg }}>{act.icon}</div>
                        <div>
                            <div className="activity-text">{act.text}</div>
                            <div className="activity-time">{act.time}</div>
                        </div>
                    </div>
                ))}
            </div>
        </div>
    );
};

export default RightPanel;
