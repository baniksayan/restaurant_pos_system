import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/constants/currency_constants.dart';

class MenuItemCard extends StatefulWidget {
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
  final Function(String, String, double, String, String, Offset)? onAddToCart;
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
  State<MenuItemCard> createState() => _MenuItemCardState();
}

class _MenuItemCardState extends State<MenuItemCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  // **LOCAL STATE: Track if this item was tapped (shows blur immediately)**
  bool _locallySelected = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Set local state based on existing quantity
    _locallySelected = widget.quantity > 0;

    if (_locallySelected) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MenuItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // **UPDATE LOCAL STATE: Sync with external quantity changes**
    if (widget.quantity > 0 && !_locallySelected) {
      setState(() {
        _locallySelected = true;
      });
      _animationController.forward();
    } else if (widget.quantity == 0 && _locallySelected) {
      setState(() {
        _locallySelected = false;
      });
      _animationController.reverse();
    }
  }

  void _provideAddHapticFeedback() {
    HapticFeedback.lightImpact();
  }

  void _provideRemoveHapticFeedback() {
    HapticFeedback.mediumImpact();
  }

  void _handleImageTap() {
    if (!widget.canOrder) return;

    if (widget.quantity == 0 && !_locallySelected) {
      // **IMMEDIATE UI UPDATE: Show blur instantly**
      setState(() {
        _locallySelected = true;
      });
      _animationController.forward();

      // Then add to cart
      _addToCartWithAnimation();
      _provideAddHapticFeedback();
    }
  }

  void _handleAdd() {
    _addToCartWithAnimation();
    _provideAddHapticFeedback();
  }

  void _handleRemove() {
    _provideRemoveHapticFeedback();

    if (widget.quantity <= 1) {
      _showRemoveConfirmation();
    } else {
      widget.onRemove?.call();
    }
  }

  void _showRemoveConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.remove_shopping_cart_rounded,
                  color: Colors.red[600],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Remove Item?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Remove "${widget.name}" completely from cart?',
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.visibility_off,
                      color: Colors.orange[700],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Selection highlight will be removed',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 45,
                        height: 45,
                        color: Colors.grey[200],
                        child:
                            widget.imageUrl != null
                                ? CachedNetworkImage(
                                  imageUrl: widget.imageUrl!,
                                  imageBuilder:
                                      (context, imageProvider) => Container(
                                        width: 45,
                                        height: 45,
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            image: imageProvider,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                  placeholder:
                                      (context, url) => Center(
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                  errorWidget:
                                      (context, url, error) => const Icon(
                                        Icons.restaurant_menu,
                                        size: 20,
                                      ),
                                )
                                : const Icon(Icons.restaurant_menu, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.price.toInt()} • Qty: ${widget.quantity}',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                HapticFeedback.heavyImpact();

                // **RESET LOCAL STATE when completely removing**
                setState(() {
                  _locallySelected = false;
                });

                widget.onRemove?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[500],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text('Remove Completely'),
            ),
          ],
        );
      },
    );
  }

  void _addToCartWithAnimation() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final buttonPosition = renderBox.localToGlobal(Offset.zero);
      if (widget.onAddToCart != null) {
        widget.onAddToCart!(
          widget.id,
          widget.name,
          widget.price,
          widget.cid,
          widget.cname,
          buttonPosition,
        );
        return;
      }
    }
    widget.onAdd?.call();
  }

  @override
  Widget build(BuildContext context) {
    // **SHOW BLUR: If locally selected OR has quantity from external state**
    final showMemoryBlur = _locallySelected || widget.quantity > 0;

    // **DEBUG: Print state for troubleshooting**
    print(
      'MenuItemCard ${widget.name}: quantity=${widget.quantity}, _locallySelected=$_locallySelected, showBlur=$showMemoryBlur',
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            showMemoryBlur
                ? Border.all(color: AppColors.primary, width: 2.5)
                : Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color:
                showMemoryBlur
                    ? AppColors.primary.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.08),
            blurRadius: showMemoryBlur ? 15.0 : 6.0,
            offset: showMemoryBlur ? const Offset(0, 4) : const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // **IMAGE SECTION WITH IMMEDIATE BLUR RESPONSE**
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                // **TAPPABLE IMAGE**
                GestureDetector(
                  onTap: _handleImageTap,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child:
                        widget.imageUrl != null
                            ? ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                              child: _buildMenuItemImage(widget.imageUrl!),
                            )
                            : Center(
                              child: Icon(
                                Icons.restaurant_menu,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                            ),
                  ),
                ),

                _buildVegIndicator(),

                // **MEMORY BLUR - Shows immediately on tap**
                if (showMemoryBlur)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(
                              0.3,
                            ), // **EVEN MORE VISIBLE**
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Center(
                            child: AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _scaleAnimation.value,
                                  child: Opacity(
                                    opacity: _opacityAnimation.value,
                                    child: _buildQuantityControls(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // **VISUAL INDICATORS**
                if (showMemoryBlur)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.green[600],
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),

                if (!showMemoryBlur && widget.canOrder)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'TAP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // **INFO SECTION**
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color:
                          showMemoryBlur
                              ? AppColors.primary
                              : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.description != null &&
                      widget.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        widget.description!,
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              showMemoryBlur
                                  ? AppColors.primary.withOpacity(0.7)
                                  : AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ] else ...[
                    const Spacer(),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${CurrencyConstants.symbol}${widget.price.toInt()}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      if (showMemoryBlur)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[600],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bookmark,
                                color: Colors.white,
                                size: 10,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'SELECTED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityControls() {
    // **USE ACTUAL QUANTITY or 1 if locally selected but not yet updated**
    final displayQuantity = widget.quantity > 0 ? widget.quantity : 1;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildControlButton(
            icon: Icons.remove,
            onPressed: _handleRemove,
            color: Colors.red[600]!,
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              displayQuantity.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          _buildControlButton(
            icon: Icons.add,
            onPressed: _handleAdd,
            color: Colors.green[600]!,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildMenuItemImage(String imageUrl) {
    String cleanImageUrl = imageUrl;
    if (imageUrl.contains('https://') &&
        imageUrl.indexOf('https://') != imageUrl.lastIndexOf('https://')) {
      cleanImageUrl = imageUrl.substring(imageUrl.lastIndexOf('https://'));
    }

    return CachedNetworkImage(
      imageUrl: cleanImageUrl,
      placeholder:
          (context, url) => Container(
            color: Colors.grey[100],
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          ),
      errorWidget:
          (context, url, error) => Container(
            color: Colors.grey[100],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant_menu, color: Colors.grey[400], size: 30),
                const SizedBox(height: 4),
                Text(
                  'Image\nUnavailable',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
      fit: BoxFit.cover,
      height: double.infinity,
      width: double.infinity,
    );
  }

  Widget _buildVegIndicator() {
    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                border: Border.all(
                  color:
                      widget.isVeg
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFF8D6E63),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Center(
              child:
                  widget.isVeg
                      ? Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                      )
                      : SizedBox(
                        width: 8,
                        height: 8,
                        child: CustomPaint(
                          painter: TrianglePainter(
                            color: const Color(0xFF8D6E63),
                          ),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width * 0.5, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
