
class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  static const supabaseAdminAccount = String.fromEnvironment('SUPABASE_ADMIN_ACCOUNT', defaultValue: '');
  static const paymongoPublicKey = String.fromEnvironment('PAYMONGO_PUBLIC_KEY', defaultValue: '');
  static const paymongoSecretKey = String.fromEnvironment('PAYMONGO_SECRET_KEY', defaultValue: '');
  static const aiApiKey = String.fromEnvironment('AI_API_KEY', defaultValue: '');
}
