import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

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
      print('SignIn error in UserService: $e');
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
    
    print('Warning: Auth state consistency check timed out');
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
      print('SignUp error in UserService: $e');
      rethrow;
    }
  }


  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<AuthResponse> signInAnonymously() async {
    return await _supabase.auth.signInAnonymously();
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
        return {
          'firm_name': response['firm_name'] ?? "No firm name",
          'bio': response['bio'] ?? "No bio available",
          'rating': (response['rating'] ?? 4.5).toDouble(),
          'profile_photo': response['profile_photo'] ?? 'defaultpic.png',
          'past_projects': List<String>.from(response['past_projects'] ?? []),
          'contact_number': response['contact_number'] ?? "No contact number",
          'specialization': response['specialization'] ?? "No specialization",
        };
      } else {
        return {
          'full_name': response['full_name'] ?? "No full name",
          'address': response['address'] ?? "No address available",
          'profile_photo': response['profile_photo'] ?? 'defaultpic.png',
          'project_history_count':
              (response['project_history_count'] ?? 0).toInt(),
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
    final String resolvedFileName = fileName ?? '${DateTime.now().millisecondsSinceEpoch}.png';
    final String filePath = folderPath != null ? '$folderPath/$resolvedFileName' : resolvedFileName;

    await _supabase.storage
        .from(bucketName)
        .uploadBinary(filePath, imageBytes, fileOptions: FileOptions(upsert: upsert));

    return _supabase.storage.from(bucketName).getPublicUrl(filePath);
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
    final String contractorFolder = 'contractor_$contractorId';
    
    final String imageUrl = await uploadImage(imageBytes, 'pastprojects', folderPath: contractorFolder);

    try {
      final response = await _supabase
          .from('Contractor')
          .select('past_projects')
          .eq('contractor_id', contractorId)
          .single();

      List<String> pastProjects = response['past_projects'] != null
          ? List<String>.from(response['past_projects'])
          : [];

      pastProjects.add(imageUrl);

      await _supabase.from('Contractor').update(
          {'past_projects': pastProjects}).eq('contractor_id', contractorId);
      return true;
    } catch (error) {
      return false;
    }
  }

  Future<Uint8List?> pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return await pickedFile.readAsBytes();
    }
    return null;
  }
}
