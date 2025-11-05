# Send Password Reset Email Edge Function

This Edge Function sends password reset emails using Resend, bypassing Supabase's email service. It generates a valid password reset token using Supabase Admin API and sends a beautifully formatted email via Resend.

## Setup

### 1. Deploy the Function

Make sure you have the Supabase CLI installed and are logged in:

```bash
supabase login
supabase link --project-ref your-project-ref
```

Deploy the function:

```bash
supabase functions deploy send-password-reset-email
```

### 2. Set Environment Variables

Set the required secrets in Supabase Dashboard or via CLI:

```bash
supabase secrets set RESEND_API_KEY=your_resend_api_key
```

The following environment variables are automatically available:
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY` - Service role key (automatically available)

### 3. Get Resend API Key

1. Go to [Resend Dashboard](https://resend.com/api-keys)
2. Create a new API key
3. Copy the API key
4. Set it as a secret: `supabase secrets set RESEND_API_KEY=your_key`

### 4. Verify Domain in Resend

Make sure your domain `contrust-sjdm.com` is verified in Resend:
1. Go to [Resend Domains](https://resend.com/domains)
2. Verify that `contrust-sjdm.com` shows as verified
3. The function uses `noreply@contrust-sjdm.com` as the sender

## Usage

### From Flutter/Dart

```dart
final userService = UserService();
await userService.resetPassword(
  'user@example.com',
  redirectTo: 'https://contractor.contrust-sjdm.com/auth/reset-password',
);
```

### Direct API Call

```bash
curl -X POST 'https://your-project.supabase.co/functions/v1/send-password-reset-email' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "email": "user@example.com",
    "redirectTo": "https://contractor.contrust-sjdm.com/auth/reset-password"
  }'
```

## How It Works

1. **Validates Input**: Checks email format and required parameters
2. **Finds User**: Uses Supabase Admin API to find the user by email
3. **Generates Reset Token**: Uses `admin.generateLink()` with type `'recovery'` to create a valid reset token
4. **Sends Email**: Uses Resend API to send a beautifully formatted HTML email with the reset link
5. **Returns Success**: Returns success status and email ID

## Error Handling

The function handles various error cases:
- Invalid email format → 400 Bad Request
- User not found → 404 Not Found
- Missing Resend API key → 500 Internal Server Error
- Token generation failure → 500 Internal Server Error
- Email sending failure → 500 Internal Server Error

## Email Template

The email includes:
- Professional ConTrust branding
- Clear call-to-action button
- Plain text fallback
- Expiration notice (1 hour)
- Security warning

## Security Notes

- Uses Supabase Admin API (service role) to generate valid reset tokens
- The reset link includes the proper token and type parameters
- Links expire after 1 hour (handled by Supabase)
- Only verified domains can send emails via Resend

