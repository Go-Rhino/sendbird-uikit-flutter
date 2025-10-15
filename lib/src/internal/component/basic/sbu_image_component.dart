// Copyright (c) 2024 Sendbird, Inc. All rights reserved.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sendbird_uikit/src/internal/component/base/sbu_base_component.dart';

class SBUImageComponent extends SBUStatelessComponent {
  final String imageUrl;
  final String? cacheKey;
  final Widget? errorWidget;

  const SBUImageComponent({
    required this.imageUrl,
    this.cacheKey,
    this.errorWidget,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return errorWidget ?? Container();
    }

    return CachedNetworkImage(
      cacheKey: cacheKey,
      imageUrl: imageUrl,
      imageBuilder: (context, imageProvider) => Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            invertColors: true,
            image: imageProvider,
            fit: BoxFit.cover,
          ),
        ),
      ),
      progressIndicatorBuilder: (context, url, downloadProgress) {
        print('UPDEBUG: $downloadProgress for $url');
        return Stack(
          alignment: Alignment.center,
          children: [
            // 1. The Placeholder widget (e.g., a grey container or an icon)
            Container(
              color: Colors.green, // Or any placeholder color you want
              // You could also use an Icon as a placeholder:
              // child: Icon(Icons.image_outlined, color: Colors.grey[400]),
            ),

            // 2. The CircularProgressIndicator that sits on top
            CircularProgressIndicator(
              value: downloadProgress.progress,
              color: Colors.blue, // Customize the indicator color
              strokeWidth: 2.0, // Customize the indicator thickness
            ),
          ],
        );
      },
      errorWidget: (context, url, error) => errorWidget ?? Container(),
      // Check
      fadeOutDuration: Duration.zero,
      // Check
      fadeInDuration: Duration.zero,
      errorListener: (e) {
        // Error
      },
    );
  }
}
