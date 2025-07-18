import 'package:flutter_quill/flutter_quill.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class ContractService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<void> saveContract({
    required String projectId,
    required String contractorId,
    required String contractTypeId,
    required String title,
    required String content,
    required List<dynamic> deltaContent,
  }) async {
    final proj = await _supabase
        .from('Projects')
        .select('contractee_id')
        .eq('project_id', projectId)
        .single();
    final contracteeId = proj['contractee_id'] as String?;
    if (contracteeId == null) {
      throw Exception('Project has no contractee assigned');
    }
    await _supabase.from('Contracts').insert({
      'project_id': projectId,
      'contractor_id': contractorId,
      'contractee_id': contracteeId,
      'contract_type_id': contractTypeId,
      'title': title,
      'content': content,
      'delta_content': deltaContent,
      'status': 'draft',
    });
  }

  static Future<void> updateContract({
    required String contractId,
    required String projectId,
    required String contractorId,
    required String contractTypeId,
    required String title,
    required String content,
    required List<dynamic> deltaContent,
  }) async {
    final proj = await _supabase
        .from('Projects')
        .select('contractee_id')
        .eq('project_id', projectId)
        .single();
    final contracteeId = proj['contractee_id'] as String?;
    if (contracteeId == null) {
      throw Exception('Project has no contractee assigned');
    }
    await _supabase.from('Contracts').update({
      'project_id': projectId,
      'contractor_id': contractorId,
      'contractee_id': contracteeId,
      'contract_type_id': contractTypeId,
      'title': title,
      'content': content,
      'delta_content': deltaContent,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('contract_id', contractId);
  }

  static Future<List<Map<String, dynamic>>> getContractorProjectInfo(
      String contractorId) async {
    final response = await _supabase
        .from('Projects')
        .select('project_id, contractee_id, description')
        .eq('contractor_id', contractorId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> sendContractToContractee({
    required String contractId,
    required String contracteeId,
    required String message,
  }) async {
    try {
      final contractData = await _supabase
          .from('Contracts')
          .select('*, contractor_id, project_id')
          .eq('contract_id', contractId)
          .single();

      final chatRoomData = await _supabase
          .from('ChatRoom')
          .select('chatroom_id')
          .eq('project_id', contractData['project_id'])
          .single();

      await _supabase.from('Contracts').update({
        'status': 'sent',
        'sent_at': DateTime.now().toIso8601String(),
      }).eq('contract_id', contractId);

      await _supabase.from('Projects').update({
      'status': 'awaiting_agreement',
      'contract_sent_at': DateTime.now().toIso8601String(),
    }).eq('project_id', contractData['project_id']);
      
      await _supabase.from('Messages').insert({
        'chatroom_id': chatRoomData['chatroom_id'],
        'sender_id': contractData['contractor_id'],
        'receiver_id': contracteeId,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
        'message_type': 'contract',
        'contract_id': contractId,
      });

      await _supabase.from('ChatRoom').update({
        'last_message': '📄 Contract sent: $message',
        'last_message_time': DateTime.now().toIso8601String(),
      }).eq('chatroom_id', chatRoomData['chatroom_id']);
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> deleteContract({
    required String contractId,
  }) async {
    try {
      await _supabase.from('Contracts').delete().eq('contract_id', contractId);
    } catch (e) {
      throw Exception('Error deleting contract: $e');
    }
  }

  static Future<void> updateContractStatus({
    required String contractId,
    required String status,
  }) async {
    Map<String, dynamic> updateData = {
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (status == 'approved' || status == 'rejected') {
      updateData['reviewed_at'] = DateTime.now().toIso8601String();
    }

    await _supabase.from('Contracts').update(updateData).eq('contract_id', contractId);

    if (status == 'approved') {
      final contractData = await _supabase
          .from('Contracts')
          .select('project_id')
          .eq('contract_id', contractId)
          .single();

      await _supabase.from('Projects').update({
        'status': 'active',
      }).eq('project_id', contractData['project_id']);
    } else if (status == 'rejected') {
      final contractData = await _supabase
          .from('Contracts')
          .select('project_id')
          .eq('contract_id', contractId)
          .single();
 
      await _supabase.from('Projects').update({
        'status': 'awaiting_agreement',
      }).eq('project_id', contractData['project_id']);
    }
  }

  static String replacePlaceholders(String template, String contractorId,
      Map<String, dynamic>? contractType) {
    String result = template;
    final contractTypeName = contractType?['template_name'] ?? '';

    if (result.contains('[CONTRACTOR_ID]')) {
      result = result.replaceAll('[CONTRACTOR_ID]', contractorId);
    }
    if (result.contains('[DATE]')) {
      result = result.replaceAll(
          '[DATE]', DateTime.now().toLocal().toString().split(' ')[0]);
    }
    if (result.contains('[TEMPLATE_NAME]')) {
      result = result.replaceAll('[TEMPLATE_NAME]', contractTypeName);
    }

    Map<String, String> commonPlaceholders = {
      '[Client Name]': '[Client Name]',
      '[Client Address]': '[Client Address]',
      '[Client Title]': '[Client Title]',
      '[Contractor Name]': '[Contractor Name]',
      '[Contractor Address]': '[Contractor Address]',
      '[Contractor Title]': '[Contractor Title]',
      '[Project Description]': '[Project Description]',
      '[Project Location]': '[Project Location]',
      '[Start Date]': '[Start Date]',
      '[Completion Date]': '[Completion Date]',
      '[Duration]': '[Duration]',
      '[Warranty Period]': '[Warranty Period]',
      '[Notice Period]': '[Notice Period]',
      '[Payment Due Days]': '[Payment Due Days]',
      '[Witness Name]': '[Witness Name]',
    };

    if (contractTypeName.toLowerCase().contains('lump sum')) {
      Map<String, String> lumpSumPlaceholders = {
        '[Total Amount]': '[Total Amount]',
        '[Down Payment]': '[Down Payment]',
        '[Progress Payment 1]': '[Progress Payment 1]',
        '[Progress Payment 2]': '[Progress Payment 2]',
        '[Progress Payment 3]': '[Progress Payment 3]',
        '[Final Payment]': '[Final Payment]',
        '[Materials List]': '[Materials List]',
        '[Equipment List]': '[Equipment List]',
      };
      commonPlaceholders.addAll(lumpSumPlaceholders);
    } else if (contractTypeName.toLowerCase().contains('cost-plus') ||
        contractTypeName.toLowerCase().contains('cost plus')) {
      Map<String, String> costPlusPlaceholders = {
        '[Contractor Fee Percentage]': '[Contractor Fee Percentage]',
        '[Fixed Fee Amount]': '[Fixed Fee Amount]',
        '[Maximum Budget]': '[Maximum Budget]',
      };
      commonPlaceholders.addAll(costPlusPlaceholders);
    } else if (contractTypeName.toLowerCase().contains('time and materials') ||
        contractTypeName.toLowerCase().contains('time & materials')) {
      Map<String, String> timeMaterialsPlaceholders = {
        '[Hourly Rate]': '[Hourly Rate]',
        '[Position/Trade]': '[Position/Trade]',
        '[Material Markup]': '[Material Markup]',
        '[Equipment Markup]': '[Equipment Markup]',
        '[Supervisor Rate]': '[Supervisor Rate]',
        '[Skilled Rate]': '[Skilled Rate]',
        '[General Rate]': '[General Rate]',
        '[Overtime Multiplier]': '[Overtime Multiplier]',
        '[Invoice Frequency]': '[Invoice Frequency]',
        '[Late Fee Percentage]': '[Late Fee Percentage]',
        '[Estimated Budget]': '[Estimated Budget]',
        '[Work Description]': '[Work Description]',
      };
      commonPlaceholders.addAll(timeMaterialsPlaceholders);
    }

    commonPlaceholders.forEach((placeholder, replacement) {
      if (result.contains(placeholder)) {
        result = result.replaceAll(placeholder, replacement);
      }
    });

    return result;
  }

  static String stripHtmlTags(String htmlString) {
    return htmlString
        .replaceAll(RegExp(r'<h[1-6]>'), '\n\n')
        .replaceAll(RegExp(r'</h[1-6]>'), '\n\n')
        .replaceAll('<p>', '\n')
        .replaceAll('</p>', '\n')
        .replaceAll('<br>', '\n')
        .replaceAll('<br/>', '\n')
        .replaceAll('<li>', '• ')
        .replaceAll('</li>', '\n')
        .replaceAll('<ul>', '\n')
        .replaceAll('</ul>', '\n')
        .replaceAll('<ol>', '\n')
        .replaceAll('</ol>', '\n')
        .replaceAll('<strong>', '')
        .replaceAll('</strong>', '')
        .replaceAll('<b>', '')
        .replaceAll('</b>', '')
        .replaceAll('<em>', '')
        .replaceAll('</em>', '')
        .replaceAll('<i>', '')
        .replaceAll('</i>', '')
        .replaceAll('<hr>', '\n─────────────────────────────────\n')
        .replaceAll(RegExp(r'<div[^>]*>'), '')
        .replaceAll('</div>', '')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n')
        .trim();
  }

  static void applyFormatting(QuillController controller) {
    final text = controller.document.toPlainText();
    final lines = text.split('\n');
    int currentPos = 0;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.isNotEmpty) {
        if (line == line.toUpperCase() &&
            line.contains('CONTRACT') &&
            line.length > 10) {
          controller.formatText(currentPos, line.length, Attribute.bold);
          controller.formatText(
              currentPos, line.length, Attribute.centerAlignment);
        } else if (RegExp(r'^\d+\.\s+[A-Z]').hasMatch(line)) {
          controller.formatText(currentPos, line.length, Attribute.bold);
        } else if (line.endsWith(':') && line.length < 50) {
          controller.formatText(currentPos, line.length, Attribute.bold);
        } else if (line == line.toUpperCase() &&
            line.length > 5 &&
            line.length < 50 &&
            !line.contains('\$')) {
          controller.formatText(currentPos, line.length, Attribute.bold);
        }
      }

      final placeholderRegex = RegExp(r'\[([^\]]+)\]');
      final matches = placeholderRegex.allMatches(lines[i]);

      for (final match in matches) {
        final placeholderStart = currentPos + match.start;
        final placeholderLength = match.end - match.start;
        controller.formatText(
            placeholderStart, placeholderLength, Attribute.bold);
        controller.formatText(
            placeholderStart, placeholderLength, Attribute.italic);
      }

      final currencyRegex = RegExp(r'₱[0-9,]+\.?[0-9]*');
      final currencyMatches = currencyRegex.allMatches(lines[i]);

      for (final match in currencyMatches) {
        final amountStart = currentPos + match.start;
        final amountLength = match.end - match.start;
        controller.formatText(amountStart, amountLength, Attribute.bold);
      }

      currentPos += lines[i].length + 1;
    }
  }

  static IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Icons.edit;
      case 'sent':
        return Icons.send;
      case 'under_review':
        return Icons.visibility;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'signed':
        return Icons.verified;
      default:
        return Icons.info;
    }
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.grey;
      case 'sent':
        return Colors.blue;
      case 'under_review':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'signed':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  static String formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  static Future<Map<String, dynamic>> getContractById(String contractId) async {
    return await _supabase
        .from('Contracts')
        .select('*')
        .eq('contract_id', contractId)
        .single();
  }
}
