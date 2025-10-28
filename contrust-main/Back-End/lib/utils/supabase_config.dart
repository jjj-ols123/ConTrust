class SupabaseConfig {
  // Supabase Configuration - using environment variables with fallback defaults
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://bgihfdqruamnjionhkeq.supabase.co',
  );
  static const String adminAccount = String.fromEnvironment(
    'SUPABASE_ADMIN_ACCOUNT',
    defaultValue: 'admin.123@gmail.com',
  );
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJnaWhmZHFydWFtbmppb25oa2VxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA4NzIyODksImV4cCI6MjA1NjQ0ODI4OX0.-GRaolUVu1hW6NUaEAwJuYJo8C2X5_1wZ-qB4a-9Txs',
  );
  
  // PayMongo API Keys (Test Mode) - using environment variables with fallback defaults
  static const String paymongoPublicKey = String.fromEnvironment(
    'PAYMONGO_PUBLIC_KEY',
    defaultValue: 'pk_test_TfqJrUTWf66y2JJM61uHxEga',
  );
  static const String paymongoSecretKey = String.fromEnvironment(
    'PAYMONGO_SECRET_KEY',
    defaultValue: 'sk_test_t5XNb5XfW94Thp1rvXJv4R5q',
  );
  
  // PayMongo Configuration
  static const String paymongoBaseUrl = 'https://api.paymongo.com/v1';
  static const bool isTestMode = true;
  static const String currency = 'PHP';
  static const List<String> paymentMethodsAllowed = ['card'];
  static const double minPaymentAmount = 100.0;
}