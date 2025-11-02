// Minimal client logic for Lurkout demo
(function(){
  const client = new appwrite.Appwrite();

  // Load saved config (simple, localStorage)
  const cfg = JSON.parse(localStorage.getItem('lurkout_cfg')||'{}');
  const endpointInput = document.getElementById('cfgEndpoint');
  const projectInput = document.getElementById('cfgProject');
  const dbInput = document.getElementById('cfgDatabase');

  endpointInput.value = cfg.endpoint || 'https://cloud.appwrite.io/v1';
  // Prefill known project id provided by user (safe to include project id client-side)
  projectInput.value = cfg.project || '6904e9f0002a87c6eb1f';
  dbInput.value = cfg.database || '';

  function saveCfg(){
    const c = {endpoint:endpointInput.value.trim(), project:projectInput.value.trim(), database:dbInput.value.trim()};
    localStorage.setItem('lurkout_cfg', JSON.stringify(c));
    initClient();
    alert('Saved config (demo only)');
  }

  document.getElementById('saveCfg').onclick = saveCfg;
  document.getElementById('resetCfg').onclick = ()=>{localStorage.removeItem('lurkout_cfg');location.reload()};

  function initClient(){
    const c = JSON.parse(localStorage.getItem('lurkout_cfg')||'{}');
    client.setEndpoint(c.endpoint||'https://cloud.appwrite.io/v1').setProject(c.project||'');
    window._LurkoutAppwrite = {client, databaseId: c.database||''};
  }

  initClient();

  // UI references
  const btnLogin = document.getElementById('btnLogin');
  const btnLogout = document.getElementById('btnLogout');
  const userArea = document.getElementById('userArea');
  const accountInfo = document.getElementById('accountInfo');
  const emailInput = document.getElementById('emailInput');
  const attachEmail = document.getElementById('attachEmail');

  const saveCheckpoint = document.getElementById('saveCheckpoint');
  const listCheckpoints = document.getElementById('listCheckpoints');
  const checkpointList = document.getElementById('checkpointList');

  const generateScript = document.getElementById('generateScript');
  const publishLink = document.getElementById('publishLink');
  const scriptPreview = document.getElementById('scriptPreview');
  const downloadLink = document.getElementById('downloadLink');

  // Simple auth helpers (Appwrite OAuth via Discord)
  function isLoggedIn(){
    return !!localStorage.getItem('lurkout_user');
  }

  function renderAuth(){
    const user = JSON.parse(localStorage.getItem('lurkout_user')||'null');
    if(user){
      userArea.innerHTML = `<div class="user">${user.name || user.$id}</div>`;
      btnLogin.classList.add('hidden');
      btnLogout.classList.remove('hidden');
      accountInfo.textContent = `Signed in: ${user.name || user.$id} • verified: ${user.email ? 'yes' : 'no'}`;
    } else {
      userArea.innerHTML = '';
      btnLogin.classList.remove('hidden');
      btnLogout.classList.add('hidden');
      accountInfo.textContent = '';
    }
  }

  btnLogin.onclick = function(){
    const c = JSON.parse(localStorage.getItem('lurkout_cfg')||'{}');
    if(!c.project){alert('Set Project ID and Database ID in Settings first');return}
    // Create OAuth session with Discord via Appwrite
    try{
      client.account.createOAuth2Session('discord', window.location.href, window.location.href);
    }catch(e){
      console.warn('OAuth redirect',e);
      // Some Appwrite versions use createOAuth2Session differently; the redirect will handle auth
    }
  };

  btnLogout.onclick = function(){ localStorage.removeItem('lurkout_user'); renderAuth(); }

  // On page load, try to get account info (after redirect)
  async function tryGetAccount(){
    try{
      const acc = await client.account.get();
      const user = {name: acc.name||acc.$id, email: acc.email||null, id:acc.$id};
      localStorage.setItem('lurkout_user', JSON.stringify(user));
      renderAuth();
    }catch(e){
      // not logged in
      renderAuth();
    }
  }

  // Attach email flow: store in Appwrite users collection (demo: store locally if Appwrite not configured)
  attachEmail.onclick = async function(){
    const email = emailInput.value.trim();
    if(!email){alert('Enter an email');return}
    const user = JSON.parse(localStorage.getItem('lurkout_user')||'null');
    if(!user){alert('Sign in first');return}
    // If Appwrite configured, write to database, else store locally
    const ctx = window._LurkoutAppwrite;
    if(ctx && ctx.databaseId){
      const databases = new appwrite.Databases(client);
      try{
        await databases.createDocument(ctx.databaseId, 'users', 'unique()', {userId:user.id, email:email});
        alert('Email attached');
        user.email = email; localStorage.setItem('lurkout_user', JSON.stringify(user)); renderAuth();
      }catch(err){console.error(err); alert('Failed to attach email: '+(err.message||err));}
    }else{
      // demo fallback
      user.email = email; localStorage.setItem('lurkout_user', JSON.stringify(user)); renderAuth(); alert('Saved locally (demo)');
    }
  }

  // Checkpoints: save and list
  async function saveCheckpointFlow(){
    const user = JSON.parse(localStorage.getItem('lurkout_user')||'null');
    if(!user){alert('Sign in to save checkpoints');return}
    const name = document.getElementById('checkpointName').value.trim()||('cp-'+Date.now());
    const notes = document.getElementById('checkpointNotes').value.trim()||'';
    const payload = {userId:user.id, name, notes, ts: Date.now()};
    const ctx = window._LurkoutAppwrite;
    if(ctx && ctx.databaseId){
      const databases = new appwrite.Databases(client);
      try{ await databases.createDocument(ctx.databaseId, 'checkpoints', 'unique()', payload); alert('Saved'); listCheckpointsFlow(); }
      catch(e){console.error(e); alert('Save failed: '+(e.message||e));}
    }else{
      // demo local storage
      const arr = JSON.parse(localStorage.getItem('lurkout_checkpoints_'+user.id)||'[]'); arr.push(payload); localStorage.setItem('lurkout_checkpoints_'+user.id, JSON.stringify(arr)); alert('Saved locally (demo)'); listCheckpointsFlow();
    }
  }

  function renderCheckpoints(items){
    checkpointList.innerHTML = '';
    if(!items||items.length===0){ checkpointList.innerHTML = '<li class="muted">No checkpoints yet</li>'; return }
    items.forEach(i=>{
      const li = document.createElement('li'); li.textContent = `${new Date(i.ts).toLocaleString()} • ${i.name} — ${i.notes || ''}`; checkpointList.appendChild(li);
    });
  }

  async function listCheckpointsFlow(){
    const user = JSON.parse(localStorage.getItem('lurkout_user')||'null'); if(!user){alert('Sign in to view');return}
    const ctx = window._LurkoutAppwrite;
    if(ctx && ctx.databaseId){
      const databases = new appwrite.Databases(client);
      try{
        const res = await databases.listDocuments(ctx.databaseId, 'checkpoints', [appwrite.Query.equal('userId', user.id)]);
        renderCheckpoints(res.documents || []);
      }catch(e){console.error(e);alert('List failed')}
    }else{
      const arr = JSON.parse(localStorage.getItem('lurkout_checkpoints_'+user.id)||'[]'); renderCheckpoints(arr);
    }
  }

  saveCheckpoint.onclick = saveCheckpointFlow; listCheckpoints.onclick = listCheckpointsFlow;

  // Script generator: very simple template replace
  generateScript.onclick = function(){
    const title = document.getElementById('scriptTitle').value || 'Lurkout Loader';
    const webhook = document.getElementById('webhookUrl').value || '';
    const tplName = document.getElementById('templateName').value || 'default';
    const template = `-- Lurkout generated script: ${title}\nlocal webhook = "${webhook}"\nprint("Lurkout: running ${title}")\n-- Replace this with real loader code\n`;
    scriptPreview.textContent = template;
    // create download link
    const blob = new Blob([template], {type:'text/plain'});
    downloadLink.href = URL.createObjectURL(blob); downloadLink.classList.remove('hidden');
  };

  publishLink.onclick = function(){
    // Demo: create data URI link
    if(!scriptPreview.textContent){ alert('Generate first'); return }
    const data = encodeURIComponent(scriptPreview.textContent);
    const url = `data:text/plain;charset=utf-8,${data}`;
    prompt('Shareable script data URL (copy):', url);
  };

  // Try to auto-get account on load
  tryGetAccount();
  renderAuth();
  // auto-list when logged in
  if(isLoggedIn()) listCheckpointsFlow();

})();
