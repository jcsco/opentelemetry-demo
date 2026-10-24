import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:splunk_otel_flutter_session_replay/splunk_otel_flutter_session_replay.dart';

/// Flutter paints into a single canvas, so Session Replay cannot detect
/// sensitive native views the way it does on Android/iOS. Wrapping a subtree
/// in this widget covers its on-screen rectangle in recorded replays.
class SessionReplayMask extends StatefulWidget {
  final Widget child;

  const SessionReplayMask({super.key, required this.child});

  @override
  State<SessionReplayMask> createState() => _SessionReplayMaskState();
}

class _SessionReplayMaskState extends State<SessionReplayMask> {
  @override
  void initState() {
    super.initState();
    _MaskCoordinator.instance.register(this);
  }

  @override
  void dispose() {
    _MaskCoordinator.instance.unregister(this);
    super.dispose();
  }

  Rect? _visibleRect() {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    if (ModalRoute.of(context)?.isCurrent == false) return null;

    // IndexedStack keeps inactive tabs mounted but offstage.
    for (RenderObject? p = box.parent; p != null; p = p.parent) {
      if (p is RenderOffstage && p.offstage) return null;
    }
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _MaskCoordinator {
  static final instance = _MaskCoordinator._();
  _MaskCoordinator._();

  final _masks = <_SessionReplayMaskState>{};
  List<Rect> _applied = const [];
  bool _frameCallbackInstalled = false;
  bool _checkScheduled = false;

  void register(_SessionReplayMaskState state) {
    _masks.add(state);
    if (!_frameCallbackInstalled) {
      _frameCallbackInstalled = true;
      // Re-measure after every frame so masks follow scrolling and relayout.
      WidgetsBinding.instance.addPersistentFrameCallback((_) => _schedule());
    }
    WidgetsBinding.instance.scheduleFrame();
  }

  void unregister(_SessionReplayMaskState state) {
    _masks.remove(state);
    WidgetsBinding.instance.scheduleFrame();
  }

  void _schedule() {
    if (_checkScheduled) return;
    _checkScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScheduled = false;
      _apply();
    });
  }

  Future<void> _apply() async {
    final rects = [
      for (final m in _masks)
        if (m.mounted) ?m._visibleRect(),
    ];
    if (_sameRects(rects, _applied)) return;
    _applied = rects;

    try {
      await SplunkSessionReplay.instance.setRecordingMask(
        mask: rects.isEmpty
            ? null
            : RecordingMask(
                elements: [
                  for (final r in rects)
                    MaskElement(rect: r, type: MaskType.covering),
                ],
              ),
      );
    } catch (_) {
      // Replay may be sampled out or unavailable; masking is then moot.
    }
  }

  bool _sameRects(List<Rect> a, List<Rect> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
