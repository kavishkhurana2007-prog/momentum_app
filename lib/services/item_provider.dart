import 'package:flutter/material.dart';
import '../models/item.dart'; // make sure this path is correct

class ItemProvider extends ChangeNotifier {
  final List<ItemModel> _items = [];

  List<ItemModel> get items => _items;

  void addItem(ItemModel item) {
    _items.add(item);
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  void updateItem(ItemModel item) {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = item;
      notifyListeners();
    }
  }

  ItemModel? getItemById(String id) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index != -1) return _items[index];
    return null;
  }
}
