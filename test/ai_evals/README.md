# AI Evaluation Harness

Catches the failure mode where a prompt change passes unit tests but produces
nonsense / regressed output on real inputs.

## Structure

```
test/ai_evals/
├── README.md                   ← you are here
├── eval_runner.dart            ← test runner (loads fixtures, checks assertions)
├── fixtures/                   ← input + expected-output pairs
│   ├── principal_digest/
│   │   ├── case_001_normal_week.json
│   │   ├── case_002_attendance_drop.json
│   │   └── …
│   ├── risk_score/
│   │   └── case_001_balanced_student.json
│   └── parent_digest/
│       └── case_001_passing_student.json
└── eval_runner_test.dart       ← `flutter test`-runnable wrapper
```

A fixture is a JSON document with three sections:

```json
{
  "feature_type": "principal_digest",
  "input": {
    "tenant_id": "demo",
    "week_of": "2026-05-19",
    "metrics": { ... }
  },
  "assertions": [
    { "kind": "contains_phrase", "value": "attendance" },
    { "kind": "not_contains_phrase", "value": "sharply" },
    { "kind": "max_words", "value": 120 },
    { "kind": "mentions_number_within", "value": 92, "tolerance": 2 }
  ],
  "notes": "If attendance dropped only 1.5%, prompt must not say 'sharply'."
}
```

## Running

```bash
# All evals
flutter test test/ai_evals/

# One feature
flutter test test/ai_evals/eval_runner_test.dart --plain-name principal_digest
```

By default the runner is `gated` — it skips itself unless `AI_EVAL=1` is set
in the environment. This keeps CI fast on every PR and runs evals only when
prompts change or someone opts in:

```bash
AI_EVAL=1 flutter test test/ai_evals/
```

CI should run this in a nightly job, not on every PR.

## Authoring fixtures

Each fixture is a **failure mode** distilled to one example. Don't write
ten cases for "the happy path" — write ten cases for ten ways the prompt
can go wrong:

* Attendance fell 1.5% → prompt must NOT say "sharply".
* All students passed → prompt must NOT recommend interventions.
* Single-student class → prompt must NOT pluralize.
* Empty data set → prompt must NOT hallucinate numbers.
* Mixed-language student names → prompt must NOT romanize / mangle them.

Aim for 50 fixtures per high-value prompt before declaring it "evaluated".

## Assertion kinds

| `kind`                       | What it checks                                                |
|------------------------------|---------------------------------------------------------------|
| `contains_phrase`            | Output contains the literal phrase (case-insensitive).        |
| `not_contains_phrase`        | Output does NOT contain the phrase. The most useful kind.     |
| `max_words`                  | Output word count ≤ value.                                    |
| `min_words`                  | Output word count ≥ value.                                    |
| `mentions_number_within`     | The integer `value` appears in output, ±tolerance.            |
| `matches_regex`              | Output matches the given regex.                               |

Add new kinds by extending `_Assertion.fromJson` in `eval_runner.dart`.

## Backend

`eval_runner.dart` defaults to **deterministic-replay mode** — it does NOT
call the LLM. Each fixture's directory may contain `expected_output.txt`
which the runner uses verbatim. This makes the harness usable offline and
in CI without keys.

To run against the live gateway:

```bash
AI_EVAL=1 AI_EVAL_LIVE=1 flutter test test/ai_evals/
```

Live mode requires `AI_GATEWAY_URL` + auth and is intended for nightly
regression runs, not PR CI.
