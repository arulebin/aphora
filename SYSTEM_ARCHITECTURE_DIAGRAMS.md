# Visual System Architecture & Flow Diagrams

## Overall System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     APHORA LEARNING SYSTEM                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │              ASSESSMENT PAGE                             │ │
│  │  - Easy Level Card                                       │ │
│  │  - Medium Level Card                                     │ │
│  │  - Hard Level Card                                       │ │
│  └─────┬───────────────────┬───────────────────┬────────────┘ │
│        │                   │                   │              │
│   Easy │               Medium │               Hard │          │
│ Level  │               Level  │               Level │          │
│   ↓    │                   ↓   │                   ↓   │          │
│  ┌─────▼──────┐        ┌────▼──────┐        ┌─────▼──────┐   │
│  │ Visual      │        │ Medium    │        │  Hard      │   │
│  │ Question    │        │ Level     │        │  Level     │   │
│  │ Page        │        │ Page      │        │  Page      │   │
│  │             │        │           │        │            │   │
│  │ Image +     │        │ Image     │        │ Dialogue   │   │
│  │ Text +      │        │ Only      │        │ Based      │   │
│  │ Tamil +     │        │ (Image    │        │            │   │
│  │ Audio       │        │ Descrip.) │        │            │   │
│  └────────────┘        └───────────┘        └────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Easy Level Flow Diagram

```
START: Easy Level Page
  │
  ├─► Initialize
  │   - Load 50 questions
  │   - Set currentIndex = 0
  │   - Create answeredQuestions array
  │   - Initialize score = 0
  │
  ├─► Display Question
  │   - Show image
  │   - Show English phrase: "FOOD"
  │   - Show Tamil: "சாப்பாடு"
  │   - Show difficulty badge
  │   - Show progress bar
  │   - Show current score
  │
  ├─► User Actions
  │   ├─► [🔊 Hear] - Play audio of Tamil
  │   │   └─► SpeechService.speakText(tamilPhrase)
  │   │
  │   ├─► [🎤 Record] - Record voice
  │   │   └─► SpeechService.startListening()
  │   │       └─► onResult: _evaluateAnswer(spokenText)
  │   │
  │   └─► [← Previous/Next →] - Navigate
  │       ├─► Previous: currentIndex--
  │       └─► Next: currentIndex++
  │
  ├─► Verification Process
  │   ├─► Extract spoken text
  │   ├─► Normalize (lowercase both)
  │   ├─► Calculate Levenshtein distance
  │   ├─► Convert to accuracy %
  │   └─► Check if >= 70%
  │
  ├─► Decision Point
  │   │
  │   ├─► accuracy >= 70%? ─── YES ──►
  │   │                         │
  │   │                         ├─► Award points?
  │   │                         │   if (!answeredQuestions[i])
  │   │                         │     score++
  │   │                         │     answeredQuestions[i] = true
  │   │                         │
  │   │                         └─► Show Success Dialog
  │   │                             ✅ Correct!
  │   │                             You said: "food"
  │   │                             Expected: "Food"
  │   │                             Accuracy: 95.2%
  │   │                             +1 Point
  │   │                             [Next Question]
  │   │
  │   └─► accuracy < 70%? ─── YES ──►
  │                           │
  │                           ├─► No points awarded
  │                           │
  │                           └─► Show Retry Dialog
  │                               ❌ Try Again
  │                               You said: "fud"
  │                               Expected: "Food"
  │                               Need 70%
  │                               [Retry] [Skip]
  │
  ├─► Post-Feedback
  │   ├─► User clicks button
  │   ├─► Clear dialog
  │   ├─► Reset state variables
  │   └─► Navigate to next question or retry
  │
  ├─► Loop Through Questions
  │   └─► Repeat until currentIndex >= 50
  │
  └─► Completion
      ├─► Calculate final score: 35 / 50
      ├─► Calculate percentage: 70.0%
      ├─► Determine badge: "Good effort!"
      ├─► Show completion screen
      └─► [Finish] → Return to Assessment Page
```

---

## Medium Level Flow Diagram

```
START: Medium Level Page
  │
  ├─► Initialize
  │   - Load 50 questions
  │   - Set currentIndex = 0
  │   - Create answeredQuestions array
  │   - Initialize score = 0
  │   - Initialize SpeechService
  │
  ├─► Display Question
  │   - Show LARGE image (300x300px) ─ NO TEXT
  │   - No English text visible
  │   - No Tamil text visible
  │   - Show instructions
  │   - Show progress bar
  │   - Show current score
  │
  ├─► User Sees
  │   │
  │   ├─► Image (e.g., 🍽️)
  │   ├─► "Instructions:" section
  │   │   - Look at image carefully
  │   │   - Click microphone
  │   │   - Say the name
  │   │   - Answer compared with word
  │   │
  │   ├─► Progress bar: 24% (10/50)
  │   ├─► Score: ⭐ Score: 7 / 50
  │   └─► Large microphone button
  │
  ├─► User Action
  │   └─► Clicks [🎤] button
  │       └─► Activates microphone
  │           ├─► Show "Listening..."
  │           ├─► Record for max 10 seconds
  │           ├─► Process speech-to-text
  │           └─► onResult: _evaluateAnswer(spokenText)
  │
  ├─► Verification Process
  │   ├─► Extract spoken text: "food"
  │   ├─► Get original word: "Food" (NOT shown to user)
  │   ├─► Normalize (lowercase both)
  │   ├─► Calculate Levenshtein distance
  │   ├─► Convert to accuracy %
  │   └─► Check if >= 70%
  │
  ├─► Decision Point
  │   │
  │   ├─► accuracy >= 70%? ─── YES ──►
  │   │                         │
  │   │                         ├─► Award points?
  │   │                         │   if (!answeredQuestions[i])
  │   │                         │     score++
  │   │                         │     answeredQuestions[i] = true
  │   │                         │
  │   │                         └─► Show Success Dialog
  │   │                             ✅ Correct!
  │   │                             You said: "food"
  │   │                             Expected: "Food"
  │   │                             Accuracy: 100%
  │   │                             +1 Point
  │   │                             [Next Question]
  │   │
  │   └─► accuracy < 70%? ─── YES ──►
  │                           │
  │                           ├─► No points awarded
  │                           │
  │                           └─► Show Retry Dialog
  │                               ℹ️ Try Again
  │                               You said: "fud"
  │                               Expected: "Food"
  │                               Accuracy: 45.8%
  │                               Need 70%
  │                               [Retry] [Skip]
  │
  ├─► Post-Feedback Actions
  │   ├─► User clicks [Next Question]
  │   ├─► Or clicks [Retry]
  │   ├─► Or clicks [Skip]
  │   ├─► Clear dialog
  │   ├─► Reset UI state
  │   └─► Navigate accordingly
  │
  ├─► Loop Through Questions
  │   └─► Repeat until currentIndex >= 50
  │
  └─► Completion
      ├─► Calculate final score: 42 / 50
      ├─► Calculate percentage: 84.0%
      ├─► Determine badge: "Excellent Performance! 🎉"
      ├─► Show completion screen with breakdown
      └─► [Finish] → Return to Assessment Page
```

---

## Verification Algorithm Flow

```
                    USER SPEAKS
                        │
                        ▼
                  CAPTURE AUDIO
                        │
                        ▼
              CONVERT SPEECH TO TEXT
                        │
                        ▼
              TEXT = spokenText = "fud"
                        │
                        ▼
         RETRIEVE ORIGINAL WORD = "Food"
                        │
                        ▼
         NORMALIZE TO LOWERCASE
         "fud" vs "food"
                        │
                        ▼
      CALCULATE LEVENSHTEIN DISTANCE
      
      Compare: "fud" → "food"
      Edit: Insert 'o'
      Distance = 1
                        │
                        ▼
      CALCULATE ACCURACY PERCENTAGE
      
      accuracy = (1 - distance/maxLength) * 100
      accuracy = (1 - 1/4) * 100
      accuracy = 75%
                        │
                        ▼
        COMPARE WITH THRESHOLD (70%)
        
        75% >= 70%?  → YES ✅
                        │
                        ▼
        AWARD POINTS (if not already answered)
        
        if (!answeredQuestions[currentIndex]) {
          score++
          answeredQuestions[currentIndex] = true
        }
                        │
                        ▼
      SHOW SUCCESS DIALOG WITH RESULTS
      
      ✅ Correct!
      You said: "fud"
      Expected: "Food" (சாப்பாடு)
      Accuracy: 75%
      ⭐ +1 Point
```

---

## State Management Flow

```
┌─────────────────────────────────────────────────────────┐
│              STATE VARIABLES                            │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  currentIndex = 0                                       │
│  ├─► Tracks which question (0-49)                       │
│  └─► Updated when navigating Previous/Next             │
│                                                         │
│  score = 0                                              │
│  ├─► Starts at 0                                        │
│  ├─► Incremented by 1 for each correct answer           │
│  ├─► Only incremented if !answeredQuestions[index]      │
│  └─► Displayed in header                               │
│                                                         │
│  answeredQuestions = [false, false, ...]               │
│  ├─► Array of 50 booleans                               │
│  ├─► Set to true when question answered correctly      │
│  ├─► Prevents duplicate points for same question       │
│  └─► Persists through navigation                       │
│                                                         │
│  lastSpokenText = ""                                    │
│  ├─► Stores what user said last                         │
│  └─► Displayed in dialog                               │
│                                                         │
│  lastAccuracy = 0.0                                     │
│  ├─► Stores accuracy percentage                         │
│  └─► Displayed in dialog                               │
│                                                         │
│  showResult = false                                     │
│  ├─► Tracks if result dialog shown                      │
│  └─► Used to clear state between answers               │
│                                                         │
└─────────────────────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────────┐
│        STATE UPDATE SEQUENCE                            │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  1. User speaks                                         │
│     └─► Extract spokenText                             │
│                                                         │
│  2. Call _evaluateAnswer(spokenText)                   │
│     ├─► Calculate accuracy                             │
│     └─► setState({ lastSpokenText, lastAccuracy })    │
│                                                         │
│  3. Check accuracy >= 70%                              │
│     ├─► YES: setState({ score++, answeredQuestions[i] })│
│     └─► NO: No state change for score                  │
│                                                         │
│  4. Show dialog                                         │
│     └─► Dialog displays stored state values             │
│                                                         │
│  5. User clicks button                                  │
│     ├─► [Next]: setState({ currentIndex++, reset })    │
│     ├─► [Retry]: setState({ reset showResult })        │
│     └─► [Skip]: setState({ currentIndex++, reset })    │
│                                                         │
│  6. Return to step 1 for next question                 │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## Point Award Protection

```
┌──────────────────────────────────────────────────────────┐
│          PREVENTING DUPLICATE POINTS                     │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  Initial State:                                          │
│  ├─► score = 5                                           │
│  └─► answeredQuestions[3] = false (Question 4)          │
│                                                          │
│  First Attempt: User answers Q4 correctly               │
│  ├─► accuracy = 100% >= 70% ✓                            │
│  ├─► Check: !answeredQuestions[3] → true                │
│  ├─► Execute: score = 6                                 │
│  ├─► Execute: answeredQuestions[3] = true               │
│  └─► Result: +1 point awarded ✓                          │
│                                                          │
│  If User Retries Q4 (navigates back):                   │
│  ├─► accuracy = 100% >= 70% ✓                            │
│  ├─► Check: !answeredQuestions[3] → false ✗             │
│  ├─► Action: SKIP increment                              │
│  └─► Result: NO additional points ✓                      │
│                                                          │
│  If User Answers Q4 Wrong Then Right:                   │
│  ├─► First attempt: accuracy = 45% < 70%                │
│  │   └─► answeredQuestions[3] stays false               │
│  ├─► Second attempt: accuracy = 100% >= 70%             │
│  │   ├─► Check: !answeredQuestions[3] → true            │
│  │   ├─► score++                                         │
│  │   └─► Result: +1 point (only once total) ✓           │
│  │                                                      │
│  └─► Protection Verified ✓                              │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

---

## Complete Question Lifecycle

```
                    QUESTION LIFECYCLE
                            │
         ┌──────────────────┼──────────────────┐
         │                  │                  │
         ▼                  ▼                  ▼
    INITIAL           DISPLAYED           ATTEMPTED
    
    • Q created      • User sees       • User recorded
    • Index = 4      • Image shown      • Verification done
    • Answered = F   • Text shown       • Dialog shown
    • Score = 5      • Ready to input   • Points checked
    
         │                  │                  │
         └──────────────────┼──────────────────┘
                            │
         ┌──────────────────┼──────────────────┐
         │                  │                  │
         ▼                  ▼                  ▼
    CORRECT          INCORRECT           SKIPPED
    (≥70%)            (<70%)              (User chose)
    
    • +1 Point        • No points         • No points
    • Answered = T    • Answered = F      • Answered = F
    • Score = 6       • Score stays 5     • Score stays 5
    • Dialog success  • Dialog retry      • Move to next
    
         │                  │                  │
         └──────────────────┼──────────────────┘
                            │
                    ┌───────▼───────┐
                    │   COMPLETED   │
                    │               │
                    │ Move to Q5    │
                    │ Continue loop │
                    │               │
                    └───────────────┘
```

---

## Dialog Decision Tree

```
                    USER RECORDS AUDIO
                            │
                ┌───────────┴────────────┐
                │                        │
         Calculate Accuracy     Display Result
                │                        
         ┌──────┴──────┐                 
         │             │                 
      ≥70%            <70%               
         │             │                 
         ▼             ▼                 
      CORRECT      INCORRECT           
         │             │                 
         ├─► Award     ├─► Show "Try    
         │   +1 point  │   Again" with  
         │             │   [Retry]      
         ├─► Show      │   [Skip]       
         │   "Correct!"│               
         │   dialog    ├─► User chooses:
         │             │   ├─► [Retry]
         ├─► Button    │   │   └─► Back to
         │   "Next     │   │       same Q
         │   Question" │   │
         │             │   └─► [Skip]
         └─────┬───────┤       └─► Move to
               │       │           next Q
               │       │
               ▼       ▼
            NAVIGATE TO NEXT
                   │
        ┌──────────┴──────────┐
        │                     │
    Last?                Not Last?
    (Q50)                 (Q<50)
        │                     │
        ▼                     ▼
   COMPLETION          NEXT QUESTION
   SCREEN              │
   • Score             └─► Loop back to
   • Percentage           Display step
   • Badge
   • [Finish]
```

---

## Files Integration Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                  APHORA APP STRUCTURE                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌────────────────────────────────────────────────────┐    │
│  │ assessment_page.dart                              │    │
│  │ ├─► Easy Level Card                               │    │
│  │ │   └─► Navigator.push → VisualQuestionPage      │    │
│  │ │       questions: allQuestions                   │    │
│  │ │                                                 │    │
│  │ └─► Medium Level Card                             │    │
│  │     └─► Navigator.push → MediumLevelPage         │    │
│  │         questions: allQuestions                   │    │
│  │                                                   │    │
│  └─────────┬──────────────────┬──────────────────────┘    │
│            │                  │                           │
│     Uses allQuestions    Uses allQuestions                │
│            │                  │                           │
│            ▼                  ▼                           │
│  ┌──────────────────┐  ┌───────────────────┐             │
│  │visual_question_  │  │ medium_level_     │             │
│  │page.dart         │  │ page.dart         │             │
│  │ (Easy Level)     │  │ (Medium Level)    │             │
│  │                  │  │                   │             │
│  │ • Image + Text   │  │ • Image only      │             │
│  │ • Tamil shown    │  │ • No text         │             │
│  │ • Audio btn      │  │ • Challenge mode  │             │
│  │ • Verification   │  │ • Verification    │             │
│  │ • Points logic   │  │ • Points logic    │             │
│  └──────────────────┘  └───────────────────┘             │
│            │                  │                           │
│            └──────────┬───────┘                           │
│                       │                                   │
│            Both use from question_data                   │
│                       │                                   │
│                       ▼                                   │
│  ┌─────────────────────────────────────┐                 │
│  │ question_data.dart                  │                 │
│  │ • allQuestions list (50 items)      │                 │
│  │ • QuestionData class                │                 │
│  │ • getQuestionsByCategory()          │                 │
│  │ • getAllCategories()                │                 │
│  └─────────────────────────────────────┘                 │
│                       │                                   │
│    Each question has: │                                   │
│    ├─► id             │                                   │
│    ├─► englishPhrase  │                                   │
│    ├─► tamilPhrase    │                                   │
│    ├─► imagePath      │                                   │
│    ├─► category       │                                   │
│    └─► difficulty     │                                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Summary

This system architecture ensures:
✅ Clean separation of concerns
✅ Reusable question data
✅ Consistent verification logic
✅ Fair point system
✅ Clear user feedback
✅ Smooth navigation
✅ Proper state management

