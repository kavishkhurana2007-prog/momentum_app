import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/item.dart';

class LocalDB {
  static const itemsBox = 'items_box';
  static const categoriesBox = 'categories_box';
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(itemsBox);
    await Hive.openBox<String>(categoriesBox);
  }

  static Box<String> get _items => Hive.box<String>(itemsBox);

  static List<ItemModel> getAll() {
    return _items.values
        .map((e) => ItemModel.fromJson(jsonDecode(e)))
        .toList();
  }

  static Future<void> upsert(ItemModel item) async {
    await _items.put(item.id, jsonEncode(item.toJson()));
  }

  static Future<void> delete(String id) async {
    await _items.delete(id);
  }

  static Future<void> clear() async {
    await _items.clear();
  }
}
