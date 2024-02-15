// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shoping_list/data/categories.dart';
import 'package:shoping_list/models/category.dart';
import 'package:shoping_list/models/grocery_item.dart';
import 'package:shoping_list/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    _loadItems();
    super.initState();
  }

  void _loadItems() async {
    final url = Uri.https(
        'flutter-one-87a2a-default-rtdb.firebaseio.com', '/grocery_items.json');
    final response = await http.get(url);
    if (response.statusCode >= 400) {
      setState(() {
        _error = 'Failed to load items.Try again later again ..';
      });
      return;
    }
    final values = json.decode(response.body);
    List<GroceryItem> loadedItems = [];
    if (values == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    values.forEach((key, value) {
      Category category = categories.entries
          .firstWhere((element) => element.value.name == value['category'])
          .value;
      loadedItems.add(GroceryItem(
        id: key,
        name: value['name'],
        quantity: value['quantity'],
        category: category,
      ));
    });
    setState(() {
      _groceryItems = loadedItems;
      _isLoading = false;
    });
  }

  void _addItem() async {
    final item = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (context) => const NewItem(),
      ),
    );
    if (item != null) {
      setState(() {
        _groceryItems.add(item);
      });
    }
  }

  void _deleteItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });
    final url = Uri.https('flutter-one-87a2a-default-rtdb.firebaseio.com',
        '/grocery_items/${item.id}.json');

    final res = await http.delete(url);

    if (res.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, item);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Removing failed!'),
        ),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(child: Text("No items yet!"));
    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      content = const Center(child: Text("Something went wrong!"));
    }
    if (_groceryItems.isEmpty && !_isLoading && _error == null) {
      content = const Center(child: Text("Add some items!"));
    }
    if (_groceryItems.isNotEmpty && !_isLoading && _error == null) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: ((context, index) => Dismissible(
              key: ValueKey(_groceryItems[index].id),
              onDismissed: (direction) {
                _deleteItem(_groceryItems[index]);
              },
              child: ListTile(
                title: Text(_groceryItems[index].name),
                leading: Container(
                  width: 24,
                  height: 24,
                  color: _groceryItems[index].category.color,
                ),
                trailing: Text(_groceryItems[index].quantity.toString()),
              ),
            )),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Groceries'),
        actions: [
          IconButton(
              onPressed: _addItem, icon: const Icon(Icons.add_shopping_cart))
        ],
      ),
      body: content,
    );
  }
}
