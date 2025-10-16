// Copyright (c) 2024 Sendbird, Inc. All rights reserved.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sendbird_uikit/src/internal/component/base/sbu_base_component.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sendbird_uikit/src/public/resource/sbu_colors.dart';

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
            image: imageProvider,
            fit: BoxFit.cover,
          ),
        ),
      ),
      progressIndicatorBuilder: (context, url, downloadProgress) {
        return Center(
          child: SizedBox(
            width: 16.r,
            height: 16.r,
            child: CircularProgressIndicator(
              value: downloadProgress.progress,
              color: SBUColors.primaryMain,
              strokeWidth: 1.4.r,
            ),
          ),
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
