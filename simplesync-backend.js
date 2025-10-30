// ============================================
// SIMPLE SYNC SYSTEM
// Add this to your existing auth-handler.js or create new file
// ============================================

// In-memory storage (simple, no database needed)
const syncData = new Map();

// POST /update-sync - Receive game data from Lua
router.post('/update-sync', (req, res) => {
    try {
        const { key, placeName, placeId, tree, time } = req.body;
        
        if (!key) {
            return res.status(400).json({ error: 'No key provided' });
        }
        
        // Store the data
        syncData.set(key, {
            placeName,
            placeId,
            tree,
            time,
            lastUpdate: Date.now()
        });
        
        console.log(`[Sync] Updated data for key: ${key.substring(0, 8)}...`);
        res.json({ success: true });
        
    } catch (error) {
        console.error('[Sync] Error:', error);
        res.status(500).json({ error: 'Server error' });
    }
});

// GET /get-sync/:key - Get game data for display on website
router.get('/get-sync/:key', (req, res) => {
    const key = req.params.key;
    
    if (!key) {
        return res.status(400).json({ error: 'No key provided' });
    }
    
    const data = syncData.get(key);
    
    if (!data) {
        return res.json({ connected: false });
    }
    
    // Check if data is recent (within last 10 seconds)
    const isRecent = (Date.now() - data.lastUpdate) < 10000;
    
    res.json({
        connected: isRecent,
        placeName: data.placeName,
        placeId: data.placeId,
        tree: data.tree,
        lastUpdate: data.lastUpdate
    });
});

// Cleanup old data every minute
setInterval(() => {
    const now = Date.now();
    for (const [key, data] of syncData.entries()) {
        if (now - data.lastUpdate > 300000) { // 5 minutes
            syncData.delete(key);
            console.log(`[Sync] Cleaned up old key: ${key.substring(0, 8)}...`);
        }
    }
}, 60000);

// ============================================
// That's it! Just 2 endpoints.
// ============================================

module.exports = router;