import 'package:flutter/material.dart';
import 'package:backend/contract_templates/CostPlus.dart';
import 'package:backend/contract_templates/LumpSum.dart';
import 'package:backend/contract_templates/TimeandMaterials.dart';
import 'package:backend/utils/be_contractformat.dart';

class ContractTabsBuild {
  static Widget buildTabBar({
    required TabController tabController,
    required bool canViewFinalPreview,
    VoidCallback? onBeforeFinalPreview,
    bool showTemplate = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200.withOpacity(0.8),
            blurRadius: 12,
            offset: const Offset(0, -2),
        ),
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final previewIndex = showTemplate ? 2 : 1;

          return Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child: TabBar(
            controller: tabController,
              labelColor: Colors.white,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorSize: TabBarIndicatorSize.tab,
            isScrollable: false,
            labelPadding: EdgeInsets.zero, 
            padding: EdgeInsets.zero,
            indicator: BoxDecoration(
                color: Colors.amber.shade400,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
              ),
            ),
            onTap: (index) {
              final prevIndex = tabController.index;
              if (index == previewIndex && !canViewFinalPreview) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  tabController.animateTo(prevIndex);
                });
                  // Show feedback
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Complete all required fields first'),
                      backgroundColor: Colors.orange.shade700,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                return;
              }
              if (index == previewIndex) {
                onBeforeFinalPreview?.call();
              }
            },
            tabs: [
              if (showTemplate)
                Tab(
                    height: isMobile ? 64 : 72,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.description,
                              size: isMobile ? 16 : 20,
                              color: Colors.amber.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                    isMobile ? "Template" : "Template Preview",
                    style: TextStyle(
                              fontSize: isMobile ? 10 : 12,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ],
                    ),
                  ),
                ),
              Tab(
                  height: isMobile ? 64 : 72,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.edit,
                            size: isMobile ? 16 : 20,
                            color: Colors.amber.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                  isMobile ? "Fill" : "Fill Contract",
                  style: TextStyle(
                            fontSize: isMobile ? 10 : 12,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                      ],
                  ),
                ),
              ),
              Tab(
                  height: isMobile ? 64 : 72,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: canViewFinalPreview
                                ? Colors.amber.shade50
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                  Icons.preview,
                            size: isMobile ? 16 : 20,
                            color: canViewFinalPreview
                                ? Colors.amber.shade600
                                : Colors.grey.shade400,
                          ),
                ),
                        const SizedBox(height: 4),
                        Text(
                  isMobile ? "Preview" : "Final Preview",
                  style: TextStyle(
                            fontSize: isMobile ? 10 : 12,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                    color: canViewFinalPreview ? null : Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              ),
          );
        },
      ),
    );
  }

  static Widget buildTabBarView({
    required TabController tabController,
    required Widget? templatePreview,
    required Widget contractForm,
    required Widget finalPreview,
    required bool canViewFinalPreview,
    bool showTemplate = true,
  }) {
    final children = <Widget>[];
    if (showTemplate) {
      children.add(templatePreview ?? const SizedBox.shrink());
    }
    children.add(contractForm);
    children.add(canViewFinalPreview ? finalPreview : buildDisabledPreview());

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      child: TabBarView(
        key: ValueKey(canViewFinalPreview), // Rebuild when preview availability changes
      controller: tabController,
      physics: canViewFinalPreview ? null : const NeverScrollableScrollPhysics(),
      children: children,
      ),
    );
  }

  static Widget buildDisabledPreview() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade50, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 2),
      ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 2),
            ),
            child: Icon(
              Icons.lock_outline,
              size: 48,
              color: Colors.grey.shade500,
            ),
            ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
            Text(
                  'Preview Not Available Yet',
              style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
              ),
                  textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
                  'Complete all required fields in the contract form to unlock the final preview and generate your contract.',
              style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.amber.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tip: Switch to the "Fill Contract" tab to complete the required information',
                    style: TextStyle(
                      color: Colors.amber.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
            ),
          ],
        ),
          ),
        ],
      ),
    );
  }

  static Widget buildTemplatePreview(String? contractType) {
    if (contractType == null) {
      return buildSelectContractTypeMessage();
    }

    // Clear any existing text resolver to ensure template shows placeholders, not filled data
    ContractStyle.clearTextResolver();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This is the original contract template. Review it to understand what information you need to provide in the next tab.',
                    style: TextStyle(
                      color: Colors.amber.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              elevation: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: ScrollConfiguration(
                  behavior: const _NoGlowTabsScrollBehavior(),
                  child: SingleChildScrollView(
                    key: const PageStorageKey('template_preview_scroll'),
                    physics: const ClampingScrollPhysics(),
                    child: Builder(
                      builder: (context) {
                        ContractStyle.clearTextResolver();
                        return getTemplateWidget(contractType);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildSelectContractTypeMessage() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Select Contract Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a contract type in the Fill Contract tab to view the template preview.',
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Icon(
              Icons.arrow_forward,
              size: 32,
              color: Colors.amber.shade300,
            ),
          ],
        ),
      ),
    );
  }

  static Widget getTemplateWidget(String contractType) {
    final normalizedType = contractType.toLowerCase();
    
    if (normalizedType.contains('lump sum')) {
      return const LumpSumContract();
    } else if (normalizedType.contains('cost-plus') || normalizedType.contains('cost plus')) {
      return const CostPlusContract();
    } else if (normalizedType.contains('time and materials')) {
      return const TimeMaterialsContract();
    } else {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Center(  
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.orange.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Template Not Found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No template available for contract type: $contractType',
                style: TextStyle(
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }

  static Widget buildCompletionIndicator({
    required int completedFields,
    required int totalFields,
  }) {
    final percentage = totalFields > 0
        ? (completedFields / totalFields).clamp(0.0, 1.0)
        : 0.0;
    
    final isComplete = percentage == 1.0;
    final isLoading = totalFields == 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isComplete
              ? [Colors.green.shade50, Colors.white]
              : [Colors.amber.shade50, Colors.white],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isComplete ? Colors.green.shade200 : Colors.amber.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isComplete ? Colors.green : Colors.amber).shade100.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isComplete
                      ? Colors.green.shade100
                      : isLoading
                          ? Colors.grey.shade100
                          : Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isComplete
                        ? Colors.green.shade300
                        : isLoading
                            ? Colors.grey.shade300
                            : Colors.amber.shade300,
                  ),
                ),
                child: Icon(
                  isLoading
                      ? Icons.hourglass_empty
                      : isComplete
                          ? Icons.check_circle
                          : Icons.assignment_turned_in,
                  color: isComplete
                      ? Colors.green.shade700
                      : isLoading
                          ? Colors.grey.shade600
                          : Colors.amber.shade700,
            size: 20,
          ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
          Text(
                      isLoading
                ? 'Loading contract fields...'
                          : isComplete
                              ? 'Contract Complete! 🎉'
                              : 'Contract Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isComplete
                            ? Colors.green.shade800
                            : isLoading
                                ? Colors.grey.shade600
                                : Colors.amber.shade800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isLoading
                          ? 'Please wait while we load the form'
                          : isComplete
                              ? 'All fields completed. Ready to preview!'
                              : '$completedFields of $totalFields fields completed',
            style: TextStyle(
                        fontSize: 12,
                        color: isComplete
                            ? Colors.green.shade600
                            : isLoading
                                ? Colors.grey.shade500
                                : Colors.amber.shade600,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLoading)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isComplete ? Colors.green.shade600 : Colors.amber.shade600,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                  '${(percentage * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          if (!isLoading) ...[
            const SizedBox(height: 12),
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isComplete ? Colors.green.shade600 : Colors.amber.shade600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static bool validateRequiredFields(
    List<dynamic> contractFields,
    Map<String, TextEditingController> controllers,
  ) {
    for (final field in contractFields) {
      final f = field as dynamic;
      final isRequired = (f.isRequired as bool?) ?? false;
      final key = f.key as String;
      
      if (isRequired) {
        final value = controllers[key]?.text.trim() ?? '';
        if (value.isEmpty) {
          return false;
        }
      }
    }
    return true;
  }

  static Map<String, int> getFieldCompletionStatus(
    List<dynamic> contractFields,
    Map<String, TextEditingController> controllers,
  ) {
    int completed = 0;
    final countedFields = <String>{}; // Track unique field keys

    // Fields that are auto-filled or calculated - these should be counted but are always considered complete
    const autoFilledFields = {
      'Contractor.Company',
      'Contractor.Phone',
      'Contractor.Address',
      'Contractor.Bio',
      'Contractor.Email',
      'Contractee.FirstName',
      'Contractee.LastName',
      'Contractee.Phone',
      'Contractee.Address',
      'Contractee.Email',
      'Project.StartDate',
      'Payment.FinalPayment', // Calculated field
    };

    // Check if field key matches calculated patterns
    bool isCalculatedField(String key) {
      return key.startsWith('Milestone.') && key.endsWith('.Duration'); // Milestone duration fields
    }

    for (final field in contractFields) {
      final f = field as dynamic;
      final key = f.key as String;

      // Skip if we've already counted this field key
      if (countedFields.contains(key)) {
        continue;
      }

      countedFields.add(key);

      // Check if field has a value
        final value = controllers[key]?.text.trim() ?? '';

      if (autoFilledFields.contains(key) || isCalculatedField(key)) {
        // Auto-filled and calculated fields are always considered complete
        completed++;
      } else if (value.isNotEmpty) {
        // Non-auto-filled fields are complete if they have a value
          completed++;
      }
    }
    
    return {
      'completed': completed,
      'total': countedFields.length,
    };
  }
}

class _NoGlowTabsScrollBehavior extends ScrollBehavior {
  const _NoGlowTabsScrollBehavior();
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}