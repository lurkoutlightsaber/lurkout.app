// Appwrite Configuration
const APPWRITE_ENDPOINT = 'https://nyc.cloud.appwrite.io/v1';
const APPWRITE_PROJECT_ID = '6904e9f0002a87c6eb1f'; // Replace with your project ID
const DATABASE_ID = 'lurkout_db';
const COLLECTION_ID = 'webhook_data';

// Discord OAuth Configuration (Simplified - No backend needed!)
const DISCORD_CLIENT_ID = '1436115302336430161';
const DISCORD_REDIRECT_URI = window.location.origin; // Automatically uses your website URL

// Simplified OAuth URL using implicit grant (no backend needed)
const DISCORD_OAUTH_URL = `https://discord.com/oauth2/authorize?client_id=${DISCORD_CLIENT_ID}&redirect_uri=${encodeURIComponent(DISCORD_REDIRECT_URI)}&response_type=token&scope=identify+email+guilds`;

// Debug logging
console.log('=== LURKOUT Configuration ===');
console.log('Appwrite Endpoint:', APPWRITE_ENDPOINT);
console.log('Appwrite Project ID:', APPWRITE_PROJECT_ID);
console.log('Discord Client ID:', DISCORD_CLIENT_ID);
console.log('Redirect URI:', DISCORD_REDIRECT_URI);
console.log('OAuth URL:', DISCORD_OAUTH_URL);
console.log('============================');

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
const userEmail = document.getElementById('userEmail');
const discordId = document.getElementById('discordId');
const displayUserName = document.getElementById('displayUserName');
const displayUserEmail = document.getElementById('displayUserEmail');
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
    // Check if we have a token in the URL hash (from Discord OAuth redirect)
    const hash = window.location.hash;
    
    console.log('Checking for OAuth callback...');
    console.log('Current URL:', window.location.href);
    console.log('Hash:', hash);
    
    if (hash && hash.length > 1) {
        const params = new URLSearchParams(hash.substring(1));
        const accessToken = params.get('access_token');
        const error = params.get('error');
        
        console.log('Access Token:', accessToken ? 'Found' : 'Not found');
        console.log('Error:', error);
        
        if (error) {
            alert(`Discord OAuth Error: ${error}`);
            window.history.replaceState(null, null, window.location.pathname);
            return;
        }
        
        if (accessToken) {
            showLoading('Authenticating with Discord...');
            try {
                console.log('Fetching user data from Discord...');
                
                // Get Discord user info
                const discordUser = await getDiscordUser(accessToken);
                
                console.log('User data received:', discordUser);
                
                // Store token and user data
                localStorage.setItem('discord_token', accessToken);
                localStorage.setItem('discordUser', JSON.stringify(discordUser));
                currentUser = discordUser;
                
                // Create/login session in Appwrite
                await createAppwriteSession(discordUser);
                
                console.log('Session created successfully');
                
                // Clear the hash from URL
                window.history.replaceState(null, null, window.location.pathname);
                
                // Load dashboard
                await loadDashboard();
            } catch (error) {
                console.error('OAuth error:', error);
                hideLoading();
                alert(`Authentication failed: ${error.message}\n\nPlease check the browser console for more details.`);
                // Clear any partial data
                localStorage.removeItem('discord_token');
                localStorage.removeItem('discordUser');
            }
        }
    }
}

async function getDiscordUser(accessToken) {
    console.log('Making request to Discord API...');
    
    const response = await fetch('https://discord.com/api/users/@me', {
        headers: {
            'Authorization': `Bearer ${accessToken}`
        }
    });
    
    console.log('Discord API response status:', response.status);
    
    if (!response.ok) {
        const errorText = await response.text();
        console.error('Discord API error:', errorText);
        throw new Error(`Failed to get Discord user data (Status: ${response.status})`);
    }
    
    const data = await response.json();
    console.log('Discord user data:', data);
    
    return data;
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
    console.log('Checking for existing session in localStorage...');
    
    const storedUser = localStorage.getItem('discordUser');
    const storedToken = localStorage.getItem('discord_token');
    
    console.log('Stored user:', storedUser ? 'Found' : 'Not found');
    console.log('Stored token:', storedToken ? 'Found' : 'Not found');
    
    if (storedUser && storedToken) {
        try {
            currentUser = JSON.parse(storedUser);
            console.log('Loaded user from storage:', currentUser.username);
            await loadDashboard();
        } catch (error) {
            console.error('Error parsing stored user:', error);
            localStorage.removeItem('discordUser');
            localStorage.removeItem('discord_token');
        }
    } else {
        console.log('No existing session found');
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
    
    // Update user info in navbar
    userAvatar.src = currentUser.avatar 
        ? `https://cdn.discordapp.com/avatars/${currentUser.id}/${currentUser.avatar}.png`
        : 'https://cdn.discordapp.com/embed/avatars/0.png';
    userName.textContent = currentUser.username;
    userEmail.textContent = currentUser.email || 'No email provided';
    
    // Update user info in webhook section
    displayUserName.textContent = currentUser.username;
    displayUserEmail.textContent = currentUser.email || 'No email provided';
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
    console.log('Login button clicked');
    console.log('Redirecting to:', DISCORD_OAUTH_URL);
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
    console.log('=== LURKOUT Initializing ===');
    console.log('Current URL:', window.location.href);
    
    // FIRST: Check for OAuth callback (this must happen before checking existing session)
    await handleDiscordOAuth();
    
    // SECOND: If no OAuth callback, check for existing session
    if (!currentUser) {
        console.log('No OAuth callback, checking for existing session...');
        await checkExistingSession();
    }
    
    // THIRD: If still no user, show login page
    if (!currentUser) {
        console.log('No user found, showing login page');
        showPage(loginPage);
        hideLoading();
    } else {
        console.log('User found:', currentUser.username);
    }
})();

// Cleanup on page unload
window.addEventListener('beforeunload', () => {
    stopAutoRefresh();
});