Lurkout Website (Minimal demo)

What this provides
- SPA (static) located in `public/` with a glassmorphic dark UI inspired by the Lurkout loader.
- Uses Appwrite JS SDK for Discord OAuth login and to store "users" and "checkpoints" documents.
- Simple script-generator that produces a downloadable `.lua` file from a template.

Quick start (local/demo)
1. Serve the `public/` directory with any static server (or use GitHub Pages). Example (Python):

```powershell
# from repo root
cd .\public
python -m http.server 8080
# open http://localhost:8080
```

2. Configure Appwrite (recommended):
  - Create a project in Appwrite.
  - Create two collections: `users` and `checkpoints` (IDs as desired).
  - In `appwrite-config.example.json` copy values to your own config and paste them into the Settings panel in the SPA.
  - In Appwrite Console, enable OAuth provider `discord` and set the callback/redirect URL to your site URL (e.g., `http://localhost:8080`).

Live Server (VSCode) + PKCE (Discord OAuth) notes
- If you use Live Server (VSCode extension) or any local dev server, set that server's URL as the OAuth redirect in Appwrite's Discord provider settings.
- Appwrite uses PKCE (proof key for code exchange) under the hood for OAuth flows; you do not need to manually implement PKCE in the SPA. Ensure the redirect URL configured in Discord and Appwrite match exactly (including scheme and port).

Local loader key / secret (testing only)
- The loader API key / secret is sensitive and should never be committed. For quick local testing you can store it in an environment file or in browser localStorage, but only on your private machine. Example `.env` variables (do NOT commit):

```
APPWRITE_PROJECT_ID=6904e9f0002a87c6eb1f
LOADER_API_KEY=<your_loader_api_key_here>
```

- The client-side SPA will not include the loader secret. If you need server-side operations that require the LOADER_API_KEY (for example, creating Appwrite documents with elevated privileges), run those operations from a server or Appwrite Function that reads the key from environment variables.

Important security note
- Do NOT commit the loader API key or other secrets to the repository. Use `.env` or Appwrite functions to keep secrets server-side. The repository contains a sample Appwrite project id for convenience, but not the loader secret.

Notes & next steps
- This is a minimal demo that includes clear spots to replace with production flows:
  - Replace localStorage fallbacks (demo) with real Appwrite documents and server-side session verification if needed.
  - Move secrets (if any) to environment variables in your deployment.
  - Add access rules to the Appwrite collections and enable JWT/session verification for sensitive operations.

If you want, I can:
- Add a simple serverless Appwrite function that generates signed script download links.
- Add a `dev-server.js` that provides the same demo endpoints locally.
