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
  final Function(int)? onQuantityChanged;

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
    this.onQuantityChanged,
  });

  @override
  State<MenuItemCard> createState() => _MenuItemCardState();
}

class _MenuItemCardState extends State<MenuItemCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late TextEditingController _quantityController;

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

    final displayQuantity = widget.quantity > 0 ? widget.quantity : 1;
    _quantityController = TextEditingController(text: displayQuantity.toString());

    if (_locallySelected) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _quantityController.dispose();
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

    final displayQuantity = widget.quantity > 0 ? widget.quantity : 1;
    if (_quantityController.text != displayQuantity.toString()) {
      _quantityController.text = displayQuantity.toString();
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
    widget.onRemove?.call();
  }

  void _handleQuantityChanged(String val) {
    if (val.isEmpty) {
      widget.onQuantityChanged?.call(0);
      return;
    }
    final newQty = int.tryParse(val);
    if (newQty != null) {
      widget.onQuantityChanged?.call(newQty);
    }
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            showMemoryBlur
                ? Border.all(color: AppColors.primary, width: 2.0)
                : Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color:
                showMemoryBlur
                    ? AppColors.primary.withOpacity(0.15)
                    : Colors.grey.withOpacity(0.08),
            blurRadius: showMemoryBlur ? 12.0 : 6.0,
            offset: showMemoryBlur ? const Offset(0, 3) : const Offset(0, 2),
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
                            color: AppColors.primary.withOpacity(0.25),
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

                // **VISUAL INDICATORS - animated TAP badge**
                if (!showMemoryBlur && widget.canOrder)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: _SubtleTappingBadge(),
                  ),
              ],
            ),
          ),

          // **INFO SECTION**
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color:
                          showMemoryBlur
                              ? AppColors.primary
                              : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  if (widget.description != null &&
                      widget.description!.trim().isNotEmpty) ...[
                    Expanded(
                      child: Text(
                        widget.description!,
                        style: TextStyle(
                          fontSize: 10.5,
                          color:
                              showMemoryBlur
                                  ? AppColors.primary.withOpacity(0.7)
                                  : AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ] else ...[
                    const Spacer(),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${CurrencyConstants.symbol}${widget.price.toInt()}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildControlButton(
            icon: Icons.remove,
            onPressed: _handleRemove,
            color: Colors.red[600]!,
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.85)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: SizedBox(
              width: 28,
              child: TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 2),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: _handleQuantityChanged,
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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 14),
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
            child: const Center(
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

class _SubtleTappingBadge extends StatefulWidget {
  const _SubtleTappingBadge();

  @override
  State<_SubtleTappingBadge> createState() => _SubtleTappingBadgeState();
}

class _SubtleTappingBadgeState extends State<_SubtleTappingBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app_rounded, color: Colors.white, size: 12),
            SizedBox(width: 4),
            Text(
              'TAP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
