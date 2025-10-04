import 'dotenv/config';
import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import { supabaseAdmin } from '../../supabase/clients/server.js';
const app = express();
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '5mb' }));
// Health check
app.get('/health', async (_req, res) => {
    // simple Supabase check
    const { data, error } = await supabaseAdmin.from('services').select('id').limit(1);
    if (error)
        return res.status(500).json({ ok: false, error: error.message });
    return res.json({ ok: true, db: !!data });
});
// Basic auth check route (verifies Supabase JWT from Authorization: Bearer <token>)
app.get('/auth/me', async (req, res) => {
    try {
        const authHeader = req.headers.authorization || '';
        const token = authHeader.startsWith('Bearer ') ? authHeader.substring(7) : '';
        if (!token)
            return res.status(401).json({ error: 'Missing bearer token' });
        // Supabase-js v2: get user from token via auth.getUser
        const { data, error } = await supabaseAdmin.auth.getUser(token);
        if (error || !data?.user)
            return res.status(401).json({ error: 'Invalid token' });
        return res.json({ user: { id: data.user.id, email: data.user.email } });
    }
    catch (e) {
        return res.status(500).json({ error: e.message });
    }
});
const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
    // eslint-disable-next-line no-console
    console.log(`API listening on http://localhost:${PORT}`);
});
