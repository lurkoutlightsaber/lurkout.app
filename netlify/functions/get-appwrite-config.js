exports.handler = async function(event, context) {
  try {
    return {
      statusCode: 200,
      body: JSON.stringify({
        APPWRITE_PROJECT_ID: process.env.APPWRITE_PROJECT_ID,
        APPWRITE_API_KEY: process.env.APPWRITE_API_KEY,
        COLLECTION_ID: process.env.COLLECTION_ID
      })
    };
  } catch (err) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Failed to load configuration' })
    };
  }
}