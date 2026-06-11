# App Store Connect Submission Content

Prepared for OpenTeam iOS submission.

## Privacy Policy URL

```text
https://www.openteam.ai/policies/privacy
```

The live privacy policy currently covers Portal, Team workspaces, Gateway-backed agents, connected accounts, Google user data, and Microsoft user data.

## App Privacy Labels

Tracking:

```text
No
```

Data linked to the user:

```text
Contact Info
- Name
- Email Address

Identifiers
- User ID

User Content
- Emails or Text Messages
- Audio Data
- Other User Content

Usage Data
- Product Interaction

Diagnostics
- Other Diagnostic Data

Other Data
- Workspace, Team, connector, and connected business-system metadata
```

Purposes:

```text
App Functionality
Analytics
Product Personalization
```

Do not select:

```text
Third-Party Advertising
Developer's Advertising or Marketing
Tracking
```

Notes for internal review:

```text
The privacy policy says OpenTeam does not sell personal information or connected-account data, and does not use Google API data to serve ads, retarget users, build advertising profiles, sell advertising data, or train generalized AI/ML models.
```

## Age Rating

Recommended answers:

```text
Violence: None
Sexuality or Nudity: None
Mature or Suggestive Themes: None
Alcohol, Tobacco, or Drug Use or References: None
Medical or Treatment Information: None
Contests: None
Gambling or Simulated Gambling: None
Loot Boxes: No
Messaging and Chat: Yes
User-Generated Content: Yes
Unrestricted Web Access: No
Advertising: No
Age Assurance: No
Parental Controls: No
```

Rationale:

```text
OpenTeam is an authenticated business workspace with team chat, files, tasks, and connected-account workflows. It is not a general-purpose browser. The iOS app loads OpenTeam at openteam.ai and opens external links through the system/in-app browser rather than providing arbitrary web browsing as the app's core experience.
```

## Export Compliance

Use the following App Store Connect answers:

```text
Does your app use encryption? Yes, because it uses HTTPS/TLS through Apple's system networking/WebView components.
Does it use proprietary or non-standard encryption? No.
Does it use non-exempt encryption? No.
Does it require export compliance documentation? No, based on current app behavior.
```

The iOS app includes:

```text
ITSAppUsesNonExemptEncryption = false
```

## Pricing and Rights

```text
Price: Free
Base territory: United States
Content rights: Uses/accesses third-party content with user authorization.
IDFA: No
Copyright: 2026 OpenTeam.AI
```

## Review Information

Contact:

```text
First name: Aiden
Last name: Huang
Phone: +1 5197745881
Email: info@openteam.ai
```

Demo account required:

```text
Yes
```

Demo account:

```text
Username: [APP_REVIEW_EMAIL]
Password / login code: [APP_REVIEW_LOGIN_CODE]
```

## Review Login Plan

Recommended implementation before submission:

```text
Create a review-only login path for the configured App Review account that accepts the configured stable review code, and expires or is disabled after App Review.
```

Security constraints for the review-only code:

```text
- Only valid for the configured App Review email address.
- Only valid in production for the review window, or guarded by an explicit server-side App Review flag.
- Logs every use.
- Lands in a demo workspace only.
- No customer data.
- No payment required.
- Optional third-party connectors are not required for review.
```

Not recommended:

```text
Asking Apple reviewers to trigger an email OTP and wait for OpenTeam to forward the code. Reviewers do not have access to the review inbox, and human forwarding can delay or block review.
```

## App Review Notes

Use this version after the stable review code exists:

```text
OpenTeam is a business productivity workspace for authenticated teams. The iOS app provides mobile access to the OpenTeam workspace at openteam.ai, including team files, tasks, chat, and user-authorized workflow actions.

Review account:
Email: [APP_REVIEW_EMAIL]
Login code: [APP_REVIEW_LOGIN_CODE]

The review account opens a demo workspace containing sample data only. No payment is required for review. External account connectors such as Google or Microsoft are optional and are not required to evaluate the app's core workspace experience. If a connector screen is opened, reviewers may skip connection setup and return to the demo workspace.

The app is not a general-purpose browser. It loads the OpenTeam workspace and opens external links in the system/in-app browser.
```

## Promotional Text

```text
Run team work across files, chat, tasks, and connected business systems from one OpenTeam workspace.
```

## Description

```text
OpenTeam is a business workspace for teams that need people and AI to work together across files, conversations, tasks, and connected systems.

Use OpenTeam on iPhone to:
- Access your team workspace on the go
- Review files, tasks, and shared context
- Continue business workflows from mobile
- Coordinate with teammates through the OpenTeam workspace
- Work with connected systems authorized by your team

OpenTeam is built for company workspaces. A valid OpenTeam account is required.
```

## Keywords

```text
team workspace,AI workspace,productivity,tasks,files,business workflow,operations
```

## Subtitle

```text
AI workspace for teams
```

## Support URL

```text
https://www.openteam.ai/
```

## Marketing URL

```text
https://www.openteam.ai/
```

## App Store Screenshot Direction

Reference pattern from Manus:

```text
- Light neutral background.
- One large outcome-focused headline per screenshot.
- Real mobile UI or generated output centered in the frame.
- Icon-led prompt, connector, workspace, and workflow surfaces.
- Very little explanatory body copy; avoid paragraph-style captions.
- Each image sells one job-to-be-done rather than a generic feature list.
```

OpenTeam has matching mobile web surfaces that can support the same style:

```text
/                    Hero prompt surface: "What should we work on?"
/apps                Connected accounts and work request surface.
/#connect            Connector catalog: Gmail, Drive, Calendar, QuickBooks, etc.
/solutions           Professional workflow playbooks.
/solutions/email-operations
                     Email threads to drafts, tasks, summaries, and follow-up queues.
/solutions/calendar-scheduling
                     Meetings, agendas, follow-ups, and reminders from source context.
```

Draft screenshot set:

```text
1. What should we work on?
   Use the OpenTeam homepage prompt surface with icon chips.
   Keep the title, prompt input, plus button, arrow button, and work-category chips.
   Generated asset: store-assets/screenshots/01-what-should-we-work-on.png

2. Connect your professional tools
   Use a dense connector icon grid with Gmail, Drive, Calendar, Slack, Google Business Profile, Google Ads, WhatsApp, Outlook, QuickBooks, Stripe, Shopify, Clio, NetSuite, OneDrive, SAP, Office, Teams, AWS, Azure, and Postgres.
   Generated asset: store-assets/screenshots/02-connect-professional-tools.png

3. Cloud-scale work
   Show icon workflow nodes around the Team runtime: research, async, draft, analyze, approve, save, deliver, and done.
   Generated asset: store-assets/screenshots/03-cloud-scale-work.png

4. One shared workspace
   Show website-inspired folders, workspace modules, memory, and approval icons.
   Generated asset: store-assets/screenshots/04-shared-workspace-memory.png

5. Build without coding
   Show web, app, workflow, UI, data, and review icons from a natural-language build prompt.
   Generated asset: store-assets/screenshots/05-build-with-natural-language.png
```

Recommended visual treatment:

```text
- Build screenshots at Apple's current iPhone screenshot size in App Store Connect.
- Keep the actual app/site UI inside a rounded phone frame or centered crop.
- Put the headline outside the phone frame, not inside app chrome.
- Avoid copying Manus' exact words, brand marks, or example outputs.
- Use OpenTeam's black/warm-white/green visual system and real OpenTeam connector/workflow examples.
```

Temporary local captures used for planning:

```text
/tmp/openteam-mobile-shots/home-wait.png
/tmp/openteam-mobile-shots/apps.png
/tmp/openteam-mobile-shots/connect-scrolled.png
/tmp/openteam-mobile-shots/solutions.png
/tmp/openteam-mobile-shots/email-operations.png
/tmp/openteam-mobile-shots/calendar-scheduling.png
```
