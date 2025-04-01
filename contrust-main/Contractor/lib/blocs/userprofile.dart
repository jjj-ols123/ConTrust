// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class UserService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> fetchContractorData(String contractorId) async {
    try {
      final response =
          await supabase
              .from('Contractor')
              .select()
              .eq('contractor_id', contractorId)
              .single();

      return {
        'firm_name': response['firm_name'] ?? "No firm name",
        'bio': response['bio'] ?? "No bio available",
        'rating': (response['rating'] ?? 4.5).toDouble(),
        'profile_photo': response['profile_photo'] ?? 'default_image_url',
        'past_projects': List<String>.from(response['past_projects'] ?? []),
      };
    } catch (error) {
      print("Error fetching contractor data: $error");
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
      print("Error uploading image to $bucketName: $error");
      return null;
    }
  }

  Future<bool> updateProfilePhoto(String contractorId, String imageUrl) async {
    try {
      await supabase
          .from('Contractor')
          .update({'profile_photo': imageUrl})
          .eq('contractor_id', contractorId);
      return true;
    } catch (error) {
      print("Error updating profile photo: $error");
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
      final response =
          await supabase
              .from('Contractor')
              .select('past_projects')
              .eq('contractor_id', contractorId)
              .single();

      List<String> pastProjects =
          response['past_projects'] != null
              ? List<String>.from(response['past_projects'])
              : [];

      pastProjects.add(imageUrl);

      await supabase
          .from('Contractor')
          .update({'past_projects': pastProjects})
          .eq('contractor_id', contractorId);
      return true;
    } catch (error) {
      print("Error updating past projects: $error");
      return false;
    }
  }

  Future<bool> updateContractorProfile(
    String contractorId,
    String firmName,
    String bio,
  ) async {
    try {
      await supabase
          .from('Contractor')
          .update({'firm_name': firmName, 'bio': bio})
          .eq('contractor_id', contractorId);
      return true;
    } catch (error) {
      print("Error updating profile: $error");
      return false;
    }
  }
}
