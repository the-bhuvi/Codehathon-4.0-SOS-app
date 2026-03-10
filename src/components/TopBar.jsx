import React, { useState, useEffect } from 'react';

const TopBar = ({ stats }) => {
    const [time, setTime] = useState(new Date().toLocaleTimeString('en-IN', { hour12: false }));

    useEffect(() => {
        const timer = setInterval(() => {
            setTime(new Date().toLocaleTimeString('en-IN', { hour12: false }));
        }, 1000);
        return () => clearInterval(timer);
    }, []);

    return (
        <div className="topbar">
            <div className="logo">
                <div className="logo-dot"></div>
                SAFE<span style={{ color: 'var(--text)' }}>ALERT</span>
            </div>
            <div style={{
                fontFamily: 'var(--mono)',
                fontSize: '0.6rem',
                color: 'var(--muted)',
                letterSpacing: '0.1em',
                textTransform: 'uppercase'
            }}>
                AI-Powered Emergency Command Center
            </div>

            <div className="top-stats">
                <div className="top-stat">
                    <div className="top-stat-val" style={{ color: 'var(--red)' }}>{stats.active}</div>
                    <div className="top-stat-label">Active</div>
                </div>
                <div className="top-stat">
                    <div className="top-stat-val" style={{ color: 'var(--green)' }}>{stats.resolved}</div>
                    <div className="top-stat-label">Resolved</div>
                </div>
                <div className="top-stat">
                    <div className="top-stat-val" style={{ color: 'var(--blue)' }}>12</div>
                    <div className="top-stat-label">Responders</div>
                </div>
                <div className="top-stat">
                    <div className="top-stat-val" style={{ color: 'var(--amber)' }}>
                        {stats.avgResponse || '—'}
                    </div>
                    <div className="top-stat-label">Avg Response</div>
                </div>
            </div>

            <div className="sys-status">
                <div className="sys-dot"></div>
                All systems operational
            </div>

            <div className="clock">{time}</div>
        </div>
    );
};

export default TopBar;
