import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'canvas_provider.g.dart';

// Current InteractiveViewer zoom scale — updated by InteractiveBoardCanvas
final canvasScaleProvider = StateProvider<double>((ref) => 1.0);

// Provider for the currently selected item ID on the canvas
@riverpod
class SelectedItemId extends _$SelectedItemId {
  @override
  String? build() => null;

  void select(String? itemId) {
    state = itemId;
  }

  void clear() {
    state = null;
  }
}

