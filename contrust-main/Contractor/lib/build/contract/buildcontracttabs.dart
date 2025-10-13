import 'package:flutter/material.dart';
import 'package:backend/contract_templates/CostPlus.dart';
import 'package:backend/contract_templates/LumpSum.dart';
import 'package:backend/contract_templates/TimeandMaterials.dart';

class ContractTabsBuild {
  static Widget buildTabBar({
    required TabController tabController,
    required bool canViewFinalPreview,
    VoidCallback? onBeforeFinalPreview,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: TabBar(
        controller: tabController,
        labelColor: Colors.amber.shade700,
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: Colors.amber.shade700,
        indicatorWeight: 3,
        onTap: (index) {
          if (index == 2 && canViewFinalPreview) {
            onBeforeFinalPreview?.call();
          }
        },
        tabs: [
          const Tab(
            icon: Icon(Icons.description),
            text: "Template Preview",
          ),
          const Tab(
            icon: Icon(Icons.edit),
            text: "Fill Contract",
          ),
          Tab(
            icon: Icon(
              Icons.preview,
              color: canViewFinalPreview ? Colors.amber.shade700 : Colors.grey.shade400,
            ),
            child: Text(
              "Final Preview",
              style: TextStyle(
                color: canViewFinalPreview ? Colors.amber.shade700 : Colors.grey.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildTabBarView({
    required TabController tabController,
    required Widget templatePreview,
    required Widget contractForm,
    required Widget finalPreview,
    required bool canViewFinalPreview,
  }) {
    return TabBarView(
      controller: tabController,
      physics: canViewFinalPreview ? null : const NeverScrollableScrollPhysics(),
      children: [
        templatePreview,
        contractForm,
        canViewFinalPreview
            ? finalPreview
            : buildDisabledPreview(),
      ],
    );
  }

  static Widget buildDisabledPreview() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Complete Required Fields',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fill in all required fields in the contract form to unlock the final preview.',
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Icon(
              Icons.assignment_turned_in_outlined,
              size: 32,
              color: Colors.amber.shade300,
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildTemplatePreview(String? contractType) {
    if (contractType == null) {
      return buildSelectContractTypeMessage();
    }

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
                    child: getTemplateWidget(contractType),
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
    required int totalRequiredFields,
  }) {
    final percentage = totalRequiredFields > 0 
        ? (completedFields / totalRequiredFields).clamp(0.0, 1.0) 
        : 0.0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.assignment_turned_in,
            color: percentage == 1.0 ? Colors.green : Colors.amber.shade700,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Progress: $completedFields/$totalRequiredFields required fields',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: percentage == 1.0 ? Colors.green : Colors.amber.shade700,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage == 1.0 ? Colors.green : Colors.amber.shade700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(percentage * 100).toInt()}%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: percentage == 1.0 ? Colors.green : Colors.amber.shade700,
            ),
          ),
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
    int totalRequired = 0;
    
    for (final field in contractFields) {
      final f = field as dynamic;
      final isRequired = (f.isRequired as bool?) ?? false;
      final key = f.key as String;
      
      if (isRequired) {
        totalRequired++;
        final value = controllers[key]?.text.trim() ?? '';
        if (value.isNotEmpty) {
          completed++;
        }
      }
    }
    
    return {
      'completed': completed,
      'total': totalRequired,
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