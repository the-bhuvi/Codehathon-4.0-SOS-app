import React, { useState, useEffect } from 'react';
import ThemeToggle from './ThemeToggle';

const TopBar = ({ stats }) => {
    const [currentTime, setCurrentTime] = useState(new Date());

    useEffect(() => {
        const timer = setInterval(() => {
            setCurrentTime(new Date());
        }, 1000);
        
        return () => clearInterval(timer);
    }, []);

    const timeString = currentTime.toLocaleTimeString('en-IN', { hour12: false });
    const dateString = currentTime.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' });

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

            <div className="clock">
                <div className="clock-time">{timeString}</div>
                <div className="clock-date">{dateString}</div>
            </div>

            <ThemeToggle />
        </div>
    );
};

export default TopBar;
