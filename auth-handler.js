// auth-handler.js - Server-side Discord OAuth handler
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
    API_ENDPOINT: 'https://discord.com/api/v10'
};

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

module.exports = router;
