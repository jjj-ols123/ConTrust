// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:backend/services/both services/be_ai_service.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';
import 'package:backend/services/superadmin services/auditlogs_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// AI Service for Project Management features
/// Includes: Auto task breakdown, progress prediction, smart recommendations
class ProjectAIService {
  final AiService _aiService = AiService();
  final SuperAdminErrorService _errorService = SuperAdminErrorService();
  final SuperAdminAuditService _auditService = SuperAdminAuditService();
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Generate tasks automatically from project description
  /// Uses AI to break down project into actionable tasks with dependencies
  Future<List<Map<String, dynamic>>> generateTasksFromDescription({
    required String projectDescription,
    required String projectType,
    required double budget,
    String? duration,
    String? location,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      
      // Build context for AI
      final context = {
        'project_type': projectType,
        'budget': budget,
        'duration': duration,
        'location': location,
      };

      // Create detailed prompt for task generation
      final prompt = _buildTaskGenerationPrompt(
        description: projectDescription,
        context: context,
      );

      // Call AI service
      final aiResponse = await _aiService.generate(
        prompt: prompt,
        context: context,
      );

      // Parse AI response into structured tasks
      final tasks = _parseTasksFromAIResponse(aiResponse);

      // Log audit event
      await _auditService.logAuditEvent(
        userId: userId,
        action: 'AI_TASK_GENERATION',
        details: 'Generated ${tasks.length} tasks using AI',
        metadata: {
          'project_type': projectType,
          'tasks_count': tasks.length,
          'budget': budget,
        },
      );

      return tasks;
    } catch (e) {
      await _errorService.logError(
        userId: _supabase.auth.currentUser?.id,
        errorMessage: 'Failed to generate tasks from description: $e',
        module: 'Project AI Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Generate Tasks',
          'project_type': projectType,
        },
      );
      rethrow;
    }
  }

  /// Build the prompt for task generation
  String _buildTaskGenerationPrompt({
    required String description,
    required Map<String, dynamic> context,
  }) {
    return '''
You are an expert construction project manager. Given the following project details, generate a comprehensive task breakdown.

Project Type: ${context['project_type']}
Budget: ₱${context['budget']?.toStringAsFixed(0) ?? 'Not specified'}
Duration: ${context['duration'] ?? 'Not specified'}
Location: ${context['location'] ?? 'Not specified'}

Project Description:
$description

Generate a detailed task breakdown as a JSON array. Each task should have:
- task_name: Clear, actionable task name
- estimated_duration_days: Realistic duration in days
- priority: "High", "Medium", or "Low"
- dependencies: Array of task indices this depends on (empty array if none)
- required_resources: Array of resources needed (e.g., ["materials", "workers", "equipment"])
- description: Brief description of what needs to be done

Rules:
1. Tasks should be in logical order (foundation before walls, etc.)
2. Dependencies should reference task indices (0-based)
3. High priority tasks are critical path items
4. Estimated durations should be realistic for construction work
5. Include at least 8-15 tasks for a typical project
6. Consider common construction phases: planning, preparation, foundation, structure, finishing, inspection

Return ONLY valid JSON array, no additional text.
Example format:
[
  {
    "task_name": "Site Preparation",
    "estimated_duration_days": 3,
    "priority": "High",
    "dependencies": [],
    "required_resources": ["equipment", "workers"],
    "description": "Clear site, mark boundaries, prepare access"
  },
  {
    "task_name": "Foundation Excavation",
    "estimated_duration_days": 5,
    "priority": "High",
    "dependencies": [0],
    "required_resources": ["equipment", "workers"],
    "description": "Excavate foundation area according to plans"
  }
]
''';
  }

  /// Parse AI response into structured task list
  List<Map<String, dynamic>> _parseTasksFromAIResponse(String aiResponse) {
    try {
      // Clean the response - remove markdown code blocks if present
      String cleanedResponse = aiResponse.trim();
      if (cleanedResponse.startsWith('```json')) {
        cleanedResponse = cleanedResponse.replaceFirst('```json', '').trim();
      }
      if (cleanedResponse.startsWith('```')) {
        cleanedResponse = cleanedResponse.replaceFirst('```', '').trim();
      }
      if (cleanedResponse.endsWith('```')) {
        cleanedResponse = cleanedResponse.substring(0, cleanedResponse.length - 3).trim();
      }

      // Parse JSON
      final jsonData = jsonDecode(cleanedResponse) as List;
      
      return jsonData.map((task) {
        return {
          'task_name': task['task_name'] ?? 'Untitled Task',
          'estimated_duration_days': task['estimated_duration_days'] ?? 1,
          'priority': task['priority'] ?? 'Medium',
          'dependencies': task['dependencies'] ?? [],
          'required_resources': task['required_resources'] ?? [],
          'description': task['description'] ?? '',
          'ai_generated': true,
        };
      }).toList();
    } catch (e) {
      // If parsing fails, return default tasks
      _errorService.logError(
        errorMessage: 'Failed to parse AI task response: $e',
        module: 'Project AI Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Parse Tasks',
          'response_preview': aiResponse.substring(0, 200),
        },
      );
      
      // Return fallback tasks
      return _getFallbackTasks();
    }
  }

  /// Fallback tasks if AI parsing fails
  List<Map<String, dynamic>> _getFallbackTasks() {
    return [
      {
        'task_name': 'Project Planning',
        'estimated_duration_days': 2,
        'priority': 'High',
        'dependencies': [],
        'required_resources': [],
        'description': 'Initial project planning and setup',
        'ai_generated': false,
      },
      {
        'task_name': 'Site Preparation',
        'estimated_duration_days': 3,
        'priority': 'High',
        'dependencies': [0],
        'required_resources': ['equipment', 'workers'],
        'description': 'Prepare construction site',
        'ai_generated': false,
      },
      {
        'task_name': 'Foundation Work',
        'estimated_duration_days': 5,
        'priority': 'High',
        'dependencies': [1],
        'required_resources': ['materials', 'equipment', 'workers'],
        'description': 'Foundation construction',
        'ai_generated': false,
      },
    ];
  }

  /// Predict project completion date based on current progress
  Future<Map<String, dynamic>> predictCompletionDate({
    required String projectId,
    required double currentProgress,
    required DateTime startDate,
    DateTime? estimatedCompletion,
  }) async {
    try {
      // Fetch project data
      final project = await _supabase
          .from('Projects')
          .select('duration, progress, type, status')
          .eq('project_id', projectId)
          .single();

      final originalDuration = project['duration'] as String? ?? '30';
      final durationDays = int.tryParse(originalDuration) ?? 30;
      
      // Calculate expected completion
      final daysElapsed = DateTime.now().difference(startDate).inDays;
      final progressRate = daysElapsed > 0 ? currentProgress / daysElapsed : 0.0;
      
      // Predict remaining days
      final remainingProgress = 1.0 - currentProgress;
      final predictedRemainingDays = progressRate > 0 
          ? (remainingProgress / progressRate).ceil()
          : durationDays - daysElapsed;
      
      final predictedCompletion = DateTime.now().add(Duration(days: predictedRemainingDays));
      
      // Calculate risk factors
      final isOnTrack = predictedCompletion.isBefore(estimatedCompletion ?? DateTime.now().add(Duration(days: durationDays)));
      final riskLevel = _calculateRiskLevel(
        currentProgress: currentProgress,
        daysElapsed: daysElapsed,
        expectedDuration: durationDays,
      );

      return {
        'predicted_completion_date': predictedCompletion.toIso8601String(),
        'predicted_remaining_days': predictedRemainingDays,
        'is_on_track': isOnTrack,
        'risk_level': riskLevel,
        'progress_rate': progressRate,
        'confidence': _calculateConfidence(currentProgress, daysElapsed),
      };
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to predict completion date: $e',
        module: 'Project AI Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Predict Completion',
          'project_id': projectId,
        },
      );
      rethrow;
    }
  }

  /// Calculate risk level for project delay
  String _calculateRiskLevel({
    required double currentProgress,
    required int daysElapsed,
    required int expectedDuration,
  }) {
    final expectedProgress = daysElapsed / expectedDuration;
    final progressGap = expectedProgress - currentProgress;

    if (progressGap > 0.2) return 'High';
    if (progressGap > 0.1) return 'Medium';
    if (progressGap > -0.05) return 'Low';
    return 'On Track';
  }

  /// Calculate confidence level for predictions
  double _calculateConfidence(double currentProgress, int daysElapsed) {
    // More data = higher confidence
    if (daysElapsed < 3) return 0.3;
    if (daysElapsed < 7) return 0.5;
    if (daysElapsed < 14) return 0.7;
    if (currentProgress > 0.1) return 0.85;
    return 0.6;
  }

  /// Generate smart recommendations for project
  Future<List<Map<String, dynamic>>> generateRecommendations({
    required String projectId,
    required double currentProgress,
    required List<Map<String, dynamic>> tasks,
  }) async {
    try {
      final recommendations = <Map<String, dynamic>>[];

      // Analyze tasks
      final incompleteTasks = tasks.where((t) => t['done'] != true).toList();
      final highPriorityIncomplete = incompleteTasks.where((t) => 
        (t['priority'] as String? ?? 'Medium').toLowerCase() == 'high'
      ).toList();

      // Recommendation 1: Focus on high priority tasks
      if (highPriorityIncomplete.isNotEmpty) {
        recommendations.add({
          'type': 'priority_focus',
          'title': 'Focus on High Priority Tasks',
          'message': 'You have ${highPriorityIncomplete.length} high priority tasks remaining. Completing these will help maintain project timeline.',
          'priority': 'High',
          'tasks': highPriorityIncomplete.map((t) => t['task']).toList(),
        });
      }

      // Recommendation 2: Check dependencies
      final tasksWithDependencies = incompleteTasks.where((t) {
        final deps = t['dependencies'] as List? ?? [];
        return deps.isNotEmpty;
      }).toList();
      
      final blockedTasks = tasksWithDependencies.where((t) {
        final deps = t['dependencies'] as List? ?? [];
        return deps.any((dep) {
          final depTask = tasks.firstWhere(
            (task) => task['task_id'] == dep,
            orElse: () => {},
          );
          return depTask['done'] != true;
        });
      }).toList();

      if (blockedTasks.isNotEmpty) {
        recommendations.add({
          'type': 'dependency_block',
          'title': 'Complete Prerequisite Tasks',
          'message': 'Some tasks are blocked by incomplete dependencies. Complete prerequisite tasks first.',
          'priority': 'Medium',
          'tasks': blockedTasks.map((t) => t['task']).toList(),
        });
      }

      // Recommendation 3: Progress check
      if (currentProgress < 0.3 && tasks.length > 5) {
        recommendations.add({
          'type': 'low_progress',
          'title': 'Accelerate Progress',
          'message': 'Project is at ${(currentProgress * 100).toStringAsFixed(0)}% completion. Consider allocating more resources to accelerate progress.',
          'priority': 'Medium',
        });
      }

      return recommendations;
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to generate recommendations: $e',
        module: 'Project AI Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Generate Recommendations',
          'project_id': projectId,
        },
      );
      return [];
    }
  }

  /// Analyze project health and provide insights
  Future<Map<String, dynamic>> analyzeProjectHealth({
    required String projectId,
    required double currentProgress,
    required List<Map<String, dynamic>> tasks,
    required DateTime startDate,
    DateTime? estimatedCompletion,
  }) async {
    try {
      final completedTasks = tasks.where((t) => t['done'] == true).length;
      final totalTasks = tasks.length;
      final taskCompletionRate = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

      // Calculate health score (0-100)
      final progressScore = currentProgress * 40;
      final taskScore = taskCompletionRate * 30;
      final timelineScore = _calculateTimelineScore(startDate, estimatedCompletion) * 30;
      
      final healthScore = progressScore + taskScore + timelineScore;

      // Determine health status
      String healthStatus;
      if (healthScore >= 80) {
        healthStatus = 'Excellent';
      } else if (healthScore >= 60) {
        healthStatus = 'Good';
      } else if (healthScore >= 40) {
        healthStatus = 'Fair';
      } else {
        healthStatus = 'Needs Attention';
      }

      return {
        'health_score': healthScore,
        'health_status': healthStatus,
        'progress_percentage': currentProgress * 100,
        'task_completion_rate': taskCompletionRate * 100,
        'completed_tasks': completedTasks,
        'total_tasks': totalTasks,
        'insights': _generateInsights(healthScore, currentProgress, taskCompletionRate),
      };
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to analyze project health: $e',
        module: 'Project AI Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Analyze Project Health',
          'project_id': projectId,
        },
      );
      rethrow;
    }
  }

  /// Calculate timeline score
  double _calculateTimelineScore(DateTime startDate, DateTime? estimatedCompletion) {
    if (estimatedCompletion == null) return 0.5;
    
    final now = DateTime.now();
    final totalDuration = estimatedCompletion.difference(startDate).inDays;
    final elapsed = now.difference(startDate).inDays;
    
    if (totalDuration <= 0) return 0.5;
    if (elapsed < 0) return 1.0;
    if (elapsed >= totalDuration) return 0.0;
    
    return 1.0 - (elapsed / totalDuration);
  }

  /// Generate insights based on project metrics
  List<String> _generateInsights(double healthScore, double progress, double taskCompletion) {
    final insights = <String>[];

    if (healthScore < 40) {
      insights.add('Project health is below optimal. Consider reviewing project plan and resource allocation.');
    }

    if (progress < taskCompletion - 0.1) {
      insights.add('Progress percentage is lower than task completion rate. Some tasks may be taking longer than expected.');
    }

    if (taskCompletion > 0.8 && progress < 0.5) {
      insights.add('Most tasks are complete but overall progress is low. Remaining tasks may be complex or time-consuming.');
    }

    if (healthScore >= 80) {
      insights.add('Project is on track! Keep up the good work.');
    }

    return insights;
  }
}

