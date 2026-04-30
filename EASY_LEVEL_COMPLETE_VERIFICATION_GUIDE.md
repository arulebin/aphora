# Easy Level - Complete Word Comparison & Answer Verification System

## System Overview

The Easy Level uses a sophisticated word comparison system to verify if user's spoken input matches the target word. Here's everything you need to know:

---

## Step-by-Step Process

### 1. User Interface Setup

When a user reaches the Easy Level page:

```
┌─────────────────────────────────────┐
│ EASY LEVEL - VISUAL LEARNING        │
├─────────────────────────────────────┤
│ Score: 5              Progress: 10% │
│                                     │
│ Question 5 of 50                    │
│                                     │
│  ┌─────────────────────────┐        │
│  │                         │        │
│  │   🍽️ (Food Image)       │        │
│  │                         │        │
│  └─────────────────────────┘        │
│                                     │
│  FOOD (in large text)               │
│  சாப்பாடு (in Tamil)                  │
│                                     │
│  [🔊 Hear] [🎤 Record]              │
│                                     │
└─────────────────────────────────────┘
```

### 2. User Records Voice

User clicks the **[🎤 Record]** button:
- System activates microphone
- Listens for up to 10 seconds
- Shows "Listening..." indicator
- Captures audio input from user

### 3. Word Comparison Process

```dart
// INPUT
String spokenText = "food"           // What user said
String originalWord = "Food"         // Target word

// NORMALIZE (case-insensitive)
String normalized_input = "food"     // lowercased
String normalized_original = "food"  // lowercased

// COMPARE using Levenshtein Distance
double accuracy = TextEvaluator.calculateSimilarity(
  normalized_original,
  normalized_input
);
// Result: 100% (perfect match)

// VERIFY against threshold
if (accuracy >= 70) {
  // PASS - Correct answer
  _showSuccessDialog(...);
} else {
  // FAIL - Incorrect answer
  _showRetryDialog(...);
}
```

---

## Comparison Algorithm: Levenshtein Distance

### What It Measures

The Levenshtein distance counts the minimum number of single-character edits (insertions, deletions, substitutions) needed to change one word into another.

### Formula

```
Accuracy = (1 - (distance / max_length)) * 100%
```

### Examples with "FOOD"

| Spoken | Original | Operations | Distance | Accuracy | Pass? |
|--------|----------|------------|----------|----------|-------|
| "food" | "Food" | None (case-insensitive) | 0 | 100% | ✅ YES |
| "fod" | "Food" | Delete 1 'o' | 1 | 75% | ✅ YES |
| "foood" | "Food" | Insert 1 'o' | 1 | 80% | ✅ YES |
| "foo" | "Food" | Delete 'd' | 1 | 75% | ✅ YES |
| "fo" | "Food" | Delete 'o' and 'd' | 2 | 50% | ❌ NO |
| "feed" | "Food" | Substitute 'o'→'e' | 1 | 75% | ✅ YES |
| "fud" | "Food" | Substitute 'o'→'u' | 1 | 75% | ✅ YES |
| "fat" | "Food" | 2 substitutions | 2 | 50% | ❌ NO |
| "xyz" | "Food" | All different | 4 | 0% | ❌ NO |

---

## Answer Verification Logic

### Decision Tree

```
START: User speaks into microphone
  ↓
Extract spoken text
  ↓
Calculate Levenshtein distance
  ↓
Convert to accuracy percentage
  ↓
          ╔═════════════════════════════════╗
          ║ Is accuracy >= 70%?             ║
          ╚═════════════════════════════════╝
              ↙                       ↖
            YES                       NO
            ↙                           ↖
       ┌─────────┐              ┌──────────┐
       │ CORRECT │              │ INCORRECT│
       └─────────┘              └──────────┘
          ↓                        ↓
   ┌─ Award +1 Point      ┌─ No Points
   │  Show Success        │  Show Retry
   │  Dialog              │  Dialog
   │  Color: Green        │  Color: Orange
   │  Icon: ✅            │  Icon: ℹ️
   └─ Next Question       └─ Retry/Skip
      Automatic           Options
```

---

## Feedback Dialogs

### SUCCESS Dialog (≥70% Accuracy)

**Triggers When:** User's word matches target with 70% or higher accuracy

**Dialog Content:**
```
┌─────────────────────────────────┐
│ ✅ Correct!                     │ ← Green icon
├─────────────────────────────────┤
│                                 │
│ You said: "food"                │ ← What user actually said
│                                 │
│ The word is: "Food" (சாப்பாடு)   │ ← Target + Tamil
│                                 │
│ ┌─────────────────────────────┐ │
│ │ Accuracy: 100%              │ │ ← Shows how close
│ └─────────────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ ⭐ +1 Point                 │ │ ← Points awarded
│ └─────────────────────────────┘ │
│                                 │
│    [Next Question]              │ ← Action button
│                                 │
└─────────────────────────────────┘
```

**Backend Code:**
```dart
void _showSuccessDialog(
  QuestionData question,
  double accuracy,
  String spokenText
) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: Color(0xFF10B981)),
          SizedBox(width: 8),
          Text('Correct!'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('You said: "$spokenText"'),
          SizedBox(height: 12),
          Text('The word is: "${question.englishPhrase}" (${question.tamilPhrase})'),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Accuracy:'),
                Text('${accuracy.toStringAsFixed(1)}%'),
              ],
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xFF10B981).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.star, color: Color(0xFF10B981)),
                SizedBox(width: 8),
                Text('+1 Point'),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _goToNextQuestion();
          },
          child: Text('Next Question'),
        ),
      ],
    ),
  );
}
```

---

### RETRY Dialog (<70% Accuracy)

**Triggers When:** User's word doesn't match target sufficiently (< 70%)

**Dialog Content:**
```
┌─────────────────────────────────┐
│ ℹ️ Try Again                    │ ← Orange icon
├─────────────────────────────────┤
│                                 │
│ You said: "fud"                 │ ← What user said
│                                 │
│ Expected: "Food" (சாப்பாடு)     │ ← What they should say
│                                 │
│ ┌─────────────────────────────┐ │
│ │ Accuracy: 45.8%             │ │ ← How close they were
│ │ Need 70% to pass            │ │ ← What's needed
│ └─────────────────────────────┘ │
│                                 │
│    [Retry]       [Skip]         │ ← Two options
│                                 │
└─────────────────────────────────┘
```

**Backend Code:**
```dart
void _showRetryDialog(
  QuestionData question,
  double accuracy,
  String spokenText
) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.info, color: Color(0xFFF59E0B)),
          SizedBox(width: 8),
          Text('Try Again'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('You said: "$spokenText"'),
          SizedBox(height: 12),
          Text('Expected: "${question.englishPhrase}" (${question.tamilPhrase})'),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xFFF59E0B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Accuracy:'),
                Text('${accuracy.toStringAsFixed(1)}%'),
              ],
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.trending_up, color: Colors.grey),
                SizedBox(width: 8),
                Text('Need 70% to pass'),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            // Clear result and allow retry
            setState(() {
              showResult = false;
              lastSpokenText = "";
            });
          },
          child: Text('Retry'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _goToNextQuestion();
          },
          child: Text('Skip'),
        ),
      ],
    ),
  );
}
```

---

## Point Award System

### Critical Rule: One Point Per Question Maximum

```dart
if (accuracy >= 70) {
  // Check if this question hasn't been answered correctly yet
  if (!answeredQuestions[currentIndex]) {
    setState(() {
      score++;                              // +1 point
      answeredQuestions[currentIndex] = true; // Mark as answered
    });
  }
}
```

### Why This Matters

**Prevents cheating:** User can't retry same question and get multiple points

**Tracks progress:** `answeredQuestions` array keeps record of which questions were mastered

**Fair scoring:** Each question is worth exactly 1 point

### Scenarios

**Scenario A: First Attempt - Correct**
```
Question: 5 (Food)
Answer: "food" (100% accuracy)
Result: Correct! ✅

Processing:
  answeredQuestions[4] = false (initial)
  accuracy = 100% >= 70% → TRUE
  !answeredQuestions[4] → TRUE (hasn't been answered)
  
  Action:
    score = 5 → 6 (+1 point awarded)
    answeredQuestions[4] = true (now marked)

Output: Score increases to 6/50, +1 Point shown
```

**Scenario B: First Attempt - Wrong, Second Attempt - Correct**
```
Question: 5 (Food)

First Attempt:
  Answer: "fud" (75% accuracy)
  Result: Try Again ❌
  
  Processing:
    accuracy = 75% >= 70% → TRUE! (Wait, 75% IS >= 70%)
    !answeredQuestions[4] → TRUE
    
    Wait, let me recalculate: 75% is > 70%, so this WOULD be correct!
    Let me use 45% accuracy example instead
  
First Attempt (Corrected):
  Answer: "fuud" (45% accuracy)
  Result: Try Again ❌
  
  Processing:
    accuracy = 45% >= 70% → FALSE
    No points awarded
    answeredQuestions[4] = false (still)
    
  User clicks [Retry]

Second Attempt:
  Answer: "food" (100% accuracy)
  Result: Correct! ✅
  
  Processing:
    accuracy = 100% >= 70% → TRUE
    !answeredQuestions[4] → TRUE (still hasn't been answered correctly)
    
    Action:
      score = 5 → 6 (+1 point awarded)
      answeredQuestions[4] = true (now marked)

Output: Score increases to 6/50 (only +1 total, not +2)
```

**Scenario C: Correct Answer, Navigate Away, Come Back**
```
Question: 5 (Food)
First time: Answer "food" (100%) → +1 point (Score: 6/50)
  answeredQuestions[4] = true

User navigates to different question

User comes back to Question 5
Answer "food" again (100%)

Processing:
  accuracy = 100% >= 70% → TRUE
  !answeredQuestions[4] → FALSE (already answered!)
  
  No additional points awarded

Output: Score stays 6/50 (protection against retakes)
```

---

## Complete Verification Workflow

### Full Session Example

```
┌────────────────────────────────────────────────────────┐
│                  EASY LEVEL SESSION                    │
├────────────────────────────────────────────────────────┤

Question 5: FOOD (சாப்பாடு)
  
  1. User sees: Image + "FOOD" + Tamil + [🎤 Record]
  
  2. User clicks [🎤 Record]
     System: "Listening..."
  
  3. User says: "food"
     System: Recording stopped
  
  4. VERIFICATION PROCESS:
     ┌─────────────────────────────────────────┐
     │ Input: "food"                           │
     │ Original: "Food"                        │
     │ Normalize: "food" vs "food"             │
     │ Algorithm: Levenshtein distance         │
     │ Distance: 0 (perfect match)             │
     │ Accuracy: (1 - 0/4) * 100 = 100%       │
     │ Threshold: >= 70%?                      │
     │ Check: 100% >= 70%? YES ✅              │
     │ Points Check: !answeredQuestions[4]?    │
     │ Check: True (not answered yet) YES ✅   │
     │ Action: score = 5 → 6                   │
     │ Mark: answeredQuestions[4] = true       │
     └─────────────────────────────────────────┘
  
  5. FEEDBACK:
     ┌──────────────────────────────┐
     │ ✅ Correct!                  │
     │ You said: "food"             │
     │ The word is: "Food"(சாப்பாடு) │
     │ Accuracy: 100%               │
     │ ⭐ +1 Point                  │
     │ [Next Question]              │
     └──────────────────────────────┘
  
  6. New Score: 6/50 (displayed in header)
  
  7. User clicks [Next Question]
     → Moves to Question 6

└────────────────────────────────────────────────────────┘
```

---

## Summary Table: Answer Verification

| Step | What Happens | Input | Output |
|------|-------------|-------|--------|
| 1 | User Records | Voice | Audio data |
| 2 | Extract Text | Audio | "food" |
| 3 | Normalize | "food" | "food" (lowercased) |
| 4 | Compare | vs "Food" → "food" | Levenshtein distance |
| 5 | Calculate | Distance / Length | Accuracy: 100% |
| 6 | Verify | 100% >= 70%? | ✅ YES |
| 7 | Check Points | Already answered? | ❌ NO, first time |
| 8 | Award | score++ | Score: 5 → 6 |
| 9 | Mark | answered | answeredQuestions[4] = true |
| 10 | Feedback | Result | Success dialog ✅ |
| 11 | Next | User action | Proceed to Q6 |

---

## Key Features

✅ **Accurate Comparison** - Uses proven Levenshtein distance algorithm
✅ **Case-Insensitive** - "food", "Food", "FOOD" all match
✅ **Tolerance for Typos** - Small errors (75%+) are accepted
✅ **Fair Threshold** - 70% ensures reasonable accuracy
✅ **No Cheating** - One point maximum per question
✅ **Clear Feedback** - Users always know what they said vs correct answer
✅ **Transparent Scoring** - Accuracy percentage shown
✅ **Retry Option** - Users can try again if incorrect
✅ **Progress Tracking** - Score continuously updated
✅ **Session Summary** - Final score with performance badge

