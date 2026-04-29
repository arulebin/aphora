# Medium Level - Image Description Feature

## Overview
The Medium Level feature has been implemented to provide an intermediate learning experience where users see only images and must describe them using voice input.

## How It Works

### 1. **Image Display Only**
   - Large, centered image (300x300px) is displayed
   - No text or labels shown initially
   - Clean, focused interface to encourage thinking

### 2. **Voice Input & Description**
   - User clicks the large green microphone button
   - User speaks the name/description of the object shown
   - System listens for up to 10 seconds
   - Supports Tamil language recognition (`ta-IN`)

### 3. **Accuracy Comparison**
   - User's spoken text is compared with:
     - English phrase (primary comparison)
     - Tamil phrase (secondary comparison)
   - Uses **Levenshtein distance** for similarity calculation
   - **70% accuracy threshold** for correct answers

### 4. **Immediate Feedback**
   - **Correct** (≥70% accuracy): Shows success dialog with points
   - **Incorrect** (<70% accuracy): Shows retry dialog with suggestion
   - Displays:
     - What user said
     - Expected answer (English + Tamil)
     - Accuracy percentage
     - Option to retry or move to next

### 5. **Progress Tracking**
   - Progress bar showing current position
   - Score counter (e.g., "7 / 50")
   - Completion dialog with final score and percentage

## Features Included

✅ **50 Questions** from 6 categories:
- Basic Needs (10 questions)
- People (8 questions)
- Actions (10 questions)
- Body Parts (8 questions)
- Common Objects (6 questions)
- Feelings (8 questions)

✅ **Navigation**
- Previous/Next buttons
- Disabled Previous on first question
- Shows "Finish" button on last question

✅ **Score System**
- +1 point for each correct answer
- Final score with percentage calculation
- Performance badges (Excellent, Good, Keep Practicing)

✅ **Image Support**
- Real image files: `assets/images/questions/1_water.png` format
- Automatic emoji fallback if images unavailable
- Category-based emoji mapping for fallback

## File Structure

### New File Created:
- `lib/ui/learning/medium_level_page.dart` - Main Medium Level implementation

### Modified Files:
- `lib/ui/assessment/assessment_page.dart` - Updated Medium Level card to navigate to new page

## Integration

### From Assessment Page:
```dart
// Medium Level card now uses:
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => MediumLevelPage(
      questions: allQuestions,
    ),
  ),
);
```

## Technical Details

### Speech Recognition
- Uses `SpeechService` for Tamil language recognition
- Max duration: 10 seconds per recording
- Language: Tamil (ta-IN)

### Text Evaluation
- Uses `TextEvaluator.calculateSimilarity()` from speech_service.dart
- Similarity threshold: 70%
- Distance metric: Levenshtein distance

### State Management
- StatefulWidget with full state tracking
- Tracks answered questions for progress
- Maintains score across session

## User Experience Flow

1. **Start Session** → Click "Medium Level" from Assessment Page
2. **See Image** → Large image displayed without any text
3. **Record Voice** → Click microphone button and describe the object
4. **Get Feedback** → See immediate result with accuracy score
5. **Progress** → Navigate through all 50 questions
6. **Complete** → See final score and performance badge
7. **Return** → Back to Assessment Page

## Customization Options

### Adjust Difficulty:
- Change accuracy threshold (currently 70%)
- Modify recording duration (currently 10 seconds)
- Add/remove questions

### Enhance Feedback:
- Add sound effects for correct/incorrect
- Add animations during feedback
- Add difficulty badges

### Language Support:
- Currently supports Tamil recognition
- Can be extended to English or other languages
- Change `language: 'ta-IN'` parameter in `_startListening()`

## Future Enhancements

1. **Voice Speed Recognition** - Evaluate speaking speed
2. **Pronunciation Analysis** - Add phoneme-level feedback
3. **Difficulty Levels** - Easy/Medium/Hard variations
4. **Statistics Tracking** - Save session results
5. **Leaderboard** - Compare scores across sessions
6. **Custom Word Lists** - Therapist-created word sets

