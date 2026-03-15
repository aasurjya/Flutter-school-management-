# Flutter Build Fix

Incrementally fix Flutter build and analysis errors with minimal, safe changes.

## Step 1: Identify Errors

```bash
# Auto-fix safe issues first
dart fix --apply

# Run full analysis
flutter analyze 2>&1
```

## Step 2: Group Errors by Type

| Error Pattern | First Action |
|---|---|
| `Undefined name`, `isn't defined` | Missing import — add the import |
| `The method 'x' isn't defined` | Wrong type or missing package |
| `A value of type 'X' can't be assigned to 'Y'` | Type mismatch — check nullability |
| `The non-nullable variable must be assigned` | Add null check or `late` keyword |
| `Missing concrete implementation of` | Implement abstract method |
| `Undefined class` | Missing import or build_runner needed |
| `Part of directive` / `.freezed.dart not found` | Run build_runner |
| `ref.watch called outside build` | Change to `ref.read` |
| `mounted` warning | Add `if (!mounted) return;` after await |

## Step 3: Fix Systematically

Start with **missing imports** (they cascade into many other errors), then fix types.

```bash
# After each batch of fixes, re-analyze
flutter analyze
```

## Step 4: Freezed / Code Generation Errors

If you see errors about `.freezed.dart`, `.g.dart`, or `@riverpod` generated files:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
```

## Step 5: Nuclear Clean (Last Resort)

If errors persist after fixing:

```bash
flutter clean && flutter pub get && flutter analyze
```

With codegen:

```bash
flutter clean && flutter pub get && \
  flutter pub run build_runner build --delete-conflicting-outputs && \
  flutter analyze
```

## Success Criteria

`flutter analyze` returns **0 errors** before marking this complete.

Use `build-error-resolver` agent for complex error cascades.
