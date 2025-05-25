document.addEventListener('DOMContentLoaded', () => {
    // upload_web.sh で <API_URL> が自動置換されます
    const API = '<API_URL>';
  
    // system プロンプトと履歴を保持
    const systemPrompt = "あなたは優しい健康コーチです。80文字以内の日本語で答えて。";
    let messages = [{ role: 'system', content: systemPrompt }];
  
    const logEl = document.getElementById('chat-log');
    const inputEl = document.getElementById('prompt');
  
    function renderChat() {
      logEl.innerHTML = messages.map(m => {
        const cls = m.role === 'user' ? 'user' : m.role === 'assistant' ? 'assistant' : 'system';
        const icon = m.role === 'user' ? '👤' : m.role === 'assistant' ? '🤖' : '⚙️';
        return `<div class="${cls}">${icon} ${m.content}</div>`;
      }).join('');
      logEl.scrollTop = logEl.scrollHeight;
    }
  
    async function send() {
      const text = inputEl.value.trim();
      if (!text) return;
  
      // ユーザメッセージを履歴に追加
      messages.push({ role: 'user', content: text });
      renderChat();
      inputEl.value = '';
  
      // API に全履歴を送信
      const resp = await fetch(API, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ messages })
      });
  
      if (!resp.ok) {
        console.error('API error:', resp.status, await resp.text());
        return;
      }
  
      const { reply } = await resp.json();
      // アシスタント応答を履歴に追加
      messages.push({ role: 'assistant', content: reply });
      renderChat();
    }
  
    document.getElementById('send').addEventListener('click', send);
    document.getElementById('prompt').addEventListener('keypress', e => {
      if (e.key === 'Enter') send();
    });
  
    // 初回描画
    renderChat();
  });
  