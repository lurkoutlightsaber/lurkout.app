// UI handling for checkpoints
class CheckpointUI {
    constructor(containerId) {
        this.container = document.getElementById(containerId);
        this.checkpoints = [];
        this.pageId = null;
    }

    async initialize(pageId) {
        this.pageId = pageId;
        await this.refreshStatus();
        this.render();
    }

    async refreshStatus() {
        try {
            const response = await fetch(`/api/status/${this.pageId}`);
            const data = await response.json();
            this.checkpoints = data.checkpoints;
            this.complete = data.complete;
            this.render();
        } catch (err) {
            console.error('Failed to refresh status:', err);
        }
    }

    render() {
        this.container.innerHTML = '';
        
        // Progress indicator
        const progress = document.createElement('div');
        progress.className = 'checkpoint-progress';
        progress.innerHTML = `
            <div class="progress-bar">
                <div class="progress-fill" style="width: ${this.getProgressPercent()}%"></div>
            </div>
            <div class="progress-text">
                ${this.getCompletedCount()} / ${this.checkpoints.length} checkpoints completed
            </div>
        `;
        this.container.appendChild(progress);

        // Checkpoints list
        const list = document.createElement('div');
        list.className = 'checkpoint-list';
        
        this.checkpoints.forEach(cp => {
            const item = document.createElement('div');
            item.className = `checkpoint-item ${cp.completed ? 'completed' : ''}`;
            item.innerHTML = `
                <div class="checkpoint-status">
                    ${cp.completed ? '✓' : '○'}
                </div>
                <div class="checkpoint-info">
                    <h3>${this.getServiceName(cp.service)}</h3>
                    <p>Click to complete this step</p>
                </div>
            `;
            
            if (!cp.completed) {
                item.onclick = () => this.handleCheckpoint(cp);
            }
            
            list.appendChild(item);
        });
        
        this.container.appendChild(list);

        // Completion message
        if (this.complete) {
            const completion = document.createElement('div');
            completion.className = 'completion-message';
            completion.innerHTML = `
                <h2>🎉 All checkpoints completed!</h2>
                <p>You can now access the full content.</p>
            `;
            this.container.appendChild(completion);
        }
    }

    getProgressPercent() {
        if (!this.checkpoints.length) return 0;
        return (this.getCompletedCount() / this.checkpoints.length) * 100;
    }

    getCompletedCount() {
        return this.checkpoints.filter(cp => cp.completed).length;
    }

    getServiceName(service) {
        const services = {
            'linkvertise': 'Linkvertise',
            'workink': 'Work.ink',
            'lootlabs': 'LootLabs'
        };
        return services[service] || service;
    }

    async handleCheckpoint(checkpoint) {
        // Redirect to appropriate service
        const serviceUrls = {
            'linkvertise': 'https://linkvertise.com/api/v1/redirect',
            'workink': 'https://work.ink/api/v1/redirect',
            'lootlabs': 'https://lootlabs.gg/api/v1/redirect'
        };

        const url = new URL(serviceUrls[checkpoint.service]);
        url.searchParams.append('checkpoint', checkpoint.id);
        url.searchParams.append('page', this.pageId);
        
        // Store checkpoint info for verification after return
        sessionStorage.setItem('pendingCheckpoint', JSON.stringify({
            id: checkpoint.id,
            service: checkpoint.service,
            pageId: this.pageId
        }));

        window.location.href = url.toString();
    }

    // Call this when returning from ad service
    async verifyCompletion(proofToken) {
        const pending = JSON.parse(sessionStorage.getItem('pendingCheckpoint'));
        if (!pending) return;

        try {
            const response = await fetch(`/api/verify/${pending.pageId}/${pending.id}`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ proofToken })
            });

            if (response.ok) {
                await this.refreshStatus();
                sessionStorage.removeItem('pendingCheckpoint');
            }
        } catch (err) {
            console.error('Failed to verify completion:', err);
        }
    }
}

// CSS styles for the checkpoint UI
const style = document.createElement('style');
style.textContent = `
.checkpoint-progress {
    margin: 20px 0;
    padding: 10px;
    background: #f5f5f5;
    border-radius: 8px;
}

.progress-bar {
    height: 20px;
    background: #eee;
    border-radius: 10px;
    overflow: hidden;
}

.progress-fill {
    height: 100%;
    background: #4CAF50;
    transition: width 0.3s ease;
}

.progress-text {
    text-align: center;
    margin-top: 8px;
    font-size: 14px;
    color: #666;
}

.checkpoint-list {
    display: flex;
    flex-direction: column;
    gap: 10px;
}

.checkpoint-item {
    display: flex;
    align-items: center;
    padding: 15px;
    background: white;
    border: 1px solid #ddd;
    border-radius: 8px;
    cursor: pointer;
    transition: all 0.2s ease;
}

.checkpoint-item:hover:not(.completed) {
    transform: translateY(-2px);
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.checkpoint-item.completed {
    background: #f8fff8;
    border-color: #4CAF50;
    cursor: default;
}

.checkpoint-status {
    font-size: 24px;
    margin-right: 15px;
    color: #4CAF50;
}

.checkpoint-info h3 {
    margin: 0;
    font-size: 16px;
}

.checkpoint-info p {
    margin: 5px 0 0;
    font-size: 14px;
    color: #666;
}

.completion-message {
    text-align: center;
    margin-top: 20px;
    padding: 20px;
    background: #e8f5e9;
    border-radius: 8px;
    color: #2e7d32;
}

.completion-message h2 {
    margin: 0;
    font-size: 20px;
}

.completion-message p {
    margin: 10px 0 0;
    font-size: 16px;
}
`;

document.head.appendChild(style);