// Copyright (c) 2024 Sendbird, Inc. All rights reserved.

import 'package:flutter/material.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';
import 'package:sendbird_uikit/sendbird_uikit.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_icon_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_image_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_reaction_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_text_component.dart';
import 'package:sendbird_uikit/src/internal/resource/sbu_text_styles.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SBUOGTagManager {
  SBUOGTagManager._();

  static final SBUOGTagManager _instance = SBUOGTagManager._();

  factory SBUOGTagManager() => _instance;

  bool useOGTag = false;

  bool _isOGTagEnabled(BaseMessage message) {
    final isOGTagEnabled =
        SendbirdChat.getAppInfo()?.attributesInUse.contains('enable_og_tag') ??
            false;

    if (useOGTag &&
        isOGTagEnabled &&
        message is UserMessage &&
        message.ogMetaData != null) {
      return true;
    }
    return false;
  }

  Widget? getOGTagMessageItemWidget({
    required BaseMessage message,
    required MessageCollection collection,
    required bool isLightTheme,
    required SBUStrings strings,
    required bool isMyMessage,
  }) {
    if (_isOGTagEnabled(message)) {
      final double messageItemWidth = 244.w;

      final ogMetaData = message.ogMetaData!;
      final ogImageUrl =
          ogMetaData.ogImage?.secureUrl ?? ogMetaData.ogImage?.url;

      return Container(
        width: messageItemWidth,
        padding: EdgeInsets.only(top: 6.h),
        decoration: BoxDecoration(
          color: isMyMessage
              ? (isLightTheme ? SBUColors.primaryMain : SBUColors.primaryLight)
              : (isLightTheme
                  ? SBUColors.background100
                  : SBUColors.background400),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:  EdgeInsets.only(left: 12.w, right: 12.w, bottom: 6.h),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: SBUTextComponent(
                      text: message.message,
                      textType: SBUTextType.body3,
                      textColorType: isMyMessage
                          ? SBUTextColorType.message
                          : SBUTextColorType.text01,
                      textOverflowType: null,
                      maxLines: null,
                    ),
                  ),
                  if (message.updatedAt > message.createdAt)
                    Padding(
                      padding: EdgeInsets.only(left: 4.w),
                      child: SBUTextComponent(
                        text: strings.edited,
                        textType: SBUTextType.body3,
                        textColorType: isMyMessage
                            ? SBUTextColorType.messageEdited
                            : SBUTextColorType.text02,
                        textOverflowType: null,
                        maxLines: null,
                      ),
                    ),
                ],
              ),
            ),
            if (ogImageUrl != null && ogImageUrl.isNotEmpty)
              Container(
                width: messageItemWidth,
                height: 136.h,
                color: isLightTheme
                    ? SBUColors.background100
                    : SBUColors.background400,
                child: SBUImageComponent(
                  imageUrl: ogImageUrl,
                  cacheKey: ogImageUrl,
                  errorWidget: SBUIconComponent(
                    iconSize: 48.r,
                    iconData: SBUIcons.thumbnailNone,
                    iconColor: isLightTheme
                        ? SBUColors.lightThemeTextLowEmphasis
                        : SBUColors.darkThemeTextLowEmphasis,
                  ),
                ),
              ),
            Container(
              width: messageItemWidth,
              padding:
                  EdgeInsets.only(left: 12.w, top: 8.h, right: 12.w, bottom: 4.h),
              color: isLightTheme
                  ? SBUColors.background100
                  : SBUColors.background400,
              child: SBUTextComponent(
                text: ogMetaData.title ?? '',
                textType: SBUTextType.body2,
                textColorType: SBUTextColorType.text01,
                textOverflowType: null,
                maxLines: null,
              ),
            ),
            Container(
              width: messageItemWidth,
              padding: EdgeInsets.only(left: 12.w, right: 12.w, bottom: 8.h),
              color: isLightTheme
                  ? SBUColors.background100
                  : SBUColors.background400,
              child: SBUTextComponent(
                text: ogMetaData.description ?? '',
                textType: SBUTextType.caption2,
                textColorType: SBUTextColorType.text01,
                textOverflowType: SBUTextOverflowType.ellipsisEnd,
                maxLines: 1,
              ),
            ),
            Container(
              width: messageItemWidth,
              padding: EdgeInsets.only(left: 12.w, right: 12.w, bottom: 12.h),
              decoration: BoxDecoration(
                color: isLightTheme
                    ? SBUColors.background100
                    : SBUColors.background400,
                borderRadius:
                    message.reactions != null && message.reactions!.isNotEmpty
                        ? BorderRadius.circular(0)
                        :  BorderRadius.only(
                            bottomLeft: Radius.circular(16.r),
                            bottomRight: Radius.circular(16.r),
                          ),
              ),
              child: SBUTextComponent(
                text: ogMetaData.url ?? '',
                textType: SBUTextType.caption2,
                textColorType: SBUTextColorType.text02,
                textOverflowType: SBUTextOverflowType.ellipsisEnd,
                maxLines: 1,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: isLightTheme
                    ? SBUColors.background100
                    : SBUColors.background400,
                borderRadius:  BorderRadius.only(
                  bottomLeft: Radius.circular(16.r),
                  bottomRight: Radius.circular(16.r),
                ),
              ),
              child: SBUReactionComponent(
                channel: collection.channel,
                message: message,
                width: messageItemWidth, // Check
              ),
            ),
          ],
        ),
      );
    }
    return null;
  }
}
