import React, { useEffect, useRef } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';

// Fix for default Leaflet marker icons not showing in React
import icon from 'leaflet/dist/images/marker-icon.png';
import iconShadow from 'leaflet/dist/images/marker-shadow.png';

let DefaultIcon = L.icon({
    iconUrl: icon,
    shadowUrl: iconShadow,
    iconSize: [25, 41],
    iconAnchor: [12, 41],
    popupAnchor: [1, -34],
    shadowSize: [41, 41]
});

L.Marker.prototype.options.icon = DefaultIcon;

// Custom animated DIV icon creator for severities
const getCustomIcon = (severity, isResolved) => {
    let color = '#ffd700'; // Default low/yellow
    let className = 'map-marker low';

    if (severity?.toUpperCase() === 'HIGH') {
        color = '#ff4d4d';
        className = 'map-marker high';
    } else if (severity?.toUpperCase() === 'MEDIUM') {
        color = '#ffa600';
        className = 'map-marker medium';
    }

    const html = `<div class="${className}" style="background-color: ${color}; width: 24px; height: 24px; border-radius: 50%; border: 3px solid #fff; opacity: ${isResolved ? 0.5 : 1}; box-shadow: 0 0 10px rgba(0,0,0,0.5);"></div>`;

    return L.divIcon({
        className: 'custom-leaflet-icon',
        html: html,
        iconSize: [24, 24],
        iconAnchor: [12, 12],
    });
};

// Component to handle map fly-to animations
const MapUpdater = ({ activeIncident }) => {
    const map = useMap();

    useEffect(() => {
        if (activeIncident && activeIncident.lat && activeIncident.lng) {
            map.flyTo([activeIncident.lat, activeIncident.lng], 15, {
                animate: true,
                duration: 1.5
            });
        }
    }, [activeIncident, map]);

    return null;
};

const MapView = ({ incidents, activeIncident, setActiveIncident, onResolve }) => {
    const defaultCenter = [40.7128, -74.006]; // Default to NY
    const defaultZoom = 11;

    return (
        <MapContainer
            center={defaultCenter}
            zoom={defaultZoom}
            style={{ width: '100%', height: '100%', zIndex: 1 }}
            zoomControl={false}
        >
            {/* OpenStreetMap completely FREE tile layer! No API Key required! */}
            <TileLayer
                attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
                url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                className="map-tiles"
            />

            <MapUpdater activeIncident={activeIncident} />

            {incidents.map(incident => {
                const isResolved = incident.status === 'resolved';

                return (
                    <Marker
                        key={incident.id}
                        position={[incident.lat, incident.lng]}
                        icon={getCustomIcon(incident.severity, isResolved)}
                        eventHandlers={{
                            click: () => setActiveIncident(incident),
                        }}
                        zIndexOffset={isResolved ? 0 : 100}
                    >
                        <Popup closeButton={false} offset={[0, -10]}>
                            <div className="popup-container" style={{ margin: '-14px', background: 'var(--panel-bg)', padding: '16px', borderRadius: '12px', color: 'var(--text-primary)', border: '1px solid var(--border-color)', minWidth: '200px' }}>
                                <h3 style={{ margin: '0 0 8px 0', fontSize: '16px', color: '#fff' }}>SOS Incident</h3>
                                <p style={{ margin: '4px 0', color: '#ccc' }}><strong>Severity:</strong> {incident.severity}</p>
                                <p style={{ margin: '4px 0', color: '#ccc' }}><strong>Status:</strong> {incident.status}</p>
                                <p style={{ margin: '4px 0', color: '#ccc' }}><strong>Time:</strong> {new Date(incident.created_at).toLocaleTimeString()}</p>
                                <p style={{ margin: '8px 0' }}>{incident.message}</p>

                                {!isResolved && (
                                    <button
                                        className="resolve-btn"
                                        style={{ width: '100%', marginTop: '12px', padding: '8px', cursor: 'pointer', background: 'transparent', color: '#fff', border: '1px solid #fff', borderRadius: '4px' }}
                                        onClick={(e) => {
                                            e.stopPropagation();
                                            onResolve(incident.id);
                                        }}
                                    >
                                        Mark as Resolved
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
