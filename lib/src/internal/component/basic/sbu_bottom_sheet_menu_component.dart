// Copyright (c) 2024 Sendbird, Inc. All rights reserved.

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';
import 'package:sendbird_uikit/sendbird_uikit.dart';
import 'package:sendbird_uikit/src/internal/component/base/sbu_base_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_bottom_sheet_reaction_add_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_icon_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_image_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_text_component.dart';
import 'package:sendbird_uikit/src/internal/resource/sbu_text_styles.dart';
import 'package:sendbird_uikit/src/internal/utils/sbu_reaction_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SBUBottomSheetMenuComponent extends SBUStatefulComponent {
  final BaseChannel? channel;
  final BaseMessage? message;
  final List<IconData>? iconNames;
  final List<String> buttonNames;
  final void Function(String buttonName) onButtonClicked;
  final int? errorColorIndex;
  final List<String>? disabledNames;

  const SBUBottomSheetMenuComponent({
    this.channel,
    this.message,
    this.iconNames,
    required this.buttonNames,
    required this.onButtonClicked,
    this.errorColorIndex,
    this.disabledNames,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => SBUBottomSheetMenuComponentState();
}

class SBUBottomSheetMenuComponentState
    extends State<SBUBottomSheetMenuComponent> {
  @override
  Widget build(BuildContext context) {
    final isLightTheme = context.watch<SBUThemeProvider>().isLight();

    final channel = widget.channel;
    final message = widget.message;
    final iconNames = widget.iconNames;
    final buttonNames = widget.buttonNames;
    final onButtonClicked = widget.onButtonClicked;
    final errorColorIndex = widget.errorColorIndex;
    final disabledNames = widget.disabledNames;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color:
              isLightTheme ? SBUColors.background50 : SBUColors.background500,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8.r),
            topRight: Radius.circular(8.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _getReactionWidget(channel, message, isLightTheme),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: buttonNames.mapIndexed((index, iconName) {
                final isError = (errorColorIndex == index);
                final isDisabled =
                    disabledNames?.any((name) => name == buttonNames[index]) ??
                        false;

                return Material(
                  color: Colors.transparent,
                  child: isDisabled
                      ? _menuItem(
                          index: index,
                          iconNames: iconNames,
                          buttonNames: buttonNames,
                          isError: isError,
                          isDisabled: isDisabled,
                          isLightTheme: isLightTheme,
                        )
                      : InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            onButtonClicked(buttonNames[index]);
                          },
                          child: _menuItem(
                            index: index,
                            iconNames: iconNames,
                            buttonNames: buttonNames,
                            isError: isError,
                            isDisabled: isDisabled,
                            isLightTheme: isLightTheme,
                          ),
                        ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem({
    required int index,
    required List<IconData>? iconNames,
    required List<String> buttonNames,
    required bool isError,
    required bool isDisabled,
    required bool isLightTheme,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          index < (iconNames?.length ?? 0)
              ? Padding(
                  padding: EdgeInsets.only(left: 16.w),
                  child: SBUIconComponent(
                    iconSize: 24.r,
                    iconData: iconNames![index],
                    iconColor: isDisabled
                        ? (isLightTheme
                            ? SBUColors.lightThemeTextDisabled
                            : SBUColors.darkThemeTextDisabled)
                        : (isLightTheme
                            ? SBUColors.primaryMain
                            : SBUColors.primaryLight),
                  ),
                )
              : Container(),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: SBUTextComponent(
                text: buttonNames[index],
                textType: SBUTextType.body3,
                textColorType: isDisabled
                    ? SBUTextColorType.disabled
                    : isError
                        ? SBUTextColorType.error
                        : SBUTextColorType.text01,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getReactionWidget(
    BaseChannel? channel,
    BaseMessage? message,
    bool isLightTheme,
  ) {
    if (!SBUReactionManager().isReactionAvailable(channel, message)) {
      return Container();
    }

    final emojiList = SBUReactionManager().getEmojiList();
    final isExpandableEmoji = emojiList.length >= 7;

    if (emojiList.isEmpty) {
      return Container();
    }

    return Container(
      margin: EdgeInsets.only(left: 12.w, top: 12.h, right: 12.w, bottom: 16.h),
      height: 44.h,
      child: Row(
        children: [
          ...emojiList
              .map(
                (emoji) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          Navigator.pop(context);
                          SBUReactionManager()
                              .toggleReaction(channel, message, emoji.key);
                        },
                        child: Container(
                          decoration: message!.reactions!.any((reaction) {
                            final userId = SendbirdChat.currentUser?.userId;
                            if (reaction.key == emoji.key &&
                                userId != null &&
                                reaction.userIds.contains(userId)) {
                              return true;
                            }
                            return false;
                          })
                              ? BoxDecoration(
                                  borderRadius: BorderRadius.circular(8.r),
                                  color: isLightTheme
                                      ? SBUColors.primaryExtraLight
                                      : SBUColors.primaryDark)
                              : null,
                          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 3.h),
                          width: 44.r,
                          height: 44.r,
                          child: SBUImageComponent(
                            imageUrl: emoji.url,
                            cacheKey: emoji.key,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              )
              .take(isExpandableEmoji ? 5 : emojiList.length)
              .toList(),
          if (isExpandableEmoji)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    Navigator.pop(context);
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8.r),
                          topRight: Radius.circular(8.r),
                        ),
                      ),
                      builder: (context) {
                        return SBUBottomSheetReactionAddComponent(
                          channel: channel,
                          message: message,
                        );
                      },
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 3.h),
                    child: SBUIconComponent(
                      iconSize: 38.r,
                      iconData: SBUIcons.emoji,
                      iconColor: isLightTheme
                          ? SBUColors.lightThemeTextLowEmphasis
                          : SBUColors.darkThemeTextLowEmphasis,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
