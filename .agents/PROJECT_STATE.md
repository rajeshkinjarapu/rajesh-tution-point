# Project State

## Recent Activity
- **Backend Performance Fix (2026-09-07)**: Fixed memory leak in `students.controller.ts`.
- **Marks Excel Template Update (2026-09-07)**: Modified `ExamListPage.tsx` in frontend.
- **Flutter Profile Bug Fix (2026-09-07)**: Fixed Prisma query syntax and error handling.
- **Marks Submit Frozen Bug Fix (2026-09-07)**: Fixed a bug in `MarksEntryPage.tsx` where clicking "Submit Marks" for an unfrozen class would silently send marks of OTHER frozen classes back to the server, causing the backend to block the update with "Access Denied".

### 🚀 Recent Accomplishments
1. **Study Certificate Generator**: Built `StudyCertificatePage.tsx` with print/PDF features.
2. **JEE Progress Card UI**: Fixed button wrapping and added borders.
3. **Global Settings (Logo/Signatures)**: Made the progress card logo, principal signature, and teacher signature globally saved in the database (so they load automatically for all future exams without needing re-upload).
4. **Duplicate Subject Fix**: Fixed the issue where "CHE" (Chemistry) subject was showing twice in the Class Rank List due to case sensitivity.
5. **Total and Percentage Calculation Fix**: Fixed a bug where duplicate subject marks (due to case sensitivity like Chemistry vs chemistry) were being double-counted in the Total Marks and Percentage in the backend calculations.
6. **Flutter Progress Card Web Sync**: Integrated the exact Web App Progress Card PDF directly into the Flutter mobile app using `url_launcher`, completely eliminating the need for a separate custom Flutter design.
7. **Flutter Students Directory UI**: Converted the Students Screen to use `CustomScrollView` and `SliverAppBar` with floating & pinned headers, providing a modern hide-on-scroll search bar experience.
8. **Flutter Teachers, Classes, Subjects UI**: Converted Teachers, Classes, and Subjects screens to use `CustomScrollView` and `SliverAppBar` with gradient headers and floating search bars (where applicable) to match the premium scroll behavior of the Students screen.
9. **WhatsApp Icon Fix**: Replaced the custom network image WhatsApp icon with the native `font_awesome_flutter` exact WhatsApp icon for the Teachers Directory screen.
10. **Push Notifications Fix**: Fixed the issue where hero banner notifications and sounds were missing. The backend (`firebase.ts`) was sending pushes to the outdated `jyschool_alerts_v1` channel while the app was listening on `jyschool_alerts_v2`. Corrected the channel ID and reset the sound to default.
11. **Universal App Welcome Screen**: Designed and implemented a modern `WelcomeScreen` as the new entry point for unauthenticated users in the Universal App. It includes smooth fade and slide animations, the school logo, an attractive illustration, and a primary "Get Started" button that navigates to the Login screen.
12. **Web App Quiz Module (AI Integration)**: Built a complete Backend and Frontend for Online Quizzes using Gemini AI. Added `OnlineExamsPage`, `CreateOnlineExamModal`, and `ManageExamQuestions` with features like AI prompt generation, file upload, copy/paste, and manual entry.

## Current Pending Task
- Implement Flutter App Quiz Module (Student Screens: Quizzes List, Take Quiz with Timer, Result Screen). Waiting for User's approval on the plan.

- **Exam Creation Subjects Sync (2026-09-09)**: Updated CreateExamPage to auto-fetch and populate real Master Subjects from the database for each class during Exam Creation, permanently solving the mismatch between Exam Config subjects and Marks Entry subjects.

- **Marks Entry Decimal Fix (2026-09-09)**: Fixed a bug in MarksEntryPage where typing decimal values like '19.5' was stripping the decimal and converting to '195'. Updated input handler to preserve raw string until submission.

- **Marks Entry AB Fix (2026-09-09)**: Addressed NaN issue when typing AB. Updated exams.controller.ts to properly map marksObtained to 'AB' instead of 0 when remarks is 'AB', ensuring it reflects correctly in Results and Progress Card.

- **Daily Automated Backup (2026-09-09)**: Set up rclone and a cron job on the VPS to automatically dump the jy_school_local database and upload it to Google Drive every day, keeping the last 7 days of backups.
