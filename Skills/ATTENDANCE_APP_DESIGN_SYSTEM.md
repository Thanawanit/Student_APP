# Attendance App — UX/UI Design System

**Document type:** Product Design System / UI Standards  
**Status:** Baseline for design and implementation  
**Platform:** Android  
**Frontend direction:** Flutter (current project direction; do not migrate frameworks as part of UI work)  
**Primary language:** Thai  
**Working product name:** Attendance App (temporary; do not invent a brand name)

---

## 0. Instructions for Antigravity

Treat this document as the source of truth for the app's visual language, interaction patterns, screen hierarchy, and UX behavior.

### Mandatory rules

1. **Design for the actual attendance workflow.** This is a daily school attendance app for teachers and parents. It is not a period-by-period classroom register, school LMS, student information system, or face-recognition camera interface.
2. **Android first.** Design for Android phones and Android interaction conventions. Do not create iOS-only patterns or a web dashboard layout squeezed into a phone screen.
3. **Use Flutter for the current project.** Keep UI components and design tokens reusable. Do not migrate to React Native or another framework during a design task.
4. **Teacher and Parent are separate user journeys.** The first screen lets the user choose a role. Each role then follows its own authentication and navigation flow.
5. **Do not invent product rules.** Where this document says `UNDECIDED`, do not implement or visually imply a final behavior. Use a neutral placeholder only when a screen needs to be designed.
6. **Do not invent data.** Use clearly marked sample data only in prototypes. Never present sample values as real attendance records.
7. **Keep the interface in Thai by default.** English may be used for internal code identifiers and small technical metadata where necessary, not as decorative UI copy.
8. **Do not redesign the face-recognition engine.** The camera and Python face-recognition process are separate from the Flutter app. The app displays attendance data received from the backend; it does not pretend to scan faces itself.
9. **Preserve data integrity in the UI.** A student with no scan record before 09:00 must be shown as pending / not yet confirmed, not immediately as absent.
10. **Avoid generic AI-dashboard patterns.** Do not make every section a card, add decorative charts, add unnecessary gradients, or fill empty space with meaningless labels.

### Required design behavior

- Before implementing a screen, inspect the existing project structure and reuse existing working components when appropriate.
- Build or update a shared theme and component system before styling individual pages.
- Keep spacing, typography, colors, corner radii, and interaction feedback consistent across Teacher and Parent sections.
- If existing code conflicts with this document, do not silently make a broad architectural change. Explain the conflict and make the smallest safe UI-level adjustment.
- Do not alter backend logic, attendance calculations, authentication rules, database schema, face-recognition code, or notification infrastructure when the assigned task is UX/UI only.

---

## 1. Product definition

### 1.1 What the app does

The app provides two user experiences:

- **Teacher:** choose an education level, grade, and classroom; review daily attendance; review historical attendance; and edit attendance status when authorized.
- **Parent:** enter the student's ID number and view that student's daily attendance status, weekly summary, and historical attendance.

### 1.2 What the app does not do in the current scope

- No period-by-period attendance.
- No timetable or class-period register.
- No student-facing account or student dashboard.
- No face scanning through the phone camera.
- No parent leave-request workflow until the school decides how leave should be submitted and approved.
- No assumption that an unrecognized face or missing scan automatically means absence before the daily cutoff.

### 1.3 Locked attendance rules

| Rule | Current specification |
|---|---|
| Entry camera | Fixed camera at the school entrance; automatic recognition is handled by the separate Python system. |
| First successful scan | The first successful scan of the day creates the student's daily entry record. |
| On time | Scan before 08:00 is shown as `มาเรียน`. |
| Late | Scan at or after 08:00 is shown as `มาสาย` (use this boundary consistently unless the school changes it). |
| Absence cutoff | At 09:00, a student with no successful scan and no recorded leave is changed to `ขาดเรียน`. |
| Before 09:00 | No scan is `ยังไม่พบการสแกน` / `รอยืนยัน`, not `ขาดเรียน`. |
| Leave | `ลา` is a supported attendance status, but the way leave is submitted is **UNDECIDED**. Do not add a parent leave-request flow. |
| Editing | Teacher and Admin can edit attendance status. Parents are read-only. |
| Weekly summary | Show counts of absent, leave, and late occurrences for the current school week. The exact school-week calendar should come from school configuration/backend. |
| History | Attendance history can be viewed by date, including previous days. |
| Notifications | Notify the parent whenever the student's attendance status changes, after the change has been saved successfully. |

**Important:** The entry-camera record is a daily attendance event. It is not evidence that the student attended every class or remained at school for the whole day.

---

## 2. Design direction

### 2.1 Design concept

**Modern Editorial × Premium Utility**

The app should feel calm, precise, trustworthy, and carefully crafted. It should combine the clarity of a well-designed productivity tool with the warmth and accessibility expected of a school service.

The visual identity should be premium through restraint and consistency—not through decorative effects.

### 2.2 Desired qualities

- Clear and immediately understandable.
- Calm, bright, and welcoming.
- Professional without feeling corporate or intimidating.
- Information-first, with strong hierarchy.
- Efficient for teachers who may check many students quickly.
- Reassuring for parents who mainly want to understand whether their child arrived at school.
- Consistent across different Android screen sizes and system font settings.

### 2.3 Reference principles

Use these as design principles, not as templates to copy:

- **Linear:** disciplined information hierarchy, restrained controls, and clear interaction states.
- **Apple Wallet:** high legibility, clear status presentation, and trust through simplicity.
- **Google Calendar / Material 3:** familiar Android navigation, accessible touch targets, and predictable interaction patterns.

Do not reproduce another product's exact screens, branding, icons, or proprietary visual identity.

### 2.4 Avoid

- Dark neon dashboards, cyberpunk styling, HUDs, glow, and heavy glassmorphism.
- Large gradient hero panels or gradients behind every metric.
- Excessive shadows, thick outlines, and nested cards.
- A card/bento layout for every screen.
- Tiny uppercase English labels used only as decoration.
- Decorative charts that do not answer a real question.
- Emoji as the primary status indicator.
- Large illustrations that push useful attendance information below the fold.
- Unnecessary slogans, credits, developer labels, or fake system telemetry.

---

## 3. Visual foundations

### 3.1 Color system

Use a light theme as the default and initial product theme. Keep the palette small and semantic.

| Token | Suggested value | Usage |
|---|---:|---|
| `background` | `#F7F7F4` | Main warm-white page background |
| `surface` | `#FFFFFF` | Main content surface, dialogs, sheets |
| `surface-subtle` | `#F0F1EE` | Quiet secondary sections and selected neutral areas |
| `text-primary` | `#202624` | Main headings and body text |
| `text-secondary` | `#69716D` | Supporting labels and metadata |
| `text-disabled` | `#9AA19D` | Disabled content only |
| `border-subtle` | `#E3E7E2` | Dividers, table separators, quiet outlines |
| `brand-primary` | `#31566D` | Primary actions, selected navigation, links |
| `brand-primary-pressed` | `#254456` | Pressed state for primary actions |
| `focus-ring` | `#5B83A0` | Keyboard/accessibility focus where applicable |

#### Attendance semantic colors

Color must always be paired with a text label and, where useful, a simple icon. Never communicate attendance status by color alone.

| Status | Foreground | Soft background | Label |
|---|---:|---:|---|
| Present / on time | `#287451` | `#EAF4EE` | `มาเรียน` |
| Late | `#98621F` | `#FFF3E2` | `มาสาย` |
| Absent | `#A94444` | `#FBECEC` | `ขาดเรียน` |
| Leave | `#59659A` | `#EEF0FA` | `ลา` |
| Pending / unconfirmed | `#68716F` | `#F0F2F1` | `รอยืนยัน` / `ยังไม่พบการสแกน` |
| Unknown / sync issue | `#606A78` | `#EEF1F5` | `ตรวจสอบข้อมูล` |

The suggested values are starting tokens. Check actual contrast in the running app and adjust when needed; do not change the semantic meaning of each color.

### 3.2 Typography

**Primary Thai typeface:** IBM Plex Sans Thai.  
**Fallback:** Noto Sans Thai, then the Android system sans-serif fallback.  
**Numeric data:** use a highly legible sans-serif with tabular numerals where available; keep numeric styling consistent throughout the app.

| Style | Suggested size | Weight | Usage |
|---|---:|---:|---|
| Display | 30–34 sp | 600 | One key page metric, only when genuinely important |
| Page title | 24–28 sp | 600 | Main screen title |
| Section title | 18–20 sp | 600 | Section heading |
| Body | 15–16 sp | 400 | Main content and student names |
| Body strong | 15–16 sp | 500–600 | Important labels and selected values |
| Supporting | 13–14 sp | 400 | Secondary details and timestamps |
| Micro label | 11–12 sp | 500 | Use sparingly; never for essential information |

Typography rules:

- Use Thai text naturally; do not force English uppercase headings into the interface.
- Avoid too many font weights on one screen.
- Do not use monospaced type for ordinary content. Use it only for technical identifiers when genuinely necessary.
- Support Android font scaling. Do not lock text into fixed-height containers that clip at larger font sizes.
- Keep student names and important status labels at comfortable reading sizes.

### 3.3 Spacing and layout

Use a 4 dp base unit and an 8 dp primary rhythm.

| Token | Value | Typical usage |
|---|---:|---|
| `space-1` | 4 dp | Icon-to-label micro gap |
| `space-2` | 8 dp | Compact internal spacing |
| `space-3` | 12 dp | Related controls |
| `space-4` | 16 dp | Standard component spacing |
| `space-5` | 20 dp | Screen side inset on compact phones |
| `space-6` | 24 dp | Section spacing and standard screen inset |
| `space-8` | 32 dp | Separation between major sections |
| `space-10` | 40 dp | Large editorial spacing |

Layout rules:

- Default screen horizontal inset: 20–24 dp, adjusted for device width.
- Prefer full-width content on phones; do not create narrow desktop-style columns.
- Group related information through spacing and dividers before adding another card.
- Use a maximum content width only when the app is also presented on larger Android devices/tablets.
- Avoid horizontal scrolling for essential attendance information.

### 3.4 Shape, borders, and elevation

| Token | Suggested value | Usage |
|---|---:|---|
| `radius-control` | 10–12 dp | Inputs, chips, small buttons |
| `radius-panel` | 14–16 dp | Grouped panels and sheets |
| `radius-large` | 20 dp | Role-selection surfaces or a major feature panel, sparingly |
| `border-width` | 1 dp | Standard quiet border |

- Prefer a 1 dp subtle border over a visible shadow.
- Use elevation only when it communicates layering (modal, menu, floating action).
- Do not place every list row inside a rounded rectangle.
- Avoid excessively pill-shaped buttons unless the control is a compact filter chip.

### 3.5 Iconography

- Use one consistent icon family (Material Symbols or another coherent outline family).
- Prefer simple outline icons with consistent stroke weight.
- Icons support labels; they do not replace important Thai text.
- Do not mix emoji, filled icons, and unrelated outline styles in the same navigation system.

---

## 4. Navigation and information architecture

### 4.1 Entry flow

```text
เปิดแอป
  └── เลือกประเภทผู้ใช้งาน
       ├── คุณครู
       │    └── เข้าสู่ระบบครู
       │         └── เลือกช่วงชั้น
       │              └── เลือกระดับชั้นและห้อง
       │                   └── ภาพรวมการเข้าเรียนของห้อง
       │                        ├── รายชื่อนักเรียน / สถานะวันนี้
       │                        ├── ประวัติย้อนหลัง
       │                        ├── รายละเอียดนักเรียน
       │                        └── แก้ไขสถานะ (ครู/Admin เท่านั้น)
       └── ผู้ปกครอง
            └── กรอกเลขประจำตัวนักเรียน
                 └── ข้อมูลการเข้าเรียนของนักเรียน
                      ├── สถานะวันนี้
                      ├── สรุปรายสัปดาห์
                      └── ประวัติย้อนหลัง
```

### 4.2 Role selection

The first screen must clearly offer two primary choices:

- `เข้าสู่ระบบคุณครู`
- `เข้าสู่ระบบผู้ปกครอง`

Each choice should have a short explanatory line. The two options should have equal visual importance; do not make one look like an advertisement or a secondary link.

### 4.3 Teacher navigation

Teacher flow:

1. Teacher login.
2. Select `มัธยมศึกษาตอนต้น` or `มัธยมศึกษาตอนปลาย`.
3. Select grade.
4. Select classroom.
5. Arrive at the class attendance overview.

All teachers can access all rooms under the current requirement. Do not display a misleading “assigned rooms only” restriction.

Class structure:

- Lower secondary: ม.1, ม.2, ม.3 — 6 rooms per grade (`1/1`–`1/6`, `2/1`–`2/6`, `3/1`–`3/6`).
- Upper secondary: ม.4, ม.5, ม.6 — 7 rooms per grade (`4/1`–`4/7`, `5/1`–`5/7`, `6/1`–`6/7`).

Show the current location in the hierarchy, for example: `มัธยมศึกษาตอนปลาย / ม.5 / ห้อง 5/2`.

### 4.4 Parent navigation

Parent flow:

1. Choose `ผู้ปกครอง`.
2. Enter the student's ID number (current requested sign-in method).
3. View the attendance information for that student.

The parent experience is read-only in the current scope. Do not show teacher editing controls or class-management navigation.

**Privacy note:** The current product requirement specifies student ID entry only. This is not strong identity verification by itself. Keep the UI requirement as specified for the prototype, but flag this as a production security risk that requires school approval and a safer verification decision before real student data is exposed. Do not silently add a password, OTP, or other step without product approval.

### 4.5 Recommended navigation pattern

- Use a clear top app bar with a page title and a back action when moving through selection/detail flows.
- After entering the main role area, use a small, consistent set of destinations such as `ภาพรวม`, `ประวัติ`, and `บัญชี` where appropriate.
- Add a notification destination only if it is an actual implemented screen; otherwise use a notification affordance with a clear destination.
- Do not use more than 5 primary bottom-navigation destinations.
- Preserve navigation state when a teacher opens a student record and returns to the class list.

---

## 5. Screen specifications

### 5.1 Screen A — Role selection

**Goal:** Make it immediately obvious whether the user should enter as a teacher or parent.

Required elements:

- Product title or school-approved name (working title only until a name is approved).
- Short supporting text explaining that the app is for daily attendance.
- Two large role actions: teacher and parent.
- Quiet school identity area only if official school branding assets are provided.

UX rules:

- Do not show a complex dashboard before login.
- Do not use a carousel or marketing hero section.
- Make both role choices accessible and easy to tap.

### 5.2 Screen B — Teacher login

**Goal:** Allow teachers to sign in using an account created by the Admin.

Required elements:

- Clear title `เข้าสู่ระบบคุณครู`.
- Credential fields matching the authentication method implemented by the backend.
- Primary action `เข้าสู่ระบบ`.
- Clear validation and authentication error messages.

**UNDECIDED:** The exact teacher login identifier (email, username, or another school-issued credential) has not been specified. Do not hard-code a final label or authentication assumption before checking the existing backend requirements.

### 5.3 Screen C — Parent entry

**Goal:** Find the student's attendance record using the student's ID number.

Required elements:

- Title `เข้าสู่ระบบผู้ปกครอง`.
- One clearly labelled student ID field.
- Numeric keyboard where appropriate.
- Primary action to continue.
- Clear invalid-ID and unavailable-record states.

Do not imply that the parent can edit attendance or submit leave in the current scope.

### 5.4 Screen D — Teacher class selection

**Goal:** Let teachers reach any classroom with minimal navigation effort.

Required elements:

- Two stage choices: `มัธยมศึกษาตอนต้น` and `มัธยมศึกษาตอนปลาย`.
- Grade selection after stage selection.
- Classroom selection after grade selection.
- Breadcrumb or clear back navigation.

Design approach:

- Use editorial list rows, compact grid options, or grouped selection surfaces.
- Do not show all 39 classrooms as one dense grid on a single screen.
- Selected state must be obvious without relying on color alone.

### 5.5 Screen E — Teacher class overview

**Goal:** Let a teacher understand the current attendance situation quickly and find a student who needs attention.

Information priority:

1. Class identity: grade and room.
2. Attendance date and latest data-sync time.
3. Summary counts: `มาเรียน`, `มาสาย`, `ขาดเรียน`, `ลา`.
4. Pending / not-yet-confirmed count when before 09:00 or when data is incomplete.
5. Searchable student list with each student's current daily status.

Suggested structure:

- A compact class heading and date.
- A small summary row or restrained metric strip; do not make every metric a large card.
- A status filter row.
- Search field when the list is long.
- Student rows separated by quiet dividers.

Student row should show:

- Student name.
- Student ID only when useful for distinguishing students.
- One status label with its semantic color and optional icon.
- First scan time when available.
- A clear indication when the record has not yet been confirmed.

Do not show face images, face embeddings, recognition confidence, or raw biometric information in ordinary teacher or parent screens.

### 5.6 Screen F — Attendance history

**Goal:** Review attendance on previous dates without confusing daily status with live status.

Required capabilities:

- Select a date or date range using a familiar Android date picker/calendar.
- Filter by status.
- Search for a student in teacher mode.
- Show the selected date clearly.
- Distinguish saved attendance history from today's pending/live updates.

Avoid a dense calendar heatmap unless it adds real value and remains legible on a phone.

### 5.7 Screen G — Student attendance detail

**Goal:** Show a single student's attendance history clearly.

Required elements:

- Student name and relevant class information.
- Current selected date and daily status.
- First scan time when available.
- Historical list grouped by date or week.
- Weekly counts for late, absent, and leave occurrences.

For Parent mode, all information is read-only. For Teacher/Admin mode, show edit controls only where authorized.

### 5.8 Screen H — Edit attendance status

**Goal:** Allow authorized staff to correct an attendance record without hiding the change history.

Allowed actors: Teacher and Admin.  
Not allowed: Parent.

Required UX:

- Clearly display the student and date being edited.
- Display the existing status before the user changes it.
- Offer only the supported statuses: `มาเรียน`, `มาสาย`, `ขาดเรียน`, `ลา`.
- Ask for confirmation before saving a consequential change.
- Show clear success or failure feedback.
- Preserve an audit record: previous status, new status, editor identity, and timestamp.

A reason/note field may be included only if the product/backend team agrees on its requirement. Do not make it a required field without confirmation.

### 5.9 Screen I — Parent overview

**Goal:** Let a parent answer “Did my child arrive at school?” quickly.

Information priority:

1. Student identity and class.
2. Today's attendance status.
3. First scan time when available.
4. Weekly summary: late, absent, leave.
5. Recent attendance history.

Use calm, plain Thai. Avoid technical face-recognition terminology. Do not expose other students' names, class-level totals, teacher controls, or internal system diagnostics.

### 5.10 Notifications

The app should present notification events in clear, plain language, for example:

- `บันทึกสถานะการมาเรียนของนักเรียนแล้ว`
- `มีการเปลี่ยนแปลงสถานะการเข้าเรียน`

Where appropriate, include the date and the new status. Avoid putting excessive student information in lock-screen notification previews.

Notification UX rules:

- Trigger only after the backend confirms that the status change was saved.
- Do not send duplicate notifications for the same saved event.
- A notification should deep-link to the relevant student's date or attendance detail when the user is authorized.
- A notification is not proof that a message was delivered to or read by the parent; show delivery/read state only if the infrastructure actually supports it.

### 5.11 Admin screens

Admin is known to create teacher accounts and can edit attendance. The exact Admin interface and whether it is part of this Android app are **UNDECIDED**.

Do not invent a full Admin console. If an Admin role is present in the current project, apply the same visual system and make administrative actions visually distinct and confirmation-based.

---

## 6. Attendance status and data-state UX

### 6.1 Status definitions

| Status | Meaning in the app | Display guidance |
|---|---|---|
| `มาเรียน` | Successful first scan before 08:00 | Show status and first scan time |
| `มาสาย` | Successful first scan at or after 08:00 | Show status and first scan time |
| `ขาดเรียน` | No scan and no leave recorded after the 09:00 cutoff | Show as absent only after the cutoff is applied |
| `ลา` | Leave has been recorded by an authorized process | Display status; submission/approval workflow remains undecided |
| `รอยืนยัน` | Before 09:00, no successful scan has been received yet | Explicitly say that the record is not final |
| `ตรวจสอบข้อมูล` | Data is unavailable, delayed, or inconsistent | Do not convert this state into an absence |

### 6.2 Essential distinction

`ยังไม่พบการสแกน` is not the same as `ขาดเรียน`.

Before 09:00, show pending/unconfirmed when the student has no scan. At/after the 09:00 cutoff, show absence only when the backend has confirmed there is still no scan and no leave record.

If data synchronization is delayed or unavailable, show a data freshness warning instead of asserting absence.

### 6.3 Time and date

- Display school-local time in `Asia/Bangkok`.
- Use Thai-friendly date formatting consistently.
- Show the first scan time in 24-hour format (for example `07:42 น.`).
- Show the selected attendance date near the top of history screens.
- Do not calculate or infer school days from the device alone; use the school calendar/backend rules.

### 6.4 Counts and percentages

- Always show the denominator when showing a count, for example `34 จาก 40 คน`.
- Make clear whether counts are current, final, or pending.
- Do not include pending students in the absent count.
- Do not show a percentage without the count it represents.
- A weekly summary should use the same school-week definition as the backend.

---

## 7. Component standards

### 7.1 Buttons

- Primary: one clear primary action per screen where possible.
- Secondary: lower emphasis, used for alternate actions.
- Destructive: reserved for consequential actions; require confirmation.
- Disabled: clearly disabled but still legible.
- Minimum touch target: 48 × 48 dp.

Button labels should describe the action: `เข้าสู่ระบบ`, `ดูประวัติ`, `บันทึกการแก้ไข` rather than vague labels such as `ตกลง` when the outcome is not obvious.

### 7.2 Inputs

- Always have a visible label; placeholders are not labels.
- Show validation close to the relevant field.
- Preserve entered values after recoverable errors.
- Use the appropriate keyboard (numeric for student ID where applicable).
- Do not show an error before the user has had a reasonable chance to complete the field.

### 7.3 Status chips

- Use a compact chip for a status in a student row or summary.
- Include text, not color alone.
- Keep chip dimensions consistent across all statuses.
- Do not use status chips as decorative badges.

### 7.4 Lists and tables

- Student lists should prioritize name and status.
- Use dividers and whitespace instead of enclosing every row in a card.
- Keep row height comfortable for touch interaction.
- Avoid dense spreadsheet-like layouts on phone screens.
- If a row opens details, make the affordance clear and consistent.

### 7.5 Filters

- Use compact chips or a clear segmented control for a small set of status filters.
- Display the active filter state clearly.
- Provide an obvious way to return to `ทั้งหมด`.
- Do not hide essential filters inside a complex multi-level menu.

### 7.6 Dialogs and bottom sheets

Use a dialog for a short confirmation or a high-consequence action. Use a bottom sheet for a small contextual choice when it is easier to reach on a phone.

Do not use a modal for ordinary navigation or every minor interaction.

### 7.7 Charts and data visualization

- Use a chart only when it communicates a trend or comparison that a list/count cannot communicate as clearly.
- Keep charts simple and labelled in Thai.
- Do not use multiple overlapping lines for a basic attendance summary.
- Do not use a donut chart merely to decorate the dashboard.
- Always provide the underlying count or text equivalent for accessibility.

---

## 8. Motion and interaction

Motion should explain what changed, where content came from, or what action succeeded.

Suggested motion guidance:

- Small state transitions: approximately 120–180 ms.
- Screen or sheet transitions: approximately 180–240 ms.
- Use gentle easing; avoid spring/bounce effects for routine attendance data.
- Animate a status change subtly, then settle quickly.
- Use skeleton loading only when the layout is predictable and the wait is meaningful.
- Respect Android system settings for reduced motion where available.

Do not animate every number continuously. Do not use particle effects, glowing transitions, or decorative motion that distracts teachers during attendance review.

---

## 9. Responsive design and accessibility

- Android phone is the primary target; also avoid breaking on larger Android screens.
- Support portrait orientation as the default.
- Prevent horizontal overflow at common phone widths.
- Support Android system font scaling and display scaling.
- Maintain readable contrast; target at least 4.5:1 for normal text where applicable.
- Maintain touch targets of at least 48 × 48 dp.
- Provide meaningful semantic labels for screen readers.
- Do not rely on color alone to communicate status.
- Keep focus order logical for external keyboards/accessibility navigation.
- Ensure dialogs, error messages, and status updates are announced accessibly.
- Do not truncate student names or critical status labels where avoidable.

---

## 10. Loading, empty, offline, and error states

Every data-driven screen must have intentional states for:

### Loading

- Use a restrained skeleton or progress indicator.
- Keep the screen context visible where possible.
- Do not show fake zero counts while data is loading.

### Empty

Use plain, useful explanations, for example:

- `ยังไม่มีข้อมูลการเข้าเรียนในวันที่เลือก`
- `ไม่พบนักเรียนในห้องนี้`

### Pending

Before 09:00, clearly explain that an unscanned student is awaiting confirmation. Do not use alarming red styling for this state.

### Offline / sync delay

- Show when the displayed data was last synchronized if that information is available.
- Clearly mark stale data.
- Do not claim that an edit succeeded until the backend confirms it.
- If editing cannot safely proceed offline, disable the action and explain why.

### Error

- Use human-readable Thai.
- Explain what the user can do next (retry, check connection, or contact Admin).
- Do not expose stack traces, API payloads, database errors, or internal implementation details.

---

## 11. Privacy and trust in the interface

Attendance records and face-recognition data concern students. The UI must minimize unnecessary exposure.

- Never display raw face embeddings, biometric templates, or recognition internals.
- Do not show student information from another class to parents.
- Parent mode must be read-only in the current scope.
- Avoid placing full student ID numbers in notification previews or public-facing surfaces.
- Mask or minimize student identifiers where the full value is not needed.
- For any attendance edit, identify the authorized editor in the audit history when that data is available.
- Do not claim a face match is certain or perfect.
- The student-ID-only parent entry flow is a known production security concern; do not present it as strong identity verification.

---

## 12. Content and Thai microcopy

Use concise, respectful, everyday Thai. Prefer wording that parents and teachers understand immediately.

| Context | Preferred copy |
|---|---|
| Role choice | `คุณครู` / `ผู้ปกครอง` |
| Teacher entry | `เข้าสู่ระบบคุณครู` |
| Parent entry | `เข้าสู่ระบบผู้ปกครอง` |
| School stage | `มัธยมศึกษาตอนต้น` / `มัธยมศึกษาตอนปลาย` |
| Class overview | `ภาพรวมการเข้าเรียน` |
| Present | `มาเรียน` |
| Late | `มาสาย` |
| Absent | `ขาดเรียน` |
| Leave | `ลา` |
| Before cutoff, no scan | `ยังไม่พบการสแกน` / `รอยืนยัน` |
| History | `ประวัติการเข้าเรียน` |
| Weekly summary | `สรุปสัปดาห์นี้` |
| Edit status | `แก้ไขสถานะ` |
| Save edit | `บันทึกการแก้ไข` |
| No history | `ยังไม่มีประวัติในวันที่เลือก` |

Avoid jargon such as `Face Encoding`, `Embedding`, `Pipeline`, `Webhook`, `Sync Worker`, or `Recognition Confidence` in normal user-facing screens.

---

## 13. Definition of done for UI work

A screen is not complete just because it looks attractive in a screenshot. Before marking a screen complete, verify:

### Visual consistency

- [ ] Uses the shared color, type, spacing, shape, and icon tokens.
- [ ] Matches the Modern Editorial × Premium Utility direction.
- [ ] Does not overuse cards, shadows, gradients, or decorative English labels.
- [ ] Has consistent alignment and readable Thai typography.

### Functional UX

- [ ] Primary action is obvious.
- [ ] Navigation and back behavior are predictable.
- [ ] Loading, empty, error, and relevant pending states exist.
- [ ] Status is represented with both text and color.
- [ ] No unsupported feature is implied by the UI.

### Data integrity

- [ ] Pending students are not counted as absent before 09:00.
- [ ] No scan is not treated as an absence when the data feed is stale or unavailable.
- [ ] Counts show their denominator where relevant.
- [ ] Parent mode cannot edit attendance.
- [ ] Teacher/Admin editing controls are clearly separated from read-only views.
- [ ] A successful edit is not displayed before backend confirmation.

### Accessibility and Android

- [ ] Touch targets are at least 48 × 48 dp.
- [ ] Text scales without clipping.
- [ ] Contrast is sufficient.
- [ ] Screen reader labels are meaningful.
- [ ] Layout works on common Android phone widths.

---

## 14. Unresolved product decisions — do not invent

The following decisions are not part of this Design System and must remain open until the product owner or school confirms them:

1. **Teacher credential format:** email, username, or school-issued identifier.
2. **Parent leave workflow:** who can submit leave, who approves it, and whether the parent app will support requests.
3. **Admin interface:** whether Admin functions live inside the Android app or a separate management interface.
4. **School calendar:** holidays, weekends, special school days, and the exact definition of “this week”.
5. **After-09:00 late scan handling:** whether a student who scans after the absence cutoff is automatically changed from absent to late, or requires teacher review. Do not silently choose this rule.
6. **Data sync wording and freshness threshold:** use actual backend sync metadata; do not invent a “last updated” time.
7. **Official school branding:** school name, logo, and approved brand colors.

---

## 15. Final direction

Build a calm, high-end, Thai-first Android attendance app that makes the student's daily attendance status immediately understandable.

The Teacher experience should optimize for scanning a class list, identifying exceptions, and reviewing history. The Parent experience should optimize for reassurance, clarity, and a simple view of one student's attendance.

The design should feel intentionally crafted, but never at the expense of speed, accessibility, privacy, or accurate attendance information.

**This document governs UX/UI design. It does not authorize changes to backend behavior, authentication policy, database structure, face-recognition processing, or school attendance rules.**
