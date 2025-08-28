// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:restaurant_pos_system/data/models/menu_api_res_model.dart';
// import 'package:restaurant_pos_system/services/api_service.dart';

// import '../../view_models/providers/menu_provider.dart';
// import 'widgets/menu_header.dart';
// import 'widgets/menu_search_bar.dart';
// import 'widgets/category_tabs.dart';
// import 'widgets/menu_grid.dart';
// import 'widgets/cart_footer.dart';

// class MenuView extends StatefulWidget {
//   final String? selectedTableId;
//   final String? tableName;
//   final String? selectedLocation;
//   final Function(String itemId, String itemName, double price, Offset position)?
//   onAddToCart;

//   const MenuView({
//     super.key,
//     this.selectedTableId,
//     this.tableName,
//     this.selectedLocation,
//     this.onAddToCart,
//   });

//   @override
//   State<MenuView> createState() => _MenuViewState();
// }

// class _MenuViewState extends State<MenuView> {
//   MenuApiResModel _menuApiResModel = MenuApiResModel();
//   late Future _future;
//   @override
//   void initState() {
//     _future = getCustomerWishItems();
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Scaffold(
//         backgroundColor: Colors.grey[50],
//         body: FutureBuilder(
//           future: _future,
//           builder: (context, snapshot) {
//             if (snapshot.hasData) {
//               return Column(
//                 children: [
//                   MenuHeader(
//                     canOrder: widget.selectedTableId != null,
//                     tableName: widget.tableName,
//                     selectedLocation: widget.selectedLocation,
//                     onPrintKOT: _printKOT,
//                   ),
//                   const MenuSearchBar(),
//                   // To-Do:
//                   //you have extract all catagories from the api response
//                   // and pass it to the CategoryTabs widget
//                   // customisez MenuGried data according to the Categori tab
//                   const CategoryTabs(),
//                   Expanded(
//                     child: MenuGrid(
//                       canOrder: widget.selectedTableId != null,
//                       onAddToCart: widget.onAddToCart,
//                       data: _menuApiResModel,
//                     ),
//                   ),
//                   if (widget.selectedTableId != null)
//                     CartFooter(onPlaceOrder: () {}),
//                 ],
//               );
//             } else if (snapshot.hasError) {
//               return Center(child: Text('Error: ${snapshot.error}'));
//             } else {
//               return const Center(child: CircularProgressIndicator());
//             }
//           },
//         ),
//       ),
//     );
//   }

//   void _printKOT() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('KOT sent to kitchen printer!'),
//         backgroundColor: Colors.blue,
//       ),
//     );
//   }

//   Future<MenuApiResModel?> getCustomerWishItems() async {
//     try {
//       final endpoint = 'product/GetItemSearch';
//       final body = {
//         "itemCode": "",
//         "itemName": "",
//         "isItemCode": false,
//         "outletId": 10048,
//       };

//       if (kDebugMode) {
//         debugPrint('Calling menu API: $endpoint');
//         debugPrint('Request Body: $body');
//       }

//       final response = await ApiService.apiRequestHttpRawBody(
//         endpoint,
//         body,
//         method: 'POST',
//       );

//       if (response != null) {
//         if (kDebugMode) {
//           debugPrint('Wishlist API Response: $response');
//         }
//         _menuApiResModel = MenuApiResModel.fromJson(response);
//         return MenuApiResModel.fromJson(response);
//       } else {
//         if (kDebugMode) {
//           debugPrint('Wishlist API returned null response');
//         }
//         return null;
//       }
//     } catch (e, stackTrace) {
//       if (kDebugMode) {
//         debugPrint('Error in getCustomerWishItems: $e');
//         debugPrint('StackTrace: $stackTrace');
//       }
//       return null;
//     }
//   }
// }



import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/providers/menu_provider.dart';
import 'widgets/menu_header.dart';
import 'widgets/menu_search_bar.dart';
import 'widgets/category_tabs.dart';
import 'widgets/menu_grid.dart';
import 'widgets/cart_footer.dart';

class MenuView extends StatefulWidget {
  final String? selectedTableId;
  final String? tableName;
  final String? selectedLocation;
  final Function(String itemId, String itemName, double price,String categoryId,
    String categoryName, Offset position)? onAddToCart;

  const MenuView({
    super.key,
    this.selectedTableId,
    this.tableName,
    this.selectedLocation,
    this.onAddToCart,
  });

  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  @override
  void initState() {
    super.initState();
    // Load menu data when the widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final menuProvider = Provider.of<MenuProvider>(context, listen: false);
      menuProvider.loadMenuData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Consumer<MenuProvider>(
          builder: (context, menuProvider, child) {
            return Column(
              children: [
                MenuHeader(
                  canOrder: widget.selectedTableId != null,
                  tableName: widget.tableName,
                  selectedLocation: widget.selectedLocation,
                  onPrintKOT: _printKOT,
                ),
                const MenuSearchBar(),
                const CategoryTabs(),
                Expanded(
                  child: MenuGrid(
                    canOrder: widget.selectedTableId != null,
                    onAddToCart: widget.onAddToCart,
                  ),
                ),
                if (widget.selectedTableId != null && menuProvider.totalCartItems > 0)
                  CartFooter(onPlaceOrder: () {}),
              ],
            );
          },
        ),
      ),
    );
  }

  void _printKOT() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('KOT sent to kitchen printer!'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
