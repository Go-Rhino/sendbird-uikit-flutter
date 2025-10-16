// Copyright (c) 2024 Sendbird, Inc. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';
import 'package:sendbird_uikit/src/internal/component/base/sbu_base_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_file_icon_component.dart';
import 'package:sendbird_uikit/src/internal/utils/sbu_thumbnail_manager.dart';
import 'package:sendbird_uikit/src/public/resource/sbu_colors.dart';
import 'package:sendbird_uikit/src/public/resource/sbu_icons.dart';
import 'package:sendbird_uikit/src/public/resource/sbu_theme_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SBUFileMessageIconComponent extends SBUStatefulComponent {
  final double iconSize;
  final FileMessage fileMessage;

  const SBUFileMessageIconComponent({
    required this.iconSize,
    required this.fileMessage,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => SBUFileMessageIconComponentState();
}

class SBUFileMessageIconComponentState
    extends State<SBUFileMessageIconComponent> {
  @override
  Widget build(BuildContext context) {
    final isLightTheme = context.watch<SBUThemeProvider>().isLight();

    final iconSize = widget.iconSize;
    final fileMessage = widget.fileMessage;

    final fileType = widget.getFileType(fileMessage);

    switch (fileType) {
      case SBUFileType.image:
      case SBUFileType.video:
        final isReplyMessageToChannel =
            widget.isReplyMessageToChannel(fileMessage);

        return ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: SizedBox(
            width: iconSize,
            height: iconSize,
            child: SBUThumbnailManager().getThumbnail(
                  message: fileMessage,
                  fileType: fileType,
                  isLightTheme: isLightTheme,
                  addGifIcon: false,
                  isParentMessage: isReplyMessageToChannel,
                ) ??
                Container(), // Check
          ),
        );
      case SBUFileType.other:
        return ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: SizedBox(
            width: iconSize,
            height: iconSize,
            child: SBUFileIconComponent(
              size: iconSize,
              backgroundColor: isLightTheme
                  ? SBUColors.background200
                  : SBUColors.background500,
              iconSize: 20.r,
              iconData: SBUIcons.fileDocument,
              iconColor: isLightTheme
                  ? SBUColors.lightThemeTextMidEmphasis
                  : SBUColors.darkThemeTextMidEmphasis,
            ), // Check
          ),
        );
    }
  }
}
