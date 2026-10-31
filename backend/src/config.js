import 'dotenv/config';

const required = (name, fallback) => {
  const value = process.env[name] ?? fallback;
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
};

export const config = {
  port: Number(process.env.PORT ?? 8080),
  mongoUri: required('MONGODB_URI', 'mongodb://127.0.0.1:27017/creditsea'),
  jwtSecret: required('JWT_SECRET', 'development-only-change-me'),
  jwtExpiresIn: process.env.JWT_EXPIRES_IN ?? '30d',
  otpTtlMinutes: Number(process.env.OTP_TTL_MINUTES ?? 5),
  otpMode: process.env.OTP_MODE ?? 'development',
  stagingMobile: process.env.STAGING_MOBILE ?? '9999999999',
  stagingOtp: process.env.STAGING_OTP ?? '1234',
  corsOrigin: process.env.CORS_ORIGIN ?? '*',
  adminApiKey: required('ADMIN_API_KEY', 'development-admin-key'),
  resendApiKey: process.env.RESEND_API_KEY ?? '',
  emailFrom: process.env.EMAIL_FROM ?? 'CreditSea <onboarding@resend.dev>',
};
