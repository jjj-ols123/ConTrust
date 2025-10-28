# Configuration Guide

## Environment Variables

This project uses environment variables for sensitive configuration values.

### Required Environment Variables

#### PayMongo API Keys (REQUIRED)
- `PAYMONGO_PUBLIC_KEY` - Your PayMongo public key (starts with `pk_test_` or `pk_live_`)
- `PAYMONGO_SECRET_KEY` - Your PayMongo secret key (starts with `sk_test_` or `sk_live_`)

Get your keys from: https://dashboard.paymongo.com/developers

#### Supabase Configuration (Optional - defaults provided)
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_ANON_KEY` - Your Supabase anon/public key
- `SUPABASE_ADMIN_ACCOUNT` - Admin email account

## Local Development

### Option 1: Using --dart-define flags
```bash
flutter run --dart-define=PAYMONGO_PUBLIC_KEY=pk_test_xxx --dart-define=PAYMONGO_SECRET_KEY=sk_test_xxx
```

### Option 2: For Web Builds
```bash
flutter build web --dart-define=PAYMONGO_PUBLIC_KEY=pk_test_xxx --dart-define=PAYMONGO_SECRET_KEY=sk_test_xxx
```

## Vercel Deployment

1. Go to your Vercel project settings
2. Navigate to "Environment Variables"
3. Add the following variables:
   - `PAYMONGO_PUBLIC_KEY`
   - `PAYMONGO_SECRET_KEY`
   - `SUPABASE_URL` (optional)
   - `SUPABASE_ANON_KEY` (optional)

4. Important: Make sure to set the variables during the build phase by checking "Build Time" option

## Security Notes

- Never commit actual API keys to the repository
- Use test keys (`pk_test_`, `sk_test_`) for development
- Use production keys (`pk_live_`, `sk_live_`) only in production environment
- The PayMongo secret key should never be exposed to the client side

