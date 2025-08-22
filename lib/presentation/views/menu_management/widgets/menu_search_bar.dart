import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/providers/menu_provider.dart';

class MenuSearchBar extends StatelessWidget {
  const MenuSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) => context.read<MenuProvider>().updateSearchQuery(value),
        decoration: const InputDecoration(
          hintText: 'Search dishes...',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}
