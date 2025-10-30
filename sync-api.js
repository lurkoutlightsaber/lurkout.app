// sync-api.js - Backend API for LURKOUT LITE sync system
// This handles communication between the web interface and Lua executor

const express = require('express');
const router = express.Router();

// In-memory storage for sync data (use Redis or database in production)
const sessions = new Map();
const commandQueues = new Map();

// Session data structure:
// {
//   sessionKey: string,
//   userId: string,
//   connected: boolean,
//   executor: string,
//   placeId: number,
//   placeName: string,
//   tree: object,
//   lastUpdate: timestamp
// }

// Middleware to validate session key
function validateSessionKey(req, res, next) {
    const sessionKey = req.headers['session-key'] || req.query.key;
    
    if (!sessionKey) {
        return res.status(401).json({ error: 'No session key provided' });
    }
    
    req.sessionKey = sessionKey;
    next();
}

// POST /api/sync - Receive data from Lua executor
router.post('/sync', validateSessionKey, (req, res) => {
    const { sessionKey } = req;
    const data = req.body;
    
    try {
        if (data.type === 'status') {
            // Update connection status
            let session = sessions.get(sessionKey) || {};
            session.sessionKey = sessionKey;
            session.connected = data.status === 'connected';
            session.executor = data.executor;
            session.placeId = data.placeId;
            session.lastUpdate = Date.now();
            sessions.set(sessionKey, session);
            
            console.log(`[Sync] Status update for ${sessionKey}: ${data.status}`);
            
        } else if (data.type === 'tree_update') {
            // Update game tree
            let session = sessions.get(sessionKey) || {};
            session.sessionKey = sessionKey;
            session.connected = true;
            session.placeId = data.placeId;
            session.placeName = data.placeName;
            session.tree = data.tree;
            session.lastUpdate = Date.now();
            sessions.set(sessionKey, session);
            
            console.log(`[Sync] Tree update for ${sessionKey}: ${data.tree.length} root nodes`);
        }
        
        res.json({ success: true });
        
    } catch (error) {
        console.error('[Sync] Error processing sync data:', error);
        res.status(500).json({ error: 'Failed to process sync data' });
    }
});

// GET /api/sync/status - Web interface polls for updates
router.get('/sync/status', (req, res) => {
    const sessionKey = req.query.key;
    
    if (!sessionKey) {
        return res.status(400).json({ error: 'No session key provided' });
    }
    
    const session = sessions.get(sessionKey);
    
    if (!session) {
        return res.json({
            connected: false,
            tree: null
        });
    }
    
    // Check if session is still active (within last 10 seconds)
    const isActive = (Date.now() - session.lastUpdate) < 10000;
    
    res.json({
        connected: isActive && session.connected,
        executor: session.executor,
        placeId: session.placeId,
        placeName: session.placeName,
        tree: session.tree,
        lastUpdate: session.lastUpdate
    });
});

// POST /api/commands - Web interface sends commands to executor
router.post('/commands', validateSessionKey, (req, res) => {
    const { sessionKey } = req;
    const { command } = req.body;
    
    if (!command || !command.type) {
        return res.status(400).json({ error: 'Invalid command' });
    }
    
    // Add command to queue for this session
    if (!commandQueues.has(sessionKey)) {
        commandQueues.set(sessionKey, []);
    }
    
    commandQueues.get(sessionKey).push({
        ...command,
        timestamp: Date.now()
    });
    
    console.log(`[Commands] Added command for ${sessionKey}: ${command.type}`);
    
    res.json({ success: true });
});

// GET /api/commands - Lua executor polls for commands
router.get('/commands', validateSessionKey, (req, res) => {
    const { sessionKey } = req;
    
    const commands = commandQueues.get(sessionKey) || [];
    
    // Clear the queue after sending
    commandQueues.delete(sessionKey);
    
    // Remove old commands (older than 30 seconds)
    const freshCommands = commands.filter(cmd => 
        (Date.now() - cmd.timestamp) < 30000
    );
    
    res.json({
        commands: freshCommands
    });
});

// GET /api/sessions - Get all active sessions (admin only)
router.get('/sessions', (req, res) => {
    const activeSessions = [];
    const now = Date.now();
    
    for (const [key, session] of sessions.entries()) {
        if ((now - session.lastUpdate) < 30000) {
            activeSessions.push({
                sessionKey: key.substring(0, 8) + '...',
                connected: session.connected,
                executor: session.executor,
                placeId: session.placeId,
                placeName: session.placeName,
                lastUpdate: new Date(session.lastUpdate).toISOString()
            });
        }
    }
    
    res.json({
        count: activeSessions.length,
        sessions: activeSessions
    });
});

// Cleanup old sessions periodically
setInterval(() => {
    const now = Date.now();
    const timeout = 5 * 60 * 1000; // 5 minutes
    
    for (const [key, session] of sessions.entries()) {
        if ((now - session.lastUpdate) > timeout) {
            sessions.delete(key);
            commandQueues.delete(key);
            console.log(`[Cleanup] Removed inactive session: ${key}`);
        }
    }
}, 60000); // Run every minute

module.exports = router;

// Usage in your main Express app:
/*
const express = require('express');
const app = express();
const syncApi = require('./sync-api');

app.use(express.json());
app.use('/api', syncApi);

// Serve static files
app.use(express.static('public'));

app.listen(3000, () => {
    console.log('Server running on port 3000');
});
*/