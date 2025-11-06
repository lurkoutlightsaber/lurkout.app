// oauth-backend.js
// This is a simple Node.js backend to securely handle Discord OAuth
// Deploy this separately (e.g., on Vercel, Netlify Functions, or any Node.js server)

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const fetch = require('node-fetch');

const app = express();

// Enable CORS for your frontend
app.use(cors({
    origin: process.env.FRONTEND_URL || 'https://lurkout.app', // Change to your domain
    credentials: true
}));

app.use(express.json());

// Discord OAuth Configuration - READ FROM ENVIRONMENT VARIABLES
const DISCORD_CLIENT_ID = process.env.DISCORD_CLIENT_ID || '1436115302336430161';
const DISCORD_CLIENT_SECRET = process.env.DISCORD_CLIENT_SECRET; // MUST be set in environment
const DISCORD_REDIRECT_URI = process.env.DISCORD_REDIRECT_URI || 'https://lurkout.app';

// Validate environment variables on startup
if (!DISCORD_CLIENT_SECRET) {
    console.error('❌ ERROR: DISCORD_CLIENT_SECRET environment variable is not set!');
    console.error('Please set it in your deployment platform:');
    console.error('- GitHub Actions: Settings → Secrets → DISCORD_CLIENT_SECRET');
    console.error('- Vercel: Project Settings → Environment Variables');
    console.error('- Netlify: Site Settings → Environment Variables');
    console.error('- Local: Create a .env file with DISCORD_CLIENT_SECRET=your_secret');
    process.exit(1);
}

console.log('✅ Environment variables loaded:');
console.log(`   DISCORD_CLIENT_ID: ${DISCORD_CLIENT_ID}`);
console.log(`   DISCORD_CLIENT_SECRET: ${DISCORD_CLIENT_SECRET ? '***' + DISCORD_CLIENT_SECRET.slice(-4) : 'NOT SET'}`);
console.log(`   DISCORD_REDIRECT_URI: ${DISCORD_REDIRECT_URI}`);

// Endpoint to exchange code for token
app.post('/api/discord/token', async (req, res) => {
    try {
        const { code } = req.body;
        
        if (!code) {
            return res.status(400).json({ error: 'Code is required' });
        }
        
        // Exchange code for access token
        const tokenResponse = await fetch('https://discord.com/api/oauth2/token', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded'
            },
            body: new URLSearchParams({
                client_id: DISCORD_CLIENT_ID,
                client_secret: DISCORD_CLIENT_SECRET,
                grant_type: 'authorization_code',
                code: code,
                redirect_uri: DISCORD_REDIRECT_URI
            })
        });
        
        if (!tokenResponse.ok) {
            const error = await tokenResponse.text();
            console.error('Token exchange error:', error);
            return res.status(tokenResponse.status).json({ error: 'Failed to exchange code' });
        }
        
        const tokenData = await tokenResponse.json();
        
        // Get user data
        const userResponse = await fetch('https://discord.com/api/users/@me', {
            headers: {
                'Authorization': `Bearer ${tokenData.access_token}`
            }
        });
        
        if (!userResponse.ok) {
            return res.status(userResponse.status).json({ error: 'Failed to get user data' });
        }
        
        const userData = await userResponse.json();
        
        // Return both token and user data
        res.json({
            access_token: tokenData.access_token,
            refresh_token: tokenData.refresh_token,
            expires_in: tokenData.expires_in,
            user: userData
        });
        
    } catch (error) {
        console.error('OAuth error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Endpoint to refresh token
app.post('/api/discord/refresh', async (req, res) => {
    try {
        const { refresh_token } = req.body;
        
        if (!refresh_token) {
            return res.status(400).json({ error: 'Refresh token is required' });
        }
        
        const tokenResponse = await fetch('https://discord.com/api/oauth2/token', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded'
            },
            body: new URLSearchParams({
                client_id: DISCORD_CLIENT_ID,
                client_secret: DISCORD_CLIENT_SECRET,
                grant_type: 'refresh_token',
                refresh_token: refresh_token
            })
        });
        
        if (!tokenResponse.ok) {
            return res.status(tokenResponse.status).json({ error: 'Failed to refresh token' });
        }
        
        const tokenData = await tokenResponse.json();
        res.json(tokenData);
        
    } catch (error) {
        console.error('Token refresh error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ 
        status: 'ok',
        hasClientSecret: !!DISCORD_CLIENT_SECRET,
        clientId: DISCORD_CLIENT_ID
    });
});

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
    console.log(`✅ OAuth backend running on port ${PORT}`);
    console.log(`🔗 Health check: http://localhost:${PORT}/health`);
});

module.exports = app;