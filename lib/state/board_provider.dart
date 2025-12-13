import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/board.dart';
import '../services/storage_service.dart';

part 'board_provider.g.dart';

// Provider für den StorageService (Single Source of Truth für die Datenbank-Instanz)
@Riverpod(keepAlive: true)
StorageService storageService(StorageServiceRef ref) {
  return StorageService();
}

// Provider für das Dokumenten-Verzeichnis (für Bilder)
@riverpod
Future<Directory> appDocumentsDirectory(AppDocumentsDirectoryRef ref) async {
  return await getApplicationDocumentsDirectory();
}

// Provider, der den asynchronen Start der App (Hive Init) darstellt
@riverpod
Future<void> initialization(InitializationRef ref) async {
  final storageService = ref.read(storageServiceProvider);
  await storageService.init();
}

// Der Haupt-Provider für die Liste der Boards
@Riverpod(keepAlive: true)
class BoardList extends _$BoardList {
  @override
  List<Board> build() {
    final storageService = ref.read(storageServiceProvider);
    _loadBoards(storageService);
    return [];
  }

  void _loadBoards(StorageService storageService) async {
    state = await Future.value(storageService.getAllBoards());
  }

  Future<Board> addBoard(String name) async {
    final storageService = ref.read(storageServiceProvider);
    final newBoard = Board(name: name);
    await storageService.saveBoard(newBoard);
    // Wir laden neu oder fügen lokal hinzu. Da Board immutable ist, fügen wir es der Liste hinzu.
    state = [...state, newBoard];
    return newBoard;
  }

  Future<void> updateBoard(Board updatedBoard) async {
    final storageService = ref.read(storageServiceProvider);
    await storageService.saveBoard(updatedBoard);
    state = [
      for (final board in state)
        if (board.id == updatedBoard.id) updatedBoard else board,
    ];
  }

  Future<void> deleteBoard(String id) async {
    final storageService = ref.read(storageServiceProvider);
    await storageService.deleteBoard(id);
    state = state.where((b) => b.id != id).toList();
  }
}
