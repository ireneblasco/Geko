# Feedback Feature

In-app feedback prompt that triggers after the user completes 3+ different habits in a day.

**Note:** Currently hidden from Release builds (`#if DEBUG`). Only active in Debug configuration. If the user enjoys the app, they are prompted to leave an App Store review. If not, they can submit feedback via a textbox, which is sent to a Notion database.

## Trigger Condition

- **When:** User completes more than 3 different habits in a single day
- **Where:** Completion can be from the main habit row (today), week summary (today's dot), or month summary (today's dot)
- **Once:** The prompt is shown at most once per user (persisted via `UserDefaults`)

## Flow

1. User completes 4th habit of the day
2. Sheet appears: "Are you enjoying Geko?" with Yes / No buttons
3. **If Yes:** "Thanks! Would you leave a review?" — button triggers `StoreKit.requestReview()` and dismisses
4. **If No:** TextField for feedback, Submit button — on submit, feedback is sent to Notion and sheet dismisses

## Notion Integration

Feedback is submitted to a Notion database via the Notion API.

### Database Schema

The database must have two columns:

| Column | Type | Description |
|--------|------|-------------|
| ID | Rich text | Unique identifier (UUID) for each feedback entry |
| Feedback | Rich text | The user's feedback text |

### Notion Setup

1. Create a database in Notion with the columns above
2. Create an integration at [Notion Integrations](https://www.notion.so/my-integrations)
3. Share the database with your integration (open the database → "..." → "Add connections" → select your integration)
4. Copy the integration token and database ID

### Database ID

The database ID is the 32-character UUID from the URL when viewing the database:

- Full URL: `https://notion.so/workspace/DATABASE_ID?v=...`
- Or: Open the database as a full page, the ID is in the URL

### Secrets Configuration

Copy `Geko/Secrets.example.plist` to `Geko/Secrets.plist` and fill in:

- `NOTION_INTEGRATION_TOKEN` — your integration's secret token
- `NOTION_DATABASE_ID` — the database ID (32-char UUID)

`Secrets.plist` is gitignored and must not be committed.

## Testing

### Unit Tests (GekoTests)

- `FeedbackManager_doesNotTrigger_beforeFourthHabit` — After 3 completions, sheet not shown
- `FeedbackManager_triggers_afterFourthHabit` — After 4th habit completed today, sheet shown
- `FeedbackManager_doesNotTrigger_ifAlreadyAsked` — After `markSheetPresented()`, no trigger
- `FeedbackManager_doesNotTrigger_forPastDate` — Completions for yesterday don't count
- `FeedbackSheetView` — ViewInspector tests for initial question, Yes/No buttons, text field
- `NotionFeedbackService` — Mock URLSession, verify POST payload structure

### E2E Tests (GekoUITests)

- `testFeedbackSheetAppearsAfterFourCompletions` — Create 4 habits, complete each, verify sheet appears
- Use launch argument `--resetFeedbackState` to clear the "already asked" flag for deterministic tests

## Implementation Files

| File | Purpose |
|------|---------|
| `Geko/FeedbackManager.swift` | Trigger logic, count habits completed today |
| `Geko/FeedbackSheetView.swift` | Sheet UI: enjoy prompt, review CTA, feedback form |
| `Geko/NotionFeedbackService.swift` | POST to Notion API |
| `Geko/Secrets.example.plist` | Template for secrets (copy to Secrets.plist) |
