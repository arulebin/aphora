# Oral-cancer speech rehab pack — integration contract

Content + scoring for `Condition.oralCancerRehab` (adults after surgery for mouth /
tongue cancer). No UI here; the catalog / session pages consume it as below.

| File | What |
|---|---|
| `oral_item.dart` | `OralItem`, `OralItemKind`, `OralSoundGroup`, `SoundPosition`, `OralLang`, `OralSituation` |
| `oral_content.dart` | the data (`oralItems`, 489 items) — ids are stable, never rename |
| `oral_rehab_pack.dart` | `OralRehabPack` (selection, titles, hints, safety line) + `OralSurgery`; re-exports `oral_item.dart` |
| `../../../logic/baseline_scoring.dart` | `BaselineScoring`, `OralAttempt`, `BaselineConfig`, `ProgressBand` … |

## 1. Kinds → PracticeKind

| OralItemKind | PracticeKind | Content |
|---|---|---|
| `syllables` | `letters` | L1 sound+vowel (தா, "tea"), L2 vowel ladder (தா தி து), L3 alternating places (பா தா கா) |
| `words` | `words` | target sound at word start / middle; L1 short → L3 long / two-word |
| `minimalPairs` | `drill` | L1–2 two words (`item.pair`), L3 clarifying sentence ("I said cat, not pat") |
| `phrases` | `sentences` | needs, health, safety, family, personal templates, shop, bus, phone |
| `clearSpeech` | `phonetic` | phrase said one word at a time (`item.pacing == true`) |
| `intelligibility` | `assessment` | fixed 20-item monthly re-test |
| — | `naming` | not used (word-finding is not the problem) → `itemsFor` returns `[]` |

`OralRehabPack.kinds` is the list to show, in order. If the catalog adds new
`PracticeKind` values, `oralKindFor` (an exhaustive switch) must get a case.

## 2. Getting items

```dart
// Engine-ready items (PracticeItem). Hint (semanticCue) already resolved.
OralRehabPack.itemsFor(PracticeKind.words, level, LanguageService.currentLanguage,
    personal: personalDetails);
// Raw items (to read pacing / pair / group / chunks).
OralRehabPack.oralItemsFor(OralItemKind.clearSpeech, level, language);
// One ~10-minute mixed session (~28 items), deterministic per day.
OralRehabPack.dailySession(level: level, language: language, day: daysSinceStart,
    surgery: OralSurgery.fromId(intake.answers['o_surgery']), personal: personalDetails);
OralRehabPack.toPracticeItems(session, language, personal: personalDetails);
```

* `level` = `IntakeResult.startLevel` (1–3; the intake already caps “most / all tongue” at 2).
* Titles / descriptions: `OralRehabPack.title(kind)` / `.description(kind)` → `(en:, ta:)`;
  use `.inLanguage(language)`. Sound-group names: `groupTitle(group)`.
* `PracticeItem.voiceKey` is `<id>_ta` / `<id>_en`, so Family Voice / therapist
  recordings work unchanged. Item ids are the Firestore `taskId`.
* Sound items are language-specific (`OralLang.ta` / `.en`): in Tamil mode the
  target is Tamil and `meaning` is the English gloss; in English mode `meaning` is a
  Tamil-script reading aid. Phrases are translation pairs (`OralLang.both`).

### Personal templates
Phrases with `{name}`, `{address}`, `{phone}`, `{son_phone}`, `{place}` are skipped until
the user fills them; pass `personal: {'name': …}` (store it on the user doc, e.g.
`users/{uid}.oralPersonal`). `item.placeholders` lists what a template needs.

## 3. Pacing cue (clear speech)
For `item.pacing == true`: show `OralRehabPack.pacingCue`, and reveal
`item.chunks(language, personal: …)` one word at a time (e.g. highlight each word
for ~1 s with a visible pause). TTS model: speak chunk by chunk with ~600 ms gaps.

## 4. Safety line (mandatory)
* Show `OralRehabPack.safetyLine` on the pack's first screen and before the first
  session; keep `OralRehabPack.restCue` visible in the session footer / pause sheet.
* If the intake red flags contain any of `OralRehabPack.holdFlags`
  (`ask_surgeon`, `oral_pain`, `radiotherapy_team`), show the safety line as a
  blocking notice with "My doctor / therapist has said yes" before practice opens.
* The pack contains no tongue-strength or range-of-motion drills; do not add any.

## 5. Scoring — self-baseline (not a healthy voice)
For each attempt build an `OralAttempt` (skip nulls — no score is never a zero):

```dart
OralAttempt.from(itemId: item.id, at: now,
    cer: evaluation?.characterErrorRate,          // server /evaluate
    serverScore: evaluation?.combinedAccuracy,    // used if no CER
    deviceScore: deviceSimilarity,                // on-device match 0–100
    transcript: evaluation?.userText ?? heard);
OralAttempt.fromRecord(attemptRecord, cer: …);    // from Firestore attempts
```

* Per item: `BaselineScoring.scoreItem(id, attempts, since: sessionStart)` → `ItemProgress`.
* Per session: `BaselineScoring.summarise(attempts, since: sessionStart)` → `ProgressSummary`.
* Show the patient **only** `band.message` / `band.detail` (`(en:, ta:)`):
  `settingStartingPoint` (first 3 attempts per item — show "Setting your starting
  point", no score, no stars), `clearer`, `aboutTheSame`, `harderToday`.
  Numbers (`baseline`, `current`, `change`, `medianChange`) are for the therapist view.
* Baselines are kept per `ScoreSource`; when the server becomes reachable the
  CER-based starting point is set afresh (never mixed with phone scores).
* Practice rewards (`practice_rewards.dart`) should reward attempts, not scores, for this pack.

## 6. Monthly intelligibility test
* Items: `OralRehabPack.intelligibilitySet(language)` — 20 per language (10 words
  across the sound groups + 10 phrases). Present **in order, unshuffled, without
  hints or models** (no pacing cue, no TTS first) — it measures, it doesn't teach.
* Score: `BaselineScoring.intelligibility(testAttempts, OralRehabPack.intelligibilityIds(language), targets: {id: [target, ...alternates]})`
  → `IntelligibilityResult` (`percent`, `understood`, `attempted`, `isComplete`, `missed`).
  Understood = CER ≤ 0.25 (server CER, else CER of the device transcript).
* Compare: `BaselineScoring.compareIntelligibility(firstCompleteTest, thisTest)` → band.
  Offer the test once every ~30 days; save each result (percent + date) so the first
  complete test stays the starting point.
