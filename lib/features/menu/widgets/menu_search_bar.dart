import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/menu_provider.dart';
import 'package:restaurant_pos_system/core/constants/app_strings.dart';

class MenuSearchBar extends StatefulWidget {
  const MenuSearchBar({super.key});

  @override
  State<MenuSearchBar> createState() => _MenuSearchBarState();
}

class _MenuSearchBarState extends State<MenuSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final initialQuery = context.read<MenuProvider>().searchQuery;
    _controller = TextEditingController(text: initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = context.watch<MenuProvider>().searchQuery;
    if (_controller.text != searchQuery && !FocusScope.of(context).hasFocus) {
      _controller.text = searchQuery;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        onChanged: (value) {
          context.read<MenuProvider>().updateSearchQuery(value);
          setState(() {});
        },
        decoration: InputDecoration(
          hintText: AppStrings.menu.searchDishes,
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon:
              _controller.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                    tooltip: AppStrings.clear,
                    onPressed: () {
                      _controller.clear();
                      context.read<MenuProvider>().updateSearchQuery('');
                      setState(() {});
                    },
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
      ),
    );
  }
}
