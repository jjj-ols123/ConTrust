import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class UserService {
  SupabaseClient get _supabase => Supabase.instance.client;

 Future<AuthResponse?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
     
      await _waitForAuthConsistency(response.user?.id);
      
      return response;
    } catch (e) {
      rethrow; 
    }
  }

  Future<void> _waitForAuthConsistency(String? userId) async {
    if (userId == null) return;
    
   
    int retries = 0;
    while (retries < 5) {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser?.id == userId) {
 
        await Future.delayed(const Duration(milliseconds: 200));
        return;
      }
      await Future.delayed(const Duration(milliseconds: 100));
      retries++;
    }
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email, 
        password: password, 
        data: data
      );
      
      if (response.user != null) {
        await _waitForAuthConsistency(response.user?.id);
      }
      
      return response;
    } catch (e) {
      rethrow;
    }
  }


  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<AuthResponse> signInAnonymously() async {
    return await _supabase.auth.signInAnonymously();
  }

  Future<bool> changePassword({
    required String newPassword,
    String? oldPassword,
  }) async {
    try {
      if (newPassword.length < 6) {
        throw Exception('Password must be at least 6 characters long');
      }
      
      if (newPassword.length > 15) {
        throw Exception('Password must be no more than 15 characters long');
      }

      final hasUppercase = newPassword.contains(RegExp(r'[A-Z]'));
      final hasNumber = newPassword.contains(RegExp(r'[0-9]'));
      final hasSpecialChar = newPassword.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

      if (!hasUppercase || !hasNumber || !hasSpecialChar) {
        throw Exception('Password must include uppercase, number and special character');
      }

      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      return response.user != null;
    } catch (e) {
      rethrow;
    }
  }
  Future<void> resetPassword(String email, {String? redirectTo}) async {
    try {
      final response = await _supabase.functions.invoke(
        'send-password-reset-email',
        body: {
          'email': email,
          'redirectTo': redirectTo ?? 'https://contrust-sjdm.com/auth/reset-password',
        },
      );

      if (response.status != 200) {
        final errorData = response.data;
        final errorMessage = errorData?['error'] ?? errorData?['message'] ?? 'Failed to send password reset email';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e.toString().toLowerCase().contains('no user')) {
        throw Exception('No account found with this email address');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async { 
    final response = await _supabase
        .rpc('get_auth_user', params: {'user_id': userId}).single();
    return response;
  }

  Future<String?> getContractorId() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('Contractor')
          .select('contractor_id')
          .eq('contractor_id', user.id)
          .maybeSingle();
      return response?['contractor_id'].toString();
    } catch (error) {
      return null;
    }
  }

  Future<String?> getCurrentUserId() async {
    return _supabase.auth.currentUser?.id;
  }

  Future<String?> getContracteeId() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('Contractee')
          .select('contractee_id')
          .eq('contractee_id', user.id)
          .maybeSingle();
      return response?['contractee_id']?.toString();
    } catch (error) {
      return null;
    }
  }

  Future<String?> getCurrentUserType() async {
    final session = _supabase.auth.currentSession;
    if (session == null) return null;

    await _supabase.auth.refreshSession();
    final user = _supabase.auth.currentUser;
    final type = user?.userMetadata?['user_type'];
    return type?.toString();
  }

  Future<void> checkContracteeId(String userId) async {
    final response = await _supabase
        .from('Contractee')
        .select()
        .eq('contractee_id', userId)
        .maybeSingle();

    if (response == null) {
      throw Exception('Contractee not found');
    }
  }

  Future<void> checkContractorId(String userId) async {
    final response = await _supabase
        .from('Contractor')
        .select()
        .eq('contractor_id', userId)
        .maybeSingle();

    if (response == null) {
      throw Exception('Contractor not found');
    }
  }

  Future<Map<String, dynamic>?> fetchUserData(String userId,
      {required bool isContractor}) async {
    try {
      final tableName = isContractor ? 'Contractor' : 'Contractee';
      final response = await _supabase
          .from(tableName)
          .select()
          .eq(isContractor ? 'contractor_id' : 'contractee_id', userId)
          .single();

      if (tableName == "Contractor") {
        String email = '';
        try {
          final userData = await _supabase
              .from('Users')
              .select('email')
              .eq('users_id', userId)
              .maybeSingle();
          if (userData != null) {
            email = userData['email'] ?? '';
          }
        } catch (_) {}

        return {
          'firm_name': response['firm_name'] ?? "No firm name",
          'bio': response['bio'] ?? "No bio available",
          'rating': (response['rating'] ?? 0.0).toDouble(),
          'profile_photo': response['profile_photo'] ?? 'defaultpic.png',
          'past_projects': List<String>.from(response['past_projects'] ?? []),
          'contact_number': response['contact_number'] ?? "No contact number",
          'specialization': response['specialization'] ?? "No specialization",
          'address': response['address'] ?? "No address provided",
          'email': email,
        };
      } else {

        String email = '';
        try {
          final userData = await _supabase
              .from('Users')
              .select('email')
              .eq('users_id', userId)
              .maybeSingle();
          if (userData != null) {
            email = userData['email'] ?? '';
          }
        } catch (e) {
          //
        }
        
        return {
          'full_name': response['full_name'] ?? "",
          'phone_number': response['phone_number'] ?? "",
          'address': response['address'] ?? "",
          'email': email,
          'profile_photo': response['profile_photo'] ?? 'defaultpic.png',
          'project_history_count':
              (response['project_history_count'] ?? 0).toInt(),
          'contractee_id': response['contractee_id'],
        };
      }
    } catch (error) {
      return null;
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

      await _supabase.from(tableName).update(updateData).eq(idField, userId);
      return true;
    } catch (error) {
      return false;
    }
  }

  Future<String> uploadImage(
    Uint8List imageBytes,
    String bucketName, {
    String? folderPath,
    String? fileName,
    bool upsert = false,
  }) async {
    try {
      final String resolvedFileName = fileName ?? '${DateTime.now().millisecondsSinceEpoch}.png';
      final String filePath = folderPath != null ? '$folderPath/$resolvedFileName' : resolvedFileName;

      debugPrint('[uploadImage] Uploading to bucket: $bucketName, path: $filePath, size: ${imageBytes.length} bytes');

      await _supabase.storage
          .from(bucketName)
          .uploadBinary(filePath, imageBytes, fileOptions: FileOptions(upsert: upsert));

      final publicUrl = _supabase.storage.from(bucketName).getPublicUrl(filePath);
      debugPrint('[uploadImage] Upload successful, public URL: $publicUrl');
      
      return publicUrl;
    } catch (e) {
      debugPrint('[uploadImage] Error uploading image: $e');
      rethrow;
    }
  }

  Future<bool> updateProfilePhoto(String userId, String imageUrl,
      {required bool isContractor}) async {
    try {
      final tableName = isContractor ? 'Contractor' : 'Contractee';
      await _supabase.from(tableName).update({'profile_photo': imageUrl}).eq(
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
    try {
      final String contractorFolder = 'contractor_$contractorId';
      
      // Upload image to storage
      final String imageUrl = await uploadImage(imageBytes, 'pastprojects', folderPath: contractorFolder);
      
      if (imageUrl.isEmpty) {
        debugPrint('[addPastProjectPhoto] Failed to get image URL after upload');
        return false;
      }

      // Fetch current past projects
      final response = await _supabase
          .from('Contractor')
          .select('past_projects')
          .eq('contractor_id', contractorId)
          .single();

      List<String> pastProjects = response['past_projects'] != null
          ? List<String>.from(response['past_projects'])
          : [];

      // Add new image URL
      pastProjects.add(imageUrl);

      // Update database
      await _supabase.from('Contractor').update(
          {'past_projects': pastProjects}).eq('contractor_id', contractorId);
      
      debugPrint('[addPastProjectPhoto] Successfully uploaded and saved photo: $imageUrl');
      return true;
    } catch (error) {
      debugPrint('[addPastProjectPhoto] Error: $error');
      return false;
    }
  }

  Future<Uint8List?> pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      
      // Check file size (max 10MB)
      const maxSizeBytes = 10 * 1024 * 1024; // 10MB
      if (bytes.length > maxSizeBytes) {
        return null; // File too large
      }
      
      // Check file extension or image format (only PNG/JPG)
      final extension = pickedFile.path.contains('.') 
          ? pickedFile.path.split('.').last.toLowerCase()
          : '';
      
      // If no extension, check image format from bytes (PNG starts with 89 50 4E 47, JPEG starts with FF D8 FF)
      bool isValidImage = false;
      if (extension == 'jpg' || extension == 'jpeg' || extension == 'png') {
        isValidImage = true;
      } else if (bytes.length >= 4) {
        // Check PNG signature: 89 50 4E 47 (0x89 0x50 0x4E 0x47)
        if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
          isValidImage = true;
        }
        // Check JPEG signature: FF D8 FF
        else if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
          isValidImage = true;
        }
      }
      
      if (!isValidImage) {
        return null; // Invalid format
      }
      
      return bytes;
    }
    return null;
  }

  Future<void> updateUserVerifiedStatus(String userId, bool verified) async {
    try {
      await _supabase.from('Users').update({
        'verified': verified,
      }).eq('users_id', userId);
    } catch (e) {
      rethrow;
    }
  }
}
