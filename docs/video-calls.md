# Video calls (Jitsi Meet)

Therapist ↔ family video sessions use **[Jitsi Meet](https://jitsi.org/)**
(Apache-2.0) through the official Flutter SDK,
[`jitsi_meet_flutter_sdk`](https://pub.dev/packages/jitsi_meet_flutter_sdk)
13.3.0. It replaced Agora: no vendor account or App ID is needed.

## How a call works

- **Entry points:** *Care team* → **Video call** (family side) and
  *Patient detail* → **Video call** (therapist side). Both open the same join
  screen (`lib/ui/video_call/videocall_page.dart`) with a
  **Join video call** button.
- **Room name = access control.** Anyone who knows a Jitsi room name can
  join it, so names are `vernacura-` + 128 random bits as 32 hex characters
  (`Random.secure()`, `lib/logic/video_room.dart`). No names, phone numbers,
  uids or therapist codes go into it.
- **One room per therapist–family pair**, created once by whichever side
  opens the call first (Firestore transaction) and stored on the patient's
  `users/{uid}` document as `videoRoom` + `videoRoomFor` (the therapist code
  it belongs to). Linking a different therapist makes a new room; unlinking
  deletes it.
- **Firestore rules:** the patient may write their own doc as before. A
  linked therapist may additionally set `videoRoom`/`videoRoomFor` — only
  for their own code, only in the `vernacura-[0-9a-f]{32}` form, and never
  overwrite a room already theirs. Deploy with
  `firebase deploy --only firestore:rules`.
- **Display name:** the family's first name; the therapist shows as
  "Therapist".
- **In the call:** audio and video start on, no pre-join page, no welcome
  page. Recording, live-streaming, chat, invite, calendar, breakout rooms,
  video sharing and car mode are turned off in the app.
- **Web:** the SDK is Android/iOS only, so the web build opens the same
  room in a new browser tab (`url_launcher`) with the same settings passed in
  the URL hash (`#config.prejoinConfig.enabled=false&userInfo.displayName=…`).

## Choosing the server

```
flutter run --dart-define=JITSI_SERVER_URL=https://meet.example.org
flutter build apk --dart-define=JITSI_SERVER_URL=https://meet.example.org
```

Without it the app uses **`https://meet.ffmuc.net`** — the Freifunk München
community instance. It lets anyone open a room without signing in
(its `config.js` sets no `authdomain`), which is what an embedded app needs.
**It is for demos only:** it is run by volunteers, has no SLA, and a
health-data app must not send calls through a server it does not control.

Why not `meet.jit.si`? Since 24 Aug 2023 it no longer allows anonymous room
creation: a moderator must sign in with Google/GitHub/Facebook first
([jitsi.org blog](https://jitsi.org/blog/authentication-on-meet-jit-si/)),
so an embedded call sits at "waiting for moderator". Its `config.js` sets
`tokenAuthUrl` to a sign-in page, and since 9 Oct 2026 meetings there are
capped at 95 minutes ([jitsi.org/blog/changes-coming](https://jitsi.org/blog/changes-coming)).

## Production: self-host Jitsi

Use [docker-jitsi-meet](https://github.com/jitsi/docker-jitsi-meet)
([handbook](https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-docker))
on a small VM (2 vCPU / 4 GB is plenty for 1:1 calls), ideally in India for
latency and data residency.

1. DNS: point `meet.example.org` at the VM. Open TCP 80, 443 and
   **UDP 10000** (media).
2. Install:
   ```sh
   # latest release from https://github.com/jitsi/docker-jitsi-meet/releases
   curl -L https://github.com/jitsi/docker-jitsi-meet/archive/refs/tags/stable-XXXX.tar.gz | tar xz
   cd docker-jitsi-meet-stable-XXXX
   cp env.example .env
   ./gen-passwords.sh
   mkdir -p ~/.jitsi-meet-cfg/{web,transcripts,prosody/config,prosody/prosody-plugins-custom,jicofo,jvb,jigasi,jibri}
   ```
3. In `.env` set at least:
   ```sh
   PUBLIC_URL=https://meet.example.org
   ENABLE_LETSENCRYPT=1
   LETSENCRYPT_DOMAIN=meet.example.org
   LETSENCRYPT_EMAIL=you@example.org
   JVB_ADVERTISE_IPS=<the VM's public IP>
   ENABLE_RECORDING=0
   ENABLE_PREJOIN_PAGE=0
   ```
4. `docker compose up -d`, then open `https://meet.example.org` in a browser
   to check a call works.
5. Build the app with `--dart-define=JITSI_SERVER_URL=https://meet.example.org`.

Hardening for real patient data: enable JWT auth (`ENABLE_AUTH=1`,
`AUTH_TYPE=jwt`) and have a backend mint a token per booking — the SDK
already accepts one (`JitsiMeetConferenceOptions.token`); keep logs short;
keep the server patched.

## Platform requirements (SDK 13.3.0)

- **Android:** minSdk 24 (Flutter 3.44's default is already 24 — unchanged).
  The SDK's manifest sets `android:label`, so the app's `<application>`
  carries `tools:replace="android:label"`. Release builds keep the Jitsi /
  React Native classes via `android/app/proguard-rules.pro` (copied from the
  jitsi-meet repo). Camera + microphone permissions stay in the manifest;
  the SDK adds the rest (Bluetooth, foreground service…) itself.
- **iOS:** platform 15.1 (`ios/Podfile`, `IPHONEOS_DEPLOYMENT_TARGET`).
  `NSCameraUsageDescription` and `NSMicrophoneUsageDescription` are already
  in `Info.plist`.
