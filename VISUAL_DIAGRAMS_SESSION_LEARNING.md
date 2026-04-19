# 🎨 Visual Diagrams - Session Selection & Learning

## Complete User Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        USER FLOW                                │
└─────────────────────────────────────────────────────────────────┘

  User Signup
       │
       ▼
  ┌─────────────────────┐
  │ User Info Page      │
  │ (Phone, Password)   │
  └────────────┬────────┘
               │
               ▼
  ┌─────────────────────────────────┐
  │   Pre-Assessment Test           │
  │   • 10 Letters                  │
  │   • 10 Words                    │
  │   • 10 Sentences                │
  │   Total: 30 Questions           │
  └────────────┬────────────────────┘
               │
               ▼
  ┌─────────────────────────────────┐
  │  Score Calculation              │
  │  (Correct Answers / 30) × 30    │
  │  Result: 0.0 - 30.0             │
  └────────────┬────────────────────┘
               │
               ▼
  ┌─────────────────────────────────┐
  │ Session Selection Page          │
  │ Shows:                          │
  │ • Score: X/30                   │
  │ • Level: Beginner/Inter/Adv     │
  │ • Recommendation                │
  │ • 3 Session Cards               │
  └────────────┬────────────────────┘
               │
        ┌──────┴──────┬──────────┬──────────┐
        │             │          │          │
   [Letters]    [Words]    [Sentences]     │
        │             │          │          │
        ▼             ▼          ▼          │
   ┌──────────────────────────────────┐    │
   │   Learning Session Page          │    │
   │                                  │    │
   │   • Show Tamil Text              │    │
   │   • Show English Translation     │    │
   │   • [Hear] [Record] Buttons      │    │
   │   • Show Feedback (✅/❌)         │    │
   │   • [Next Item] Button           │    │
   │   • Progress: 1/10 to 10/10      │    │
   │                                  │    │
   │   Repeat 10 times...             │    │
   └──────────────┬───────────────────┘    │
                  │                        │
        ┌─────────┴────────────┐          │
        │                      │          │
        ▼                      ▼          │
   ┌─────────┐         ┌──────────────┐  │
   │ Restart │         │ Go to Home   │  │
   └────┬────┘         └──────┬───────┘  │
        │                     │          │
        │        ┌────────────┴─────┐    │
        └────────┤                  │    │
                 ▼                  ▼    │
          ┌──────────────┐         │    │
          │ Home Page    │         │    │
          │ Dashboard    │         │    │
          └──────────────┘         │    │
                                   │    │
                    [Close/Home]◄──┘    │
                           ▲           │
                           └───────────┘
```

---

## Score to Level Mapping

```
┌──────────────────────────────────────────────────────┐
│          SCORE → LEVEL → RECOMMENDATION              │
└──────────────────────────────────────────────────────┘

  0 ─────┬───── 10 ───────┬────── 20 ───────┬─────── 30
         │                │                 │
    BEGINNER          INTERMEDIATE        ADVANCED
         │                │                 │
         ▼                ▼                 ▼
   
  [📝 LETTERS]        [✍️ WORDS]      [📖 SENTENCES]
   
  Start with:        Start with:      Start with:
  • Tamil vowels     • Common words   • Full sentences
  • Sound practice   • Vocabulary     • Grammar usage
  • Building basics  • Word practice  • Advanced skills
```

---

## Score Distribution Example

```
    Score Distribution (100 Test Users)
    
    30 ┤
       │                                    ▄█▓░ Advanced
    25 ┤                                  ▄█████░
       │                          ▄▄▄▄▄▄██████░
    20 ┤ INTERMEDIATE ████░ ▄▄▄▄██░ Intermediate
       │          ▄████████████░
    15 ┤      ▄████████████░
       │   ▄████████░
    10 ┤ BEGINNER ████░
       │   ████
     5 ┤   ███
       │   ██
     0 ┼─────────────────────────
        Low    Average    High
```

---

## Session Selection Page Layout

```
┌─────────────────────────────────────────────────┐
│  ← Back     SELECT YOUR SESSION                 │
├─────────────────────────────────────────────────┤
│                                                 │
│  ╔═══════════════════════════════════════════╗ │
│  ║                                           ║ │
│  ║    Pre-Assessment Score                  ║ │
│  ║                                           ║ │
│  ║             18.5                          ║ │
│  ║              /30                          ║ │
│  ║                                           ║ │
│  ║      Your Level: Intermediate             ║ │
│  ║                                           ║ │
│  ╚═══════════════════════════════════════════╝ │
│                                                 │
│  Recommended Session                           │
│  ────────────────────                          │
│  Based on your score, we recommend Words.      │
│  You're ready to expand your vocabulary...     │
│                                                 │
│  Choose Your Session                           │
│  ────────────────────                          │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │ 📝  LETTERS            BEGINNER    →    │   │
│  │ Learn Tamil letters                     │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │ ✍️  WORDS ⭐RECOMMENDED  INTERMEDIATE  →│   │
│  │ Learn Tamil words                       │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │ 📖  SENTENCES            ADVANCED   →   │   │
│  │ Learn Tamil sentences                   │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │         [ Go to Home ]                  │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## Learning Session Page Layout

```
┌──────────────────────────────────────────────────────┐
│  ← Learn Letters                                     │
├──────────────────────────────────────────────────────┤
│                                                      │
│  Progress: ████████░░░░░░░░░░░░░░░░░░░░░░░░░░░  30%│
│  Item 3 of 10                                       │
│                                                      │
│  ┌────────────────────────────────────────────────┐ │
│  │                                                │ │
│  │                    இ                           │ │
│  │                                                │ │
│  │              (Large Tamil Letter)              │ │
│  │                                                │ │
│  └────────────────────────────────────────────────┘ │
│                                                      │
│              English Meaning: I                     │
│                                                      │
│  ┌────────────────┐         ┌────────────────────┐ │
│  │  🔊 HEAR       │         │ 🎤 RECORD          │ │
│  └────────────────┘         └────────────────────┘ │
│                                                      │
│  ┌────────────────────────────────────────────────┐ │
│  │  ✅ Correct!                                   │ │
│  │  You said: "ഇ"                                │ │
│  └────────────────────────────────────────────────┘ │
│                                                      │
│  ┌────────────────────────────────────────────────┐ │
│  │         [ Next Item →  ]                       │ │
│  └────────────────────────────────────────────────┘ │
│                                                      │
└──────────────────────────────────────────────────────┘
```

---

## Audio Interaction Flow

```
┌────────────────────────────────────────────┐
│         LEARNING SESSION                    │
│                                             │
│  Show: Tamil Text + English Translation    │
│         ▲        ▼                         │
│         │        │                         │
│  User Clicks [HEAR] Button                 │
│         │        ▼                         │
│  ┌──────────────────────────────┐         │
│  │ SpeechService.speakText()    │         │
│  │ • Language: ta-IN            │         │
│  │ • Volume: MAX (1.0)          │         │
│  │ • Rate: 0.5 (clear)          │         │
│  │ • Pitch: 1.0 (normal)        │         │
│  └──────────────────────────────┘         │
│         │        ▼                         │
│  SnackBar: "Playing audio..."              │
│         │        ▼                         │
│  ┌──────────────────────────────┐         │
│  │     AUDIO PLAYS              │         │
│  │  🔊🔊🔊🔊🔊🔊🔊🔊          │         │
│  └──────────────────────────────┘         │
│         │        ▼                         │
│  User Clicks [RECORD] Button               │
│         │        ▼                         │
│  ┌──────────────────────────────┐         │
│  │ SpeechService.startListening()         │
│  │ • Language: ta-IN            │         │
│  │ • Duration: 10 seconds       │         │
│  │ • Wait for final result      │         │
│  └──────────────────────────────┘         │
│         │        ▼                         │
│  SnackBar: "Listening... Speak now!"       │
│         │        ▼                         │
│  ┌──────────────────────────────┐         │
│  │     USER SPEAKS              │         │
│  │  🎤🎤🎤🎤🎤🎤🎤🎤          │         │
│  └──────────────────────────────┘         │
│         │        ▼                         │
│  ┌──────────────────────────────┐         │
│  │ Evaluate Answer              │         │
│  │ targetText == recognizedText │         │
│  └──────────────────────────────┘         │
│         │        ▼                         │
│   ┌─────┴──────────┬──────────────┐      │
│   │                │              │      │
│   ▼                ▼              ▼      │
│  ✅ Correct!    ❌ Try Again   🤔 Close │
│  Show green     Show red       Match?   │
│  border         border         feedback │
│                                          │
└────────────────────────────────────────────┘
```

---

## State Management in Learning Session

```
┌─────────────────────────────────────────────┐
│        LEARNING SESSION STATE               │
└─────────────────────────────────────────────┘

_currentItemIndex: 0-9
    ▼
_items: [Letter1, Letter2, ..., Letter10]
    ▼
_recognizedText: ""
    ▼
_isCorrect: false
    ▼
_showFeedback: false
    ▼
_isListening: false
    ▼
Session Flow:
  1. Load items
  2. Show item[0]
  3. User clicks Hear → Play audio
  4. User clicks Record → Start listening
  5. Evaluate → _isCorrect = true/false
  6. Show feedback (_showFeedback = true)
  7. User clicks Next → _currentItemIndex++
  8. Repeat 2-7 until _currentItemIndex == 10
  9. Show completion dialog
 10. Return to Home or Restart
```

---

## Route Navigation Graph

```
             ┌─────────────────┐
             │ Language Select │
             └────────┬────────┘
                      │
                      ▼
             ┌─────────────────┐
             │  Login/Signup   │
             └────────┬────────┘
                      │
                      ▼
             ┌─────────────────┐
             │ User Info Page  │
             └────────┬────────┘
                      │
                      ▼
        ┌─────────────────────────┐
        │ Pre-Assessment Test (30)│
        └────────┬────────────────┘
                 │
                 ▼
    ┌──────────────────────────────┐
    │ Session Selection Page       │
    │ (Routes based on score)      │
    └──────┬──────────────┬────────┘
           │              │
        [Letters]    [Words][Sentences]
           │              │
    ┌──────▼────┬─────────▼────┬──────────┐
    │            │              │          │
    ▼            ▼              ▼          ▼
 Letters     Words         Sentences    Home
 Session     Session       Session      Page
 (10 items)  (10 items)    (10 items)   │
    │           │              │        │
    └───────────┴──────────────┴────────┘
               All lead back to Home
```

---

## Score Calculation Example

```
PRE-ASSESSMENT RESULTS
═════════════════════════════════════

Correct Answers Breakdown:
  Letters:  7 out of 10  ✅✅✅✅✅✅✅
  Words:    6 out of 10  ✅✅✅✅✅✅
  Sentences: 5 out of 10 ✅✅✅✅✅

Total Correct: 18 out of 30

SCORE CALCULATION:
  (Correct / Total) × Max Score
  (18 / 30) × 30
  = 0.6 × 30
  = 18.0/30

LEVEL DETERMINATION:
  18.0 is in range: 10 ≤ score < 20
  ➜ INTERMEDIATE Level
  ➜ RECOMMEND: Words Session

RECOMMENDATION:
  "You're doing well! You've got the basics
   down. Let's expand your vocabulary with
   the Words session."
```

---

## Content Structure

```
TAMIL LEARNING CONTENT
══════════════════════════════════════

LETTERS (10 items - Beginner)
├─ அ (A)      - Basic vowel
├─ ஆ (AA)     - Extended vowel
├─ இ (I)      - Short vowel
├─ ஈ (II)     - Long vowel
├─ உ (U)      - Back vowel
├─ ஊ (UU)     - Extended back vowel
├─ எ (E)      - Front vowel
├─ ஏ (EE)     - Extended front vowel
├─ ஐ (AI)     - Diphthong
└─ ஒ (O)      - Back vowel

WORDS (10 items - Intermediate)
├─ மல்லி     (Jasmine)
├─ பூ        (Flower)
├─ மரம்      (Tree)
├─ பூனை     (Cat)
├─ நாய்      (Dog)
├─ வீடு      (House)
├─ கதை      (Story)
├─ பெயர்    (Name)
├─ நகை      (Jewelry)
└─ பால்      (Ball)

SENTENCES (10 items - Advanced)
├─ வணக்கம்    (Hello)
├─ நீ யாரு?   (Who are you?)
├─ என் பெயர் ராம். (My name is Ram)
├─ இது நல்ல நாள் (Good day)
├─ எப்படி இருக்கீ? (How are you?)
├─ நான் நன்றாக உள்ளேன் (I'm fine)
├─ இதை நான் விரும்புகிறேன் (I like this)
├─ நீ வருகிறாயா? (Will you come?)
├─ உன்னை நான் அறிவேன் (I know you)
└─ நன்றி (Thank you)
```

---

## Performance Timeline

```
USER JOURNEY TIMELINE
════════════════════════════════════

T+0:00    User completes signup
T+5:00    Pre-assessment test begins
T+15:00   Pre-assessment complete
          Score calculated: 18.0/30
T+15:05   Navigate to Session Selection
T+15:10   User selects "Words"
T+15:15   Learning session starts (Item 1)
T+20:00   Finish item 5 (50% complete)
T+30:00   Finish all 10 items
T+30:30   Session completion dialog
T+30:35   Return to Home
          Total time: ~30 minutes
```

---

**Last Updated**: April 19, 2026
**Version**: 1.0.0
**Status**: Production Ready ✅
