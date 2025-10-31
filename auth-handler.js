// auth-handler.js - Server-side Discord OAuth handler + Sync Endpoints
// Deploy this to your server (Node.js/Express example)

const express = require('express');
const fetch = require('node-fetch');
const router = express.Router();

const CONFIG = {
    DISCORD_CLIENT_ID: '1432798922757115985',
    DISCORD_CLIENT_SECRET: process.env.DISCORD_CLIENT_SECRET, // Store securely!
    REDIRECT_URI: 'https://lurkout.app/auth/callback',
    REQUIRED_SERVER_ID: '1431480103686246420',
    REQUIRED_ROLE_ID: '1433579851259838464',
    API_ENDPOINT: 'https://discord.com/api/v10',
    // Appwrite Configuration
    APPWRITE_PROJECT_ID: '6904e9f0002a87c6eb1f',
    APPWRITE_DATABASE_ID: 'lurkout-db',
    APPWRITE_USERS_COLLECTION: 'users',
    APPWRITE_PLAYERS_COLLECTION: 'player_lists',
    APPWRITE_API_KEY: 'standard_3b70cbb723e21a8ac2fa83cdb599637b92dfcbd36261b0dd7d4e52a8aa89446a60c45c89017f9681eedb0984bca0b7879ca3c97587522369c92d05a8988a5129033c557a000509e5deb699146e529bdae1cdfd04681e6d147135c6c81da47737f2ab5a50fce96c6b1d3d87cf762236fcd82dd9ef7896a13a06963990c84bd2a6E',
    APPWRITE_ENDPOINT: 'https://cloud.appwrite.io/v1'
};

// ============================================
// SYNC DATA STORAGE
// ============================================
const activeSessions = new Map();

// Clean up old sessions every minute
setInterval(() => {
    const now = Date.now();
    for (const [key, data] of activeSessions.entries()) {
        if (now - data.lastUpdate > 300000) { // 5 minutes
            activeSessions.delete(key);
            console.log(`[Sync] Cleaned up inactive session: ${key.substring(0, 8)}...`);
        }
    }
}, 60000);

// ============================================
// DISCORD OAUTH ENDPOINTS
// ============================================

// OAuth callback endpoint
router.get('/auth/callback', async (req, res) => {
    const { code } = req.query;

    if (!code) {
        return res.redirect('/?error=no_code');
    }

    try {
        // Exchange code for token
        const tokenResponse = await fetch(`${CONFIG.API_ENDPOINT}/oauth2/token`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: new URLSearchParams({
                client_id: CONFIG.DISCORD_CLIENT_ID,
                client_secret: CONFIG.DISCORD_CLIENT_SECRET,
                grant_type: 'authorization_code',
                code: code,
                redirect_uri: CONFIG.REDIRECT_URI
            })
        });

        if (!tokenResponse.ok) {
            throw new Error('Token exchange failed');
        }

        const tokenData = await tokenResponse.json();
        const accessToken = tokenData.access_token;

        // Fetch user info
        const userResponse = await fetch(`${CONFIG.API_ENDPOINT}/users/@me`, {
            headers: {
                'Authorization': `Bearer ${accessToken}`
            }
        });

        if (!userResponse.ok) {
            throw new Error('Failed to fetch user info');
        }

        const user = await userResponse.json();

        // Check server membership
        const guildsResponse = await fetch(`${CONFIG.API_ENDPOINT}/users/@me/guilds`, {
            headers: {
                'Authorization': `Bearer ${accessToken}`
            }
        });

        if (!guildsResponse.ok) {
            throw new Error('Failed to fetch guilds');
        }

        const guilds = await guildsResponse.json();
        const inServer = guilds.some(guild => guild.id === CONFIG.REQUIRED_SERVER_ID);

        if (!inServer) {
            return res.redirect('/?error=not_in_server');
        }

        // Check role (requires bot to be in server with proper permissions)
        const memberResponse = await fetch(
            `${CONFIG.API_ENDPOINT}/guilds/${CONFIG.REQUIRED_SERVER_ID}/members/${user.id}`,
            {
                headers: {
                    'Authorization': `Bot ${process.env.DISCORD_BOT_TOKEN}`
                }
            }
        );

        if (!memberResponse.ok) {
            throw new Error('Failed to fetch member info');
        }

        const member = await memberResponse.json();
        const hasRole = member.roles.includes(CONFIG.REQUIRED_ROLE_ID);

        if (!hasRole) {
            return res.redirect('/?error=no_role');
        }

        // Create session
        req.session.user = {
            id: user.id,
            username: user.username,
            discriminator: user.discriminator,
            avatar: user.avatar,
            accessToken: accessToken,
            verified: true
        };

        // Redirect to success
        res.redirect('/?auth=success');

    } catch (error) {
        console.error('Auth error:', error);
        res.redirect('/?error=auth_failed');
    }
});

// Get current user endpoint
router.get('/api/me', (req, res) => {
    if (!req.session.user) {
        return res.status(401).json({ error: 'Not authenticated' });
    }

    res.json({
        id: req.session.user.id,
        username: req.session.user.username,
        discriminator: req.session.user.discriminator,
        avatar: req.session.user.avatar,
        verified: req.session.user.verified
    });
});

// Logout endpoint
router.post('/api/logout', (req, res) => {
    req.session.destroy();
    res.json({ success: true });
});

// Verify session endpoint
router.get('/api/verify', async (req, res) => {
    if (!req.session.user) {
        return res.status(401).json({ error: 'Not authenticated' });
    }

    try {
        // Re-verify role (optional, can be done periodically)
        const memberResponse = await fetch(
            `${CONFIG.API_ENDPOINT}/guilds/${CONFIG.REQUIRED_SERVER_ID}/members/${req.session.user.id}`,
            {
                headers: {
                    'Authorization': `Bot ${process.env.DISCORD_BOT_TOKEN}`
                }
            }
        );

        if (!memberResponse.ok) {
            throw new Error('Failed to verify member');
        }

        const member = await memberResponse.json();
        const hasRole = member.roles.includes(CONFIG.REQUIRED_ROLE_ID);

        res.json({
            verified: hasRole,
            user: req.session.user
        });

    } catch (error) {
        console.error('Verification error:', error);
        res.status(500).json({ error: 'Verification failed' });
    }
});

// ============================================
// SYNC ENDPOINTS (NEW)
// ============================================

// POST /update-sync - Receive game data from Lua
router.post('/update-sync', express.json(), (req, res) => {
    try {
        const { key, placeName, placeId, tree, time } = req.body;
        
        console.log('[Sync] Received update request:', {
            hasKey: !!key,
            placeName,
            placeId,
            treeLength: tree ? tree.length : 0
        });
        
        if (!key) {
            console.log('[Sync] ✗ No session key provided');
            return res.status(400).json({ error: 'No session key provided' });
        }
        
        // Store the data
        activeSessions.set(key, {
            placeName: placeName || 'Unknown',
            placeId: placeId || 0,
            tree: tree || [],
            time: time || Date.now(),
            lastUpdate: Date.now(),
            connected: true
        });
        
        console.log(`[Sync] ✓ Stored data for key: ${key.substring(0, 8)}... (${placeName || 'Unknown'})`);
        
        res.json({ 
            success: true,
            message: 'Data received and stored'
        });
        
    } catch (error) {
        console.error('[Sync] ✗ Error receiving data:', error);
        res.status(500).json({ error: 'Server error: ' + error.message });
    }
});

// GET /get-sync/:key - Frontend polls for game data
router.get('/get-sync/:key', (req, res) => {
    try {
        const key = req.params.key;
        
        if (!key) {
            return res.status(400).json({ error: 'No session key provided' });
        }
        
        const sessionData = activeSessions.get(key);
        
        if (!sessionData) {
            return res.json({ 
                connected: false,
                message: 'Waiting for executor connection...'
            });
        }
        
        // Check if data is recent (within last 10 seconds)
        const isRecent = (Date.now() - sessionData.lastUpdate) < 10000;
        
        if (isRecent) {
            res.json({
                connected: true,
                placeName: sessionData.placeName,
                placeId: sessionData.placeId,
                tree: sessionData.tree,
                lastUpdate: sessionData.lastUpdate
            });
        } else {
            res.json({
                connected: false,
                message: 'Session timed out (no data in last 10 seconds)'
            });
        }
        
    } catch (error) {
        console.error('[Sync] Error fetching data:', error);
        res.status(500).json({ error: 'Server error' });
    }
});

// GET /test-sync - Test endpoint to verify sync is working
router.get('/test-sync', (req, res) => {
    const sessions = [];
    for (const [key, data] of activeSessions.entries()) {
        sessions.push({
            key: key.substring(0, 8) + '...',
            placeName: data.placeName,
            lastUpdate: new Date(data.lastUpdate).toISOString(),
            ageSeconds: Math.floor((Date.now() - data.lastUpdate) / 1000)
        });
    }
    
    res.json({
        success: true,
        message: 'Sync endpoints are working!',
        activeSessions: activeSessions.size,
        sessions: sessions,
        timestamp: new Date().toISOString()
    });
});

// ============================================
// APPWRITE PROXY ENDPOINTS (for Lua loader)
// ============================================

// POST /api/appwrite/users - Create user document (proxied from Lua)
router.post('/api/appwrite/users', express.json(), async (req, res) => {
    try {
        const { user_key, username } = req.body;
        
        if (!user_key || !username) {
            return res.status(400).json({ error: 'user_key and username are required' });
        }

        const url = `${CONFIG.APPWRITE_ENDPOINT}/databases/${CONFIG.APPWRITE_DATABASE_ID}/collections/${CONFIG.APPWRITE_USERS_COLLECTION}/documents`;
        
        const response = await fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-Appwrite-Project': CONFIG.APPWRITE_PROJECT_ID,
                'X-Appwrite-Key': CONFIG.APPWRITE_API_KEY
            },
            body: JSON.stringify({
                documentId: 'unique()',
                data: {
                    user_key: user_key,
                    username: username,
                    is_active: true,
                    last_active: new Date().toISOString()
                }
            })
        });

        if (!response.ok) {
            const errorText = await response.text();
            console.error('[Appwrite] Create user failed:', response.status, errorText);
            return res.status(response.status).json({ 
                error: 'Failed to create user document',
                details: errorText 
            });
        }

        const data = await response.json();
        console.log(`[Appwrite] ✓ Created user document for key: ${user_key.substring(0, 8)}...`);
        
        res.json({ success: true, data: data });
        
    } catch (error) {
        console.error('[Appwrite] ✗ Error creating user:', error);
        res.status(500).json({ error: 'Server error: ' + error.message });
    }
});

// POST /api/appwrite/players - Send player list (proxied from Lua)
router.post('/api/appwrite/players', express.json(), async (req, res) => {
    try {
        const { user_key, game_name, players, timestamp } = req.body;
        
        if (!user_key) {
            return res.status(400).json({ error: 'user_key is required' });
        }

        const url = `${CONFIG.APPWRITE_ENDPOINT}/databases/${CONFIG.APPWRITE_DATABASE_ID}/collections/${CONFIG.APPWRITE_PLAYERS_COLLECTION}/documents`;
        
        const response = await fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-Appwrite-Project': CONFIG.APPWRITE_PROJECT_ID,
                'X-Appwrite-Key': CONFIG.APPWRITE_API_KEY
            },
            body: JSON.stringify({
                documentId: 'unique()',
                data: {
                    user_key: user_key,
                    game_name: game_name || 'Unknown Place',
                    players: typeof players === 'string' ? players : JSON.stringify(players || []),
                    timestamp: timestamp || new Date().toISOString()
                }
            })
        });

        if (!response.ok) {
            const errorText = await response.text();
            console.error('[Appwrite] Send players failed:', response.status, errorText);
            return res.status(response.status).json({ 
                error: 'Failed to send player list',
                details: errorText 
            });
        }

        const data = await response.json();
        console.log(`[Appwrite] ✓ Sent player list for key: ${user_key.substring(0, 8)}...`);
        
        res.json({ success: true, data: data });
        
    } catch (error) {
        console.error('[Appwrite] ✗ Error sending players:', error);
        res.status(500).json({ error: 'Server error: ' + error.message });
    }
});

console.log('[Auth] Discord OAuth endpoints initialized');
console.log('[Sync] Sync endpoints initialized: POST /update-sync, GET /get-sync/:key, GET /test-sync');
console.log('[Appwrite] Proxy endpoints initialized: POST /api/appwrite/users, POST /api/appwrite/players');

module.exports = router;