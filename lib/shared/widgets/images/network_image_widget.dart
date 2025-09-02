// Create: lib/shared/widgets/images/network_image_widget.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class NetworkImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const NetworkImageWidget({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Clean up malformed URLs
    String cleanUrl = _cleanImageUrl(imageUrl);

    return CachedNetworkImage(
      imageUrl: cleanUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? _buildPlaceholder(),
      errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(),
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
    );
  }

  String _cleanImageUrl(String url) {
    // Fix double URL issue
    if (url.contains('https://') && url.indexOf('https://') != url.lastIndexOf('https://')) {
      return url.substring(url.lastIndexOf('https://'));
    }
    return url;
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant,
              color: Colors.grey[400],
              size: width != null && width! < 100 ? 24 : 40,
            ),
            const SizedBox(height: 4),
            Text(
              'Image\nUnavailable',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: width != null && width! < 100 ? 8 : 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
