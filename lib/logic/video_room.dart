import 'dart:math';

/// Jitsi Meet room naming and server config for therapist ↔ family calls.
///
/// Rooms on a Jitsi server are open to anyone who knows the name, so the
/// name *is* the access control. It is `vernacura-` plus 128 random bits
/// (32 hex chars) from a cryptographic RNG, generated once per
/// therapist–family pair and stored on the patient's `users/{uid}` doc
/// (`videoRoom`, with `videoRoomFor` = the therapist code it belongs to).
/// It never contains names, phone numbers, uids or codes.
///
/// See docs/video-calls.md for the server choice and self-hosting.
class VideoRoom {
  VideoRoom._();

  /// Demo-only default: the Freifunk München community instance, which lets
  /// anyone open a room without signing in. meet.jit.si cannot be used for an
  /// embedded app: since 2023 a moderator must sign in with Google/GitHub/
  /// Facebook before a room opens. Production should point this at a
  /// self-hosted server: `--dart-define=JITSI_SERVER_URL=https://meet.example.org`.
  static const defaultServerUrl = 'https://meet.ffmuc.net';

  static const _configured = String.fromEnvironment('JITSI_SERVER_URL');

  /// Server the app joins, without a trailing slash.
  static String get serverUrl => normaliseServer(_configured);

  static const prefix = 'vernacura-';
  static final _valid = RegExp(r'^vernacura-[0-9a-f]{32}$');

  /// Empty → [defaultServerUrl]; adds `https://` when missing; strips
  /// trailing slashes.
  static String normaliseServer(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return defaultServerUrl;
    if (!s.contains('://')) s = 'https://$s';
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  /// A fresh, unguessable room name: `vernacura-` + 128 random bits as hex.
  static String newName([Random? random]) {
    final rng = random ?? Random.secure();
    final hex = StringBuffer(prefix);
    for (var i = 0; i < 16; i++) {
      hex.write(rng.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return hex.toString();
  }

  static bool isValid(String? name) => name != null && _valid.hasMatch(name);

  /// The name shown to the other side: the first word of [fullName], or
  /// [fallback] when there is none.
  static String firstName(String fullName, {String fallback = 'Guest'}) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.first.isEmpty ? fallback : parts.first;
  }

  /// Browser link for the room (used on web, where the Jitsi SDK does not
  /// run). Jitsi reads `config.*` / `userInfo.*` overrides from the hash,
  /// so the web call matches the in-app one: no pre-join page, audio and
  /// video on, the display name filled in.
  static Uri meetingUri(String room, {required String displayName, String? server}) {
    final base = Uri.parse(normaliseServer(server ?? _configured));
    String q(String v) => Uri.encodeComponent('"$v"');
    final fragment = [
      'config.prejoinConfig.enabled=false',
      'config.prejoinPageEnabled=false',
      'config.startWithAudioMuted=false',
      'config.startWithVideoMuted=false',
      'config.disableDeepLinking=true',
      'userInfo.displayName=${q(displayName)}',
    ].join('&');
    return base.replace(
      path: '${base.path}/$room',
      fragment: fragment,
    );
  }

  /// Host name for the "Calls use …" note.
  static String get serverHost => Uri.parse(serverUrl).host;
}
