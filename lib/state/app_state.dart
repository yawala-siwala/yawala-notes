import 'package:flutter/foundation.dart';

import '../domain/model.dart';
import '../domain/service.dart';

/// Owns the observable state of Yawala Notes: filtered notes, loading
/// flag and app-scoped runtime flags. Widgets rebuild via notifyListeners.
class NotesState extends ChangeNotifier {
  NotesState({required NotesService service}) : _service = service;

  final NotesService _service;
  String _filter = '';
  bool _loading = false;
  List<Note> _items = const [];



  Iterable<Note> get items => _filter.isEmpty
      ? _items
      : _items.where((item) => item.matches(_filter.toLowerCase()));

  bool get isLoading => _loading;

  void setFilter(String value) {
    _filter = value.trim().toLowerCase();
    notifyListeners();
  }



  Future<void> reload() async {
    _loading = true;
    notifyListeners();
    try {
      _items = await _service.list();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}