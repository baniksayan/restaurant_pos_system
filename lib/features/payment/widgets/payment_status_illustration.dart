import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum PaymentStatusState {
  pending,
  partiallyPaid,
  paidInFull,
}

class PaymentStatusIllustration extends StatefulWidget {
  final PaymentStatusState status;
  final double size;

  const PaymentStatusIllustration({
    super.key,
    required this.status,
    this.size = 110,
  });

  @override
  State<PaymentStatusIllustration> createState() =>
      _PaymentStatusIllustrationState();
}

class _PaymentStatusIllustrationState extends State<PaymentStatusIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String get _assetPath => switch (widget.status) {
        PaymentStatusState.pending =>
          'assets/images/icons/payment_illustration.svg',
        PaymentStatusState.partiallyPaid =>
          'assets/images/icons/payment_illustration_amber.svg',
        PaymentStatusState.paidInFull =>
          'assets/images/icons/payment_illustration_green.svg',
      };

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnim.value),
          child: child,
        );
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: SvgPicture.asset(
          _assetPath,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
