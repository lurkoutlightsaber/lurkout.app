// Checkpoint verification and tracking
const express = require('express');
const router = express.Router();
const { Client, Databases } = require('node-appwrite');

// Initialize Appwrite
const client = new Client();
client.setEndpoint('https://cloud.appwrite.io/v1');
client.setProject(process.env.APPWRITE_PROJECT_ID);
client.setKey(process.env.APPWRITE_API_KEY);

const databases = new Databases(client);

// Verify checkpoint completion
router.post('/verify/:pageId/:checkpointId', async (req, res) => {
  try {
    const { pageId, checkpointId } = req.params;
    const { proofToken } = req.body; // From linkvertise/work.ink callback
    
    // Verify with service API (example for linkvertise)
    const verified = await verifyCompletion(checkpointId, proofToken);
    if (!verified) {
      return res.status(400).json({ error: 'Invalid completion' });
    }

    // Record completion in Appwrite
    await databases.createDocument('completions', 'unique()', {
      pageId,
      checkpointId,
      timestamp: new Date().toISOString(),
      // Add user/session info if needed
    });

    res.json({ success: true });
  } catch (err) {
    console.error('Checkpoint verify error:', err);
    res.status(500).json({ error: 'Verification failed' });
  }
});

// Check overall completion status
router.get('/status/:pageId', async (req, res) => {
  try {
    const { pageId } = req.params;
    
    // Get page details
    const page = await databases.getDocument('pages', pageId);
    
    // Get all completions for this page
    const completions = await databases.listDocuments('completions', [
      Query.equal('pageId', pageId)
    ]);

    // Map checkpoint completion status
    const status = page.checkpoints.map(cp => ({
      id: cp.$id,
      service: cp.service,
      completed: completions.documents.some(c => c.checkpointId === cp.$id)
    }));

    res.json({
      pageId,
      complete: status.every(s => s.completed),
      checkpoints: status
    });
  } catch (err) {
    console.error('Status check error:', err);
    res.status(500).json({ error: 'Status check failed' });
  }
});

// Service-specific verification
async function verifyCompletion(checkpointId, proofToken) {
  // Implementation varies by service (linkvertise, work.ink etc)
  // This is a placeholder - implement actual API calls
  return true; 
}

module.exports = router;