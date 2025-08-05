// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, deprecated_member_use
import 'package:backend/models/be_appbar.dart';
import 'package:backend/services/be_user_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class EditProfileScreen extends StatefulWidget {
  final String userId;
  final bool isContractor;

  const EditProfileScreen({
    super.key,
    required this.userId,
    required this.isContractor,
  });

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _firmNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController();
  
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  String? _profileImage;
  bool _isUploadingImage = false;

  static const String profileUrl =
      'https://bgihfdqruamnjionhkeq.supabase.co/storage/v1/object/public/profilephotos/defaultpic.png';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final userData = await UserService().fetchUserData(
        widget.userId,
        isContractor: widget.isContractor,
      );

      if (userData != null) {
        setState(() {
          if (widget.isContractor) {
            _firmNameController.text = userData['firm_name'] ?? "";
            _bioController.text = userData['bio'] ?? "";
            _contactNumberController.text = userData['contact_number'] ?? "";
            _specializationController.text = userData['specialization'] ?? "";
          } else {
            _fullNameController.text = userData['full_name'] ?? "";
            _addressController.text = userData['address'] ?? "";
          }
          _profileImage = userData['profile_photo'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load profile data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateProfilePhoto() async {
    setState(() => _isUploadingImage = true);
    
    try {
      Uint8List? imageBytes = await UserService().pickImage();
      
      if (imageBytes != null) {
        final String? imageUrl = await UserService().uploadImage(imageBytes, 'profilephotos');
        
        if (imageUrl != null) {
          final success = await UserService().updateProfilePhoto(
            widget.userId,
            imageUrl,
            isContractor: widget.isContractor,
          );
          
          if (success) {
            setState(() => _profileImage = imageUrl);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile photo updated successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _updateProfile() async {
    if (_isSaving) return;
    
    setState(() => _isSaving = true);
    
    try {
      bool success;
      
      if (widget.isContractor) {
        success = await _updateContractorProfile();
      } else {
        success = await UserService().updateUserProfile(
          widget.userId,
          _fullNameController.text.trim(),
          _addressController.text.trim(),
          isContractor: false,
        );
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<bool> _updateContractorProfile() async {
    try {
      final supabase = Supabase.instance.client;
      
      await supabase.from('Contractor').update({
        'firm_name': _firmNameController.text.trim(),
        'bio': _bioController.text.trim(),
        'contact_number': _contactNumberController.text.trim(),
        'specialization': _specializationController.text.trim(),
      }).eq('contractor_id', widget.userId);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    
    if (_isLoading) {
      return Scaffold(
        appBar: const ConTrustAppBar(headline: 'Edit Profile'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: const ConTrustAppBar(headline: 'Edit Profile'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: (_profileImage != null && _profileImage!.isNotEmpty)
                            ? NetworkImage(_profileImage!)
                            : NetworkImage(profileUrl),
                        child: (_profileImage == null || _profileImage!.isEmpty)
                            ? const Icon(Icons.person, size: 60, color: Colors.grey)
                            : null,
                      ),
                      if (_isUploadingImage)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isUploadingImage ? null : _updateProfilePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(_isUploadingImage ? 'Uploading...' : 'Change Photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            if (widget.isContractor) ...[
              _buildTextField(
                controller: _firmNameController,
                label: 'Firm Name',
                icon: Icons.business,
                isRequired: true,
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _contactNumberController,
                label: 'Contact Number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                isRequired: true,
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _specializationController,
                label: 'Specialization',
                icon: Icons.work,
                hint: 'e.g., Residential, Commercial, Renovation',
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _bioController,
                label: 'Bio',
                icon: Icons.description,
                maxLines: 4,
                hint: 'Tell clients about your experience and expertise...',
              ),
            ] else ...[
              _buildTextField(
                controller: _fullNameController,
                label: 'Full Name',
                icon: Icons.person,
                isRequired: true,
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _addressController,
                label: 'Address',
                icon: Icons.location_on,
                maxLines: 3,
                isRequired: true,
              ),
            ],
            
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSaving
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Saving...'),
                        ],
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? hint,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.blue.shade600, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
