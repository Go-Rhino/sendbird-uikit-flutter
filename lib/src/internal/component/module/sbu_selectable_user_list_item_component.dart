// Copyright (c) 2024 Sendbird, Inc. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';
import 'package:sendbird_uikit/sendbird_uikit.dart';
import 'package:sendbird_uikit/src/internal/component/base/sbu_base_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_icon_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_text_component.dart';
import 'package:sendbird_uikit/src/internal/resource/sbu_text_styles.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SBUSelectableUserListItemComponent extends SBUStatefulComponent {
  final double width;
  final double height;
  final Color backgroundColor;
  final bool isChecked;
  final User user;
  final void Function(bool isChecked, User user) onListItemCheckChanged;

  const SBUSelectableUserListItemComponent({
    required this.width,
    required this.height,
    required this.backgroundColor,
    required this.isChecked,
    required this.user,
    required this.onListItemCheckChanged,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => SBUUserListItemComponentState();
}

class SBUUserListItemComponentState
    extends State<SBUSelectableUserListItemComponent> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    final isLightTheme = context.watch<SBUThemeProvider>().isLight();
    final strings = context.watch<SBUStringProvider>().strings;

    final width = widget.width;
    final height = widget.height;
    final backgroundColor = widget.backgroundColor;
    _isChecked = widget.isChecked;
    final user = widget.user;
    final onListItemCheckChanged = widget.onListItemCheckChanged;

    final item = Container(
      width: width,
      height: height,
      color: backgroundColor,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (mounted) {
              setState(() {
                _isChecked = !_isChecked;
              });
            }
            onListItemCheckChanged(_isChecked, user);
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                child: widget.getAvatarComponent(
                  isLightTheme: isLightTheme,
                  size: 36.r,
                  user: user,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: 12.w),
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(right: 4.w),
                                child: SBUTextComponent(
                                  text: widget.getNickname(user, strings),
                                  textType: SBUTextType.subtitle2,
                                  textColorType: SBUTextColorType.text01,
                                ),
                              ),
                            ),
                            _isChecked
                                ? Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 8.h),
                                    child: SBUIconComponent(
                                      iconSize: 24.r,
                                      iconData: SBUIcons.checkboxOn,
                                      iconColor: isLightTheme
                                          ? SBUColors.primaryMain
                                          : SBUColors.primaryLight,
                                    ),
                                  )
                                : Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 8.h),
                                    child: SBUIconComponent(
                                      iconSize: 24.r,
                                      iconData: SBUIcons.checkboxOff,
                                      iconColor: isLightTheme
                                          ? SBUColors.lightThemeTextLowEmphasis
                                          : SBUColors.darkThemeTextLowEmphasis,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                    Divider(
                      height: 1.h,
                      thickness: 1.h,
                      color: isLightTheme
                          ? SBUColors.lightThemeTextDisabled
                          : SBUColors.darkThemeTextDisabled,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return item;
  }
}
