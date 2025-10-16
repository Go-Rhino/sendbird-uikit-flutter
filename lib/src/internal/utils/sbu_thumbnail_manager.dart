// Copyright (c) 2024 Sendbird, Inc. All rights reserved.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:gif/gif.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';
import 'package:sendbird_uikit/src/internal/component/base/sbu_base_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_icon_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_image_component.dart';
import 'package:sendbird_uikit/src/internal/utils/sbu_preferences.dart';
import 'package:sendbird_uikit/src/internal/utils/sbu_thumbnail_cache.dart';
import 'package:sendbird_uikit/src/public/resource/sbu_colors.dart';
import 'package:sendbird_uikit/src/public/resource/sbu_icons.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SBUThumbnailManager {
  SBUThumbnailManager._();

  static final SBUThumbnailManager _instance = SBUThumbnailManager._();

  factory SBUThumbnailManager() => _instance;

  List<String> completerKeys = [];
  Map<String, List<Completer<Widget?>>> completerMap = {};

  String? _getKey(FileMessage message) {
    String? cacheKey;
    if (message.requestId != null && message.requestId!.isNotEmpty) {
      cacheKey = message.requestId;
    } else if (message.messageId > 0) {
      cacheKey = message.messageId.toString();
    }
    return cacheKey;
  }

  bool _isGif(FileMessage message) {
    String? mimeType = message.type;
    if (mimeType != null && mimeType == 'image/gif') {
      return true;
    }
    return false;
  }

  Widget? getThumbnail({
    required FileMessage message,
    required SBUFileType fileType,
    required bool isLightTheme,
    required bool addGifIcon,
    required bool isParentMessage,
  }) {
    String? thumbnailUrl;
    if (message.thumbnails?.isNotEmpty ?? false) {
      final thumbnail = message.thumbnails!.first;
      if (thumbnail.secureUrl.isNotEmpty) {
        thumbnailUrl = thumbnail.secureUrl;
      }
    }

    final isGif = _isGif(message);

    if (fileType == SBUFileType.image) {
      Widget? thumbnailWidget = _getThumbnail(message, fileType, isLightTheme);
      final size = isParentMessage ? 31.2 : 48.0;
      final iconSize = isParentMessage ? 18.2 : 28.0;

      if (thumbnailWidget == null) {
        if (isGif && thumbnailUrl == null && message.secureUrl.isNotEmpty) {
          final gif = Gif(
            image: NetworkImage(message.secureUrl),
            autostart: Autostart.no,
            fit: BoxFit.cover,
            useCache: true,
          );

          if (addGifIcon) {
            return _getGifWidget(
              thumbnailWidget: gif,
              size: size,
              iconSize: iconSize,
            );
          } else {
            return gif;
          }
        } else {
          thumbnailWidget = SBUImageComponent(
            imageUrl: thumbnailUrl ?? message.secureUrl,
            cacheKey: _getKey(message),
            errorWidget: isGif
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          color: SBUColors.darkThemeTextHighEmphasis,
                          borderRadius: BorderRadius.circular(size),
                        ),
                      ),
                      SBUIconComponent(
                        iconSize: iconSize,
                        iconData: SBUIcons.gif,
                        iconColor: SBUColors.lightThemeTextMidEmphasis,
                      ),
                    ],
                  )
                : SBUIconComponent(
                    iconSize: size,
                    iconData: SBUIcons.photo,
                    iconColor: isLightTheme
                        ? SBUColors.lightThemeTextMidEmphasis
                        : SBUColors.darkThemeTextMidEmphasis,
                  ),
          );
        }
      }

      if (isGif) {
        return _getGifWidget(
          thumbnailWidget: thumbnailWidget,
          size: size,
          iconSize: iconSize,
        );
      } else {
        return thumbnailWidget;
      }
    } else if (fileType == SBUFileType.video) {
      if (kIsWeb) {
        return null;
      }

      final widget = _getThumbnail(message, fileType, isLightTheme);
      if (widget != null) {
        return widget;
      }

      if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
        return SBUImageComponent(
          imageUrl: thumbnailUrl,
          cacheKey: _getKey(message),
        );
      }

      return FutureBuilder<Widget?>(
        future: _getVideoThumbnail(message),
        builder: (BuildContext context, AsyncSnapshot<Widget?> snapshot) {
          if (snapshot.data == null) {
            return Container(); // Check
          } else if (snapshot.hasData && snapshot.data != null) {
            final widget = snapshot.data!;
            return widget;
          } else if (snapshot.hasError) {
            return Container(); // Check
          } else {
            return Container(); // Check
          }
        },
      );
    } else {
      return null;
    }
  }

  Widget _getGifWidget({
    required Widget thumbnailWidget,
    required double size,
    required double iconSize,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        thumbnailWidget,
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: SBUColors.darkThemeTextHighEmphasis,
            borderRadius: BorderRadius.circular(size),
          ),
        ),
        SBUIconComponent(
          iconSize: iconSize,
          iconData: SBUIcons.gif,
          iconColor: SBUColors.lightThemeTextMidEmphasis,
        ),
      ],
    );
  }

  Widget? _getThumbnail(
    FileMessage message,
    SBUFileType fileType,
    bool isLightTheme,
  ) {
    SBUThumbnailCache? cache = SBUPreferences().getThumbnailCache(message);

    if (cache == null && fileType == SBUFileType.image) {
      final filePath = message.file?.path;
      if (filePath != null && filePath.isNotEmpty) {
        SBUPreferences().addThumbnailCache(message, filePath); // No await
      }
    }

    if (cache != null) {
      try {
        if (_isGif(message)) {
          return Gif(
            image: FileImage(File(cache.path)),
            autostart: Autostart.no,
            fit: BoxFit.cover,
            useCache: true,
          );
        } else {
          return Image.file(
            File(cache.path),
            fit: BoxFit.cover,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded || frame != null) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    child,
                  ],
                );
              }

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: ColoredBox(
                  color: isLightTheme
                      ? SBUColors.background100
                      : SBUColors.background400,
                  child: Center(
                    child: SizedBox(
                      width: 16.r,
                      height: 16.r,
                      child: CircularProgressIndicator(
                        color: isLightTheme
                            ? SBUColors.primaryMain
                            : SBUColors.primaryLight,
                        strokeWidth: 1.4.r,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }
      } catch (_) {
        // Check
      }
    }
    return null;
  }

  Future<Widget?> _getVideoThumbnail(FileMessage message) async {
    final filePath = message.file?.path;
    final fileUrl = message.secureUrl;
    final dir = await getTemporaryDirectory();

    Widget? widget;
    String? videoPathOrUrl;
    if (filePath != null && filePath.isNotEmpty) {
      videoPathOrUrl = filePath;
    } else if (fileUrl.isNotEmpty) {
      videoPathOrUrl = fileUrl;
    }

    if (videoPathOrUrl != null && videoPathOrUrl.isNotEmpty) {
      final result = await _genVideoThumbnail(
        message,
        VideoThumbnailRequest(video: videoPathOrUrl, thumbnailPath: dir.path),
      );
      widget = result?.image;
    }

    if (widget != null) {
      await Future.delayed(const Duration(milliseconds: 1000)); // Anti-flicker
    }
    return widget;
  }

  Future<VideoThumbnailResult?> _genVideoThumbnail(
    FileMessage message,
    VideoThumbnailRequest request,
  ) async {
    Uint8List? bytes;
    final completer = Completer<VideoThumbnailResult>();
    if (request.thumbnailPath != null) {
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: request.video,
        thumbnailPath: request.thumbnailPath,
        imageFormat: request.imageFormat ?? ImageFormat.PNG,
        maxHeight: request.maxHeight ?? 0,
        maxWidth: request.maxWidth ?? 0,
        timeMs: request.timeMs ?? 0,
        quality: request.quality ?? 10,
      );

      if (thumbnailPath != null) {
        await SBUPreferences().addThumbnailCache(message, thumbnailPath);
        final file = File(thumbnailPath);
        bytes = file.readAsBytesSync();
      }
    } else {
      bytes = await VideoThumbnail.thumbnailData(
        video: request.video,
        imageFormat: request.imageFormat ?? ImageFormat.PNG,
        maxHeight: request.maxHeight ?? 0,
        maxWidth: request.maxWidth ?? 0,
        timeMs: request.timeMs ?? 0,
        quality: request.quality ?? 10,
      );
    }

    if (bytes != null) {
      final imageDataSize = bytes.length;
      final image = Image.memory(bytes, fit: BoxFit.cover);
      image.image.resolve(ImageConfiguration.empty).addListener(
            ImageStreamListener(
              (ImageInfo info, bool synchronousCall) {
                completer.complete(
                  VideoThumbnailResult(
                    image: image,
                    dataSize: imageDataSize,
                    height: info.image.height,
                    width: info.image.width,
                  ),
                );
              },
              onError: completer.completeError,
            ),
          );
      return completer.future;
    }
    return null;
  }
}

class VideoThumbnailRequest {
  final String video;
  final String? thumbnailPath;
  final ImageFormat? imageFormat;
  final int? maxHeight;
  final int? maxWidth;
  final int? timeMs;
  final int? quality;

  const VideoThumbnailRequest({
    required this.video,
    this.thumbnailPath,
    this.imageFormat,
    this.maxHeight,
    this.maxWidth,
    this.timeMs,
    this.quality,
  });
}

class VideoThumbnailResult {
  final Image image;
  final int dataSize;
  final int height;
  final int width;

  const VideoThumbnailResult({
    required this.image,
    required this.dataSize,
    required this.height,
    required this.width,
  });
}
