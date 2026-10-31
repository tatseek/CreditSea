import jwt from 'jsonwebtoken';
import { config } from '../config.js';
import { User } from '../models/User.js';

export async function requireAuth(req, res, next) {
  try {
    const token = req.headers.authorization?.replace(/^Bearer\s+/i, '');
    if (!token) return res.status(401).json({ message: 'Authentication required.' });
    const payload = jwt.verify(token, config.jwtSecret);
    const user = await User.findById(payload.sub);
    if (!user) return res.status(401).json({ message: 'Session is no longer valid.' });
    req.user = user;
    next();
  } catch {
    res.status(401).json({ message: 'Invalid or expired session.' });
  }
}
