# Boda — ideas backlog

Proposed features for future versions of the wedding planner. The planner
manages the experience; guests participate through the wedding’s own link.

## 1. AI wedding chat

Add a chat to each wedding page where guests can ask about the celebration and
discover more about the couple.

Possible conversations:

- Gift ideas, preferences, or links to the couple’s gift registry.
- Fun facts about each partner and their relationship.
- How they met, favorite memories, hobbies, and shared interests.
- Wedding questions: schedule, locations, dress code, and other guest details.

The planner would prepare a profile with facts and stories approved by the
couple, along with any gift guidance they want to share. The AI should answer
from that material and the wedding’s actual details. If it does not know an
answer, it should say so instead of inventing a personal fact.

Clarification for later: “gist” is interpreted here as gift ideas; confirm if a
different type of conversation was intended.

## 2. A landing page that changes with the event

Give each wedding a local start date and time, plus an end time. Use the
wedding’s configured time zone to determine the current phase.

| Phase | Guest experience |
| --- | --- |
| Before the wedding | Invitation, countdown, couple’s story, schedule, maps, and RSVP. |
| During the wedding | A celebration message, guestbook, and prominent camera/photo upload actions. Keep the schedule and maps easy to find. |
| After the wedding | A thank-you message, guest messages, and the shared wedding photo collection. |

Example: if the wedding starts at **8:00 PM**, the page automatically switches
to its live event experience at 8:00 PM in the wedding’s time zone. A guest who
already has the page open should see the change without needing to reopen it.
The planner should be able to preview each phase and manually override it when
the real celebration starts earlier or later than planned.

## 3. Guest photo capture and uploads

During the live event, guests can:

- Take a photo with their phone’s camera, after granting camera access.
- Choose existing photos from their phone or computer.
- Upload several photos, optionally adding their name and a short caption.
- See upload progress, confirmation, and a useful retry option if the venue’s
  internet connection is unreliable.

Save photos to persistent server storage associated with the correct wedding.
Rails Active Storage is already available in the project; a hosted version
could use object storage for guest uploads. Guests should be able to close
their browser after a successful upload without losing the photo.

Guest contributions should be separate from the planner’s curated cover and
carousel photos. The planner can review uploads, hide unwanted submissions,
and choose whether photos appear immediately or after approval. Set file type,
size, and upload limits appropriate for guest contributions.

## 4. A guestbook for the newlyweds

When the event starts, let guests leave congratulations, wishes, and memories
for the couple. Offer an optional guest name and a text message. Store each
message under that wedding so the couple and planner can revisit it later.

The planner should be able to review and hide messages. Decide whether guests
see a shared guestbook or whether messages are delivered privately to the
couple.

## 5. Relive the celebration afterward

After the event, provide a gallery of approved guest photos and a collection
of guestbook messages. Keep them available through the same wedding link.

Possible additions:

- Browse photos in a carousel or gallery and open them in full size.
- Let the planner download the full collection for the couple.
- Show contributor names and captions when supplied.
- Add a thank-you message from the newlyweds.
- Select favorite guest photos for the main wedding page.

## 6. Phone-first experience

Guests will often open the invitation on a phone. Treat the phone layout as a
primary experience, including smaller 320 px screens and modern notched phones.

- Keep names, venue addresses, maps, and gallery photos within the screen width.
- Provide easy-to-tap links to the invitation, schedule/maps, photos, and RSVP.
- Use readable form fields that do not cause unwanted input zoom on iPhone.
- Keep carousel swiping and camera/photo selection easy to use with one hand.
- Respect safe areas and the keyboard so controls do not cover form fields.
- Test long names and addresses, many photos, and slower venue connections.

## 7. Optional guest reminders and notifications

Let each guest choose to receive reminders for a particular wedding. Ask from
an explicit **Enable wedding reminders** action, with an easy way to stop them.

| When | Example notification | Opens |
| --- | --- | --- |
| Before the RSVP deadline | “Will you be joining us? Please confirm your attendance.” | That wedding’s RSVP form. |
| On the wedding day, before arrival | “Today is the day! Here is how to get to the celebration.” | The correct venue and Google Maps directions. |
| When the event starts | “The celebration has begun. Leave a wish for the newlyweds!” | The live guestbook. |
| At a planner-selected time during the event | “Capture a little joy! Take a photo and share it with the couple.” | The camera/photo upload action. |
| After the celebration | “Relive the day: the wedding gallery is ready.” | The approved post-event gallery. |

Only remind guests who opted in. Stop RSVP reminders after that guest responds,
and avoid sending event participation prompts to guests who declined. Allow the
planner to choose timings, edit copy, preview reminders, pause them, and cancel
or reschedule them if wedding details change. Use the wedding’s local time zone.

### Delivery options and phone support

- **Web push:** notifications can arrive while the page is closed, using a
  service worker, a guest push subscription, and server-scheduled delivery.
  Production requires HTTPS and the guest’s permission.
- **iPhone/iPad:** web push is supported for Home Screen web apps on iOS/iPadOS
  16.4 and later. The guest must add the wedding page to their Home Screen and
  enable reminders from a tap in that web app. Include simple setup guidance.
- **Email:** consider a separate opt-in alternative for guests who prefer not
  to install the page or whose browser does not support push.
- **While the page is open:** use visible page reminders as a useful companion
  to push, particularly when the event phase changes.

The server should schedule reminders with a persistent job queue so they do not
depend on an open browser tab. Track sends to avoid duplicates, drop expired
subscriptions, and re-check consent and RSVP status before delivery. Tie each
subscription to its wedding and, when identified, the relevant guest. Plan for
best-effort delivery: phone settings and network conditions can delay a push.

Phone support references:

- [Apple: sending web push notifications](https://developer.apple.com/documentation/usernotifications/sending-web-push-notifications-in-web-apps-and-browsers).
- [MDN: Notifications API](https://developer.mozilla.org/en-US/docs/Web/API/Notifications_API).

## 8. Wedding QR codes and a digital book of good wishes

Place printed QR codes at the entrance, on tables, and near the photo area.
Each code opens that wedding’s permanent page. Once the celebration has
started, the page gives guests two prominent actions:

1. **“Subir fotos de la boda”** — take a photo or select several from the phone,
   optionally add a caption, and upload them to this wedding’s album.
2. **“Dejar buenos deseos”** — write a wish, memory, or congratulations for the
   newlyweds, with an optional name or signature.

This carries the idea of the physical wedding guestbook into a digital keepsake.
Suggested opening copy: **“¡La fiesta ya comenzó! Comparte un recuerdo con los
novios.”** Keep maps, the schedule, and the couple’s story available as secondary
links so the two participation actions are easy to find on a phone.

### Guest experience

- Scan the QR and participate directly in the phone’s browser.
- Use the wedding’s start time and time zone to select live event mode, with
  the planner’s manual override available if the celebration changes time.
- Keep participation simple: optional guest name, message or photos, and a
  clear confirmation after submission. Guest accounts are not needed.
- Treat reminder subscriptions as a separate optional action, so guests can
  participate through the QR without setting up push notifications.
- Let guests return to add another memory later, subject to the planner’s
  chosen submission window.

### Planner and keepsake

- Generate a downloadable QR for each wedding, with a printable table-card
  design that includes the couple’s names, a short instruction, and the readable
  wedding URL as an alternative.
- Use the same stable destination for all printed QR codes for that wedding.
  After the event, that link opens the post-event memories experience.
- Review guest photos and wishes from the wedding dashboard.
- Suggested default: good wishes are private to the couple and planner, with
  an option to share selected approved messages later.
- Collect approved photos and signed wishes into a digital memory book. A
  downloadable, printable PDF could give the couple a physical keepsake too.

Suggested first delivery: one QR per wedding, the live screen with two large
actions, text wishes, multiple photo uploads, and a planner review screen.
Printable memory books can follow once contributions are collected.

## Decisions to make before building

- What information and stories should the AI be allowed to share?
- Should guest participation use just the wedding URL or an optional event code?
- Should new photos and messages appear immediately or wait for approval?
- When does the live event end, and can guests keep uploading afterward?
- Who can view the final gallery: everyone with the link, or only invited guests?
- How long should photos be stored, and who can download the originals?
- Should reminders use web push, email, or both, and how often can guests receive them?
- How will an anonymous guest link their reminder subscription to their RSVP?
- Should good wishes remain private, or can the couple share selected entries?
- What format should the printable QR cards and eventual memory book use?

## Suggested order

1. Continue phone layout and usability checks throughout development.
2. Event start/end times and automatic page phases.
3. Guest messages and planner review, presented as a book of good wishes.
4. Guest photo capture, uploads, and planner review, reached through the wedding QR.
5. Post-event gallery and downloads.
6. Reminder opt-in, guest identification, and scheduled notifications.
7. AI chat using the couple’s approved profile and wedding details.
