# Easy Level Testing & Verification Quick Reference

## Quick Test Scenarios

### Test 1: Perfect Match

**Setup:** Easy Level page showing "Food"

**Action:**
1. Click [🎤 Record]
2. Say: "food" (or "Food", "FOOD")
3. Wait for result

**Expected Result:**
```
Dialog: ✅ Correct!
Message: You said: "food"
Message: The word is: "Food" (சாப்பாடு)
Accuracy: 95%+ 
Reward: +1 Point
Score: Increases by 1
Button: [Next Question]
```

**Verification Points:**
- ✅ Accuracy >= 70%
- ✅ Points awarded (if first time)
- ✅ answeredQuestions[index] = true

---

### Test 2: Close Match (Should Pass)

**Setup:** Easy Level page showing "Water"

**Action:**
1. Click [🎤 Record]
2. Say: "watr" (missing one 'e')
3. Wait for result

**Expected Result:**
```
Dialog: ✅ Correct!
Accuracy: 75%+ 
Reward: +1 Point
Score: Increases by 1
```

**Why it passes:** 75% >= 70% threshold

---

### Test 3: Bad Match (Should Fail)

**Setup:** Easy Level page showing "Water"

**Action:**
1. Click [🎤 Record]
2. Say: "wet" (substituted letters)
3. Wait for result

**Expected Result:**
```
Dialog: ❌ Try Again
Message: You said: "wet"
Message: Expected: "Water" (தண்ணீர்)
Accuracy: 45%
Requirement: Need 70% to pass
Buttons: [Retry] [Skip]
Score: NO CHANGE
```

**Why it fails:** 45% < 70% threshold

---

### Test 4: Retry After Wrong Answer

**Setup:** Already failed once with "wet"

**Action:**
1. Dialog shows [Retry]
2. User clicks [Retry]
3. Say: "water" (correct this time)
4. Wait for result

**Expected Result:**
```
Dialog: ✅ Correct!
Accuracy: 100%
Reward: +1 Point
Score: Increases by 1 (ONLY ONCE for this question)
```

**Critical Check:** Score should increase by exactly 1, not 2
- First attempt: "wet" = No points
- Second attempt: "water" = +1 point
- Total for question: +1 (not +2)

---

### Test 5: Skip Wrong Answer

**Setup:** Easy Level page with wrong answer

**Action:**
1. Answer incorrectly
2. Dialog shows [Skip]
3. User clicks [Skip]
4. Wait for result

**Expected Result:**
```
Current question cleared
Move to next question
Score: NO CHANGE
answeredQuestions[index] = false (not marked as answered)
```

---

### Test 6: Navigate Backward After Correct Answer

**Setup:** Answered Q5 correctly with +1 point

**Action:**
1. Answer Q6
2. Click [← Previous]
3. Back to Q5
4. Click [🎤 Record]
5. Say the word again
6. Wait for result

**Expected Result:**
```
Dialog: ✅ Correct!
Accuracy: 95%+
BUT: NO ADDITIONAL POINTS
Score: NO CHANGE

Why: answeredQuestions[4] = true (already answered)
System checks: !answeredQuestions[4] → FALSE
No points awarded second time
```

---

## Detailed Verification Checklist

### Accuracy Calculation Verification

**Test Case: "Food"**

```
Scenario: User says "fod" (missing one 'o')

Step 1: Input
  spokenText = "fod"
  originalWord = "Food"

Step 2: Normalize (case-insensitive)
  normalized_input = "fod"
  normalized_original = "food"

Step 3: Calculate Levenshtein distance
  "fod" → "food"
  Need to insert one 'o'
  Distance = 1

Step 4: Calculate accuracy
  max_length = max(3, 4) = 4
  accuracy = (1 - 1/4) * 100 = 75%

Step 5: Verify threshold
  75% >= 70%? YES ✅
  Result: CORRECT

Expected Dialog: ✅ Correct! (Accuracy: 75%)
```

---

### Point Award Verification

**Test Case: Point System**

```
Initial State:
  score = 5
  answeredQuestions[3] = false (Question 4 not answered)

User answers Q4 correctly with "Water" (100% accuracy):
  accuracy = 100%
  if (100% >= 70%) → TRUE
    if (!answeredQuestions[3]) → TRUE (hasn't been answered)
      score++ → score = 6
      answeredQuestions[3] = true
    end
  end

Result: Score = 6, answeredQuestions[3] = true

User tries Q4 again:
  accuracy = 100%
  if (100% >= 70%) → TRUE
    if (!answeredQuestions[3]) → FALSE (already answered!)
      // SKIP - no increment
    end
  end

Result: Score stays 6 (NO additional points)
```

---

### Dialog Appearance Verification

**Success Dialog (>=70%) Checklist:**
- ✅ Title shows: "✅ Correct!" with green checkmark
- ✅ Shows: "You said: [user's input]"
- ✅ Shows: "The word is: [original] ([tamil])"
- ✅ Accuracy box displays percentage with %
- ✅ Points box shows: "⭐ +1 Point"
- ✅ Button: "Next Question" available
- ✅ Dialog is non-dismissible (no X button)
- ✅ Background dim (modal dialog)

**Retry Dialog (<70%) Checklist:**
- ✅ Title shows: "ℹ️ Try Again" with orange icon
- ✅ Shows: "You said: [user's input]"
- ✅ Shows: "Expected: [original] ([tamil])"
- ✅ Shows accuracy percentage
- ✅ Shows: "Need 70% to pass"
- ✅ Two buttons: "Retry" and "Skip"
- ✅ Dialog is non-dismissible
- ✅ Background dim

---

## Test Execution Steps

### How to Run Tests

1. **Start Easy Level:**
   - Go to Assessment Page
   - Click "Easy Level"
   - Select question 1 or use [Next] to navigate

2. **Test Each Scenario:**
   - Follow action steps above
   - Check all expected results
   - Verify score display updates
   - Confirm dialog appearance

3. **Record Results:**
   - ✅ Pass: All checks verified
   - ❌ Fail: List which checks failed
   - Note: Any unexpected behavior

4. **Test Completion:**
   - After ~50 questions (or click Finish early)
   - Verify completion screen appears
   - Check final score calculation
   - Verify performance badge displayed

---

## Common Issues & Solutions

### Issue 1: Score Not Increasing

**Check:**
```dart
// In _evaluateAnswer method:
if (accuracy >= 70) {
  if (!answeredQuestions[currentIndex]) {
    setState(() {
      score++;  // This line must execute
      answeredQuestions[currentIndex] = true;
    });
  }
}
```

**Verify:**
- Accuracy actually >= 70%?
- answeredQuestions[currentIndex] was false?
- setState() is being called?
- Widget refreshed?

---

### Issue 2: Points Awarded Multiple Times

**Check:**
```dart
// This should prevent multiple awards:
if (!answeredQuestions[currentIndex]) {  // This check
  score++;
}
```

**Fix:**
- Ensure answeredQuestions array is initialized
- Ensure array is updated when answer is correct
- Ensure array persists between dialogs

---

### Issue 3: Wrong Accuracy Percentage

**Check:**
```dart
double accuracy = TextEvaluator.calculateSimilarity(
  question.englishPhrase.toLowerCase(),
  spokenText.toLowerCase(),
);
```

**Verify:**
- Both strings are lowercased
- Using correct comparison method
- No extra spaces in comparison

---

## Performance Badges Testing

**Test Case 1: Excellent (≥80%)**
```
Questions: 50
Correct: 40+
Score: 40/50 = 80%
Expected Badge: ⭐ Excellent Performance!
```

**Test Case 2: Good (60-79%)**
```
Questions: 50
Correct: 30-39
Score: 30/50 = 60%
Expected Badge: 👍 Good effort! Keep practicing.
```

**Test Case 3: Keep Practicing (<60%)**
```
Questions: 50
Correct: <30
Score: 25/50 = 50%
Expected Badge: 💡 Keep practicing to improve!
```

---

## Complete Session Test

### Full Session Walkthrough

```
Step 1: Start Easy Level
  - See Question 1/50
  - See image
  - See "Water" and "தண்ணீர்"
  - Score: 0/50

Step 2: Answer Q1 correctly
  - Say "water"
  - Get "✅ Correct!" dialog
  - See +1 Point
  - Score: 1/50
  - Click [Next Question]

Step 3: Answer Q2 wrong, retry, then correct
  - Say "watr" (wrong)
  - Get "❌ Try Again" dialog
  - Click [Retry]
  - Say "water" (correct)
  - Get "✅ Correct!" dialog
  - Score: 2/50 (only +1 for this question)
  - Click [Next Question]

Step 4: Continue through ~47 more questions
  - Score increases for each correct answer
  - Retry dialogs for wrong answers
  - Progress bar shows advancement

Step 5: Answer Q50
  - Last question
  - Answer correctly or incorrectly
  - System detects last question

Step 6: Completion Screen
  - Shows final score (e.g., 35/50)
  - Shows percentage (e.g., 70%)
  - Shows correct/incorrect breakdown
  - Shows performance badge
  - Button: [Finish]
  - Click [Finish] to return to Assessment Page
```

---

## Validation Criteria

### Must Pass All:

- ✅ Accuracy calculation is correct
- ✅ Points awarded only once per question
- ✅ Success dialog shows for ≥70% accuracy
- ✅ Retry dialog shows for <70% accuracy
- ✅ Spoken text displayed correctly
- ✅ Original word displayed correctly
- ✅ Tamil translation displayed
- ✅ Score updates in real-time
- ✅ Completion screen shows final stats
- ✅ Can retry and skip incorrect answers
- ✅ Navigation (Previous/Next) works
- ✅ Progress bar accurate
- ✅ No points awarded on retry of already-answered Q
- ✅ Case-insensitive comparison works
- ✅ Performance badges correct

### If Any Fail:
- Note which test failed
- Check the corresponding code section
- Fix and re-test

