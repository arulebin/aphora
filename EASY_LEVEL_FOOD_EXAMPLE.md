# Easy Level - Word Comparison & Verification Guide

## How It Works: Step-by-Step Example

### Scenario: User Learning "Food" (சாப்பாடு)

#### Step 1: Easy Level Page Shows
```
┌──────────────────────────────────────────────┐
│          Easy Level - Visual Learning        │
├──────────────────────────────────────────────┤
│                                              │
│  Score: 5                                    │
│  Progress: 10% ▓░░░░░░░░░░                   │
│                                              │
│  Question 5 of 50                           │
│                                              │
│  ┌─────────────────────────────┐            │
│  │                             │            │
│  │        🍽️  (or Image)        │            │
│  │                             │            │
│  └─────────────────────────────┘            │
│                                              │
│        FOOD                                 │
│      சாப்பாடு                                │
│                                              │
│     Easy   [🔊 Hear] [🎤 Record]            │
│                                              │
│  [← Previous]        [Next →]                │
└──────────────────────────────────────────────┘
```

#### Step 2: User Clicks Microphone Button
- System starts listening (max 10 seconds)
- Shows "Listening..." indicator
- Captures user's voice input

#### Step 3A: User Says "Food" (CORRECT)

**What happens:**
1. System records: "food"
2. Compares with original: "Food"
3. Calculates accuracy using Levenshtein distance
4. Result: **95.2% match** ✅ (≥70% threshold)

**Dialog Shows:**
```
┌─────────────────────────────────────┐
│ ✅ Correct!                         │
├─────────────────────────────────────┤
│                                     │
│ You said: "food"                    │
│                                     │
│ The word is: "Food" (சாப்பாடு)       │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Accuracy: 95.2%                 │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ ⭐ +1 Point                     │ │
│ └─────────────────────────────────┘ │
│                                     │
│    [Next Question]                  │
└─────────────────────────────────────┘
```

**Backend Processing:**
```dart
String spokenText = "food";
QuestionData question = {
  englishPhrase: "Food",
  tamilPhrase: "சாப்பாடு",
};

// Compare
double accuracy = TextEvaluator.calculateSimilarity(
  "food",           // lowercased question
  "food"            // lowercased spokenText
);
// Result: 95.2%

// Verify
if (accuracy >= 70) {  // 95.2% >= 70% ✅
  score++;             // +1 point (now 6/50)
  answeredQuestions[4] = true;
  
  // Show SUCCESS dialog
  _showSuccessDialog(question, accuracy, spokenText);
}
```

---

#### Step 3B: User Says "Fud" (INCORRECT - Misspoken)

**What happens:**
1. System records: "fud"
2. Compares with original: "Food"
3. Calculates accuracy
4. Result: **45.8% match** ❌ (<70% threshold)

**Dialog Shows:**
```
┌─────────────────────────────────────┐
│ ℹ️ Try Again                        │
├─────────────────────────────────────┤
│                                     │
│ You said: "fud"                     │
│                                     │
│ Expected: "Food" (சாப்பாடு)         │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Accuracy: 45.8%                 │ │
│ │ Need 70% to pass                │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 📈 Need 70% to pass             │ │
│ └─────────────────────────────────┘ │
│                                     │
│    [Retry]           [Skip]         │
└─────────────────────────────────────┘
```

**Backend Processing:**
```dart
String spokenText = "fud";
QuestionData question = {
  englishPhrase: "Food",
  tamilPhrase: "சாப்பாடு",
};

// Compare
double accuracy = TextEvaluator.calculateSimilarity(
  "food",           // lowercased question
  "fud"             // lowercased spokenText
);
// Result: 45.8% (similar but not enough)

// Verify
if (accuracy >= 70) {  // 45.8% >= 70% ❌ FALSE
  // NO POINTS AWARDED
  // score stays at 5
} else {
  // Show RETRY dialog
  _showRetryDialog(question, accuracy, spokenText);
}
```

---

#### Step 3C: User Says "Foo" (BORDERLINE - Close but not quite)

**What happens:**
1. System records: "foo"
2. Compares with original: "Food"
3. Calculates accuracy
4. Result: **52.3% match** ❌ (<70% threshold)

**Dialog Shows:**
```
┌─────────────────────────────────────┐
│ ℹ️ Try Again                        │
├─────────────────────────────────────┤
│                                     │
│ You said: "foo"                     │
│                                     │
│ Expected: "Food" (சாப்பாடு)         │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Accuracy: 52.3%                 │ │
│ │ Need 70% to pass                │ │
│ └─────────────────────────────────┘ │
│                                     │
│ You're close! Try again.            │
│                                     │
│    [Retry]           [Skip]         │
└─────────────────────────────────────┘
```

**User Options:**
1. **Retry** - Try again without penalty (score stays 5)
2. **Skip** - Move to next question (score stays 5)

---

## Accuracy Scoring System

### How Accuracy is Calculated

Uses **Levenshtein Distance** algorithm:
- Measures minimum edits needed to transform one word to another
- Edits include: insertions, deletions, substitutions

### Examples:

| User Said | Original | Changes | Accuracy | Result |
|-----------|----------|---------|----------|--------|
| "food" | "Food" | 0 (case-insensitive) | 100% | ✅ CORRECT |
| "fod" | "Food" | 1 deletion (missing 'o') | 75% | ✅ CORRECT |
| "fo" | "Food" | 2 deletions | 50% | ❌ INCORRECT |
| "foood" | "Food" | 1 insertion (extra 'o') | 80% | ✅ CORRECT |
| "fud" | "Food" | 1 substitution ('o' → 'u') | 75% | ✅ CORRECT |
| "xyz" | "Food" | 3 substitutions | 0% | ❌ INCORRECT |

### Threshold: 70%
- **≥70%** → Correct answer, +1 point
- **<70%** → Incorrect, no points, retry option

---

## Point Award System

### Rule: Points Only Awarded Once Per Question

```dart
if (accuracy >= 70) {
  // Check if this question hasn't been answered correctly yet
  if (!answeredQuestions[currentIndex]) {
    score++;                              // +1 point
    answeredQuestions[currentIndex] = true; // Mark as answered
  }
}
```

### Examples:

**Scenario 1: Get it right on first try**
- User says "food" (95% accuracy)
- Score: 5 → 6 (+1 point awarded) ✅
- `answeredQuestions[4] = true`
- If user goes back: No additional points

**Scenario 2: Get it wrong, then right on retry**
- Attempt 1: User says "fud" (45% accuracy) → No points, retry offered
- Attempt 2: User says "food" (95% accuracy)
- Score: 5 → 6 (+1 point awarded) ✅
- Total for this question: +1 point (not +2)

**Scenario 3: Get it wrong, skip, come back later**
- First time: User says "fud" (45% accuracy) → Skip
- User navigates backward to this question
- Attempts again: "food" (95% accuracy)
- Score: 5 → 6 (+1 point awarded) ✅

---

## Complete Verification Flow

```
START: Easy Level Page
  ↓
User sees: Image + "Food" + "சாப்பாடு" + [🎤 Record] button
  ↓
User clicks microphone → System listens
  ↓
User speaks into mic
  ↓
┌─────────────────────────────────────────┐
│ Compare with original word using:       │
│ - Levenshtein Distance algorithm        │
│ - Case-insensitive comparison           │
│ - Calculate accuracy percentage         │
└─────────────────────────────────────────┘
  ↓
┌─────────────────────────────────────────┐
│ Is accuracy >= 70%?                     │
│                                         │
│ YES (≥70%) → CORRECT                    │
│   ✅ Show SUCCESS dialog                │
│   ✅ Award +1 point (if not already got)│
│   ✅ Show: You said + Accuracy %        │
│   ✅ Button: "Next Question"            │
│                                         │
│ NO (<70%) → INCORRECT                   │
│   ❌ Show RETRY dialog                  │
│   ❌ No points awarded                  │
│   ❌ Show: You said vs Expected         │
│   ❌ Buttons: "Retry" or "Skip"         │
└─────────────────────────────────────────┘
  ↓
User clicks action button
  ↓
Continue to next question OR Complete all questions → Final score
```

---

## Dialog Details

### SUCCESS Dialog (Correct Answer ✅)

**Title:** ✅ Correct!

**Shows:**
- "You said: [what user said]"
- "The word is: [original] ([tamil])"
- "Accuracy: [percentage]%"
- "+1 Point" indicator

**Action:** [Next Question]

**Color Scheme:**
- Title icon: Green (0xFF10B981)
- Accuracy box: Light green background
- Points box: Green background with icon

---

### RETRY Dialog (Wrong Answer ❌)

**Title:** ℹ️ Try Again

**Shows:**
- "You said: [what user said]"
- "Expected: [original] ([tamil])"
- "Accuracy: [percentage]% (Need 70%)"

**Actions:**
1. [Retry] - Try same question again
2. [Skip] - Move to next question

**Color Scheme:**
- Title icon: Orange/Yellow (0xFFF59E0B)
- Accuracy box: Orange background
- Need 70% box: Grey background

---

## Real Example: Learning "Food"

### Session Flow:

**Question: Identify and name the food item**

1️⃣ Easy Level Page Shows:
```
Score: 12/50
Progress: 24%
🍽️ Image displayed
FOOD
சாப்பாடு
[🎤 Record] [🔊 Hear]
```

2️⃣ User clicks [🎤 Record]

3️⃣ System listens for user to say the word

4️⃣ User says: "food" or "Food" or "FOOD" (any case)

5️⃣ System processes:
```
Input: "food"
Original: "Food"
Compare: "food" vs "food" (lowercased)
Accuracy: 100%
Threshold: ≥70%
Result: 100% >= 70% ✅ PASS
Points: +1 awarded
New Score: 13/50
```

6️⃣ SUCCESS Dialog appears:
```
✅ Correct!
You said: "food"
The word is: "Food" (சாப்பாடு)
Accuracy: 100%
⭐ +1 Point
[Next Question]
```

7️⃣ User clicks [Next Question]

8️⃣ Continue to next question

---

## Code Implementation

### Main Verification Function:
```dart
void _evaluateAnswer(String spokenText) {
  final question = widget.questions[currentIndex];
  
  // STEP 1: Calculate similarity
  final accuracy = TextEvaluator.calculateSimilarity(
    question.englishPhrase.toLowerCase(),
    spokenText.toLowerCase(),
  );

  // STEP 2: Store result in state
  setState(() {
    lastSpokenText = spokenText;
    lastAccuracy = accuracy;
    showResult = true;
  });

  // STEP 3: Check if correct
  if (accuracy >= 70) {
    // CORRECT - Award points
    if (!answeredQuestions[currentIndex]) {
      setState(() {
        score++;
        answeredQuestions[currentIndex] = true;
      });
    }
    // Show success feedback
    _showSuccessDialog(question, accuracy, spokenText);
  } else {
    // INCORRECT - No points
    // Show retry feedback
    _showRetryDialog(question, accuracy, spokenText);
  }
}
```

---

## Summary

### Easy Level Verification Process:

✅ **User speaks into microphone**
  ↓
✅ **System compares with original word**
  ↓
✅ **Calculates accuracy using Levenshtein distance**
  ↓
✅ **Checks if accuracy ≥ 70%**
  ↓
✅ **If CORRECT: Award +1 point, show success dialog**
  ↓
✅ **If INCORRECT: Show what they said vs expected, offer retry**
  ↓
✅ **User continues or moves to next question**
  ↓
✅ **Final score calculated at end of session**

This system ensures fair, transparent feedback where users always know:
- What they said
- What the correct answer is
- How close they were (accuracy %)
- Whether they earned points
- How to improve

