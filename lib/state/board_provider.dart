import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../models/board.dart';
import '../services/storage_service.dart';

// Provider für den StorageService (Single Source of Truth für die Datenbank-Instanz)
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// Provider für das Dokumenten-Verzeichnis (für Bilder)
final appDocumentsDirectoryProvider = FutureProvider<Directory>((ref) async {
  return await getApplicationDocumentsDirectory();
});

// Provider, der den asynchronen Start der App (Hive Init) darstellt
final initializationProvider = FutureProvider<void>((ref) async {
  final storageService = ref.read(storageServiceProvider);
  await storageService.init();
});

// Der Haupt-Provider für die Liste der Boards
class BoardListNotifier extends StateNotifier<List<Board>> {
  final StorageService _storageService;

  BoardListNotifier(this._storageService) : super([]) {
    _loadBoards();
  }

  void _loadBoards() {
    state = _storageService.getAllBoards();
  }

  Future<void> addBoard(String name) async {
    final newBoard = Board(name: name);
    await _storageService.saveBoard(newBoard);
    // Wir laden neu oder fügen lokal hinzu. Da Board immutable ist, fügen wir es der Liste hinzu.
    state = [...state, newBoard];
  }

  Future<void> updateBoard(Board updatedBoard) async {
    await _storageService.saveBoard(updatedBoard);
    state = [
      for (final board in state)
        if (board.id == updatedBoard.id) updatedBoard else board,
    ];
  }

  Future<void> deleteBoard(String id) async {
    await _storageService.deleteBoard(id);
    state = state.where((b) => b.id != id).toList();
  }
}

// Der eigentliche Provider, den die UI nutzen wird
final boardListProvider = StateNotifierProvider<BoardListNotifier, List<Board>>(
  (ref) {
    final storageService = ref.watch(storageServiceProvider);
    return BoardListNotifier(storageService);
  },
);
