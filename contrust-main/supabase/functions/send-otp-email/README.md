# Send OTP Email Edge Function

This Supabase Edge Function sends OTP verification codes via email using Resend API.

## Setup Instructions

### 1. Get Resend API Key

1. Sign up at [Resend.com](https  resend.com)
2. Go to API Keys section
3. Create a new API key
4. Copy the API key (starts with `re_`)

### 2. Deploy the Function

```bash
# Install Supabase CLI if you haven't
npm install -g supabase

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref your-project-ref

# Deploy the function
supabase functions deploy send-otp-email
```

### 3. Set Environment Variables

Set the following secrets in Supabase Dashboard:

1. Go to **Project Settings** → **Edge Functions** → **Secrets**
2. Add the following secrets:
   - `RESEND_API_KEY` - Your Resend API key (e.g., `re_xxxxxxxxxxxxx`)
   - `SUPABASE_URL` - Your Supabase project URL (auto-populated)
   - `SUPABASE_SERVICE_ROLE_KEY` - Your Supabase service role key (auto-populated)

Or via CLI:
```bash
supabase secrets set RESEND_API_KEY=re_xxxxxxxxxxxxx
```

### 4. Verify Your Domain in Resend

1. Go to Resend Dashboard → Domains
2. Add your domain (e.g., `contrust.com`)
3. Add the DNS records provided by Resend
4. Wait for verification
5. Update the `from` field in `index.ts` to use your verified domain:
   ```typescript
   from: 'ConTrust <noreply@yourdomain.com>'
   ```

### 5. Update the OTP Service

Once deployed, update `Back-End/lib/services/both services/be_otp_service.dart`:

```dart
Future<void> _sendOtpEmail({
  required String email,
  required String otpCode,
}) async {
  try {
    await _supabase.functions.invoke('send-otp-email', body: {
      'email': email,
      'otp': otpCode,
    });
  } catch (e) {
    throw Exception('Failed to send OTP email: $e');
  }
}
```

## Testing

Test the function locally:
```bash
supabase functions serve send-otp-email
```

Then test with:
```bash
curl -i --location --request POST 'http://localhost:54321/functions/v1/send-otp-email' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{
    "email": "test@example.com",
    "otp": "123456"
  }'
```

## Alternative: Using SendGrid

If you prefer SendGrid instead of Resend:

1. Replace the Resend API call with SendGrid API
2. Update environment variable to `SENDGRID_API_KEY`
3. Update the email sending logic accordingly

## Troubleshooting

- **401 Unauthorized**: Check that your Resend API key is correct
- **Email not received**: Check spam folder, verify domain in Resend
- **Function not found**: Make sure the function is deployed and the name matches

