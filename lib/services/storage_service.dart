import 'package:hive_flutter/hive_flutter.dart';
import '../models/board.dart';
import '../models/board_item.dart';

class StorageService {
  static const String _boxName = 'boards';

  // Initialisiert Hive und öffnet die Box
  Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    Hive.registerAdapter(BoardAdapter());
    Hive.registerAdapter(BoardItemAdapter());

    await Hive.openBox<Board>(_boxName);
  }

  // Gibt die Box zurück (synchrone Hilfsmethode, da init() gewartet wurde)
  Box<Board> get _box => Hive.box<Board>(_boxName);

  // Alle Boards laden
  List<Board> getAllBoards() {
    return _box.values.toList();
  }

  // Speichert oder aktualisiert ein Board
  Future<void> saveBoard(Board board) async {
    await _box.put(board.id, board);
  }

  // Löscht ein Board
  Future<void> deleteBoard(String id) async {
    await _box.delete(id);
  }

  // Einzelnes Board laden (optional, falls benötigt)
  Board? getBoard(String id) {
    return _box.get(id);
  }
}
