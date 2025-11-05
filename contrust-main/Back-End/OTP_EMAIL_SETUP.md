# OTP Email Setup Guide

## Overview
The OTP email verification system has been implemented. Currently, OTP codes are generated and stored in the `EmailOTP` table, but **email sending needs to be configured**.

## Current Status
- ✅ OTP generation and storage
- ✅ OTP verification logic
- ✅ UI for OTP input
- ✅ Integration with registration flow
- ⚠️ **Email sending** (needs configuration)

## Email Configuration Options

### Option 1: Supabase Edge Function (Recommended)

1. **Create an Edge Function** in your Supabase project:
   - Go to Supabase Dashboard → Edge Functions
   - Create a new function named `send-otp-email`

2. **Function Code** (TypeScript):
```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')

serve(async (req) => {
  const { email, otp } = await req.json()

  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${RESEND_API_KEY}`,
    },
    body: JSON.stringify({
      from: 'ConTrust <noreply@contrust.com>',
      to: email,
      subject: 'ConTrust - Email Verification Code',
      html: `
        <h2>Your Verification Code</h2>
        <p>Your OTP code is: <strong>${otp}</strong></p>
        <p>This code will expire in 10 minutes.</p>
        <p>If you didn't request this code, please ignore this email.</p>
      `,
    }),
  })

  return new Response(JSON.stringify({ success: true }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
```

3. **Update `be_otp_service.dart`**:
   - Uncomment the Edge Function call in `_sendOtpEmail()` method
   - Remove the print statements

### Option 2: Supabase Email Templates

1. **Configure Email Templates** in Supabase Dashboard:
   - Go to Authentication → Email Templates
   - Create a custom template for OTP

2. **Use Database Trigger**:
   - Create a trigger that sends email when OTP is inserted
   - Requires Supabase Pro plan

### Option 3: Custom Email Service (Resend/SendGrid/Mailgun)

1. **Get API Key** from your email service provider
2. **Create a backend service** that sends emails
3. **Update `_sendOtpEmail()`** to call your service

## Database Table

Make sure your `EmailOTP` table has these columns:
```sql
- id (UUID, Primary Key)
- email (TEXT, NOT NULL)
- otp_code (TEXT, NOT NULL)
- expires_at (TIMESTAMPTZ, NOT NULL)
- created_at (TIMESTAMPTZ, DEFAULT NOW())
- used (BOOLEAN, DEFAULT FALSE)
- user_type (TEXT)
- attempts (INTEGER, DEFAULT 0)
```

## Testing

For development/testing, the OTP is currently printed to the console:
```
🔐 OTP for user@email.com: 123456
```

**⚠️ Remove print statements in production!**

## Security Notes

1. OTP codes expire after 10 minutes
2. Maximum 5 verification attempts per OTP
3. Used OTPs cannot be reused
4. Only the most recent unused OTP is valid
5. Expired OTPs are automatically cleaned up

## Next Steps

1. Choose your email sending method (Option 1 recommended)
2. Configure the email service
3. Update `_sendOtpEmail()` in `be_otp_service.dart`
4. Test the complete flow
5. Remove debug print statements

