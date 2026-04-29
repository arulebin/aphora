# Easy vs Medium Level - Complete Comparison Guide

## Side-by-Side Feature Comparison

### Easy Level (Visual Question Page)

**Purpose:** Learn with guidance - Image + Word + Tamil + Audio support

```
EASY LEVEL INTERFACE:
┌──────────────────────────────────┐
│    EASY LEVEL - VISUAL LEARNING  │
├──────────────────────────────────┤
│ Score: 12/50    Progress: 24%    │
│ Question 5 of 50                 │
│                                  │
│  ┌────────────────────────────┐  │
│  │     🍽️ (Food Image)        │  │
│  └────────────────────────────┘  │
│                                  │
│     FOOD                         │ ← English text shown
│    சாப்பாடு                       │ ← Tamil text shown
│                                  │
│   Easy (difficulty badge)        │
│                                  │
│  [🔊 Hear] [🎤 Record]           │ ← Two action buttons
│                                  │
│ [← Previous]    [Next →]         │
└──────────────────────────────────┘
```

### Medium Level (Image Description Page)

**Purpose:** Challenge level - Image only, describe it

```
MEDIUM LEVEL INTERFACE:
┌──────────────────────────────────┐
│  MEDIUM LEVEL - IMAGE DESCRIPTION│
├──────────────────────────────────┤
│ Score: 12/50    Progress: 24%    │
│ Question 5 of 50                 │
│                                  │
│  ┌────────────────────────────┐  │
│  │     🍽️ (Food Image)        │  │
│  │   (NO TEXT BELOW IMAGE)    │  │
│  └────────────────────────────┘  │
│                                  │
│   Instructions:                  │
│   1. Look at image carefully     │
│   2. Click microphone            │
│   3. Say the name               │
│   4. Answer compared with word  │
│                                  │
│          ⭕ [🎤 RECORD]           │ ← Large mic button
│       (Listening... when active)  │
│                                  │
│  [← Previous]    [Next →]         │
└──────────────────────────────────┘
```

---

## Feature Comparison Table

| Feature | Easy Level | Medium Level |
|---------|-----------|--------------|
| **What User Sees** | Image + English text + Tamil text | Image only (no text) |
| **Difficulty Level** | Beginner | Intermediate |
| **Audio Support** | Yes - [🔊 Hear] button | No audio support |
| **Microphone** | [🎤 Record] button | Large circular [🎤] button |
| **Image Size** | 280x280 px | 300x300 px |
| **Text Shown** | English + Tamil + Difficulty | Only instructions |
| **Guidance** | Max guidance | Minimal guidance |
| **Feedback Type** | Dialog box | Dialog box |
| **Comparison Method** | With English phrase | With English + Tamil |
| **Accuracy Threshold** | 70% | 70% |
| **Points Per Question** | +1 (max once) | +1 (max once) |
| **Retry Option** | Yes | Yes |
| **Completion Screen** | Yes | Yes |
| **Performance Badge** | Yes | Yes |

---

## User Interface Comparison

### Navigation Buttons

**Easy Level:**
```
[← Previous]        [Next →]
  Green if enabled    Green if enabled
  Grey if disabled    Grey if disabled
```

**Medium Level:**
```
[← Previous]        [Next →]
  Green if enabled    Green if enabled
  Grey if disabled    Grey if disabled
```
*(Same styling)*

---

### Score Display

**Easy Level:**
```
┌─────────────────────┐
│  Score: 12          │ ← Simple display
└─────────────────────┘
```

**Medium Level:**
```
┌─────────────────────────────┐
│ ⭐ Score: 12 / 50          │ ← With icon and total
└─────────────────────────────┘
```

---

### Progress Bar

**Easy Level:**
```
Progress         24%
▓▓▓▓▓░░░░░░░░░░░░░
(Linear progress indicator)
```

**Medium Level:**
```
Progress
▓▓▓▓▓░░░░░░░░░░░░░  24%
(Similar linear progress)
```

---

### Feedback Dialogs

#### Success Dialog - Easy Level
```
┌─────────────────────────────────┐
│ ✅ Correct!                     │
├─────────────────────────────────┤
│ You said: "food"                │
│ The word is: "Food" (சாப்பாடு)   │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ Accuracy: 95.2%             │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ ⭐ +1 Point                 │ │
│ └─────────────────────────────┘ │
│                                 │
│      [Next Question]            │
└─────────────────────────────────┘
```

#### Success Dialog - Medium Level
```
┌─────────────────────────────────┐
│ ✅ Correct!                     │
├─────────────────────────────────┤
│ You said: "food"                │
│ The word is: "Food" (சாப்பாடு)   │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ Accuracy: 95.2%             │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ ⭐ +1 Point                 │ │
│ └─────────────────────────────┘ │
│                                 │
│      [Next Question]            │
└─────────────────────────────────┘
```
*(Identical)*

---

## Learning Flow Comparison

### Easy Level Flow

```
Start Easy Level
      ↓
Show Image + "Food" + "சாப்பாடு" + Audio Button
      ↓
User sees the answer on screen
      ↓
User clicks [🔊 Hear] to hear Tamil pronunciation
      ↓
User clicks [🎤 Record] to record voice
      ↓
User says "food" (already knows the answer!)
      ↓
System compares with "Food"
      ↓
      ┌────── Accuracy >= 70%? ──────┐
      ↓                              ↓
   SUCCESS                        RETRY
   ✅ Correct!                    ❌ Try Again
   +1 Point                       No Points
   Move to Next                   [Retry/Skip]
      ↓                              ↓
   Continue or Complete         Try Again or Skip
```

### Medium Level Flow

```
Start Medium Level
      ↓
Show Image ONLY (no text)
      ↓
User must think of the word
      ↓
User clicks [🎤] to record voice
      ↓
User says what they think it is
      ↓
System compares spoken word with original
      ↓
      ┌────── Accuracy >= 70%? ──────┐
      ↓                              ↓
   SUCCESS                        RETRY
   ✅ Correct!                    ❌ Try Again
   +1 Point                       No Points
   Move to Next                   [Retry/Skip]
      ↓                              ↓
   Continue or Complete         Try Again or Skip
```

---

## Difficulty Progression

```
BEGINNER → INTERMEDIATE → ADVANCED
   ↓            ↓            ↓
 EASY        MEDIUM        HARD
 Level       Level         Level
   ↓            ↓            ↓
Image +     Image only    Interactive
Text +                     Dialogue
Tamil +                    Conversation
Audio
```

### Easy Level - Beginner
- **Guidance:** Maximum
- **Text:** Shown completely
- **Audio:** Available
- **Help:** Full context
- **Best for:** Beginning learners
- **Example:** "Here's FOOD (சாப்பாடு). Now repeat it!"

### Medium Level - Intermediate
- **Guidance:** Minimal
- **Text:** Not shown
- **Audio:** Not available
- **Help:** Image only
- **Best for:** Intermediate learners
- **Example:** "What is this? (shows food image - user must name it)"

### Hard Level - Advanced
- **Guidance:** None
- **Text:** Not shown
- **Audio:** Not available
- **Help:** Natural conversation
- **Best for:** Advanced learners
- **Example:** "Have you eaten today?"

---

## Verification System Comparison

### Easy Level Verification

```
Input: "food" (spoken by user)
Original: "Food" (text shown on screen)
Already visible to user before recording

Comparison:
  1. Case-insensitive: "food" vs "food"
  2. Levenshtein distance: 0
  3. Accuracy: 100%
  4. Threshold: >= 70%
  5. Result: ✅ PASS

Expected behavior:
- User has already read the word
- More likely to get it right
- Good for building confidence
```

### Medium Level Verification

```
Input: "food" (spoken by user)
Original: "Food" (NOT shown to user, image only)
User must think of answer on their own

Comparison:
  1. Case-insensitive: "food" vs "food"
  2. Levenshtein distance: 0
  3. Accuracy: 100%
  4. Threshold: >= 70%
  5. Result: ✅ PASS

Expected behavior:
- User has NOT read the word
- Tests actual vocabulary knowledge
- More challenging, better assessment
```

---

## Completion Screens

### Easy Level - Completion

```
┌──────────────────────────────┐
│ 🎉 Session Complete!        │
├──────────────────────────────┤
│                              │
│  Score: 35 / 50              │
│  70.0% Accuracy              │
│                              │
│ ┌──────────────────────────┐ │
│ │ ✅ Correct:      35      │ │
│ │ ❌ Incorrect:    15      │ │
│ └──────────────────────────┘ │
│                              │
│  👍 Good effort!             │
│  Keep practicing.            │
│                              │
│        [Finish]              │
└──────────────────────────────┘
```

### Medium Level - Completion

```
┌──────────────────────────────┐
│ 🎉 Session Complete!        │
├──────────────────────────────┤
│                              │
│  Score: 35 / 50              │
│  70.0% Accuracy              │
│                              │
│ ┌──────────────────────────┐ │
│ │ ✅ Correct:      35      │ │
│ │ ❌ Incorrect:    15      │ │
│ └──────────────────────────┘ │
│                              │
│  👍 Good effort!             │
│  Keep practicing.            │
│                              │
│        [Finish]              │
└──────────────────────────────┘
```
*(Identical)*

---

## When to Use Each Level

### Use Easy Level When:
✅ User is a beginner
✅ Building confidence is important
✅ Learning new vocabulary
✅ Need audio pronunciation support
✅ Want maximum guidance
✅ Pre-assessment phase

### Use Medium Level When:
✅ User is intermediate
✅ Want to assess real knowledge
✅ Need to challenge the learner
✅ Testing retention
✅ No text hints available
✅ Want realistic scenarios

### Use Hard Level When:
✅ User is advanced
✅ Need full conversation skills
✅ Real-world dialogue practice
✅ No structure or hints
✅ Advanced assessment

---

## Processing Comparison

### Easy Level Processing

```dart
String spokenText = "food";
String originalWord = "Food";  // Already shown to user

// User has read this word
final accuracy = TextEvaluator.calculateSimilarity(
  originalWord.toLowerCase(),      // "food"
  spokenText.toLowerCase()          // "food"
);
// Result: 100% (very likely since user read it)

if (accuracy >= 70) {
  score++;  // Reward effort and confidence building
  answeredQuestions[currentIndex] = true;
}
```

### Medium Level Processing

```dart
String spokenText = "food";
String originalWord = "Food";  // NOT shown to user

// User hasn't read this word
// Must recall from memory or visual recognition
final accuracy = TextEvaluator.calculateSimilarity(
  originalWord.toLowerCase(),      // "food"
  spokenText.toLowerCase()          // "food"
);
// Result: 100% (tests actual knowledge)

if (accuracy >= 70) {
  score++;  // Reward genuine knowledge
  answeredQuestions[currentIndex] = true;
}
```

---

## Summary

| Aspect | Easy Level | Medium Level |
|--------|-----------|--------------|
| **User Sees** | Image + Text + Tamil | Image Only |
| **Guidance** | Maximum | Minimum |
| **Audio Support** | Yes | No |
| **Purpose** | Learn & Build Confidence | Challenge & Assess |
| **Difficulty** | Beginner | Intermediate |
| **Text Hints** | Full | None |
| **Expected Accuracy** | High (80%+) | Variable (50%+) |
| **Best For** | New learners | Knowledge check |
| **Feedback** | Dialog box | Dialog box |
| **Points System** | +1 max per Q | +1 max per Q |
| **Completion Screen** | Yes | Yes |

---

## Complete Learning Journey

```
ASSESSMENT PAGE
      ↓
  ┌───┴────┬────────┬────────┐
  ↓        ↓        ↓        ↓
Easy    Medium    Hard    Other
Level    Level    Level   Tests
  ↓        ↓        ↓        ↓
Image +  Image    Interactive Picture
Text +   Only     Dialogue   Match
Tamil +  (50 Qs)  (Advance)  Test
Audio    Tests         
(50 Qs)  Knowledge     Scores
Builds   Real          Compared
Config.  Vocab.        & Tracked
Learns
```

