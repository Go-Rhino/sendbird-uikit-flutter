// Copyright (c) 2024 Sendbird, Inc. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';
import 'package:sendbird_uikit/sendbird_uikit.dart';
import 'package:sendbird_uikit/src/internal/component/base/sbu_base_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_text_component.dart';
import 'package:sendbird_uikit/src/internal/resource/sbu_text_styles.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SBUReactionMemberListItemComponent extends SBUStatefulComponent {
  final double width;
  final double height;
  final Color backgroundColor;
  final User user;

  const SBUReactionMemberListItemComponent({
    required this.width,
    required this.height,
    required this.backgroundColor,
    required this.user,
    super.key,
  });

  @override
  State<StatefulWidget> createState() =>
      SBUReactionMemberListItemComponentState();
}

class SBUReactionMemberListItemComponentState
    extends State<SBUReactionMemberListItemComponent> {
  @override
  Widget build(BuildContext context) {
    final isLightTheme = context.watch<SBUThemeProvider>().isLight();
    final strings = context.watch<SBUStringProvider>().strings;

    final width = widget.width;
    final height = widget.height;
    final backgroundColor = widget.backgroundColor;
    final user = widget.user;

    String name = widget.getNickname(user, strings);
    if (user.userId == SendbirdChat.currentUser?.userId) {
      name += ' (${strings.you})';
    }

    final item = Container(
      width: width,
      height: height,
      color: backgroundColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:  EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            child: widget.getAvatarComponent(
              isLightTheme: isLightTheme,
              size: 36,
              user: user,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: 16.w),
                    child: Row(
                      children: [
                        Expanded(
                          child: SBUTextComponent(
                            text: name,
                            textType: SBUTextType.subtitle2,
                            textColorType: SBUTextColorType.text01,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return item;
  }
}
