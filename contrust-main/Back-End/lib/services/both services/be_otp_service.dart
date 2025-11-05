// ignore_for_file: use_build_context_synchronously
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/utils/be_datetime_helper.dart';
import 'dart:math';

class OtpService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String _generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  Future<bool> sendOtp({
    required String email,
    String? userType,
  }) async {
    try {
      await _supabase
          .from('EmailOTP')
          .delete()
          .eq('email', email.toLowerCase());

      final otpCode = _generateOtp();
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));

      await _supabase.from('EmailOTP').insert({
        'email': email.toLowerCase(),
        'otp_code': otpCode,
        'expires_at': expiresAt.toIso8601String(),
        'created_at': DateTimeHelper.getLocalTimeISOString(),
        'used': false,
        'user_type': userType ?? 'contractor',
        'attempts': 0,
      });

      await _sendOtpEmail(email: email, otpCode: otpCode);

      return true;
    } catch (e) {
      throw Exception('Failed to send OTP: $e');
    }
  }

  Future<void> _sendOtpEmail({
    required String email,
    required String otpCode,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'send-otp-email',
        body: {
          'email': email,
          'otp': otpCode,
        },
      );

      if (response.status != 200) {
        final errorData = response.data;
        throw Exception('Failed to send OTP email: ${errorData?['error'] ?? 'Unknown error'}');
      }
    } catch (e) {

      throw Exception('Failed to send OTP email: $e');
    }
  }

  Future<bool> verifyOtp({
    required String email,
    required String otpCode,
  }) async {
    try {
      final response = await _supabase
          .from('EmailOTP')
          .select()
          .eq('email', email.toLowerCase())
          .eq('used', false)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return false;
      }

      final storedOtp = response['otp_code'] as String;
      final expiresAt = DateTime.parse(response['expires_at'] as String);
      final attempts = (response['attempts'] as int?) ?? 0;

      if (DateTime.now().isAfter(expiresAt)) {
        await _supabase
            .from('EmailOTP')
            .update({'used': true})
            .eq('email', email.toLowerCase())
            .eq('otp_code', otpCode);
        return false;
      }

      if (attempts >= 5) {
        await _supabase
            .from('EmailOTP')
            .update({'used': true})
            .eq('email', email.toLowerCase())
            .eq('otp_code', storedOtp);
        return false;
      }

      if (storedOtp == otpCode) {
        await _supabase
            .from('EmailOTP')
            .update({'used': true})
            .eq('email', email.toLowerCase())
            .eq('otp_code', otpCode);

        await _supabase
            .from('EmailOTP')
            .delete()
            .eq('email', email.toLowerCase())
            .eq('used', false);

        return true;
      } else {
        await _supabase
            .from('EmailOTP')
            .update({'attempts': attempts + 1})
            .eq('email', email.toLowerCase())
            .eq('otp_code', storedOtp);
        return false;
      }
    } catch (e) {
      throw Exception('Failed to verify OTP: $e');
    }
  }

  Future<bool> resendOtp({
    required String email,
    String? userType,
  }) async {
    return await sendOtp(email: email, userType: userType);
  }

  Future<bool> hasValidOtp(String email) async {
    try {
      final response = await _supabase
          .from('EmailOTP')
          .select()
          .eq('email', email.toLowerCase())
          .eq('used', false)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return false;

      final expiresAt = DateTime.parse(response['expires_at'] as String);
      return DateTime.now().isBefore(expiresAt);
    } catch (e) {
      return false;
    }
  }

  Future<void> cleanupExpiredOtps() async {
    try {
      await _supabase
          .from('EmailOTP')
          .delete()
          .lt('expires_at', DateTime.now().toIso8601String());
    } catch (e) {
      // Ignore cleanup errors
    }
  }
}

