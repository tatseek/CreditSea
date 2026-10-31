import mongoose from 'mongoose';
import { app } from '../src/app.js';
import { config } from '../src/config.js';

let connectionPromise;

const connectDatabase = () => {
  if (mongoose.connection.readyState === 1) return Promise.resolve();
  connectionPromise ??= mongoose.connect(config.mongoUri);
  return connectionPromise;
};

export default async function handler(req, res) {
  try {
    await connectDatabase();
    return app(req, res);
  } catch (error) {
    console.error('Database connection failed.', error);
    return res.status(503).json({ message: 'Database service unavailable.' });
  }
}
