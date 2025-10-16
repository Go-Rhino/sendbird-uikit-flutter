// Copyright (c) 2024 Sendbird, Inc. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sendbird_uikit/sendbird_uikit.dart';
import 'package:sendbird_uikit/src/internal/component/base/sbu_base_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_text_button_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_text_component.dart';
import 'package:sendbird_uikit/src/internal/resource/sbu_text_styles.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SBUDialogInputComponent extends SBUStatefulComponent {
  final String title;
  final String? initialText;
  final void Function() onCancelButtonClicked;
  final void Function(String enteredText) onSaveButtonClicked;

  const SBUDialogInputComponent({
    required this.title,
    this.initialText,
    required this.onCancelButtonClicked,
    required this.onSaveButtonClicked,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => SBUDialogInputComponentState();
}

class SBUDialogInputComponentState extends State<SBUDialogInputComponent> {
  final textEditingController = TextEditingController();
  final textFieldFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    textEditingController.text = widget.initialText ?? '';
    textFieldFocusNode.requestFocus();
  }

  @override
  void dispose() {
    textEditingController.dispose();
    textFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<SBUThemeProvider>();
    final theme = themeProvider.theme;
    final isLightTheme = themeProvider.isLight();
    final strings = context.watch<SBUStringProvider>().strings;

    final title = widget.title;
    final onCancelButtonClicked = widget.onCancelButtonClicked;
    final onSaveButtonClicked = widget.onSaveButtonClicked;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      backgroundColor:
          isLightTheme ? SBUColors.background50 : SBUColors.background500,
      child: Padding(
        padding: EdgeInsets.only(top: 24.h, bottom: 12.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 24.w, right: 24.w, bottom: 24.h),
              child: SBUTextComponent(
                text: title,
                textType: SBUTextType.heading1,
                textColorType: SBUTextColorType.text01,
              ),
            ),
            Container(
              height: 38.h,
              padding: EdgeInsets.only(left: 24.w, right: 24.w),
              alignment: AlignmentDirectional.centerStart,
              child: TextField(
                controller: textEditingController,
                decoration: InputDecoration.collapsed(
                  hintText: strings.enterMessage,
                  hintStyle: SBUTextStyles.getTextStyle(
                    theme: theme,
                    textType: SBUTextType.body3,
                    textColorType: SBUTextColorType.text03,
                  ),
                ),
                style: SBUTextStyles.getTextStyle(
                  theme: theme,
                  textType: SBUTextType.body3,
                  textColorType: SBUTextColorType.text01,
                ),
                focusNode: textFieldFocusNode,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Container(
                height: 2.h,
                color: isLightTheme
                    ? SBUColors.primaryMain
                    : SBUColors.primaryLight,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 24.h, right: 12.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 8.w),
                    child: SBUTextButtonComponent(
                      height: 32.h,
                      text: SBUTextComponent(
                        text: strings.cancel,
                        textType: SBUTextType.button,
                        textColorType: SBUTextColorType.primary,
                      ),
                      onButtonClicked: () {
                        Navigator.pop(context);
                        onCancelButtonClicked();
                      },
                      padding: EdgeInsets.symmetric(horizontal:  8.w, vertical: 8.h,),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 8.w),
                    child: SBUTextButtonComponent(
                      height: 32.h,
                      text: SBUTextComponent(
                        text: strings.save,
                        textType: SBUTextType.button,
                        textColorType: SBUTextColorType.primary,
                      ),
                      onButtonClicked: () {
                        final enteredText = textEditingController.text;
                        Navigator.pop(context);
                        onSaveButtonClicked(enteredText);
                      },
                      padding: EdgeInsets.symmetric(horizontal:  8.w, vertical: 8.h,),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
