# Kaizen

SwiftUI daily planning and a single-day calendar with Firebase Authentication and Firestore. Open `Kaizen.xcodeproj` in Xcode, resolve its Swift packages, and run the Kaizen scheme on iOS 18.5 or later.

## Daily planning

- Health, Work and Personal each have A/B/C priority tabs, with three tasks per tier (27 spaces per day).
- The home screen is a chronological agenda. Tap a day in the scrollable strip, or use More → Go to date to jump anywhere. Morning, Afternoon and Night group events by start time; all-day events have their own section. Overnight events appear on each day they overlap.
- Tap + to create a dated event with a category, start/end, optional all-day setting and notes. Tap an event to edit or delete it. These events live independently of daily priorities.
- Switch to Priorities to manage Health/Work/Personal and A/B/C tiers for the selected date. Completing a task stays attached to that day.
- Use the capture icon in the bottom bar to add a backburner task. The backburner also exposes unfinished tasks from previous days, including legacy tasks.
- End of Day opens a saved reflection for today, with mood, wins, improvements and focus. Feedback is generated locally from those answers and completion counts; no AI service is used.
- Account deletion is available from the account menu. It reauthenticates with the current email/password, removes the user’s tasks, events, reviews, and user document, then deletes the Firebase Auth account.
- A Privacy Policy screen is available from the welcome screen. Before release, publish the same policy at a stable public HTTPS URL and enter that URL in App Store Connect.
- Planning has three steps: review today’s agenda and reflection, select tomorrow’s priorities, then schedule the day. Existing appointments are visible in the final step. Give tasks start/end times, leave them untimed, and add or edit calendar events. Overlaps are allowed, with conflicts shown when scheduling a task. Empty spaces are allowed. Saving commits the reflection, tasks and changed events in a single batch. Selected backburner tasks move into tomorrow; selected daily tasks are copied so today's history stays intact. Closing without saving leaves storage unchanged.

## Firebase

The existing `GoogleService-Info.plist` supplies the Firebase project configuration. Enable Email/Password authentication and Firestore in that project.

Storage paths:

- `users/{uid}/tasks/{taskId}`: original task fields plus optional `category`, `scheduledDay` (`yyyy-MM-dd` local calendar date), `isBackburner`, `sourceTaskID`, and optional `scheduledStart` / `scheduledEnd` timestamps.
- `users/{uid}/events/{eventId}`: title, category, start/end timestamps, all-day flag and notes. All-day end dates are exclusive in storage, inclusive in the editor.
- `users/{uid}/reviews/{yyyy-MM-dd}`: mood, wins, improvement, focus, and completion totals.

Existing tasks remain readable without migration: absent categories appear under Personal and absent scheduled dates use the creation day. Earlier unfinished tasks are accessible in Backburner.

Before submission, complete App Store Connect’s App Privacy questionnaire based on the Firebase Authentication and Firestore data flows, and provide a support contact for privacy requests.

`firestore.rules` provides owner-only access for all three collections. Review it against any existing project rules before publishing through Firebase. Rules have **not** been deployed by this change. The app must have owner-only access to the events collection to load the agenda and to the reviews collection for End of Day. Existing deployed rules may need these new paths added.

Task limits are enforced in this client. Simultaneous edits from multiple devices are not transactionally reconciled, so a backend enforcement strategy is needed if strict cross-device limits are required. Writes wait for Firebase acknowledgement and show errors while retaining entered data.

## Verification

Unit tests cover legacy Firestore decoding, task field round trips, calendar date boundaries (including daylight saving), reflection feedback, chronological agenda merging, period boundaries, overnight events, and successful/failed plan saves. UI tests cover event creation/date selection and the three-step planning flow. They use a DEBUG-only in-memory store (`--ui-testing-calendar`) and do not write to Firebase. Run the KaizenTests and KaizenUITests targets using Xcode.

With a test Firebase account, verify: create three tasks in a tier; switch categories; capture and complete a backburner task; plan tomorrow using a backburner and unfinished task; cancel a changed plan; save and relaunch; check today's tasks remain and tomorrow's plan persists; sign out and use a second account to confirm isolation. Test write failures using restricted test rules and check that sheets retain unsaved input.


This is an in-app Firebase calendar. Apple/Google Calendar sync, recurrence and notification reminders are not implemented. Event times use the device time zone; daily task keys retain their selected local date. The date strip covers a year in each direction and recentres when Go to date selects a date outside that window.
