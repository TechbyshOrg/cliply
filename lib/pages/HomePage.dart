import 'package:cliply/models/item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final ScrollController _scrollController = ScrollController();
  late Box<Item> itemsBox;
  List<Item> dummyData = [];
  List<Item> filteredData = [];
  
  int? expandedIndex;
  int? editingIndex;
  int? newItemIndex;

  final Map<int, TextEditingController> _controllers = {};
  final Map<int, TextEditingController> _titleControllers = {};
  
  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;
  FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    itemsBox = Hive.box<Item>('itemsBox');
    dummyData = itemsBox.values.toList();
    filteredData = List.from(dummyData);
    
    // Listen to search text changes
    _searchController.addListener(() {
      filterItems();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    
    // Dispose all controllers
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    for (var controller in _titleControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void addItem(Item item) {
    itemsBox.add(item);
    setState(() {
      dummyData = itemsBox.values.toList();
      filterItems();
    });
  }

  void updateItem(int index, Item newItem) {
    itemsBox.putAt(index, newItem);
    setState(() {
      dummyData = itemsBox.values.toList();
      filterItems();
    });
  }

  void deleteItem(int index) {
    itemsBox.deleteAt(index);
    setState(() {
      dummyData = itemsBox.values.toList();
      filterItems();
    });
  }

  void filterItems() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        filteredData = List.from(dummyData);
      });
    } else {
      setState(() {
        filteredData = dummyData.where((item) {
          return item.title.toLowerCase().contains(query) || 
                 item.content.toLowerCase().contains(query);
        }).toList();
      });
    }
  }

  void _saveItems() async {
    await itemsBox.clear();
    for (var item in dummyData) {
      await itemsBox.add(item);
    }
  }

  void _showEditDialog({Item? item, int? index}) {
    final titleController = TextEditingController(text: item?.title ?? '');
    final contentController = TextEditingController(text: item?.content ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(item == null ? 'Add New Item' : 'Edit Item'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contentController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Content',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {}); // Update character count live
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${contentController.text.length} characters',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                      if (item == null) {
                        // Add new item
                        final newItem = Item(
                          id: dummyData.isNotEmpty ? dummyData.last.id + 1 : 1,
                          title: titleController.text,
                          content: contentController.text,
                        );
                        addItem(newItem);
                      } else if (index != null) {
                        // Update existing item
                        final updatedItem = Item(
                          id: item.id,
                          title: titleController.text,
                          content: contentController.text,
                        );
                        updateItem(index, updatedItem);
                      }
                      Navigator.of(context).pop();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Changes saved")),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          centerTitle: false,
          elevation: 0,
          title: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Image.asset(
                    'lib/assets/app_icon.png',
                    width: 30,
                    height: 30,
                  ),
                ),
                const Text(
                  'Cliply',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(top: 16, right: 12),
              child: IconButton(
                icon: Icon(_showSearch ? Icons.close : Icons.search, size: 28),
                onPressed: () {
                  setState(() {
                    _showSearch = !_showSearch;
                    if (!_showSearch) {
                      _searchController.clear();
                      FocusScope.of(context).unfocus();
                    } else {
                      // Delay focus to allow the widget to build
                      Future.delayed(Duration(milliseconds: 100), () {
                        FocusScope.of(context).requestFocus(_searchFocusNode);
                      });
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar that appears conditionally
          if (_showSearch)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Search items...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: filteredData.length,
                itemBuilder: (context, index) {
                  final item = filteredData[index];
                  final originalIndex = dummyData.indexWhere((element) => element.id == item.id);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Dismissible(
                      key: Key(item.id.toString()),
                      background: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      secondaryBackground: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        // Show confirmation dialog before dismissing
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text("Confirm Delete"),
                              content: const Text("Are you sure you want to delete this item?"),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text("Delete"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      onDismissed: (direction) {
                        deleteItem(originalIndex);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF676776).withAlpha((0.25 * 255).toInt()),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        child: ListTile(
                          title: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.content,
                                maxLines: expandedIndex == index ? null : 2,
                                overflow: expandedIndex == index
                                    ? TextOverflow.visible
                                    : TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Text(
                                    '${item.content.length} characters',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (expandedIndex == index)
                                    GestureDetector(
                                      onTap: () {
                                        _showEditDialog(item: item, index: originalIndex);
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        width: 45,
                                        height: 45,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF676776).withAlpha((0.25 * 255).toInt()),
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: const Icon(Icons.edit, color: Colors.grey),
                                      ),
                                    ),
                                  GestureDetector(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: item.content))
                                          .then((_) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Copied to clipboard")),
                                        );
                                      });
                                    },
                                    child: Container(
                                      width: 45,
                                      height: 45,
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      alignment: Alignment.center,
                                      child: Image.asset(
                                        'lib/assets/copy.png',
                                        width: 17,
                                        height: 17,
                                        fit: BoxFit.contain,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () {
                            setState(() {
                              if (expandedIndex == index) {
                                expandedIndex = null;
                              } else {
                                expandedIndex = index;
                              }
                            });
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showEditDialog();
        },
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 28, weight: 800),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}