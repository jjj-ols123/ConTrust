# Integration Guide: AI/ML Features for Contractor Project Management

This guide shows how to integrate the new AI/ML features into the existing ConTrust contractor project management system.

## Files Created

1. **`be_project_ai_service.dart`** - Main AI service for project management
2. **`be_computer_vision_service.dart`** - Computer vision service for image analysis
3. **`AI_ML_ENHANCEMENTS_SUGGESTIONS.md`** - Comprehensive feature list

## Integration Steps

### Step 1: Add AI Task Generation to Project Creation

**File**: `Contractor/lib/Screen/cor_ongoing.dart` or wherever project tasks are created

```dart
import 'package:backend/services/both services/be_project_ai_service.dart';

// Add this method to your screen
Future<void> _generateTasksWithAI() async {
  try {
    setState(() => isLoading = true);
    
    final projectAIService = ProjectAIService();
    final projectData = // Get your project data
    
    final aiTasks = await projectAIService.generateTasksFromDescription(
      projectDescription: projectData['description'] ?? '',
      projectType: projectData['type'] ?? '',
      budget: (projectData['max_budget'] as num?)?.toDouble() ?? 0.0,
      duration: projectData['duration'],
      location: projectData['location'],
    );

    // Show dialog to review AI-generated tasks
    showDialog(
      context: context,
      builder: (context) => _buildAITasksReviewDialog(aiTasks),
    );
  } catch (e) {
    ConTrustSnackBar.error(context, 'Failed to generate tasks: $e');
  } finally {
    setState(() => isLoading = false);
  }
}

Widget _buildAITasksReviewDialog(List<Map<String, dynamic>> aiTasks) {
  return AlertDialog(
    title: Text('AI Generated Tasks'),
    content: SizedBox(
      width: double.maxFinite,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: aiTasks.length,
        itemBuilder: (context, index) {
          final task = aiTasks[index];
          return ListTile(
            title: Text(task['task_name'] ?? ''),
            subtitle: Text('${task['estimated_duration_days']} days - ${task['priority']}'),
            trailing: Checkbox(
              value: task['selected'] ?? true,
              onChanged: (value) {
                setState(() {
                  task['selected'] = value;
                });
              },
            ),
          );
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: () {
          final selectedTasks = aiTasks.where((t) => t['selected'] == true).toList();
          _addAITasksToProject(selectedTasks);
          Navigator.pop(context);
        },
        child: Text('Add Selected Tasks'),
      ),
    ],
  );
}
```

### Step 2: Add AI Progress Analysis to Photo Upload

**File**: `Back-End/lib/services/contractor services/cor_ongoingservices.dart`

```dart
import 'package:backend/services/both services/be_computer_vision_service.dart';

// Modify the uploadPhoto method
Future<void> uploadPhoto({
  required String projectId,
  required BuildContext context,
  required VoidCallback onSuccess,
}) async {
  try {
    // ... existing photo upload code ...
    
    // After successful upload, analyze with AI
    final cvService = ComputerVisionService();
    final projectData = await _fetchService.fetchProjectDetails(projectId);
    
    // Analyze progress from photo
    final analysis = await cvService.analyzeConstructionProgress(
      imageBase64: base64Image, // Convert image to base64
      projectType: projectData?['type'] ?? '',
      projectId: projectId,
    );

    // Show analysis results
    if (context.mounted) {
      _showProgressAnalysisDialog(analysis);
    }

    // ... rest of existing code ...
  } catch (e) {
    // Handle error
  }
}

void _showProgressAnalysisDialog(Map<String, dynamic> analysis) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('AI Progress Analysis'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Estimated Progress: ${(analysis['estimated_progress'] * 100).toStringAsFixed(0)}%'),
          Text('Confidence: ${(analysis['confidence'] * 100).toStringAsFixed(0)}%'),
          SizedBox(height: 16),
          Text('Detected Phases:', style: TextStyle(fontWeight: FontWeight.bold)),
          ...(analysis['detected_phases'] as List).map((phase) => Text('• $phase')),
          SizedBox(height: 16),
          Text('Recommendations:', style: TextStyle(fontWeight: FontWeight.bold)),
          ...(analysis['recommendations'] as List).map((rec) => Text('• $rec')),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK'),
        ),
      ],
    ),
  );
}
```

### Step 3: Add AI Predictions to Dashboard

**File**: `Contractor/lib/Screen/cor_dashboard.dart` or `Contractor/lib/build/builddashboard.dart`

```dart
import 'package:backend/services/both services/be_project_ai_service.dart';

// Add AI insights widget
Widget buildAIInsights() {
  return FutureBuilder<Map<String, dynamic>>(
    future: _getProjectPredictions(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return CircularProgressIndicator();
      }
      
      if (!snapshot.hasData) {
        return SizedBox.shrink();
      }

      final predictions = snapshot.data!;
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'AI Insights',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (predictions['risk_level'] == 'High')
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Project may face delays. Consider allocating more resources.',
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 8),
            Text(
              'Predicted Completion: ${predictions['predicted_completion_date']}',
              style: TextStyle(fontSize: 14),
            ),
            Text(
              'Confidence: ${(predictions['confidence'] * 100).toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    },
  );
}

Future<Map<String, dynamic>> _getProjectPredictions() async {
  if (recentActivities.isEmpty) return {};
  
  final project = recentActivities.first;
  final projectAIService = ProjectAIService();
  
  try {
    return await projectAIService.predictCompletionDate(
      projectId: project['project_id'],
      currentProgress: project['progress'] ?? 0.0,
      startDate: DateTime.parse(project['start_date']),
      estimatedCompletion: project['estimated_completion'] != null
          ? DateTime.parse(project['estimated_completion'])
          : null,
    );
  } catch (e) {
    return {};
  }
}
```

### Step 4: Add AI Recommendations Widget

**File**: `Contractor/lib/Screen/cor_ongoing.dart`

```dart
// Add recommendations section
Widget buildAIRecommendations() {
  return FutureBuilder<List<Map<String, dynamic>>>(
    future: _getAIRecommendations(),
    builder: (context, snapshot) {
      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return SizedBox.shrink();
      }

      final recommendations = snapshot.data!;
      return Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber.shade700),
                SizedBox(width: 8),
                Text(
                  'AI Recommendations',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ...recommendations.map((rec) => Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    rec['priority'] == 'High' ? Icons.priority_high : Icons.info_outline,
                    size: 20,
                    color: rec['priority'] == 'High' ? Colors.red : Colors.blue,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rec['title'],
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 4),
                        Text(
                          rec['message'],
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      );
    },
  );
}

Future<List<Map<String, dynamic>>> _getAIRecommendations() async {
  final projectAIService = ProjectAIService();
  
  try {
    return await projectAIService.generateRecommendations(
      projectId: widget.projectId,
      currentProgress: _localProgress,
      tasks: _localTasks,
    );
  } catch (e) {
    return [];
  }
}
```

### Step 5: Add Project Health Analysis

**File**: `Contractor/lib/Screen/cor_ongoing.dart`

```dart
// Add health analysis widget
Widget buildProjectHealth() {
  return FutureBuilder<Map<String, dynamic>>(
    future: _getProjectHealth(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return SizedBox.shrink();
      }

      final health = snapshot.data!;
      final healthScore = health['health_score'] as double;
      final healthColor = healthScore >= 80
          ? Colors.green
          : healthScore >= 60
              ? Colors.blue
              : healthScore >= 40
                  ? Colors.orange
                  : Colors.red;

      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: healthColor.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: healthColor),
                SizedBox(width: 8),
                Text(
                  'Project Health: ${health['health_status']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: healthColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            LinearProgressIndicator(
              value: healthScore / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(healthColor),
            ),
            SizedBox(height: 8),
            Text(
              'Health Score: ${healthScore.toStringAsFixed(0)}/100',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            if ((health['insights'] as List).isNotEmpty) ...[
              Text(
                'Insights:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              ...(health['insights'] as List).map((insight) => Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.arrow_right, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        insight,
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      );
    },
  );
}

Future<Map<String, dynamic>> _getProjectHealth() async {
  final projectAIService = ProjectAIService();
  
  try {
    return await projectAIService.analyzeProjectHealth(
      projectId: widget.projectId,
      currentProgress: _localProgress,
      tasks: _localTasks,
      startDate: projectData?['start_date'] != null
          ? DateTime.parse(projectData!['start_date'])
          : DateTime.now(),
      estimatedCompletion: projectData?['estimated_completion'] != null
          ? DateTime.parse(projectData!['estimated_completion'])
          : null,
    );
  } catch (e) {
    return {};
  }
}
```

## Environment Variables

Add to your `.env` file or configuration:

```env
HUGGING_FACE_API_TOKEN=your_token_here
```

Then update `be_computer_vision_service.dart`:

```dart
static const String? _hfApiToken = String.fromEnvironment('HUGGING_FACE_API_TOKEN');
```

## Testing

1. **Test AI Task Generation**:
   - Create a new project
   - Click "Generate Tasks with AI"
   - Review and select generated tasks
   - Verify tasks are added correctly

2. **Test Progress Analysis**:
   - Upload a project photo
   - Check AI analysis results
   - Verify recommendations are relevant

3. **Test Predictions**:
   - View dashboard with active projects
   - Check AI insights widget
   - Verify predictions are reasonable

## Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  http: ^1.1.0  # For Hugging Face API calls (if not already present)
```

## Notes

- All AI features should be **optional** - users can still manage projects manually
- Provide **manual override** for all AI suggestions
- **Cache AI results** to reduce API calls
- **Handle API failures gracefully** with fallbacks
- **Log all AI usage** for audit purposes

## Next Steps

1. Get Hugging Face API token from https://huggingface.co/settings/tokens
2. Implement the integrations above
3. Test with real project data
4. Iterate based on user feedback
5. Consider self-hosting models for production use

