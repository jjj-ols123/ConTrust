import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';


class AiService {
  final SupabaseClient _supabase;
  final String functionName;

  AiService({SupabaseClient? supabase, this.functionName = 'ai-assistant'})
      : _supabase = supabase ?? Supabase.instance.client;

  Future<String> generate({
    required String prompt,
    Map<String, dynamic>? context,
    Map<String, String>? headers,
  }) async {
    final payload = {
      'prompt': prompt,
      if (context != null) 'context': context,
    };

    final res = await _supabase.functions.invoke(
      functionName,
      body: jsonEncode(payload),
      headers: headers,
    );

    if (res.data == null) {
      throw Exception('AI function returned no data');
    }

    if (res.data is Map && (res.data as Map).containsKey('text')) {
      return (res.data as Map)['text']?.toString() ?? '';
    }
    return res.data.toString();
  }
}
