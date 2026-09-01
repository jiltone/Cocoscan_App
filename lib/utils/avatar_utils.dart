import 'dart:convert';

import 'package:flutter/material.dart';

/// Avatars are stored as raw base64 JPEG (see FirebaseService.uploadProfileAvatar
/// — no Firebase Storage bucket, so no network URL). Falls back to
/// NetworkImage for any legacy/external http(s) value. Returns null for
/// empty/unrecognised input so callers can show a placeholder.
ImageProvider? avatarImageProvider(String? avatar) {
  if (avatar == null || avatar.isEmpty) return null;
  if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
    return NetworkImage(avatar);
  }
  try {
    return MemoryImage(base64Decode(avatar));
  } catch (_) {
    return null;
  }
}
