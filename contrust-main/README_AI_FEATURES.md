# AI/ML Features for Contractor Project Management - Quick Reference

## Overview

This document provides a quick reference for the AI/ML enhancements added to the ConTrust contractor project management system. These features leverage Hugging Face APIs and custom algorithms to provide intelligent project management capabilities.

## Files Overview

### Documentation
- **`AI_ML_ENHANCEMENTS_SUGGESTIONS.md`** - Comprehensive list of all possible AI/ML features with detailed explanations
- **`INTEGRATION_GUIDE.md`** - Step-by-step guide on how to integrate AI features into existing code
- **`README_AI_FEATURES.md`** - This file (quick reference)

### Implementation Files
- **`Back-End/lib/services/both services/be_project_ai_service.dart`** - Main AI service for project management
- **`Back-End/lib/services/both services/be_computer_vision_service.dart`** - Computer vision service for image analysis

## Quick Start

### 1. Get Hugging Face API Token
- Visit https://huggingface.co/settings/tokens
- Create a new token
- Add to environment variables: `HUGGING_FACE_API_TOKEN=your_token_here`

### 2. Use AI Task Generation
```dart
final aiService = ProjectAIService();
final tasks = await aiService.generateTasksFromDescription(
  projectDescription: "Build a 2-story house",
  projectType: "Residential",
  budget: 5000000.0,
  duration: "90 days",
  location: "Manila",
);
```

### 3. Analyze Progress from Photos
```dart
final cvService = ComputerVisionService();
final analysis = await cvService.analyzeConstructionProgress(
  imageBase64: imageBase64String,
  projectType: "Residential",
  projectId: projectId,
);
```

### 4. Get Project Predictions
```dart
final predictions = await aiService.predictCompletionDate(
  projectId: projectId,
  currentProgress: 0.45,
  startDate: DateTime.now(),
  estimatedCompletion: DateTime.now().add(Duration(days: 90)),
);
```

## Available Features

### ✅ Implemented

1. **Auto Task Breakdown** - Generate tasks from project description
2. **Completion Date Prediction** - Predict project completion based on progress
3. **Project Health Analysis** - Analyze overall project health
4. **Smart Recommendations** - AI-generated recommendations
5. **Progress Photo Analysis** (Mock) - Analyze construction progress from photos
6. **Material Detection** (Mock) - Detect materials in photos
7. **Safety Compliance Detection** (Mock) - Check safety compliance

### 🔄 Ready to Implement (with Hugging Face API)

1. **Real Progress Photo Analysis** - Connect to Hugging Face CV models
2. **Voice-to-Task Conversion** - Use Whisper model
3. **Smart Report Generation** - Use LLM models
4. **Contract Analysis** - Document understanding models

### 📋 Planned Features

See `AI_ML_ENHANCEMENTS_SUGGESTIONS.md` for complete list.

## Key Services

### ProjectAIService
Main service for project management AI features.

**Methods:**
- `generateTasksFromDescription()` - Auto-generate tasks
- `predictCompletionDate()` - Predict completion
- `generateRecommendations()` - Get recommendations
- `analyzeProjectHealth()` - Health analysis

### ComputerVisionService
Service for image analysis and computer vision features.

**Methods:**
- `analyzeConstructionProgress()` - Analyze photos
- `detectMaterials()` - Material detection
- `detectSafetyCompliance()` - Safety checks
- `comparePhotos()` - Photo comparison

## Integration Examples

### Add to Dashboard
```dart
// In cor_dashboard.dart
Widget buildAIInsights() {
  return FutureBuilder(
    future: _getProjectPredictions(),
    builder: (context, snapshot) {
      // Display AI insights
    },
  );
}
```

### Add to Project Screen
```dart
// In cor_ongoing.dart
Widget buildAIRecommendations() {
  return FutureBuilder(
    future: _getAIRecommendations(),
    builder: (context, snapshot) {
      // Display recommendations
    },
  );
}
```

See `INTEGRATION_GUIDE.md` for detailed integration steps.

## Hugging Face Models to Use

### For NLP/Task Generation
- `mistralai/Mistral-7B-Instruct-v0.2` - General purpose
- `google/flan-t5-xxl` - Text generation
- `openai/whisper-large-v2` - Speech-to-text

### For Computer Vision
- `microsoft/beit-base-patch16-224` - Image classification
- `facebook/detr-resnet-50` - Object detection

### For Time Series
- `microsoft/forecast-tools` - Forecasting
- `facebook/anomaly-detection` - Anomaly detection

## Cost Considerations

- **Hugging Face Inference API**: Pay per request (free tier available)
- **Self-hosted**: Use your own infrastructure (more cost-effective for production)
- **Caching**: Cache predictions to reduce API calls
- **Batching**: Batch requests when possible

## Best Practices

1. **Always provide manual overrides** - AI suggestions should be optional
2. **Handle failures gracefully** - Fallback to manual methods
3. **Log all AI usage** - For audit and improvement
4. **Cache results** - Reduce API calls
5. **Respect user privacy** - Get consent for AI features
6. **Be transparent** - Show when AI is being used

## Testing Checklist

- [ ] AI task generation works correctly
- [ ] Predictions are reasonable
- [ ] Recommendations are relevant
- [ ] Photo analysis provides useful insights
- [ ] Error handling works properly
- [ ] Fallbacks work when AI fails
- [ ] UI is responsive with AI features
- [ ] Manual overrides work correctly

## Troubleshooting

### AI Service Not Working
1. Check Hugging Face API token is set
2. Verify internet connection
3. Check error logs in `SuperAdminErrorService`
4. Ensure Supabase Edge Functions are configured (if using)

### Predictions Seem Wrong
1. Check if project has enough data (need at least 3-7 days of progress)
2. Verify project data is accurate
3. Adjust confidence thresholds if needed

### Photo Analysis Not Working
1. Ensure image is properly encoded to base64
2. Check image size (not too large)
3. Verify Hugging Face API token
4. Check if model is available/loaded

## Next Steps

1. **Get API Token** - Set up Hugging Face account
2. **Test Features** - Try with sample data
3. **Integrate UI** - Add widgets to dashboard/project screens
4. **Collect Feedback** - Get user input
5. **Iterate** - Improve based on feedback
6. **Production** - Consider self-hosting for scale

## Support

For issues or questions:
1. Check error logs in SuperAdmin dashboard
2. Review `AI_ML_ENHANCEMENTS_SUGGESTIONS.md` for feature details
3. See `INTEGRATION_GUIDE.md` for implementation help
4. Check Hugging Face documentation for API issues

## License & Credits

- Uses Hugging Face models (check individual model licenses)
- Built on top of existing ConTrust architecture
- Follows ConTrust coding standards and patterns

