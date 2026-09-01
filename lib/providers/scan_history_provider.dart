import 'package:flutter/foundation.dart';

import '../services/backend_service.dart';

/// Shared scan history state.
///
/// MainShell keeps every tab mounted simultaneously via IndexedStack, so
/// HistoryScreen's initState() only ever fires once at app startup — a scan
/// saved afterwards (PredictionResultScreen's "Save to History" button)
/// would never appear until a full app restart. Routing both through this
/// provider means saving immediately notifies HistoryScreen via
/// notifyListeners(), regardless of which tab is currently visible.
class ScanHistoryProvider extends ChangeNotifier {
  List<dynamic> _scans = [];
  bool _loaded = false;
  bool _loading = false;

  List<dynamic> get scans => List.unmodifiable(_scans);
  bool get isLoaded => _loaded;
  bool get isLoading => _loading;

  Future<void> loadIfNeeded() async {
    if (_loaded || _loading) return;
    await refresh();
  }

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    try {
      _scans = await BackendService.getScans();
      _loaded = true;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Called right after a successful save so the new scan appears instantly
  /// without waiting on a fresh Firestore round trip.
  void prepend(Map<String, dynamic> scan) {
    _scans = [scan, ..._scans];
    notifyListeners();
  }
}
