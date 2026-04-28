# Visual Learning System - 50 Questions Implementation Guide

## Overview
This guide explains the new visual learning system with 50 questions organized in 6 categories.

## Categories & Questions (50 Total)

### 1. Basic Needs (10 Questions)
1. Water (தண்ணீர்)
2. Food (சாப்பாடு)
3. Child (பச்சி)
4. Drink (தாகம்)
5. Medicine (வளி)
6. Tablet (மருந்து)
7. Sleep (தூக்கம்)
8. Sitting (உட்கார்)
9. Milk (பால்)
10. Soup (கசதி)

### 2. People (8 Questions)
11. Woman (அம்மா)
12. Man (அப்பா)
13. Boy (அண்ணன்)
14. Girl (அக்கா)
15. Sister (தங்கை)
16. Brother (தம்பி)
17. Doctor (மருத்துவர்)
18. Nurse (நர்ஸ்)

### 3. Actions (10 Questions)
19. Walk (வா)
20. Go (போ)
21. Come (வா)
22. Eat (சாப்பிடு)
23. Help (உதவி)
24. Yes (ஆம்)
25. No (இல்லை)
26. Hello (வணக்கம்)
27. Thank you (நன்றி)
28. Please (தயவு)

### 4. Body Parts (8 Questions)
29. Head (தலை)
30. Hand (கை)
31. Foot (கால்)
32. Eye (கண்)
33. Mouth (வாய்)
34. Nose (காது)
35. Thumb (வெண்டாம்)
36. Arm (வாயிறு)

### 5. Common Objects (6 Questions)
37. Bed (படுக்கை)
38. Cup (கப்)
39. Plate (தட்டு)
40. Book (புத்தகம்)
41. Door (கதவு)
42. Window (ஜன்னல்)

### 6. Feelings (8 Questions)
43. Happy (சந்தோஷம்)
44. Sad (கவலை)
45. Pain (வலி)
46. Tired (உபாயம்)
47. Angry (கோபம்)
48. Cold (சளி)
49. Hot (வெப்பம்)
50. Scared (பயம்)

## File Structure

### New Files Created:
```
lib/
  data/
    learning/
      question_data.dart          # 50 questions dataset
  ui/
    learning/
      visual_question_page.dart   # Visual question display

assets/
  images/
    questions/                    # Directory for question images
      1_water.png
      2_food.png
      ... (all 50 images)
      svg_data.dart               # SVG data for images
```

### Modified Files:
- `lib/ui/learning/task_list_page.dart` - Updated to use visual question system

## How It Works

1. **User selects a category** from TaskListPage
2. **System loads 50 questions** via `getQuestionsByCategory()`
3. **VisualQuestionPage displays** each question with:
   - Large image (280x280)
   - English phrase
   - Tamil translation
   - Difficulty level
   - Progress bar
4. **User navigates** through questions using Previous/Next buttons
5. **System tracks completion** status

## Image Setup Options

### Option 1: Use Placeholder Icons (Current)
- System uses emoji icons as placeholders
- Works immediately without additional files
- Located in `_buildImagePlaceholder()` method

### Option 2: Add PNG Images Manually
1. Download or create 50 PNG images (256x256px)
2. Save to `assets/images/questions/` directory
3. Name them: `1_water.png`, `2_food.png`, etc.
4. Images will auto-load, falling back to emojis if missing

### Option 3: Generate SVG Images
1. Use the SVG data in `assets/images/questions/svg_data.dart`
2. Convert SVGs to PNGs using online tools
3. Place PNG files in `assets/images/questions/`

### Option 4: Use Online Image URLs
Modify `VisualQuestionPage._buildImageContent()` to use network images:

```dart
Widget _buildImageContent(QuestionData question) {
  return Image.network(
    question.imagePath,  // Use URLs instead
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) {
      return _buildImagePlaceholder(question);
    },
  );
}
```

## Implementation Steps

1. **Images Already Created:**
   - Placeholder system is ready
   - Emoji icons display for all 50 questions
   - SVG data is available

2. **To Use Real Images:**
   - Download or create PNG files
   - Save to `assets/images/questions/`
   - No code changes needed - they'll auto-load

3. **Testing:**
   - Run the app
   - Navigate to a learning category
   - Click on any question to see the visual page
   - Use Previous/Next to browse questions

## Customization

### Add More Questions:
Edit `lib/data/learning/question_data.dart` and add to `allQuestions` list:
```dart
QuestionData(
  id: 51,
  category: 'New Category',
  englishPhrase: 'New Word',
  tamilPhrase: 'Tamil Word',
  imagePath: 'assets/images/questions/51_image.png',
  difficulty: 'Easy',
)
```

### Change Difficulty Colors:
Edit `VisualQuestionPage._buildDifficultyBadge()` to adjust colors.

### Modify Image Display Size:
Change `width` and `height` in `_buildImageDisplay()` method.

## API Reference

### QuestionData Class
```dart
QuestionData({
  required int id,
  required String category,
  required String englishPhrase,
  required String tamilPhrase,
  required String imagePath,
  required String difficulty,
  String? description,
})
```

### Utility Functions
```dart
// Get questions by category
List<QuestionData> getQuestionsByCategory(String category)

// Get all unique categories
List<String> getAllCategories()
```

## Notes
- All 50 questions use difficulty levels: Easy, Medium, Hard
- Questions are organized alphabetically within categories
- Progress is tracked per learning session
- System supports both emoji placeholders and actual images
