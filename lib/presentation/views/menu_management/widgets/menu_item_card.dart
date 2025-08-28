import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';

class MenuItemCard extends StatelessWidget {
  final String id;
  final String name;
  final double price;
  final String? imageUrl;
  final String? description;
  final String cid;
  final String cname;
  final bool isVeg;
  final bool canOrder;

  final int quantity;
  final Function(String, String, double,String,String, Offset)? onAddToCart;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;

  const MenuItemCard({
    super.key,
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    this.description,
    required this.cid,
    required this.cname,
    required this.isVeg,
    required this.canOrder,
    required this.quantity,
    this.onAddToCart,
    this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildItemImage(),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildItemName(),
                  const SizedBox(height: 2),
                  _buildItemDescription(),
                  const SizedBox(height: 4),
                  _buildPriceAndActions(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemImage() {
    return Expanded(
      flex: 3,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: imageUrl != null
                ? ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.restaurant,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.restaurant,
                    size: 40,
                    color: Colors.grey,
                  ),
          ),
          _buildVegIndicator(),
        ],
      ),
    );
  }

  Widget _buildVegIndicator() {
    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isVeg ? Colors.green : Colors.red,
            shape: isVeg ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: isVeg ? BorderRadius.circular(2) : null,
          ),
        ),
      ),
    );
  }

  Widget _buildItemName() {
    return Text(
      name,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildItemDescription() {
    return Flexible(
      child: Text(
        description ?? '',
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.textSecondary,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildPriceAndActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '₹${price.toInt()}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        if (canOrder) _buildCartControls(context),
      ],
    );
  }

  Widget _buildCartControls(BuildContext context) {
    if (quantity == 0) {
      return Builder(
        builder: (context) {
          return GestureDetector(
            onTap: () => _addToCartWithAnimation(context),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 14,
              ),
            ),
          );
        },
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.remove,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
          Text(
            quantity.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Builder(
            builder: (context) {
              return GestureDetector(
                onTap: () => _addToCartWithAnimation(context),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _addToCartWithAnimation(BuildContext context) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final buttonPosition = renderBox.localToGlobal(Offset.zero);
      onAddToCart?.call(id, name, price,cid, cname, buttonPosition);
    }
    onAdd?.call();
  }
}