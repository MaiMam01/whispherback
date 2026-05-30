import 'dart:math';

/// Fisher-Yates shuffle that tracks cycle position — no repeat until all played.
class ShuffleEngine {
  ShuffleEngine();

  final _random = Random();
  List<String> _order = [];
  int _index = 0;

  void reset(List<String> clipIds) {
    _order = List<String>.from(clipIds)..shuffle(_random);
    _index = 0;
  }

  void loadPersisted(List<String> order, int index) {
    _order = List<String>.from(order);
    _index = index;
  }

  String? next(List<String> clipIds) {
    if (clipIds.isEmpty) return null;
    if (_order.isEmpty ||
        _order.length != clipIds.length ||
        !_order.every(clipIds.contains)) {
      reset(clipIds);
    }
    if (_index >= _order.length) {
      reset(clipIds);
    }
    return _order[_index++];
  }

  List<String> get order => List.unmodifiable(_order);
  int get index => _index;
}
