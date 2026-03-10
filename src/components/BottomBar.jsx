import React from 'react';

const BottomBar = ({ connected = true }) => {
    return (
        <div className="bottombar">
            <div className="status-item">
                <div className="status-dot" style={{ background: connected ? 'var(--green)' : 'var(--red)' }}></div>
                Supabase Realtime · {connected ? 'Connected' : 'Disconnected'}
            </div>
            <div className="status-item">
                <div className="status-dot" style={{ background: 'var(--blue)' }}></div>
                AI Backend · Online
            </div>
            <div className="status-item">
                <div className="status-dot" style={{ background: 'var(--green)' }}></div>
                Node.js API · Running
            </div>
            <div className="status-item">
                <div className="status-dot" style={{ background: 'var(--amber)' }}></div>
                SMS Gateway · Active
            </div>
            <div style={{ marginLeft: 'auto', fontFamily: 'var(--mono)', fontSize: '0.55rem' }}>
                v2.4.1 · BUILD {new Date().toISOString().slice(0, 10).replace(/-/g, '')}
            </div>
        </div>
    );
};

export default BottomBar;
