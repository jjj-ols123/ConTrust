// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, unnecessary_type_check, deprecated_member_use, depend_on_referenced_packages, unused_local_variable, dead_code, curly_braces_in_flow_control_structures

import 'dart:io' show File;
import 'dart:typed_data';

import 'package:backend/services/both services/be_bidding_service.dart';
import 'package:backend/services/both services/be_project_service.dart';
import 'package:backend/services/both services/be_realtime_service.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:backend/utils/be_validation.dart';
import 'package:backend/utils/be_constraint.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

String toProperCase(String text) {
  if (text.isEmpty) return text;
  
  final words = text.trim().split(RegExp(r'\s+'));
  final properCaseWords = words.map((word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).toList();
  
  return properCaseWords.join(' ');
}

const String profileUrl =
    'https://bgihfdqruamnjionhkeq.supabase.co/storage/v1/object/public/profilephotos/defaultpic.png';

/// Show date picker with amber theme matching add tasks dialog
Future<DateTime?> showThemedDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? helpText,
  String? cancelText,
  String? confirmText,
}) async {
  return await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    helpText: helpText ?? 'Select Date',
    cancelText: cancelText ?? 'Cancel',
    confirmText: confirmText ?? 'OK',
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Colors.amber.shade700,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black87,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Colors.amber.shade700,
            ),
          ),
        ),
        child: child!,
      );
    },
  );
}

class ProjectDialog extends StatefulWidget {
  final String contracteeId;
  final TextEditingController titleController;
  final TextEditingController constructionTypeController;
  final TextEditingController minBudgetController;
  final TextEditingController maxBudgetController;
  final TextEditingController locationController;
  final TextEditingController descriptionController;
  final TextEditingController bidTimeController;
  final bool isUpdate;
  final String? projectId;
  final VoidCallback? onRefresh;
  final BuildContext parentContext;
  final String? initialStartDate;

  const ProjectDialog({
    super.key,
    required this.contracteeId,
    required this.titleController,
    required this.constructionTypeController,
    required this.minBudgetController,
    required this.maxBudgetController,
    required this.locationController,
    required this.descriptionController,
    required this.bidTimeController,
    this.isUpdate = false,
    this.projectId,
    this.onRefresh,
    required this.parentContext,
    this.initialStartDate,
  });

  @override
  State<ProjectDialog> createState() => _ProjectDialogState();
}

class _ProjectDialogState extends State<ProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _customTypeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  Uint8List? _selectedPhoto;
  String? _photoUrl;
  bool _isUploadingPhoto = false;
  String? _selectedBarangay;

  static const List<String> _availableSpecializations = [
    'General Construction',
    'Residential Construction',
    'Commercial Construction',
    'Interior Design',
    'Exterior Design',
    'Architecture',
    'Electrical Work',
    'Plumbing',
    'HVAC (Heating, Ventilation, Air Conditioning)',
    'Roofing',
    'Flooring',
    'Painting',
    'Landscaping',
    'Kitchen Renovation',
    'Bathroom Renovation',
    'Structural Engineering',
    'Civil Engineering',
    'Project Management',
    'Home Improvement',
    'Maintenance & Repair',
    'Concrete Work',
    'Masonry',
    'Carpentry',
    'Welding',
    'Flooring Installation',
    'Wall Finishing',
    'Window Installation',
    'Door Installation',
    'Tile Work',
    'Drywall',
    'Insulation',
    'Solar Installation',
    'Smart Home Integration',
  ];

  static const List<String> _barangays = [
    'Minuyan Proper',
    'Minuyan I',
    'Minuyan II',
    'Minuyan III',
    'Minuyan IV',
    'Minuyan V',
    'Bagong Buhay I',
    'Bagong Buhay II',
    'Bagong Buhay III',
    'San Martin I',
    'San Martin II',
    'San Martin III',
    'San Martin IV',
    'Sta. Cruz I',
    'Sta. Cruz II',
    'Sta. Cruz III',
    'Sta. Cruz IV',
    'Sta. Cruz V',
    'Fatima I',
    'Fatima II',
    'Fatima III',
    'Fatima IV',
    'Fatima V',
    'Citrus',
    'San Pedro',
    'Sapang Palay Proper',
    'San Martin De Porres',
    'Assumption',
    'Sto. Nino I',
    'Sto. Nino II',
    'Lawang Pare',
    'San Rafael I',
    'San Rafael II',
    'San Rafael III',
    'San Rafael IV',
    'San Rafael V',
    'Poblacion',
    'Poblacion 1',
    'Francisco Homes - Narra',
    'Francisco Homes - Mulawin',
    'Francisco Homes - Yakall',
    'Francisco Homes - Guijo',
    'Gumaok East',
    'Gumaok West',
    'Gumaok Central',
    'Graceville',
    'Gaya-gaya',
    'Sto. Cristo',
    'Tungkong Mangga',
    'Dulong Bayan',
    'Ciudad Real',
    'Maharlika',
    'San Manuel',
    'Kaypian',
    'San Isidro',
    'San Roque',
    'Kaybanban',
    'Paradise III',
    'Muzon Proper',
    'Muzon East',
    'Muzon West',
    'Muzon South',
  ];

  bool _showCustomTypeField = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialStartDate != null &&
        widget.initialStartDate!.isNotEmpty) {
      try {
        final date = DateTime.parse(widget.initialStartDate!);
        _startDateController.text = DateFormat('yyyy-MM-dd').format(date);
      } catch (e) {
        _startDateController.text = widget.initialStartDate!;
      }
    }

    // Check if current type is custom
    if (widget.constructionTypeController.text.isNotEmpty) {
      final currentType = widget.constructionTypeController.text;
      if (!_availableSpecializations.contains(currentType) && 
          currentType.toLowerCase() != 'other') {
        setState(() {
          _showCustomTypeField = true;
          _customTypeController.text = currentType;
          widget.constructionTypeController.text = 'Other';
        });
      }
    }

    final existingLocation = widget.locationController.text.trim();
    if (existingLocation.isNotEmpty) {
      const citySuffix = 'SJDM, Bulacan';
      String withoutCity = existingLocation;
      if (withoutCity.toLowerCase().endsWith(citySuffix.toLowerCase())) {
        withoutCity = withoutCity
            .substring(0, withoutCity.length - citySuffix.length)
            .trim();
        if (withoutCity.endsWith(',')) {
          withoutCity =
              withoutCity.substring(0, withoutCity.length - 1).trim();
        }
      }
      final parts = withoutCity.split(',');
      if (parts.length >= 2) {
        final barangayCandidate = parts.last.trim();
        if (_barangays.contains(barangayCandidate)) {
          _selectedBarangay = barangayCandidate;
          _addressController.text =
              parts.sublist(0, parts.length - 1).join(',').trim();
        } else {
          _addressController.text = withoutCity;
        }
      } else {
        _addressController.text = withoutCity;
      }
    }
  }

  bool _isLoading = false;

  Future<void> _pickPhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 60,
      );

      if (pickedFile != null) {
        Uint8List? bytes;
        try {
          bytes = await pickedFile.readAsBytes();
        } catch (readError) {
          bool recovered = false;
          if (pickedFile.path.isNotEmpty) {
            try {
              bytes = await File(pickedFile.path).readAsBytes();
              recovered = true;
            } catch (_) {
              // fall through to stream fallback
            }
          }

          if (!recovered) {
            try {
              final builder = BytesBuilder();
              await for (final chunk in pickedFile.openRead()) {
                builder.add(chunk);
              }
              bytes = builder.takeBytes();
              recovered = true;
            } catch (streamError) {
              if (mounted) {
                ConTrustSnackBar.error(
                  context,
                  'Failed to read selected file: $streamError',
                );
              }
              return;
            }
          }
        }
        
        // Check file size (max 10MB)
        if (bytes == null) {
          if (mounted) {
            ConTrustSnackBar.error(
              context,
              'Failed to read selected image. Please try again.',
            );
          }
          return;
        }

        final Uint8List confirmedBytes = bytes;

        const maxSizeBytes = 10 * 1024 * 1024; // 10MB
        if (confirmedBytes.length > maxSizeBytes) {
          if (mounted) {
            ConTrustSnackBar.error(
              context, 
              'Image size exceeds 10MB limit. Please choose a smaller image.'
            );
          }
          return;
        }
        
        final extension = pickedFile.path.contains('.') 
            ? pickedFile.path.split('.').last.toLowerCase()
            : '';
        
        bool isValidImage = false;
        if (extension == 'jpg' || extension == 'jpeg' || extension == 'png') {
          isValidImage = true;
        } else if (confirmedBytes.length >= 4) {
          if (confirmedBytes[0] == 0x89 && confirmedBytes[1] == 0x50 && confirmedBytes[2] == 0x4E && confirmedBytes[3] == 0x47) {
            isValidImage = true;
          }
          else if (confirmedBytes.length >= 3 && confirmedBytes[0] == 0xFF && confirmedBytes[1] == 0xD8 && confirmedBytes[2] == 0xFF) {
            isValidImage = true;
          }
        }
        
        if (!isValidImage) {
          if (mounted) {
            ConTrustSnackBar.error(
              context, 
              'Only PNG and JPG images are allowed.'
            );
          }
          return;
        }
        
        setState(() {
          _selectedPhoto = confirmedBytes;
          _photoUrl = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ConTrustSnackBar.error(context, 'Failed to pick image: $e');
      }
    }
  }

  Future<String?> _uploadPhoto() async {
    if (_selectedPhoto == null) return null;

    setState(() => _isUploadingPhoto = true);
    try {
      final supabase = Supabase.instance.client;
      final fileName = '${widget.contracteeId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'contractee/photo_url/$fileName';

      await supabase.storage
          .from('projectphotos')
          .uploadBinary(
            storagePath,
            _selectedPhoto!,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      setState(() {
        _photoUrl = storagePath;
        _isUploadingPhoto = false;
      });

      return storagePath;
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      if (mounted) {
        debugPrint('Photo upload error: $e');
        ConTrustSnackBar.error(context, 'Failed to upload photo: ${e.toString()}');
      }
      return null;
    }
  }

  Future<void> _selectStartDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final minStartDate = today.add(const Duration(days: 7));
    final maxStartDate = today.add(const Duration(days: 365));

    final DateTime? picked = await showThemedDatePicker(
      context: context,
      initialDate: minStartDate,
      firstDate: minStartDate,
      lastDate: maxStartDate,
    );
    if (picked != null) {
      _startDateController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final startdate_format =
          DateTime.parse(_startDateController.text.trim());

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final minAllowed = today.add(const Duration(days: 7));
      if (startdate_format.isBefore(minAllowed)) {
        setState(() => _isLoading = false);
        ConTrustSnackBar.error(
          widget.parentContext,
          'Start date must be at least 7 days from today.',
        );
        return;
      }

      final composedLocation =
          '${_addressController.text.trim()}, ${_selectedBarangay ?? ''}, SJDM, Bulacan';
      widget.locationController.text = composedLocation;

      final isValid = validateFieldsPostRequest(
        widget.parentContext,
        widget.titleController.text.trim(),
        widget.constructionTypeController.text.trim(),
        widget.minBudgetController.text.trim(),
        widget.maxBudgetController.text.trim(),
        _startDateController.text.trim(),
        composedLocation,
        widget.descriptionController.text.trim(),
        widget.bidTimeController.text.trim(),
      );

      if (!isValid) return;

      String finalProjectType;
      if (widget.constructionTypeController.text.trim().toLowerCase() == 'other') {
        if (_customTypeController.text.trim().isEmpty) {
          setState(() => _isLoading = false);
          ConTrustSnackBar.error(
            widget.parentContext,
            'Please enter a construction type when "Other" is selected.',
          );
          return;
        }
        finalProjectType = toProperCase(_customTypeController.text.trim());
      } else {
        finalProjectType = widget.constructionTypeController.text.trim();
      }
      
      String? uploadedPhotoUrl = _photoUrl;
      if (_selectedPhoto != null && _photoUrl == null) {
        uploadedPhotoUrl = await _uploadPhoto();
      }

      if (widget.isUpdate && widget.projectId != null) {
        await ProjectService().updateProject(
          projectId: widget.projectId!,
          title: widget.titleController.text.trim(),
          type: finalProjectType,
          description: widget.descriptionController.text.trim(),
          location: composedLocation,
          minBudget: double.tryParse(widget.minBudgetController.text.trim()),
          maxBudget: double.tryParse(widget.maxBudgetController.text.trim()),
          duration: int.tryParse(widget.bidTimeController.text.trim()) ?? 7,
          startDate: startdate_format,
          photoUrl: uploadedPhotoUrl,
        );
      } else {
        await ProjectService().postProject(
          contracteeId: widget.contracteeId,
          title: widget.titleController.text.trim(),
          type: finalProjectType,
          description: widget.descriptionController.text.trim(),
          location: composedLocation,
          minBudget: widget.minBudgetController.text.trim(),
          maxBudget: widget.maxBudgetController.text.trim(),
          duration: widget.bidTimeController.text.trim(),
          startDate: startdate_format,
          context: widget.parentContext,
          photoUrl: uploadedPhotoUrl,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true); 
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(false);
      }
      ConTrustSnackBar.error(
          widget.parentContext, 'Error submitting project. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTwoColumnDropdown() {
    final selectedValue = widget.constructionTypeController.text.isNotEmpty &&
            (_availableSpecializations.contains(widget.constructionTypeController.text) ||
             widget.constructionTypeController.text.toLowerCase() == 'other')
        ? widget.constructionTypeController.text
        : null;

    return InkWell(
      onTap: () async {
        final result = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => Container(
            constraints: const BoxConstraints(maxHeight: 500),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'Select Construction Type',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._availableSpecializations.map((spec) => ChoiceChip(
                          label: Text(spec, style: const TextStyle(fontSize: 12)),
                          selected: selectedValue == spec,
                          selectedColor: Colors.amber.shade100,
                          checkmarkColor: Colors.amber.shade900,
                          onSelected: (selected) {
                            if (selected) Navigator.pop(context, spec);
                          },
                        )),
                        ChoiceChip(
                          label: const Text('Other', style: TextStyle(fontSize: 12)),
                          selected: selectedValue?.toLowerCase() == 'other',
                          selectedColor: Colors.amber.shade100,
                          checkmarkColor: Colors.amber.shade900,
                          onSelected: (selected) {
                            if (selected) Navigator.pop(context, 'Other');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        if (result != null && mounted) {
          setState(() {
            widget.constructionTypeController.text = result;
            _showCustomTypeField = (result.toLowerCase() == 'other');
            if (!_showCustomTypeField) {
              _customTypeController.clear();
            }
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Select construction type',
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          selectedValue ?? 'Select construction type',
          style: TextStyle(
            color: selectedValue != null ? Colors.black87 : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  static Widget _buildTwoColumnDropdownForHire({
    required BuildContext context,
    required String? selectedValue,
    required List<String> availableSpecializations,
    required Function(String) onSelected,
  }) {
    return InkWell(
      onTap: () async {
        final result = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => Container(
            constraints: const BoxConstraints(maxHeight: 500),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'Select Construction Type',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...availableSpecializations.map((spec) => ChoiceChip(
                          label: Text(spec, style: const TextStyle(fontSize: 12)),
                          selected: selectedValue == spec,
                          selectedColor: Colors.amber.shade100,
                          checkmarkColor: Colors.amber.shade900,
                          onSelected: (selected) {
                            if (selected) Navigator.pop(context, spec);
                          },
                        )),
                        ChoiceChip(
                          label: const Text('Other', style: TextStyle(fontSize: 12)),
                          selected: selectedValue?.toLowerCase() == 'other',
                          selectedColor: Colors.amber.shade100,
                          checkmarkColor: Colors.amber.shade900,
                          onSelected: (selected) {
                            if (selected) Navigator.pop(context, 'Other');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        if (result != null) {
          onSelected(result);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Select construction type',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          selectedValue ?? 'Select construction type',
          style: TextStyle(
            color: selectedValue != null ? Colors.black87 : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _customTypeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final sortedBarangays = List<String>.from(_barangays)..sort();
    
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: isMobile 
                  ? const BoxConstraints(
                      maxWidth: double.infinity,
                      maxHeight: double.infinity,
                    )
                  : const BoxConstraints(maxWidth: 800),
              margin: isMobile 
                  ? EdgeInsets.zero 
                  : const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: isMobile 
                    ? BorderRadius.zero 
                    : BorderRadius.circular(20),
                border: Border.all(color: Colors.black, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 1,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700,
                      borderRadius: isMobile 
                          ? BorderRadius.zero
                          : const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            widget.isUpdate ? Icons.edit : Icons.add_business,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.isUpdate
                                ? "Update Project"
                                : "Post Construction Request",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close,
                              color: Colors.white, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 16),
                            _buildLabeledField(
                                label: 'Project Title',
                                child: TextFormField(
                                    controller: widget.titleController,
                                    decoration: const InputDecoration(
                                        labelText: 'Enter project title',
                                        border: OutlineInputBorder()),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Please enter a project title'
                                            : null)),
                            const SizedBox(height: 16),
                            _buildLabeledField(
                                label: 'Type of Construction',
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildTwoColumnDropdown(),
                                    if (_showCustomTypeField) ...[
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _customTypeController,
                                        decoration: const InputDecoration(
                                          labelText: 'Enter custom construction type',
                                          hintText: 'e.g., Kitchen Renovation',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.edit),
                                        ),
                                        textCapitalization: TextCapitalization.words,
                                        validator: (v) {
                                          if (_showCustomTypeField &&
                                              (v == null || v.trim().isEmpty)) {
                                            return 'Please enter a construction type';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            const SizedBox(height: 16),
                            _buildLabeledField(
                                label: 'Estimated Budget Range',
                                child: Row(children: [
                                  Expanded(
                                      child: TextFormField(
                                          controller: widget.minBudgetController,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                              labelText: 'Min Budget',
                                              prefixText: '₱',
                                              border: OutlineInputBorder()),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly
                                          ],
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty)
                                              return 'Please enter minimum budget';
                                            final n = int.tryParse(value.trim());
                                            if (n == null || n <= 0)
                                              return 'Budget must be > 0';
                                            return null;
                                          })),
                                  const SizedBox(width: 10),
                                  const Text('-',
                                      style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                      child: TextFormField(
                                          controller: widget.maxBudgetController,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                              labelText: 'Max Budget',
                                              prefixText: '₱',
                                              border: OutlineInputBorder()),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly
                                          ],
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty)
                                              return 'Please enter maximum budget';
                                            final n = int.tryParse(value.trim());
                                            if (n == null || n <= 0)
                                              return 'Budget must be > 0';
                                            final min = int.tryParse(widget
                                                    .minBudgetController.text
                                                    .trim()) ??
                                                0;
                                            if (n <= min)
                                              return 'Max must be greater';
                                            return null;
                                          })),
                                ])),
                            const SizedBox(height: 16),
                            _buildLabeledField(
                                label: 'Location',
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextFormField(
                                      controller: _addressController,
                                      decoration: const InputDecoration(
                                        labelText:
                                            'Home address / Street / Subdivision',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? 'Please enter your home address, street, and subdivision'
                                              : null,
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      value: _selectedBarangay,
                                      items: sortedBarangays
                                          .map(
                                            (b) => DropdownMenuItem<String>(
                                              value: b,
                                              child: Text(b),
                                            ),
                                          )
                                          .toList(),
                                      decoration: const InputDecoration(
                                        labelText: 'Select Barangay',
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedBarangay = value;
                                        });
                                      },
                                      validator: (value) =>
                                          (value == null || value.isEmpty)
                                              ? 'Please select a barangay'
                                              : null,
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      enabled: false,
                                      initialValue: 'SJDM, Bulacan',
                                      decoration: const InputDecoration(
                                        labelText: 'City',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ],
                                )),
                            const SizedBox(height: 16),
                            _buildLabeledField(
                                label: 'Preferred Start Date',
                                child: TextFormField(
                                    controller: _startDateController,
                                    readOnly: true,
                                    decoration: const InputDecoration(
                                        labelText: 'Select a start date',
                                        border: OutlineInputBorder(),
                                        suffixIcon: Icon(Icons.calendar_today)),
                                    onTap: _selectStartDate,
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Please select a start date'
                                            : null)),
                            const SizedBox(height: 16),
                            _buildLabeledField(
                                label: 'Message to Contractor',
                                child: TextFormField(
                                    controller: widget.descriptionController,
                                    maxLines: 4,
                                    decoration: const InputDecoration(
                                        labelText: 'Describe your project details',
                                        border: OutlineInputBorder()),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Please describe your project'
                                            : null)),
                            const SizedBox(height: 16),
                            _buildLabeledField(
                              label: 'Project Photo (Optional)',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_selectedPhoto != null || _photoUrl != null)
                                    Container(
                                      height: 150,
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: _selectedPhoto != null
                                            ? Image.memory(
                                                _selectedPhoto!,
                                                fit: BoxFit.cover,
                                              )
                                            : _photoUrl != null
                                                ? Image.network(
                                                    _photoUrl!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return const Icon(Icons.image, size: 50);
                                                    },
                                                  )
                                                : const SizedBox(),
                                      ),
                                    ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: _isUploadingPhoto ? null : _pickPhoto,
                                          icon: const Icon(Icons.photo_library),
                                          label: Text(_selectedPhoto != null ? 'Change Photo' : 'Select Photo'),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                        ),
                                      ),
                                      if (_selectedPhoto != null || _photoUrl != null) ...[
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _selectedPhoto = null;
                                              _photoUrl = null;
                                            });
                                          },
                                          icon: const Icon(Icons.delete_outline),
                                          color: Colors.red,
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (!widget.isUpdate ||
                                (widget.isUpdate &&
                                    (int.tryParse(widget.bidTimeController.text) ??
                                            0) >
                                        0))
                              _buildLabeledField(
                                  label: 'Bid Duration (in days)',
                                  child: Row(children: [
                                    IconButton(
                                        icon: const Icon(Icons.remove),
                                        onPressed: () {
                                          int current = int.tryParse(
                                                  widget.bidTimeController.text) ??
                                              1;
                                          if (current > 1) {
                                            current--;
                                            widget.bidTimeController.text =
                                                current.toString();
                                            setState(() {});
                                          }
                                        }),
                                    Expanded(
                                        child: TextFormField(
                                            controller: widget.bidTimeController,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                                labelText:
                                                    'Enter number of days (1–20)',
                                                border: OutlineInputBorder()),
                                            inputFormatters: [
                                              FilteringTextInputFormatter.digitsOnly
                                            ],
                                            validator: (value) {
                                              if (value == null ||
                                                  value.trim().isEmpty)
                                                return 'Please enter bid duration';
                                              final d = int.tryParse(value.trim());
                                              if (d == null || d < 1 || d > 20)
                                                return 'Bid duration 1-20 days';
                                              return null;
                                            },
                                            onChanged: (v) {
                                              int? n = int.tryParse(v);
                                              if (n == null || n < 1) {
                                                widget.bidTimeController.text = '1';
                                              } else if (n > 20)
                                                widget.bidTimeController.text =
                                                    '20';
                                            })),
                                    IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: () {
                                          int current = int.tryParse(
                                                  widget.bidTimeController.text) ??
                                              1;
                                          if (current < 20) {
                                            current++;
                                            widget.bidTimeController.text =
                                                current.toString();
                                            setState(() {});
                                          }
                                        }),
                                  ])),
                            const SizedBox(height: 24),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFB300),
                                  foregroundColor: Colors.black,
                                  minimumSize: const Size.fromHeight(50),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            color: Colors.black, strokeWidth: 2))
                                    : Text(widget.isUpdate
                                        ? "Update Project"
                                        : "Submit Request"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabeledField({
    required String label,
    required Widget child,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1000;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 180,
                  child: Text(
                    '$label:',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: child),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                child,
              ],
            ),
    );
  }
}

class ProjectModal {
  static Future<bool> show({
    required BuildContext context,
    required String contracteeId,
    required TextEditingController titleController,
    required TextEditingController constructionTypeController,
    required TextEditingController minBudgetController,
    required TextEditingController maxBudgetController,
    required TextEditingController locationController,
    required TextEditingController descriptionController,
    required TextEditingController bidTimeController,
    bool isUpdate = false,
    String? projectId,
    VoidCallback? onRefresh,
    String? initialStartDate,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProjectDialog(
        contracteeId: contracteeId,
        titleController: titleController,
        constructionTypeController: constructionTypeController,
        minBudgetController: minBudgetController,
        maxBudgetController: maxBudgetController,
        locationController: locationController,
        descriptionController: descriptionController,
        bidTimeController: bidTimeController,
        isUpdate: isUpdate,
        projectId: projectId,
        onRefresh: onRefresh,
        parentContext: context,
        initialStartDate: initialStartDate,
      ),
    );
    return result ?? false;
  }
}

class BidsModal {
  static const String profileUrl =
      'https://bgihfdqruamnjionhkeq.supabase.co/storage/v1/object/public/profilephotos/defaultpic.png';

  static Future<bool> show({
    required BuildContext context,
    required String projectId,
    required Future<void> Function(String projectId, String bidId)
        acceptBidding,
    String? initialAcceptedBidId,
    VoidCallback? onRefresh,
    String? projectStatus,
  }) async {
    String? acceptedBidId = initialAcceptedBidId;
    Future<List<Map<String, dynamic>>> bidsFuture =
        BiddingService().getBidsForProject(projectId);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 1,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: _BidsModalContent(
                projectId: projectId,
                initialAcceptedBidId: initialAcceptedBidId,
                acceptBidding: acceptBidding,
                onRefresh: onRefresh,
                projectStatus: projectStatus,
                initialBidsFuture: bidsFuture,
              ),
            ),
          ),
        );
      },
    );

    return result ?? false;
  }
}

class _BidsModalContent extends StatefulWidget {
  final String projectId;
  final String? initialAcceptedBidId;
  final Future<void> Function(String projectId, String bidId) acceptBidding;
  final VoidCallback? onRefresh;
  final String? projectStatus;
  final Future<List<Map<String, dynamic>>> initialBidsFuture;

  const _BidsModalContent({
    required this.projectId,
    this.initialAcceptedBidId,
    required this.acceptBidding,
    this.onRefresh,
    this.projectStatus,
    required this.initialBidsFuture,
  });

  @override
  State<_BidsModalContent> createState() => _BidsModalContentState();
}

class _BidsModalContentState extends State<_BidsModalContent> {
  String? acceptedBidId;
  late Future<List<Map<String, dynamic>>> bidsFuture;
  RealtimeChannel? _bidsChannel;
  int _refreshKey = 0; // Key to force FutureBuilder rebuild

  @override
  void initState() {
    super.initState();
    acceptedBidId = widget.initialAcceptedBidId;
    bidsFuture = widget.initialBidsFuture;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupRealtimeSubscription();
    });
  }

  void _setupRealtimeSubscription() {
    _bidsChannel = RealtimeSubscriptionService().subscribeToProjectBids(
      projectId: widget.projectId,
      onUpdate: () {
        if (mounted) {
          // Force a complete refresh by creating a new future and incrementing key
          setState(() {
            _refreshKey++;
            bidsFuture = BiddingService().getBidsForProject(widget.projectId);
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _bidsChannel?.unsubscribe();
    RealtimeSubscriptionService().unsubscribeFromChannel('project_bids_${widget.projectId}');
    super.dispose();
  }

  void _refreshBids() {
    setState(() {
      _refreshKey++;
      bidsFuture = BiddingService().getBidsForProject(widget.projectId);
    });
  }

  Widget _buildBidDetailField({
    required BuildContext context,
    required String label,
    required String value,
    required bool isDesktop,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.amber.shade700,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.gavel,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Project Bids',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close,
                    color: Colors.white, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            key: ValueKey('bids_$_refreshKey'),
            future: bidsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 400,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.amber),
                  ),
                );
              }
              if (snapshot.hasError) {
                return SizedBox(
                  height: 400,
                  child: Center(
                    child: Text('Error loading bids: ${snapshot.error}'),
                  ),
                );
              }
              final bids = snapshot.data ?? [];
              if (bids.isEmpty) {
                return const SizedBox(
                  height: 400,
                  child: Center(
                    child: Text('No bids for this project yet.'),
                  ),
                );
              }
              final anyAccepted = bids.any((bid) => bid['status'] == 'accepted');
              return SizedBox(
                height: 500,
                child: Column(
                  children: [
                    if (widget.projectStatus == 'stopped')
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          border: Border.all(color: Colors.orange.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.orange.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Bidding period has expired. Update the project to restart bidding or cancel it.',
                                style: TextStyle(
                                  color: Colors.orange.shade900,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: bids.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, color: Colors.grey),
                        itemBuilder: (context, index) {
                          final bid = bids[index];
                          final contractor = bid['contractor'] ?? {};
                          final dynamic profilePhotoRaw = contractor['profile_photo'];
                          final String profilePhoto = profilePhotoRaw is String
                              ? profilePhotoRaw
                              : profilePhotoRaw?.toString() ?? '';
                          final firmName = contractor['firm_name'] as String? ?? 'Unknown Firm';
                          final bidAmount = bid['bid_amount'] ?? 0;
                          final message = bid['message'] as String? ?? '';
                          final createdAtStr = bid['created_at'] as String? ?? '';
                          final status = bid['status'] as String? ?? 'pending';
                          DateTime? createdAt;
                          if (createdAtStr.isNotEmpty) {
                            try {
                              createdAt = DateTime.parse(createdAtStr).toLocal();
                            } catch (_) {
                              createdAt = null;
                            }
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade300, width: 1),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      ClipOval(
                                        child: SizedBox(
                                          width: 56,
                                          height: 56,
                                          child: Image.network(
                                            profilePhoto.isNotEmpty
                                                ? profilePhoto
                                                : BidsModal.profileUrl,
                                            width: 56,
                                            height: 56,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Image(
                                                image: const AssetImage('assets/defaultpic.png'),
                                                width: 56,
                                                height: 56,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    color: Colors.grey.shade300,
                                                    child: Icon(Icons.business, size: 28, color: Colors.grey.shade600),
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              firmName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                              ),
                                            ),
                                            if (contractor['email'] != null && (contractor['email'] as String).isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                contractor['email'],
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.shade50,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.amber.shade200,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Text(
                                                    'Bid Amount: ',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  Text(
                                                    '₱$bidAmount',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.amber.shade700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              createdAt != null
                                                  ? DateFormat.yMMMd().add_jm().format(createdAt)
                                                  : '',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (status == 'accepted') ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade600,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Accepted Bid',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ] else if (status == 'rejected') ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.red.shade300),
                                      ),
                                      child: const Text(
                                        'Rejected',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ] else if (!anyAccepted) ...[
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () {
                                            if (!mounted) return;
                                            showDialog(
                                              context: context,
                                              builder: (dialogContext) {
                                                final screenWidth = MediaQuery.of(dialogContext).size.width;
                                                final isDesktop = screenWidth >= 1000;
                                                
                                                return Center(
                                                  child: Material(
                                                    color: Colors.transparent,
                                                    child: Container(
                                                      constraints: BoxConstraints(
                                                        maxWidth: isDesktop ? 800 : 500,
                                                        maxHeight: MediaQuery.of(dialogContext).size.height * 0.9,
                                                      ),
                                                      margin: const EdgeInsets.symmetric(horizontal: 16),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius: BorderRadius.circular(20),
                                                        border: Border.all(color: Colors.black, width: 1.5),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black.withOpacity(0.15),
                                                            blurRadius: 20,
                                                            spreadRadius: 1,
                                                            offset: const Offset(0, 8),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Container(
                                                            padding: const EdgeInsets.all(20),
                                                            decoration: BoxDecoration(
                                                              color: Colors.amber.shade700,
                                                              borderRadius: const BorderRadius.only(
                                                                topLeft: Radius.circular(20),
                                                                topRight: Radius.circular(20),
                                                              ),
                                                            ),
                                                            child: Row(
                                                              children: [
                                                                Container(
                                                                  padding: const EdgeInsets.all(6),
                                                                  decoration: BoxDecoration(
                                                                    color: Colors.white.withOpacity(0.2),
                                                                    borderRadius: BorderRadius.circular(6),
                                                                  ),
                                                                  child: const Icon(Icons.description,
                                                                      color: Colors.white, size: 18),
                                                                ),
                                                                const SizedBox(width: 10),
                                                                const Expanded(
                                                                  child: Text(
                                                                    'Bid Description',
                                                                    style: TextStyle(
                                                                      color: Colors.white,
                                                                      fontSize: 16,
                                                                      fontWeight: FontWeight.bold,
                                                                    ),
                                                                  ),
                                                                ),
                                                                IconButton(
                                                                  onPressed: () => Navigator.pop(dialogContext),
                                                                  icon: const Icon(Icons.close,
                                                                      color: Colors.white, size: 20),
                                                                  padding: EdgeInsets.zero,
                                                                  constraints: const BoxConstraints(),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          Flexible(
                                                            child: SingleChildScrollView(
                                                              padding: const EdgeInsets.all(24),
                                                              child: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  _buildBidDetailField(
                                                                    context: dialogContext,
                                                                    label: 'Bid Message',
                                                                    value: message,
                                                                    isDesktop: isDesktop,
                                                                  ),
                                                                  const SizedBox(height: 24),
                                                                  SizedBox(
                                                                    width: double.infinity,
                                                                    child: ElevatedButton(
                                                                      onPressed: () => Navigator.pop(dialogContext),
                                                                      style: ElevatedButton.styleFrom(
                                                                        backgroundColor: const Color(0xFFFFB300),
                                                                        foregroundColor: Colors.white,
                                                                        minimumSize: const Size.fromHeight(50),
                                                                        shape: RoundedRectangleBorder(
                                                                          borderRadius: BorderRadius.circular(8),
                                                                        ),
                                                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                                                      ),
                                                                      child: const Text('Close'),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                          icon: const Icon(Icons.info_outline, size: 16),
                                          label: const Text('More Details'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.blue.shade700,
                                            textStyle: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        if (widget.projectStatus != 'stopped')
                                          Row(
                                            children: [
                                              TextButton(
                                                onPressed: () async {
                                                  if (!mounted) return;
                                                  final reasonController = TextEditingController();
                                                  final reason = await showDialog<String>(
                                                    context: context,
                                                    builder: (dialogContext) => Scaffold(
                                                      backgroundColor: Colors.black.withOpacity(0.5),
                                                      body: Center(
                                                        child: Material(
                                                          color: Colors.transparent,
                                                          child: Container(
                                                          constraints: const BoxConstraints(maxWidth: 500),
                                                          margin: const EdgeInsets.symmetric(horizontal: 16),
                                                          decoration: BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius: BorderRadius.circular(20),
                                                            border: Border.all(color: Colors.black, width: 1.5),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Colors.black.withOpacity(0.15),
                                                                blurRadius: 20,
                                                                spreadRadius: 1,
                                                                offset: const Offset(0, 8),
                                                              ),
                                                            ],
                                                          ),
                                                          child: Column(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Container(
                                                                padding: const EdgeInsets.all(20),
                                                                decoration: BoxDecoration(
                                                                  color: Colors.amber.shade700,
                                                                  borderRadius: const BorderRadius.only(
                                                                    topLeft: Radius.circular(20),
                                                                    topRight: Radius.circular(20),
                                                                  ),
                                                                ),
                                                                child: Row(
                                                                  children: [
                                                                    Container(
                                                                      padding: const EdgeInsets.all(6),
                                                                      decoration: BoxDecoration(
                                                                        color: Colors.white.withOpacity(0.2),
                                                                        borderRadius: BorderRadius.circular(6),
                                                                      ),
                                                                      child: const Icon(Icons.cancel,
                                                                          color: Colors.white, size: 18),
                                                                    ),
                                                                    const SizedBox(width: 10),
                                                                    const Expanded(
                                                                      child: Text(
                                                                        'Reject Bid',
                                                                        style: TextStyle(
                                                                          color: Colors.white,
                                                                          fontSize: 16,
                                                                          fontWeight: FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    IconButton(
                                                                      onPressed: () => Navigator.pop(dialogContext),
                                                                      icon: const Icon(Icons.close,
                                                                          color: Colors.white, size: 20),
                                                                      padding: EdgeInsets.zero,
                                                                      constraints: const BoxConstraints(),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Flexible(
                                                                child: SingleChildScrollView(
                                                                  padding: const EdgeInsets.all(16),
                                                                  child: Column(
                                                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                                                    children: [
                                                                      const SizedBox(height: 16),
                                                                      Padding(
                                                                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                                                        child: Column(
                                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                                          children: [
                                                                            const Text(
                                                                              'Reason for rejection (optional)',
                                                                              style: TextStyle(
                                                                                fontWeight: FontWeight.bold,
                                                                                fontSize: 16,
                                                                              ),
                                                                            ),
                                                                            const SizedBox(height: 8),
                                                                            TextField(
                                                                              controller: reasonController,
                                                                              decoration: const InputDecoration(
                                                                                hintText: 'Enter reason...',
                                                                                border: OutlineInputBorder(),
                                                                              ),
                                                                              maxLines: 3,
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                      const SizedBox(height: 24),
                                                                      Padding(
                                                                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                                                        child: Row(
                                                                          mainAxisAlignment: MainAxisAlignment.end,
                                                                          children: [
                                                                            TextButton(
                                                                              onPressed: () => Navigator.pop(dialogContext),
                                                                              child: const Text('Cancel'),
                                                                            ),
                                                                            const SizedBox(width: 8),
                                                                            ElevatedButton(
                                                                              onPressed: () => Navigator.pop(
                                                                                  dialogContext, reasonController.text.trim()),
                                                                              style: ElevatedButton.styleFrom(
                                                                                backgroundColor: const Color(0xFFFFB300),
                                                                                foregroundColor: Colors.black,
                                                                                minimumSize: const Size.fromHeight(50),
                                                                                shape: RoundedRectangleBorder(
                                                                                  borderRadius: BorderRadius.circular(8),
                                                                                ),
                                                                              ),
                                                                              child: const Text('Reject'),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    )
                                                  );
                                                  
                                                  if (!mounted) return;
                                                  
                                                  if (reason != null) {
                                                    try {
                                                      await BiddingService().rejectBid(
                                                        bid['bid_id'],
                                                        reason: reason.isNotEmpty ? reason : null,
                                                        projectId: widget.projectId,
                                                      );
                                                      
                                                      if (mounted) {
                                                        _refreshBids();
                                                        ConTrustSnackBar.success(context, 'Bid rejected successfully');
                                                      }
                                                    } catch (e) {
                                                      if (mounted) {
                                                        ConTrustSnackBar.error(context, 'Error rejecting bid: $e');
                                                      }
                                                    }
                                                  }
                                                },
                                                style: TextButton.styleFrom(
                                                  backgroundColor: Colors.red.shade50,
                                                  foregroundColor: Colors.red.shade700,
                                                  side: BorderSide(color: Colors.red.shade300, width: 1),
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  textStyle: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                child: const Text('Reject'),
                                              ),
                                              const SizedBox(width: 8),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  if (!mounted) return;
                                                  try {
                                                    await widget.acceptBidding(widget.projectId, bid['bid_id']);
                                                    if (!mounted) return;
                                                    setState(() {
                                                      acceptedBidId = bid['bid_id'];
                                                    });
                                                    if (mounted) {
                                                      ConTrustSnackBar.success(context, 'Bid accepted successfully!');
                                                    }
                                                  } catch (e) {
                                                    if (mounted) {
                                                      ConTrustSnackBar.error(context, 'Error accepting bid: $e');
                                                    }
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green.shade600,
                                                  side: BorderSide(color: Colors.green.shade600, width: 1),
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  textStyle: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                child: const Text('Accept'),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class HireModal {
  static Future<bool> show({
    required BuildContext context,
    required String contracteeId,
    required String contractorId,
  }) async {
    final ongoingProject = await hasOngoingProject(contracteeId);
    if (ongoingProject != null) {
      final ongoingContractorId = ongoingProject['contractor_id'] as String?;
      if (ongoingContractorId != null && ongoingContractorId != contractorId) {
        if (context.mounted) {
          ConTrustSnackBar.error(
            context,
            'You already have an active project with another contractor. Complete it before hiring a new contractor.',
          );
        }
        return false;
      }
    }

    TextEditingController titleController = TextEditingController();
    TextEditingController typeController = TextEditingController();
    TextEditingController customTypeController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    TextEditingController locationController = TextEditingController();
    TextEditingController addressController = TextEditingController();
    TextEditingController minBudgetController = TextEditingController();
    TextEditingController maxBudgetController = TextEditingController();
    DateTime? selectedStartDate;
    String? selectedBarangay;

    // Photo-related variables for auto-fill
    Uint8List? selectedPhoto;
    String? photoUrl;
    bool isUploadingPhoto = false;

    final checkResults = await Future.wait([
      hasExistingProjectWithContractor(contracteeId, contractorId),
      hasPendingProject(contracteeId),
      hasPendingHireRequest(contracteeId, contractorId),
    ]);
    
    final existingProjectWithContractor = checkResults[0];
    final pendingProject = checkResults[1];
    final pendingHireRequest = checkResults[2];

    if (existingProjectWithContractor != null) {
      titleController.text = existingProjectWithContractor['title'] ?? '';
      typeController.text = existingProjectWithContractor['type'] ?? '';
      descriptionController.text = existingProjectWithContractor['description'] ?? '';
      locationController.text = existingProjectWithContractor['location'] ?? '';
      minBudgetController.text =
          existingProjectWithContractor['min_budget']?.toString() ?? '';
      maxBudgetController.text =
          existingProjectWithContractor['max_budget']?.toString() ?? '';
      photoUrl = existingProjectWithContractor['photo_url'] as String?;
      if (existingProjectWithContractor['start_date'] != null) {
        try {
          selectedStartDate = DateTime.parse(existingProjectWithContractor['start_date']);
        } catch (e) {
          debugPrint('Error parsing start date from existing project: $e');
        }
      }
    } else if (pendingHireRequest != null) {
      titleController.text = pendingHireRequest['title'] ?? '';
      typeController.text = pendingHireRequest['type'] ?? '';
      descriptionController.text = pendingHireRequest['description'] ?? '';
      locationController.text = pendingHireRequest['location'] ?? '';
      minBudgetController.text =
          pendingHireRequest['min_budget']?.toString() ?? '';
      maxBudgetController.text =
          pendingHireRequest['max_budget']?.toString() ?? '';
      photoUrl = pendingHireRequest['photo_url'] as String?;
      if (pendingHireRequest['start_date'] != null) {
        try {
          selectedStartDate = DateTime.parse(pendingHireRequest['start_date']);
        } catch (e) {
          debugPrint('Error parsing start date from pending hire request: $e');
        }
      }
    } else if (pendingProject != null) {
      titleController.text = pendingProject['title'] ?? '';
      typeController.text = pendingProject['type'] ?? '';
      descriptionController.text = pendingProject['description'] ?? '';
      locationController.text = pendingProject['location'] ?? '';
      minBudgetController.text =
          pendingProject['min_budget']?.toString() ?? '';
      maxBudgetController.text =
          pendingProject['max_budget']?.toString() ?? '';
      photoUrl = pendingProject['photo_url'] as String?;
      if (pendingProject['start_date'] != null) {
        try {
          selectedStartDate = DateTime.parse(pendingProject['start_date']);
        } catch (e) {
          debugPrint('Error parsing start date from pending project: $e');
        }
      }
    }

    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    
    // Use predefined specializations list
    const availableSpecializations = _ProjectDialogState._availableSpecializations;

    Future<String?> uploadPhoto() async {
      if (selectedPhoto == null) return null;

      isUploadingPhoto = true;
      try {
        final supabase = Supabase.instance.client;
        final fileName = '${contracteeId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storagePath = 'contractee/photo_url/$fileName';

        await supabase.storage
            .from('projectphotos')
            .uploadBinary(
              storagePath,
              selectedPhoto!,
              fileOptions: const FileOptions(
                upsert: true,
                contentType: 'image/jpeg',
              ),
            );

        isUploadingPhoto = false;
        return storagePath;
      } catch (e) {
        isUploadingPhoto = false;
        debugPrint('Photo upload error: $e');
        if (context.mounted) {
          ConTrustSnackBar.error(context, 'Failed to upload photo: ${e.toString()}');
        }
        return null;
      }
    }

    Future<void> pickPhoto(StateSetter setDialogState) async {
      try {
        final ImagePicker picker = ImagePicker();
        final XFile? pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 600,
          imageQuality: 60,
        );

        if (pickedFile != null) {
          Uint8List? bytes;
          try {
            bytes = await pickedFile.readAsBytes();
          } catch (readError) {
            bool recovered = false;
            if (pickedFile.path.isNotEmpty) {
              try {
                bytes = await File(pickedFile.path).readAsBytes();
                recovered = true;
              } catch (_) {
                // continue to stream fallback
              }
            }

            if (!recovered) {
              try {
                final builder = BytesBuilder();
                await for (final chunk in pickedFile.openRead()) {
                  builder.add(chunk);
                }
                bytes = builder.takeBytes();
                recovered = true;
              } catch (streamError) {
                if (context.mounted) {
                  ConTrustSnackBar.error(
                    context,
                    'Failed to read selected file: $streamError',
                  );
                }
                return;
              }
            }
          }
        
        // Check file size (max 10MB)
        if (bytes == null) {
          if (context.mounted) {
            ConTrustSnackBar.error(
              context,
              'Failed to read selected image. Please try again.',
            );
          }
          return;
        }

        final Uint8List confirmedBytes = bytes;

        // Check file extension or image format (only PNG/JPG)
        final extension = pickedFile.path.contains('.') 
            ? pickedFile.path.split('.').last.toLowerCase()
            : '';
        
        // If no extension, check image format from bytes (PNG starts with 89 50 4E 47, JPEG starts with FF D8 FF)
        bool isValidImage = false;
        if (extension == 'jpg' || extension == 'jpeg' || extension == 'png') {
          isValidImage = true;
        } else if (confirmedBytes.length >= 4) {
          // Check PNG signature: 89 50 4E 47 (0x89 0x50 0x4E 0x47)
          if (confirmedBytes[0] == 0x89 && confirmedBytes[1] == 0x50 && confirmedBytes[2] == 0x4E && confirmedBytes[3] == 0x47) {
            isValidImage = true;
          }
          // Check JPEG signature: FF D8 FF
          else if (confirmedBytes.length >= 3 && confirmedBytes[0] == 0xFF && confirmedBytes[1] == 0xD8 && confirmedBytes[2] == 0xFF) {
            isValidImage = true;
          }
        }
        
        if (!isValidImage) {
          if (context.mounted) {
            ConTrustSnackBar.error(
              context, 
              'Only PNG and JPG images are allowed.'
            );
          }
          return;
        }
        
        setDialogState(() {
          selectedPhoto = confirmedBytes;
          photoUrl = null;
        });
        }
      } catch (e) {
        if (context.mounted) {
          ConTrustSnackBar.error(context, 'Failed to pick image: $e');
        }
      }
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final hasAutoFilledProject = existingProjectWithContractor != null || 
                                               pendingProject != null || 
                                               pendingHireRequest != null;
            final sortedBarangays = List<String>.from(_ProjectDialogState._barangays)..sort();
            
            // Check if current type is custom
            final showCustomField = !hasAutoFilledProject && 
                (typeController.text.toLowerCase() == 'other' || 
                 (typeController.text.isNotEmpty && 
                  !availableSpecializations.contains(typeController.text)));
            
            // If existing type is custom, populate custom field once
            if (typeController.text.isNotEmpty && 
                !availableSpecializations.contains(typeController.text) &&
                typeController.text.toLowerCase() != 'other' &&
                customTypeController.text.isEmpty) {
              customTypeController.text = typeController.text;
              typeController.text = 'Other';
            }
            
            final screenWidth = MediaQuery.of(context).size.width;
            final isMobile = screenWidth < 600;
            
            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: isMobile 
                      ? const BoxConstraints(
                          maxWidth: double.infinity,
                          maxHeight: double.infinity,
                        )
                      : const BoxConstraints(maxWidth: 800),
                  margin: isMobile 
                      ? EdgeInsets.zero 
                      : const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: isMobile 
                        ? BorderRadius.zero 
                        : BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade700,
                          borderRadius: isMobile 
                              ? BorderRadius.zero
                              : const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.person_add,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                "Hire Contractor",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close,
                                  color: Colors.white, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Form(
                            key: formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 16),
                                if (hasAutoFilledProject) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.green.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.check_circle,
                                              color: Colors.green.shade700,
                                              size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Using details from your existing project. Wait for acceptance.',
                                              style: TextStyle(
                                                color: Colors.green.shade700,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ] else ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.blue.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.info,
                                              color: Colors.blue.shade700,
                                              size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Creating a new project and hiring this contractor.',
                                              style: TextStyle(
                                                color: Colors.blue.shade700,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                HireModal._buildLabeledField(
                                  context: context,
                                  label: 'Project Title',
                                  child: TextFormField(
                                    controller: titleController,
                                    enabled: !hasAutoFilledProject,
                                    decoration: InputDecoration(
                                      labelText: hasAutoFilledProject
                                        ? 'Project title'
                                        : 'Enter project title',
                                      border: const OutlineInputBorder(),
                                      filled: hasAutoFilledProject,
                                      fillColor: hasAutoFilledProject 
                                        ? Colors.grey.shade100 
                                        : null,
                                    ),
                                    validator: (value) =>
                                        (value == null || value.trim().isEmpty)
                                            ? 'Please enter a project title'
                                            : null,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                HireModal._buildLabeledField(
                                  context: context,
                                  label: 'Type of Construction',
                                  child: hasAutoFilledProject
                                      ? TextFormField(
                                          controller: TextEditingController(text: typeController.text),
                                          enabled: false,
                                          decoration: InputDecoration(
                                            labelText: 'Construction type',
                                            border: const OutlineInputBorder(),
                                            filled: true,
                                            fillColor: Colors.grey.shade100,
                                          ),
                                        )
                                      : _ProjectDialogState._buildTwoColumnDropdownForHire(
                                          context: context,
                                          selectedValue: typeController.text.isNotEmpty &&
                                                  (availableSpecializations.contains(typeController.text) ||
                                                   typeController.text.toLowerCase() == 'other')
                                              ? typeController.text
                                              : null,
                                          availableSpecializations: availableSpecializations,
                                          onSelected: (value) {
                                            setDialogState(() {
                                              typeController.text = value;
                                              if (value.toLowerCase() != 'other') {
                                                customTypeController.clear();
                                              }
                                            });
                                          },
                                        ),
                                ),
                                if (!hasAutoFilledProject && showCustomField) ...[
                                  const SizedBox(height: 16),
                                  HireModal._buildLabeledField(
                                    context: context,
                                    label: 'Custom Construction Type',
                                    child: TextFormField(
                                      controller: customTypeController,
                                      decoration: const InputDecoration(
                                        labelText: 'Enter custom construction type',
                                        hintText: 'e.g., Kitchen Renovation',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.edit),
                                      ),
                                      textCapitalization: TextCapitalization.words,
                                      validator: (value) {
                                        if (showCustomField &&
                                            (value == null || value.trim().isEmpty)) {
                                          return 'Please enter a construction type';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                HireModal._buildLabeledField(
                                  context: context,
                                  label: 'Location',
                                  child: hasAutoFilledProject
                                      ? TextFormField(
                                          controller: locationController,
                                          enabled: false,
                                          decoration: const InputDecoration(
                                            labelText: 'Project location',
                                            border: OutlineInputBorder(),
                                            filled: true,
                                            fillColor: Colors.grey,
                                          ),
                                          validator: (value) =>
                                              (value == null ||
                                                      value.trim().isEmpty)
                                                  ? 'Please enter a location'
                                                  : null,
                                        )
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            TextFormField(
                                              controller: addressController,
                                              decoration:
                                                  const InputDecoration(
                                                labelText:
                                                    'Home address / Street / Subdivision',
                                                border:
                                                    OutlineInputBorder(),
                                              ),
                                              validator: (value) =>
                                                  (value == null ||
                                                          value
                                                              .trim()
                                                              .isEmpty)
                                                      ? 'Please enter your home address, street, and subdivision'
                                                      : null,
                                            ),
                                            const SizedBox(height: 8),
                                            DropdownButtonFormField<String>(
                                              value: selectedBarangay,
                                              items: sortedBarangays
                                                  .map(
                                                    (b) =>
                                                        DropdownMenuItem<
                                                            String>(
                                                      value: b,
                                                      child: Text(b),
                                                    ),
                                                  )
                                                  .toList(),
                                              decoration:
                                                  const InputDecoration(
                                                labelText: 'Select Barangay',
                                                border:
                                                    OutlineInputBorder(),
                                              ),
                                              onChanged: (value) {
                                                setDialogState(() {
                                                  selectedBarangay = value;
                                                });
                                              },
                                              validator: (value) =>
                                                  (value == null ||
                                                          value.isEmpty)
                                                      ? 'Please select a barangay'
                                                      : null,
                                            ),
                                            const SizedBox(height: 8),
                                            TextFormField(
                                              enabled: false,
                                              initialValue: 'SJDM, Bulacan',
                                              decoration:
                                                  const InputDecoration(
                                                labelText: 'City',
                                                border:
                                                    OutlineInputBorder(),
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                                const SizedBox(height: 16),
                                HireModal._buildLabeledField(
                                  context: context,
                                  label: 'Start Date',
                                  child: FormField<DateTime>(
                                    validator: (value) {
                                      if (selectedStartDate == null) {
                                        return 'Please select a start date';
                                      }
                                      if (!hasAutoFilledProject) {
                                        final now = DateTime.now();
                                        final today =
                                            DateTime(now.year, now.month, now.day);
                                        final minAllowed = today
                                            .add(const Duration(days: 7));
                                        if (selectedStartDate!
                                            .isBefore(minAllowed)) {
                                          return 'Start date must be at least 7 days from today';
                                        }
                                      }
                                      return null;
                                    },
                                    builder: (FormFieldState<DateTime> field) {
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          InkWell(
                                            onTap: hasAutoFilledProject
                                                ? null
                                                : () async {
                                                    final now = DateTime.now();
                                                    final today = DateTime(
                                                        now.year,
                                                        now.month,
                                                        now.day);
                                                    final minStartDate = today
                                                        .add(const Duration(
                                                            days: 7));
                                                    final maxStartDate = today
                                                        .add(const Duration(
                                                            days: 365));

                                                    final DateTime? picked =
                                                        await showThemedDatePicker(
                                                      context: context,
                                                      initialDate:
                                                          selectedStartDate ??
                                                              minStartDate,
                                                      firstDate: minStartDate,
                                                      lastDate: maxStartDate,
                                                    );
                                              if (picked != null) {
                                                setDialogState(() {
                                                  selectedStartDate = picked;
                                                  field.didChange(picked);
                                                });
                                              }
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: field.hasError ? Colors.red : Colors.grey,
                                                ),
                                                borderRadius: BorderRadius.circular(4),
                                                color: hasAutoFilledProject 
                                                  ? Colors.grey.shade100 
                                                  : null,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    selectedStartDate != null
                                                        ? '${selectedStartDate!.year}-${selectedStartDate!.month.toString().padLeft(2, '0')}-${selectedStartDate!.day.toString().padLeft(2, '0')}'
                                                        : (hasAutoFilledProject 
                                                            ? 'Start date'
                                                            : 'Select start date'),
                                                    style: TextStyle(
                                                      color: selectedStartDate != null
                                                          ? Colors.black
                                                          : Colors.grey,
                                                    ),
                                                  ),
                                                  Icon(Icons.calendar_today,
                                                      color: hasAutoFilledProject 
                                                        ? Colors.grey.shade400
                                                        : Colors.grey),
                                                ],
                                              ),
                                            ),
                                          ),
                                          if (field.hasError)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: Text(
                                                field.errorText!,
                                                style: const TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                                HireModal._buildLabeledField(
                                  context: context,
                                  label: 'Estimated Budget Range',
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: minBudgetController,
                                          enabled: !hasAutoFilledProject,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: 'Min Budget',
                                            border: const OutlineInputBorder(),
                                            prefixText: '₱ ',
                                            filled: hasAutoFilledProject,
                                            fillColor: hasAutoFilledProject 
                                              ? Colors.grey.shade100 
                                              : null,
                                          ),
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          validator: (value) {
                                            if (hasAutoFilledProject) {
                                              return null;
                                            }
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return 'Please enter minimum budget';
                                            }
                                            final num =
                                                int.tryParse(value.trim());
                                            if (num == null || num <= 0) {
                                              return 'Budget must be greater than 0';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextFormField(
                                          controller: maxBudgetController,
                                          enabled: !hasAutoFilledProject,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: 'Max Budget',
                                            border: const OutlineInputBorder(),
                                            prefixText: '₱ ',
                                            filled: hasAutoFilledProject,
                                            fillColor: hasAutoFilledProject 
                                              ? Colors.grey.shade100 
                                              : null,
                                          ),
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          validator: (value) {
                                            if (hasAutoFilledProject) {
                                              return null;
                                            }
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return 'Please enter maximum budget';
                                            }
                                            final num =
                                                int.tryParse(value.trim());
                                            if (num == null || num <= 0) {
                                              return 'Budget must be greater than 0';
                                            }
                                            final minBudget = int.tryParse(
                                                    minBudgetController.text
                                                        .trim()) ??
                                                0;
                                            if (num <= minBudget) {
                                              return 'Max budget must be greater';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                HireModal._buildLabeledField(
                                  context: context,
                                  label: 'Project Description',
                                  child: TextFormField(
                                    controller: descriptionController,
                                    enabled: !hasAutoFilledProject,
                                    maxLines: 4,
                                    decoration: InputDecoration(
                                      labelText: hasAutoFilledProject
                                        ? 'Project description'
                                        : 'Describe your project details',
                                      border: const OutlineInputBorder(),
                                      filled: hasAutoFilledProject,
                                      fillColor: hasAutoFilledProject 
                                        ? Colors.grey.shade100 
                                        : null,
                                    ),
                                    validator: (value) =>
                                        (value == null || value.trim().isEmpty)
                                            ? 'Please describe your project'
                                            : null,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                HireModal._buildLabeledField(
                                  context: context,
                                  label: 'Project Photo (Optional)',
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (selectedPhoto != null || photoUrl != null)
                                        Container(
                                          height: 150,
                                          width: double.infinity,
                                          margin: const EdgeInsets.only(bottom: 8),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: selectedPhoto != null
                                                ? Image.memory(
                                                    selectedPhoto!,
                                                    fit: BoxFit.cover,
                                                  )
                                                : photoUrl != null
                                                    ? Image.network(
                                                        photoUrl!,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context, error, stackTrace) {
                                                          return const Icon(Icons.image, size: 50);
                                                        },
                                                      )
                                                    : const SizedBox(),
                                          ),
                                        ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: isUploadingPhoto ? null : () => pickPhoto(setDialogState),
                                              icon: const Icon(Icons.photo_library),
                                              label: Text(selectedPhoto != null ? 'Change Photo' : 'Select Photo'),
                                              style: OutlinedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                              ),
                                            ),
                                          ),
                                          if (selectedPhoto != null || photoUrl != null) ...[
                                            const SizedBox(width: 8),
                                            IconButton(
                                              onPressed: () {
                                                setDialogState(() {
                                                  selectedPhoto = null;
                                                  photoUrl = null;
                                                });
                                              },
                                              icon: const Icon(Icons.delete_outline),
                                              color: Colors.red,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : () async {
                                      if (!(formKey.currentState?.validate() ??
                                          false)) {
                                        return;
                                      }

                                      // Validate custom type if "Other" is selected
                                      if (typeController.text.trim().toLowerCase() == 'other') {
                                        if (customTypeController.text.trim().isEmpty) {
                                          ConTrustSnackBar.error(
                                            context,
                                            'Please enter a construction type when "Other" is selected.',
                                          );
                                          return;
                                        }
                                      }

                                      setDialogState(() => isLoading = true);

                                      try {
                                        // Determine final project type (use custom if "Other" is selected)
                                        String finalProjectType;
                                        if (typeController.text.trim().toLowerCase() == 'other') {
                                          finalProjectType = toProperCase(customTypeController.text.trim());
                                        } else {
                                          finalProjectType = typeController.text.trim();
                                        }
                                        
                                        String finalLocation;
                                        if (hasAutoFilledProject) {
                                          finalLocation =
                                              locationController.text.trim();
                                        } else {
                                          finalLocation =
                                              '${addressController.text.trim()}, ${selectedBarangay ?? ''}, SJDM, Bulacan';
                                          locationController.text = finalLocation;
                                        }
                                        
                                        String? uploadedPhotoUrl = photoUrl;
                                        if (selectedPhoto != null && photoUrl == null) {
                                          uploadedPhotoUrl = await uploadPhoto();
                                        }

                                        await ProjectService().notifyContractor(
                                          contracteeId: contracteeId,
                                          contractorId: contractorId,
                                          title: titleController.text.trim(),
                                          type: finalProjectType,
                                          description:
                                              descriptionController.text.trim(),
                                          location: finalLocation,
                                          minBudget:
                                              minBudgetController.text.trim(),
                                          maxBudget:
                                              maxBudgetController.text.trim(),
                                          startDate: selectedStartDate,
                                          photoUrl: uploadedPhotoUrl,
                                        );

                                        Navigator.pop(context, true);
                                      } catch (e) {
                                        Navigator.pop(context, false);
                                        ConTrustSnackBar.error(context,
                                            '$e');
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFFB300),
                                      foregroundColor: Colors.black,
                                      minimumSize: const Size.fromHeight(50),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.black),
                                            ),
                                          )
                                        : Text(hasAutoFilledProject
                                            ? "Send Hire Request"
                                            : "Create Project & Send Hire Request"),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    return result ?? false;
  }

  static Widget _buildLabeledField({
    required BuildContext context,
    required String label,
    required Widget child,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1000;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 180,
                  child: Text(
                    '$label:',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: child),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                child,
              ],
            ),
    );
  }
}

class _DialogLifecycleWatcher extends StatefulWidget {
  final Widget child;

  const _DialogLifecycleWatcher({required this.child});

  @override
  __DialogLifecycleWatcherState createState() =>
      __DialogLifecycleWatcherState();
}

class __DialogLifecycleWatcherState extends State<_DialogLifecycleWatcher> {
  bool _dialogShown = false;

  void _checkForDialog() {
    if (!_dialogShown) {
      _dialogShown = true;
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.grey.shade50],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.handshake,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Contract Agreement',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close,
                            color: Colors.white, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Do you agree to proceed with the contract?',
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('Not now'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600],
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('Agree'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dialogShown = false;
    _checkForDialog();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
