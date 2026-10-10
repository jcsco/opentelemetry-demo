import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Generates and persists an anonymous per-install user id, mirroring the
/// react-native-app's `Session.gateway.ts`. The id is sent to the backend as
/// `sessionId`/`userId` and used to correlate telemetry with this install.
class SessionGateway {
  static const _userIdKey = 'session_user_id';

  String? _cachedUserId;

  Future<String> getUserId() async {
    if (_cachedUserId != null) {
      return _cachedUserId!;
    }

    final prefs = await SharedPreferences.getInstance();
    var userId = prefs.getString(_userIdKey);
    if (userId == null) {
      userId = const Uuid().v4();
      await prefs.setString(_userIdKey, userId);
    }

    _cachedUserId = userId;
    return userId;
  }
}

final sessionGateway = SessionGateway();
