import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Contract each native Yawala Notes host (Kotlin/Swift/C++/...) implements.
/// The Dart layer stays portable across Android, iOS, Linux, macOS and
/// Windows by talking to a single method channel per platform.
abstract interface class NotesNative {
  Future<Object?> invoke(String method, [Map<String, Object?>? args]);
}

const MethodChannel notesChannel = MethodChannel('com.yawalasiwala/notes');

/// Default implementation forwarding calls over the method channel.
class MethodChannelNotesNative implements NotesNative {
  MethodChannelNotesNative();

  @override
  Future<Object?> invoke(String method, [Map<String, Object?>? args]) =>
      notesChannel.invokeMethod<Object?>(method, args);
}

/// Boots the platform bindings for this OS.
NotesNative bootNotesNative() => MethodChannelNotesNative();

/// Human-readable platform name for logs and feature gating.
String get platformName {
  if (kIsWeb) return 'web';
  if (Platform.isAndroid) return 'android';
  if (Platform.isIOS) return 'ios';
  if (Platform.isMacOS) return 'macos';
  if (Platform.isWindows) return 'windows';
  if (Platform.isLinux) return 'linux';
  return 'unknown';
}

/// Desktop targets share tighter bindings (window controls, FS roots, ...).
bool get isDesktop =>
    Platform.isMacOS || Platform.isWindows || Platform.isLinux;