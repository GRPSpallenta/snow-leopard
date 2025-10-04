import React from 'react'
import ReactDOM from 'react-dom/client'
import { supabase } from './lib/supabase'

function App() {
  const [status, setStatus] = React.useState<string>('checking...')

  React.useEffect(() => {
    fetch('/api/health')
      .then(r => r.json())
      .then(d => setStatus(d.ok ? 'ok' : 'error'))
      .catch(() => setStatus('error'))
  }, [])

  const loginWithGoogle = async () => {
    const { error } = await supabase.auth.signInWithOAuth({ provider: 'google' })
    if (error) alert(error.message)
  }

  return (
    <div style={{ fontFamily: 'system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial', padding: 24 }}>
      <h1>Snow Leopard</h1>
      <p>API health: {status}</p>
      <button onClick={loginWithGoogle}>Continue with Google</button>
    </div>
  )
}

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
)
