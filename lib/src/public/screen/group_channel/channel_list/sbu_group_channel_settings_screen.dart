// Copyright (c) 2024 Sendbird, Inc. All rights reserved.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';
import 'package:sendbird_uikit/sendbird_uikit.dart';
import 'package:sendbird_uikit/src/internal/component/base/sbu_base_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_bottom_sheet_menu_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_dialog_input_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_dialog_menu_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_icon_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_text_button_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_text_component.dart';
import 'package:sendbird_uikit/src/internal/component/module/sbu_header_component.dart';
import 'package:sendbird_uikit/src/internal/resource/sbu_text_styles.dart';
import 'package:sendbird_uikit/src/internal/utils/sbu_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// SBUGroupChannelSettingsScreen
class SBUGroupChannelSettingsScreen extends SBUStatefulComponent {
  final Future<bool> Function(bool isPushNotificationsOn)? setPushNotifications;
  final void Function(String nickname)? onNicknameChanged;

  const SBUGroupChannelSettingsScreen({
    this.setPushNotifications,
    this.onNicknameChanged,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => SBUGroupChannelSettingsScreenState();
}

class SBUGroupChannelSettingsScreenState
    extends State<SBUGroupChannelSettingsScreen> {
  bool isPushNotificationsOn = SBUPreferences().getPushNotifications();
  bool isDoNotDisturbOn = SBUPreferences().getDoNotDisturb();

  @override
  void initState() {
    super.initState();

    runZonedGuarded(() {
      SendbirdChat.getDoNotDisturb().then((value) async {
        await SBUPreferences().setDoNotDisturb(value.isDoNotDisturbOn);
        if (mounted) {
          setState(() {
            isDoNotDisturbOn = value.isDoNotDisturbOn;
          });
        }
      });
    }, (error, stack) {
      // TODO: Check error
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLightTheme = context.watch<SBUThemeProvider>().isLight();
    final strings = context.watch<SBUStringProvider>().strings;

    final currentUser = SendbirdChat.currentUser;

    final header = SBUHeaderComponent(
      width: double.maxFinite,
      height: 56.h,
      backgroundColor:
          isLightTheme ? SBUColors.background50 : SBUColors.background500,
      title: SBUTextComponent(
        text: strings.settings,
        textType: SBUTextType.heading1,
        textColorType: SBUTextColorType.text01,
      ),
      hasBackKey: false,
      textButton: SBUTextButtonComponent(
        height: 32.h,
        text: SBUTextComponent(
          text: strings.edit,
          textType: SBUTextType.button,
          textColorType: SBUTextColorType.primary,
        ),
        onButtonClicked: () async {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape:  RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8.r),
                topRight: Radius.circular(8.r),
              ),
            ),
            builder: (context) {
              return SBUBottomSheetMenuComponent(
                buttonNames: [
                  strings.changeNickname,
                  if (widget.canGetPhotoFile()) strings.changeProfileImage,
                ],
                onButtonClicked: (buttonName) async {
                  if (buttonName == strings.changeNickname) {
                    await showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (context) => SBUDialogInputComponent(
                        title: strings.changeNickname,
                        initialText: currentUser?.nickname,
                        onCancelButtonClicked: () {
                          // Cancel
                        },
                        onSaveButtonClicked: (enteredText) async {
                          runZonedGuarded(() async {
                            await SendbirdChat.updateCurrentUserInfo(
                              nickname: enteredText,
                            );

                            if (widget.onNicknameChanged != null) {
                              widget.onNicknameChanged!(enteredText);
                            }

                            if (mounted) {
                              setState(() {});
                            }
                          }, (error, stack) {
                            // TODO: Check error
                          });
                        },
                      ),
                    );
                  } else if (buttonName == strings.changeProfileImage) {
                    await showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (context) => SBUDialogMenuComponent(
                        title: strings.changeProfileImage,
                        buttonNames: [
                          if (widget.canTakePhoto()) strings.takePhoto,
                          if (widget.canChoosePhoto()) strings.choosePhoto,
                        ],
                        onButtonClicked: (buttonName) async {
                          FileInfo? fileInfo;
                          if (buttonName == strings.takePhoto) {
                            fileInfo = await SendbirdUIKit().takePhoto!();
                          } else if (buttonName == strings.choosePhoto) {
                            fileInfo = await SendbirdUIKit().choosePhoto!();
                          }

                          if (fileInfo != null) {
                            runZonedGuarded(() async {
                              await SendbirdChat.updateCurrentUserInfo(
                                  profileFileInfo: fileInfo);

                              if (mounted) {
                                setState(() {});
                              }
                            }, (error, stack) {
                              // TODO: Check error
                            });
                          }
                        },
                      ),
                    );
                  }
                },
              );
            },
          );
        },
        padding:  EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      ),
    );

    final darkThemeSwitch = Switch(
      value: !isLightTheme,
      onChanged: (value) async {
        await SBUThemeProvider()
            .setTheme(value ? SBUTheme.dark : SBUTheme.light);
      },
      activeColor: SBUColors.primaryMain,
      activeTrackColor: SBUColors.primaryLight,
      inactiveThumbColor: SBUColors.background200,
      inactiveTrackColor: SBUColors.background300,
    );

    final pushNotificationsSwitch = Switch(
      value: isPushNotificationsOn,
      onChanged: (value) async {
        if (widget.setPushNotifications != null) {
          runZonedGuarded(() async {
            if (await widget.setPushNotifications!(value)) {
              await SBUPreferences().setPushNotifications(value);

              if (mounted) {
                setState(() {
                  isPushNotificationsOn = value;
                });
              }
            }
          }, (error, stack) {
            // TODO: Check error
          });
        }
      },
      activeColor: SBUColors.primaryMain,
      activeTrackColor: SBUColors.primaryLight,
      inactiveThumbColor: SBUColors.background200,
      inactiveTrackColor: SBUColors.background300,
    );

    final doNotDisturbSwitch = Switch(
      value: isDoNotDisturbOn,
      onChanged: (value) async {
        runZonedGuarded(() async {
          await SendbirdChat.setDoNotDisturb(enable: value);
          await SBUPreferences().setDoNotDisturb(value);

          if (mounted) {
            setState(() {
              isDoNotDisturbOn = value;
            });
          }
        }, (error, stack) {
          // TODO: Check error
        });
      },
      activeColor: SBUColors.primaryMain,
      activeTrackColor: SBUColors.primaryLight,
      inactiveThumbColor: SBUColors.background200,
      inactiveTrackColor: SBUColors.background300,
    );

    return Container(
      width: double.maxFinite,
      height: double.maxFinite,
      color: isLightTheme ? SBUColors.background50 : SBUColors.background600,
      child: Column(
        children: [
          header,
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.maxFinite,
                color: isLightTheme
                    ? SBUColors.background50
                    : SBUColors.background600,
                child: currentUser != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 24.h, bottom: 12.h),
                            child: Center(
                              child: widget.getAvatarComponent(
                                isLightTheme: isLightTheme,
                                size: 80.r,
                                user: currentUser,
                              ),
                            ),
                          ),
                          Padding(
                            padding:  EdgeInsets.only(
                                left: 16.w, right: 16.w, bottom: 23.h),
                            child: Center(
                              child: SBUTextComponent(
                                text: widget.getNickname(currentUser, strings),
                                textType: SBUTextType.heading1,
                                textColorType: SBUTextColorType.text01,
                              ),
                            ),
                          ),
                          _line(isLightTheme),
                          Padding(
                            padding: EdgeInsets.only(
                                left: 16.w, top: 16.h, right: 16.w, bottom: 15.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SBUTextComponent(
                                  text: strings.userId,
                                  textType: SBUTextType.body2,
                                  textColorType: SBUTextColorType.text02,
                                ),
                                SizedBox(height: 4.h),
                                SBUTextComponent(
                                  text: currentUser.userId,
                                  textType: SBUTextType.body3,
                                  textColorType: SBUTextColorType.text01,
                                ),
                              ],
                            ),
                          ),
                          _line(isLightTheme),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                darkThemeSwitch
                                    .onChanged!(!darkThemeSwitch.value);
                              },
                              child: Padding(
                                padding: EdgeInsets.only(
                                    left: 16.w, top: 16.h, right: 16.w, bottom: 15.h),
                                child: Row(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(right: 16.w),
                                      child: Container(
                                        width: 24.r,
                                        height: 24.r,
                                        decoration: BoxDecoration(
                                          color: isLightTheme
                                              ? SBUColors.background600
                                              : SBUColors.background300,
                                          borderRadius:
                                              BorderRadius.circular(12.r),
                                        ),
                                        alignment: AlignmentDirectional.center,
                                        child: SBUIconComponent(
                                          iconSize: 13.71.r,
                                          iconData: SBUIcons.theme,
                                          iconColor: isLightTheme
                                              ? SBUColors
                                                  .darkThemeTextHighEmphasis
                                              : SBUColors
                                                  .lightThemeTextHighEmphasis,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: SBUTextComponent(
                                        text: strings.darkTheme,
                                        textType: SBUTextType.subtitle2,
                                        textColorType: SBUTextColorType.text01,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(left: 8.w),
                                      child: SizedBox(
                                        height: 24.r,
                                        child: darkThemeSwitch,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          _line(isLightTheme),
                          if (!kIsWeb && widget.setPushNotifications != null)
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  pushNotificationsSwitch.onChanged!(
                                      !pushNotificationsSwitch.value);
                                },
                                child: Padding(
                                  padding:  EdgeInsets.only(
                                      left: 16.w, top: 16.h, right: 16.w, bottom: 15.h),
                                  child: Row(
                                    children: [
                                      Padding(
                                        padding:
                                            EdgeInsets.only(right: 16.w),
                                        child: Container(
                                          width: 24.r,
                                          height: 24.r,
                                          decoration: BoxDecoration(
                                            color: isLightTheme
                                                ? SBUColors.secondaryMain
                                                : SBUColors.secondaryLight,
                                            borderRadius:
                                                BorderRadius.circular(12.r),
                                          ),
                                          alignment:
                                              AlignmentDirectional.center,
                                          child: SBUIconComponent(
                                            iconSize: 13.71.r,
                                            iconData:
                                                SBUIcons.notificationsFilled,
                                            iconColor: isLightTheme
                                                ? SBUColors
                                                    .darkThemeTextHighEmphasis
                                                : SBUColors
                                                    .lightThemeTextHighEmphasis,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: SBUTextComponent(
                                          text: strings.pushNotifications,
                                          textType: SBUTextType.subtitle2,
                                          textColorType:
                                              SBUTextColorType.text01,
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(left: 8.w),
                                        child: SizedBox(
                                          height: 24.r,
                                          child: pushNotificationsSwitch,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (!kIsWeb && widget.setPushNotifications != null)
                            _line(isLightTheme),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                doNotDisturbSwitch
                                    .onChanged!(!doNotDisturbSwitch.value);
                              },
                              child: Padding(
                                padding: EdgeInsets.only(
                                    left: 16.w, top: 16.h, right: 16.w, bottom: 15.h),
                                child: Row(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(right: 16.w),
                                      child: Container(
                                        width: 24.r,
                                        height: 24.r,
                                        decoration: BoxDecoration(
                                          color: isLightTheme
                                              ? SBUColors.secondaryMain
                                              : SBUColors.secondaryLight,
                                          borderRadius:
                                              BorderRadius.circular(12.r),
                                        ),
                                        alignment: AlignmentDirectional.center,
                                        child: SBUIconComponent(
                                          iconSize: 13.71.r,
                                          iconData:
                                              SBUIcons.notificationsFilled,
                                          iconColor: isLightTheme
                                              ? SBUColors
                                                  .darkThemeTextHighEmphasis
                                              : SBUColors
                                                  .lightThemeTextHighEmphasis,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: SBUTextComponent(
                                        text: strings.doNotDisturb,
                                        textType: SBUTextType.subtitle2,
                                        textColorType: SBUTextColorType.text01,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(left: 8.w),
                                      child: SizedBox(
                                        height: 24.r,
                                        child: doNotDisturbSwitch,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          _line(isLightTheme),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                Navigator.pop(context);
                              },
                              child: Padding(
                                padding: EdgeInsets.only(
                                    left: 16.w, top: 16.h, right: 16.w, bottom: 15.h),
                                child: Row(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(right: 16.w),
                                      child: Container(
                                        width: 24.r,
                                        height: 24.r,
                                        decoration: BoxDecoration(
                                          color: isLightTheme
                                              ? SBUColors.errorMain
                                              : SBUColors.errorLight,
                                          borderRadius:
                                              BorderRadius.circular(12.r),
                                        ),
                                        alignment: AlignmentDirectional.center,
                                        child: SBUIconComponent(
                                          iconSize: 13.71.r,
                                          iconData: SBUIcons.leave,
                                          iconColor: isLightTheme
                                              ? SBUColors
                                                  .darkThemeTextHighEmphasis
                                              : SBUColors
                                                  .lightThemeTextHighEmphasis,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: SBUTextComponent(
                                        text: strings.exitToHome,
                                        textType: SBUTextType.subtitle2,
                                        textColorType: SBUTextColorType.text01,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          _line(isLightTheme),
                        ],
                      )
                    : Container(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(bool isLightTheme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        height: 1,
        color: isLightTheme
            ? SBUColors.lightThemeTextDisabled
            : SBUColors.darkThemeTextDisabled,
      ),
    );
  }
}
