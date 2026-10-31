import cors from 'cors';
import express from 'express';
import rateLimit from 'express-rate-limit';
import helmet from 'helmet';
import { config } from './config.js';
import { authRouter } from './routes/auth.js';
import { emailVerificationRouter } from './routes/emailVerification.js';
import { loanRouter } from './routes/loans.js';
import { profileRouter } from './routes/profile.js';

export const app = express();
app.use(helmet());
app.use(cors({ origin: config.corsOrigin === '*' ? true : config.corsOrigin }));
app.use(express.json({ limit: '100kb' }));
app.use('/api', rateLimit({ windowMs: 60_000, limit: 120 }));

app.get('/', (_req, res) =>
  res.json({
    name: 'CreditSea API',
    status: 'ok',
    health: '/health',
  }),
);
app.get('/health', (_req, res) => res.json({ status: 'ok' }));
app.use('/api/auth', authRouter);
app.use('/api/email', emailVerificationRouter);
app.use('/api/profile', profileRouter);
app.use('/api/loans', loanRouter);

app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(500).json({ message: 'Unexpected server error.' });
});

export default app;
