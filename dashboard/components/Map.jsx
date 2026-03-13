import React, { useEffect, useRef } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import 'leaflet.heat';

// Fix for default Leaflet marker icons
import icon from 'leaflet/dist/images/marker-icon.png';
import iconShadow from 'leaflet/dist/images/marker-shadow.png';

let DefaultIcon = L.icon({
    iconUrl: icon, shadowUrl: iconShadow,
    iconSize: [25, 41], iconAnchor: [12, 41], popupAnchor: [1, -34], shadowSize: [41, 41]
});
L.Marker.prototype.options.icon = DefaultIcon;

const AGENCY_ICONS = {
    police: '🚔', ambulance: '🚑', fire_dept: '🚒',
};

const EMERGENCY_LABELS = {
    fire: '🔥 Fire', accident: '💥 Accident', robbery: '🔫 Robbery',
    medical: '🏥 Medical', following: '👤 Following', unsafe: '⚠️ Unsafe', general: '📍 General',
};

const LANG_NAMES = {
    en: 'English', hi: 'Hindi', ta: 'Tamil', te: 'Telugu', kn: 'Kannada', ml: 'Malayalam',
};

const getCustomIcon = (severity, isResolved) => {
    let color = '#ffd700';
    let className = 'map-marker low';

    if (severity?.toUpperCase() === 'HIGH') { color = '#ff4d4d'; className = 'map-marker high'; }
    else if (severity?.toUpperCase() === 'MEDIUM') { color = '#ffa600'; className = 'map-marker medium'; }

    const pulseRing = !isResolved && severity?.toUpperCase() === 'HIGH'
        ? `<div style="position:absolute;top:-8px;left:-8px;width:40px;height:40px;border-radius:50%;border:2px solid ${color};animation:pulse 2s infinite;"></div>`
        : '';

    const html = `<div style="position:relative;">${pulseRing}<div class="${className}" style="background-color: ${color}; width: 24px; height: 24px; border-radius: 50%; border: 3px solid #fff; opacity: ${isResolved ? 0.4 : 1};"></div></div>`;

    return L.divIcon({ className: 'custom-leaflet-icon', html, iconSize: [24, 24], iconAnchor: [12, 12] });
};

// Heatmap layer component
const HeatmapLayer = ({ incidents, show }) => {
    const map = useMap();
    const heatLayerRef = useRef(null);

    useEffect(() => {
        if (heatLayerRef.current) {
            map.removeLayer(heatLayerRef.current);
            heatLayerRef.current = null;
        }

        if (show && incidents.length > 0) {
            const points = incidents
                .filter(i => i.status === 'active')
                .map(i => {
                    const intensity = i.severity === 'HIGH' ? 1.0 : i.severity === 'MEDIUM' ? 0.6 : 0.3;
                    return [i.lat, i.lng, intensity];
                });

            if (points.length > 0) {
                heatLayerRef.current = L.heatLayer(points, {
                    radius: 35, blur: 25, maxZoom: 17, max: 1.0,
                    gradient: { 0.2: '#2ecc71', 0.5: '#ffa600', 0.8: '#ff6b35', 1.0: '#ff4d4d' }
                }).addTo(map);
            }
        }

        return () => {
            if (heatLayerRef.current) { map.removeLayer(heatLayerRef.current); }
        };
    }, [incidents, show, map]);

    return null;
};

const MapUpdater = ({ activeIncident }) => {
    const map = useMap();
    useEffect(() => {
        if (activeIncident?.lat && activeIncident?.lng) {
            map.flyTo([activeIncident.lat, activeIncident.lng], 15, { animate: true, duration: 1.5 });
        }
    }, [activeIncident, map]);
    return null;
};

const MapView = ({ incidents, activeIncident, setActiveIncident, onResolve, showHeatmap }) => {
    const defaultCenter = [28.6139, 77.2090]; // Delhi
    const defaultZoom = 12;

    return (
        <MapContainer center={defaultCenter} zoom={defaultZoom}
            style={{ width: '100%', height: '100%', zIndex: 1 }} zoomControl={false}>
            <TileLayer
                attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OSM</a>'
                url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                className="map-tiles"
            />

            <MapUpdater activeIncident={activeIncident} />
            <HeatmapLayer incidents={incidents} show={showHeatmap} />

            {incidents.map(incident => {
                const isResolved = incident.status === 'resolved';
                const agencyIcon = AGENCY_ICONS[incident.agency] || '📍';
                const typeLabel = EMERGENCY_LABELS[incident.emergency_type] || EMERGENCY_LABELS.general;
                const langName = LANG_NAMES[incident.detected_language] || incident.detected_language || 'en';

                return (
                    <Marker key={incident.id}
                        position={[incident.lat, incident.lng]}
                        icon={getCustomIcon(incident.severity, isResolved)}
                        eventHandlers={{ click: () => setActiveIncident(incident) }}
                        zIndexOffset={isResolved ? 0 : 100}>
                        <Popup closeButton={false} offset={[0, -10]}>
                            <div className="popup-container" style={{ margin: '-14px', background: 'var(--panel-bg)', padding: '16px', borderRadius: '12px', color: 'var(--text-primary)', border: '1px solid var(--border-color)', minWidth: '260px' }}>
                                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
                                    <h3 style={{ margin: 0, fontSize: '15px', color: '#fff' }}>{agencyIcon} {typeLabel}</h3>
                                    <span className={`incident-severity ${incident.severity?.toLowerCase()}`}>{incident.severity}</span>
                                </div>

                                {incident.user_name && <p style={{ margin: '4px 0', color: '#aaa', fontSize: '12px' }}>👤 {incident.user_name}</p>}
                                <p style={{ margin: '4px 0', color: '#ccc', fontSize: '13px' }}>{incident.message}</p>

                                {incident.original_message && incident.detected_language !== 'en' && (
                                    <p style={{ margin: '4px 0', color: '#888', fontSize: '11px', fontStyle: 'italic' }}>
                                        Original ({langName}): {incident.original_message}
                                    </p>
                                )}

                                {incident.blood_group && <p style={{ margin: '2px 0', color: '#aaa', fontSize: '11px' }}>🩸 {incident.blood_group}</p>}
                                {incident.medical_conditions && <p style={{ margin: '2px 0', color: '#aaa', fontSize: '11px' }}>💊 {incident.medical_conditions}</p>}

                                <p style={{ margin: '6px 0 0', color: '#666', fontSize: '11px' }}>
                                    🕒 {new Date(incident.created_at).toLocaleTimeString()}
                                    {incident.severity_score ? ` · Score: ${incident.severity_score}` : ''}
                                </p>

                                {/* Audio player */}
                                {incident.audio_url && (
                                    <div style={{ marginTop: '8px' }}>
                                        <p style={{ color: '#aaa', fontSize: '11px', marginBottom: '4px' }}>🎤 Voice Recording:</p>
                                        <audio controls style={{ width: '100%', height: '32px' }} src={incident.audio_url} />
                                    </div>
                                )}

                                {/* Video player */}
                                {incident.video_url && (
                                    <div style={{ marginTop: '8px' }}>
                                        <p style={{ color: '#aaa', fontSize: '11px', marginBottom: '4px' }}>📹 Video Evidence:</p>
                                        <video controls style={{ width: '100%', borderRadius: '6px' }} src={incident.video_url} />
                                    </div>
                                )}

                                {!isResolved && (
                                    <button className="resolve-btn"
                                        style={{ width: '100%', marginTop: '12px', padding: '8px', cursor: 'pointer', background: 'rgba(46,204,113,0.15)', color: '#2ecc71', border: '1px solid #2ecc71', borderRadius: '6px', fontWeight: '600' }}
                                        onClick={(e) => { e.stopPropagation(); onResolve(incident.id); }}>
                                        ✓ Mark as Resolved
                                    </button>
                                )}
                            </div>
                        </Popup>
                    </Marker>
                );
            })}
        </MapContainer>
    );
};

export default MapView;
