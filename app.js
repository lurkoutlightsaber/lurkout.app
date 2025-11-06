// Appwrite Configuration
const APPWRITE_ENDPOINT = 'https://nyc.cloud.appwrite.io/v1';
const APPWRITE_PROJECT_ID = '6904e9f0002a87c6eb1f'; // Replace with your project ID
const DATABASE_ID = 'lurkout_db';
const COLLECTION_ID = 'webhook_data';

// Discord OAuth Configuration
const DISCORD_CLIENT_ID = '1436115302336430161'; // Replace with your Discord OAuth Client ID
const DISCORD_REDIRECT_URI = window.location.origin; // Your website URL
const DISCORD_OAUTH_URL = `https://discord.com/oauth2/authorize?client_id=1436115302336430161&response_type=code&redirect_uri=https%3A%2F%2Flurkout.app&scope=identify+email+guilds.join+guilds+guilds.channels.read+gdm.join+messages.read`;

// Initialize Appwrite
const client = new Appwrite.Client();
client
    .setEndpoint(APPWRITE_ENDPOINT)
    .setProject(APPWRITE_PROJECT_ID);

const account = new Appwrite.Account(client);
const databases = new Appwrite.Databases(client);

// State management
let currentUser = null;
let autoRefreshInterval = null;

// DOM Elements
const loginPage = document.getElementById('loginPage');
const dashboardPage = document.getElementById('dashboardPage');
const discordLoginBtn = document.getElementById('discordLoginBtn');
const logoutBtn = document.getElementById('logoutBtn');
const loadingOverlay = document.getElementById('loadingOverlay');
const userAvatar = document.getElementById('userAvatar');
const userName = document.getElementById('userName');
const discordId = document.getElementById('discordId');
const channelId = document.getElementById('channelId');
const webhookUrl = document.getElementById('webhookUrl');
const totalData = document.getElementById('totalData');
const lastUpdate = document.getElementById('lastUpdate');
const dataContainer = document.getElementById('dataContainer');
const refreshBtn = document.getElementById('refreshBtn');
const autoRefreshToggle = document.getElementById('autoRefreshToggle');

// Utility Functions
function showLoading(text = 'Loading...') {
    loadingOverlay.querySelector('.loading-text').textContent = text;
    loadingOverlay.classList.add('active');
}

function hideLoading() {
    loadingOverlay.classList.remove('active');
}

function showPage(page) {
    loginPage.classList.remove('active');
    dashboardPage.classList.remove('active');
    page.classList.add('active');
}

function formatTimestamp(timestamp) {
    const date = new Date(timestamp);
    return date.toLocaleString();
}

function formatRelativeTime(timestamp) {
    const now = new Date();
    const date = new Date(timestamp);
    const seconds = Math.floor((now - date) / 1000);
    
    if (seconds < 60) return `${seconds}s ago`;
    if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
    if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`;
    return `${Math.floor(seconds / 86400)}d ago`;
}

// Authentication Functions
async function handleDiscordOAuth() {
    // Check if we have a token in the URL hash
    const hash = window.location.hash;
    if (hash) {
        const params = new URLSearchParams(hash.substring(1));
        const accessToken = params.get('access_token');
        
        if (accessToken) {
            showLoading('Authenticating with Discord...');
            try {
                // Get Discord user info
                const discordUser = await getDiscordUser(accessToken);
                
                // Create/login session in Appwrite
                await createAppwriteSession(discordUser);
                
                // Clear the hash from URL
                window.history.replaceState(null, null, window.location.pathname);
                
                // Load dashboard
                await loadDashboard();
            } catch (error) {
                console.error('OAuth error:', error);
                alert('Authentication failed. Please try again.');
                hideLoading();
            }
        }
    }
}

async function getDiscordUser(accessToken) {
    const response = await fetch('https://discord.com/api/users/@me', {
        headers: {
            'Authorization': `Bearer ${accessToken}`
        }
    });
    
    if (!response.ok) {
        throw new Error('Failed to get Discord user');
    }
    
    return await response.json();
}

async function createAppwriteSession(discordUser) {
    try {
        // Try to create an anonymous session first
        // In production, you'd want to use proper authentication
        // For now, we'll store the Discord user info in localStorage
        localStorage.setItem('discordUser', JSON.stringify(discordUser));
        currentUser = discordUser;
    } catch (error) {
        console.error('Session creation error:', error);
        throw error;
    }
}

async function checkExistingSession() {
    const storedUser = localStorage.getItem('discordUser');
    if (storedUser) {
        currentUser = JSON.parse(storedUser);
        await loadDashboard();
    }
}

function logout() {
    localStorage.removeItem('discordUser');
    currentUser = null;
    stopAutoRefresh();
    showPage(loginPage);
}

// Dashboard Functions
async function loadDashboard() {
    if (!currentUser) {
        showPage(loginPage);
        return;
    }
    
    showLoading('Loading dashboard...');
    
    // Update user info
    userAvatar.src = currentUser.avatar 
        ? `https://cdn.discordapp.com/avatars/${currentUser.id}/${currentUser.avatar}.png`
        : 'https://cdn.discordapp.com/embed/avatars/0.png';
    userName.textContent = currentUser.username;
    discordId.textContent = currentUser.id;
    
    // Load data
    await loadWebhookData();
    
    showPage(dashboardPage);
    hideLoading();
    
    // Start auto-refresh if enabled
    if (autoRefreshToggle.checked) {
        startAutoRefresh();
    }
}

async function loadWebhookData() {
    try {
        // In a real implementation, you'd fetch from Appwrite
        // For now, we'll simulate with mock data
        const data = await fetchDataFromAppwrite();
        
        displayData(data);
        updateStats(data);
    } catch (error) {
        console.error('Error loading data:', error);
        displayNoData();
    }
}

async function fetchDataFromAppwrite() {
    try {
        // Fetch documents from Appwrite
        const response = await databases.listDocuments(
            DATABASE_ID,
            COLLECTION_ID,
            [
                Appwrite.Query.equal('user_discord_id', currentUser.id),
                Appwrite.Query.orderDesc('timestamp'),
                Appwrite.Query.limit(50)
            ]
        );
        
        return response.documents;
    } catch (error) {
        console.error('Appwrite fetch error:', error);
        // Return empty array if there's an error
        return [];
    }
}

function displayData(dataArray) {
    if (!dataArray || dataArray.length === 0) {
        displayNoData();
        return;
    }
    
    dataContainer.innerHTML = '';
    
    dataArray.forEach(item => {
        const dataItem = createDataItem(item);
        dataContainer.appendChild(dataItem);
    });
}

function createDataItem(data) {
    const div = document.createElement('div');
    div.className = 'data-item';
    
    let content;
    try {
        // Parse the content if it's a JSON string
        const parsedContent = typeof data.content === 'string' 
            ? JSON.parse(data.content) 
            : data.content;
        content = JSON.stringify(parsedContent, null, 2);
    } catch (e) {
        content = data.content;
    }
    
    div.innerHTML = `
        <div class="data-header">
            <span class="data-timestamp">${formatTimestamp(data.timestamp)}</span>
            <span class="data-badge">${formatRelativeTime(data.timestamp)}</span>
        </div>
        <div class="data-content">${escapeHtml(content)}</div>
    `;
    
    return div;
}

function displayNoData() {
    dataContainer.innerHTML = `
        <div class="no-data">
            <div class="no-data-icon">📭</div>
            <p>No data received yet</p>
            <p class="no-data-sub">Configure your Luau script and send test data to see it here</p>
        </div>
    `;
}

function updateStats(dataArray) {
    totalData.textContent = dataArray.length;
    
    if (dataArray.length > 0) {
        const latestData = dataArray[0];
        lastUpdate.textContent = formatRelativeTime(latestData.timestamp);
    } else {
        lastUpdate.textContent = 'Never';
    }
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// Auto-refresh functionality
function startAutoRefresh() {
    stopAutoRefresh();
    autoRefreshInterval = setInterval(() => {
        loadWebhookData();
    }, 5000); // Refresh every 5 seconds
}

function stopAutoRefresh() {
    if (autoRefreshInterval) {
        clearInterval(autoRefreshInterval);
        autoRefreshInterval = null;
    }
}

// Event Listeners
discordLoginBtn.addEventListener('click', () => {
    window.location.href = DISCORD_OAUTH_URL;
});

logoutBtn.addEventListener('click', logout);

refreshBtn.addEventListener('click', async () => {
    showLoading('Refreshing data...');
    await loadWebhookData();
    hideLoading();
});

autoRefreshToggle.addEventListener('change', (e) => {
    if (e.target.checked) {
        startAutoRefresh();
    } else {
        stopAutoRefresh();
    }
});

// Initialize
(async function init() {
    // Check for OAuth callback
    await handleDiscordOAuth();
    
    // Check for existing session
    await checkExistingSession();
    
    // If no session, show login page
    if (!currentUser) {
        showPage(loginPage);
    }
})();

// Cleanup on page unload
window.addEventListener('beforeunload', () => {
    stopAutoRefresh();
});