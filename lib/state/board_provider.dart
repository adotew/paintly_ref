import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/board.dart';
import '../models/board_item.dart';
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
    return storageService.getAllBoards();
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

  // Löscht ein Item aus einem Board
  Future<void> deleteItemFromBoard(String boardId, String itemId) async {
    final board = state.firstWhere((b) => b.id == boardId);
    final updatedItems = board.items
        .where((item) => item.id != itemId)
        .toList();
    final updatedBoard = board.copyWith(items: updatedItems);
    await updateBoard(updatedBoard);
  }

  // Dupliziert ein Item in einem Board
  Future<void> duplicateItem(String boardId, String itemId) async {
    final board = state.firstWhere((b) => b.id == boardId);
    final itemIndex = board.items.indexWhere((item) => item.id == itemId);

    if (itemIndex == -1) return;

    final originalItem = board.items[itemIndex];
    // Neues Item mit leichtem Offset erstellen
    final duplicatedItem = originalItem.copyWith(
      x: originalItem.x + 20,
      y: originalItem.y + 20,
    );

    final updatedItems = List<BoardItem>.from(board.items)..add(duplicatedItem);
    final updatedBoard = board.copyWith(items: updatedItems);
    await updateBoard(updatedBoard);
  }

  // Spiegelt ein Item horizontal
  Future<void> flipItemHorizontal(String boardId, String itemId) async {
    final board = state.firstWhere((b) => b.id == boardId);
    final itemIndex = board.items.indexWhere((item) => item.id == itemId);

    if (itemIndex == -1) return;

    final item = board.items[itemIndex];
    final flippedItem = item.copyWith(flipHorizontal: !item.flipHorizontal);

    final updatedItems = List<BoardItem>.from(board.items);
    updatedItems[itemIndex] = flippedItem;
    final updatedBoard = board.copyWith(items: updatedItems);
    await updateBoard(updatedBoard);
  }

  Future<void> toggleBlackAndWhite(String boardId, String itemId) async {
    final board = state.firstWhere((b) => b.id == boardId);
    final itemIndex = board.items.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) return;
    final item = board.items[itemIndex];
    final updatedItems = List<BoardItem>.from(board.items);
    updatedItems[itemIndex] = item.copyWith(isBlackAndWhite: !item.isBlackAndWhite);
    await updateBoard(board.copyWith(items: updatedItems));
  }

  Future<void> toggleBlur(String boardId, String itemId) async {
    final board = state.firstWhere((b) => b.id == boardId);
    final itemIndex = board.items.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) return;
    final item = board.items[itemIndex];
    final updatedItems = List<BoardItem>.from(board.items);
    updatedItems[itemIndex] = item.copyWith(isBlurred: !item.isBlurred);
    await updateBoard(board.copyWith(items: updatedItems));
  }

  Future<void> togglePosterize(String boardId, String itemId) async {
    final board = state.firstWhere((b) => b.id == boardId);
    final itemIndex = board.items.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) return;
    final item = board.items[itemIndex];
    final updatedItems = List<BoardItem>.from(board.items);
    updatedItems[itemIndex] = item.copyWith(isPosterized: !item.isPosterized);
    await updateBoard(board.copyWith(items: updatedItems));
  }

  Future<void> setBlurSigma(String boardId, String itemId, double sigma) async {
    final board = state.firstWhere((b) => b.id == boardId);
    final itemIndex = board.items.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) return;
    final item = board.items[itemIndex];
    final updatedItems = List<BoardItem>.from(board.items);
    updatedItems[itemIndex] = item.copyWith(blurSigma: sigma);
    await updateBoard(board.copyWith(items: updatedItems));
  }

  Future<void> setPosterizationLevels(String boardId, String itemId, double levels) async {
    final board = state.firstWhere((b) => b.id == boardId);
    final itemIndex = board.items.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) return;
    final item = board.items[itemIndex];
    final updatedItems = List<BoardItem>.from(board.items);
    updatedItems[itemIndex] = item.copyWith(posterizationLevels: levels);
    await updateBoard(board.copyWith(items: updatedItems));
  }
}
