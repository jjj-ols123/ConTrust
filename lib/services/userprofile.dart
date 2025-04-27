// user_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class UserService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> fetchUserData(String userId,
      {required bool isContractor}) async {
    try {
      final tableName = isContractor ? 'Contractor' : 'Contractee';
      final response = await supabase
          .from(tableName)
          .select()
          .eq(isContractor ? 'contractor_id' : 'contractee_id', userId)
          .single();

      if (tableName == "Contractor") {
        return {
          'firm_name': response['firm_name'] ?? "No firm name",
          'bio': response['bio'] ?? "No bio available",
          'rating': (response['rating'] ?? 4.5).toDouble(),
          'profile_photo':
              response['profile_photo'] ?? 'Portrait_Placeholder.png',
          'past_projects': List<String>.from(response['past_projects'] ?? []),
        };
      } else {
        return {
          'full_name': response['full_name'] ?? "No full name",
          'address': response['address'] ?? "No address available",
          'profile_photo':
              response['profile_photo'] ?? 'Portrait_Placeholder.png',
          'project_history_count':
              (response['project_history_count'] ?? 0).toInt(),
        };
      }
    } catch (error) {
      return null;
    }
  }

  Future<String?> uploadImage(Uint8List imageBytes, String bucketName) async {
    try {
      final String filePath = '${DateTime.now().millisecondsSinceEpoch}.png';

      await supabase.storage
          .from(bucketName)
          .uploadBinary(filePath, imageBytes);

      return supabase.storage.from(bucketName).getPublicUrl(filePath);
    } catch (error) {
      return null;
    }
  }

  Future<bool> updateProfilePhoto(String userId, String imageUrl,
      {required bool isContractor}) async {
    try {
      final tableName = isContractor ? 'Contractor' : 'Contractee';
      await supabase.from(tableName).update({'profile_photo': imageUrl}).eq(
          isContractor ? 'contractor_id' : 'contractee_id', userId);
      return true;
    } catch (error) {
      return false;
    }
  }

  Future<bool> addPastProjectPhoto(
    String contractorId,
    Uint8List imageBytes,
  ) async {
    final String? imageUrl = await uploadImage(imageBytes, 'pastprojects');

    if (imageUrl == null) return false;

    try {
      final response = await supabase
          .from('Contractor')
          .select('past_projects')
          .eq('contractor_id', contractorId)
          .single();

      List<String> pastProjects = response['past_projects'] != null
          ? List<String>.from(response['past_projects'])
          : [];

      pastProjects.add(imageUrl);

      await supabase.from('Contractor').update(
          {'past_projects': pastProjects}).eq('contractor_id', contractorId);
      return true;
    } catch (error) {
      return false;
    }
  }

  Future<bool> updateUserProfile(
    String userId,
    String firstText,
    String secondText, {
    required bool isContractor,
  }) async {
    try {
      final tableName = isContractor ? 'Contractor' : 'Contractee';
      final idField = isContractor ? 'contractor_id' : 'contractee_id';

      final updateData = isContractor
          ? {
              'firm_name': firstText,
              'bio': secondText,
            }
          : {
              'full_name': firstText,
              'address': secondText,
            };

      await supabase.from(tableName).update(updateData).eq(idField, userId);

      return true;
    } catch (error) {
      return false;
    }
  }

 Future<Uint8List?> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return await pickedFile.readAsBytes();
    }
    return null;
  }
}
