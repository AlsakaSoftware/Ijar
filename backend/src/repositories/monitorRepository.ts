const GITHUB_TOKEN = process.env.GITHUB_TOKEN;
const REPO_OWNER = 'AlsakaSoftware';
const REPO_NAME = 'ijar';

export class MonitorRepository {
  async triggerWorkflow(userId: string): Promise<void> {
    if (!GITHUB_TOKEN) {
      throw new Error('GITHUB_TOKEN environment variable is not set');
    }

    const url = `https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/dispatches`;

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Accept': 'application/vnd.github+json',
        'Authorization': `Bearer ${GITHUB_TOKEN}`,
        'X-GitHub-Api-Version': '2022-11-28',
      },
      body: JSON.stringify({
        event_type: 'monitor-user',
        client_payload: { user_id: userId },
      }),
    });

    if (response.status !== 204) {
      const body = await response.text();
      throw new Error(`GitHub API error (${response.status}): ${body}`);
    }
  }
}
