import React, { useState, useEffect, useMemo } from 'react';
import Map, { Marker, Popup, NavigationControl } from 'react-map-gl';
import 'mapbox-gl/dist/mapbox-gl.css';

const MAPBOX_TOKEN = import.meta.env.VITE_MAPBOX_TOKEN || '';

const MapView = ({ incidents, activeIncident, setActiveIncident, onResolve }) => {
    const [viewState, setViewState] = useState({
        longitude: -74.006,
        latitude: 40.7128,
        zoom: 11
    });

    // When active incident changes, fly to its location
    useEffect(() => {
        if (activeIncident && activeIncident.lng && activeIncident.lat) {
            setViewState({
                longitude: activeIncident.lng,
                latitude: activeIncident.lat,
                zoom: 14,
                transitionDuration: 1000
            });
        }
    }, [activeIncident]);

    const getSeverityClass = (severity) => {
        switch (severity?.toUpperCase()) {
            case 'HIGH': return 'high';
            case 'MEDIUM': return 'medium';
            case 'LOW': return 'low';
            default: return 'low';
        }
    };

    const markers = useMemo(() => incidents.map(incident => {
        const sevClass = getSeverityClass(incident.severity);
        const isResolved = incident.status === 'resolved';

        return (
            <Marker
                key={incident.id}
                longitude={incident.lng}
                latitude={incident.lat}
                anchor="center"
                onClick={e => {
                    e.originalEvent.stopPropagation();
                    setActiveIncident(incident);
                }}
                style={{ zIndex: isResolved ? 1 : 2 }} // put resolved ones underneath
            >
                <div
                    className={`map-marker ${sevClass}`}
                    style={{ opacity: isResolved ? 0.5 : 1 }}
                ></div>
            </Marker>
        );
    }), [incidents, setActiveIncident]);

    return (
        <Map
            {...viewState}
            onMove={evt => setViewState(evt.viewState)}
            mapStyle="mapbox://styles/mapbox/dark-v11"
            mapboxAccessToken={MAPBOX_TOKEN}
            attributionControl={false}
        >
            <NavigationControl position="top-right" />

            {markers}

            {activeIncident && (
                <Popup
                    longitude={activeIncident.lng}
                    latitude={activeIncident.lat}
                    anchor="bottom"
                    onClose={() => setActiveIncident(null)}
                    closeOnClick={false}
                    offset={[0, -15]}
                >
                    <div className="popup-container">
                        <h3>SOS Incident</h3>
                        <p><strong>Severity:</strong> {activeIncident.severity}</p>
                        <p><strong>Status:</strong> {activeIncident.status}</p>
                        <p><strong>Time:</strong> {new Date(activeIncident.created_at).toLocaleTimeString()}</p>
                        <p><strong>Message:</strong> {activeIncident.message}</p>
                        {activeIncident.status !== 'resolved' && (
                            <button
                                className="resolve-btn"
                                style={{ width: '100%', justifyContent: 'center', marginTop: '10px' }}
                                onClick={() => onResolve(activeIncident.id)}
                            >
                                Mark as Resolved
                            </button>
                        )}
                    </div>
                </Popup>
            )}
        </Map>
    );
};

export default MapView;
