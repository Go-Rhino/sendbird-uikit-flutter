// Copyright (c) 2024 Sendbird, Inc. All rights reserved.

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';
import 'package:sendbird_uikit/sendbird_uikit.dart';
import 'package:sendbird_uikit/src/internal/component/base/sbu_base_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_bottom_sheet_menu_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_bottom_sheet_user_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_dialog_menu_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_file_icon_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_icon_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_reaction_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_text_component.dart';
import 'package:sendbird_uikit/src/internal/provider/sbu_message_collection_provider.dart';
import 'package:sendbird_uikit/src/internal/resource/sbu_text_styles.dart';
import 'package:sendbird_uikit/src/internal/utils/sbu_mark_as_unread_manager.dart';
import 'package:sendbird_uikit/src/internal/utils/sbu_ogtag_manager.dart';
import 'package:sendbird_uikit/src/internal/utils/sbu_reaction_manager.dart';
import 'package:sendbird_uikit/src/internal/utils/sbu_reply_manager.dart';
import 'package:sendbird_uikit/src/internal/utils/sbu_thumbnail_manager.dart';

class SBUMessageListItemComponent extends SBUStatefulComponent {
  final int messageCollectionNo;
  final List<BaseMessage> messageList;
  final int messageIndex;
  final void Function(GroupChannel)? on1On1ChannelCreated;
  final void Function(GroupChannel, BaseMessage)? onListItemClicked;
  final void Function(BaseMessage)? onParentMessageClicked;
  final void Function(User)? onUserIconClicked;

  const SBUMessageListItemComponent({
    required this.messageCollectionNo,
    required this.messageList,
    required this.messageIndex,
    this.on1On1ChannelCreated,
    this.onListItemClicked,
    this.onParentMessageClicked,
    this.onUserIconClicked,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => SBUMessageListItemComponentState();
}

class SBUMessageListItemComponentState
    extends State<SBUMessageListItemComponent> {
  final double imageWidth = 240.w;
  final double imageHeight = 160.h;

  late bool isReactionAvailable;
  late bool isOGTagEnabled;

  @override
  Widget build(BuildContext context) {
    // MARK: rhino updated (set theme to always light for now)
    final isLightTheme = true; //context.watch<SBUThemeProvider>().isLight();
    final strings = context.watch<SBUStringProvider>().strings;

    final collectionProvider = SBUMessageCollectionProvider();
    final collection = collectionProvider.getCollection(
      widget.messageCollectionNo,
    )!; // Check

    final messageList = widget.messageList;
    final messageIndex = widget.messageIndex;
    final message = messageList[messageIndex];

    final isSameDayAtPreviousMessage = _isSameDayAtPreviousMessage(
      collection,
      messageList,
      messageIndex,
    );

    final hasNewMessageLine = SBUMarkAsUnreadManager().hasNewMessageLine(
      collection: collection,
      messageList: messageList,
      messageIndex: messageIndex,
    );

    isReactionAvailable = SBUReactionManager().isReactionAvailable(
      collection.channel,
      message,
    );

    final isMyMessage = _isMyMessage(message);

    Widget? messageWidget;
    if (message.messageType == MessageType.admin) {
      messageWidget = _adminMessageWidget(
        collection,
        messageList,
        messageIndex,
        message as AdminMessage,
        isLightTheme,
        strings,
      );
    } else if (message.messageType == MessageType.user) {
      if (isMyMessage) {
        messageWidget = _myUserMessageWidget(
          collection,
          messageList,
          messageIndex,
          message as UserMessage,
          isLightTheme,
          strings,
        );
      } else {
        messageWidget = _otherUserMessageWidget(
          collection,
          messageList,
          messageIndex,
          message as UserMessage,
          isLightTheme,
          strings,
        );
      }
    } else if (message.messageType == MessageType.file) {
      if (isMyMessage) {
        messageWidget = _myFileMessageWidget(
          collection,
          messageList,
          messageIndex,
          message as FileMessage,
          isLightTheme,
          strings,
        );
      } else {
        messageWidget = _otherFileMessageWidget(
          collection,
          messageList,
          messageIndex,
          message as FileMessage,
          isLightTheme,
          strings,
        );
      }
    }

    // MARK: rhino updated
    String formatPtBrTitleCase(DateTime date) {
      final raw = DateFormat('EEE, MMM dd').format(date); // "qua., out. 15"
      final noDots = raw.replaceAll('.', ''); // "qua, out 15"
      // Capitalize each word from the letters tokens:
      final pretty = noDots
          .split(' ')
          .map(
            (word) =>
                '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
          )
          .join(' ');

      return pretty; // "Qua, Out 15"
    }

    Widget messageWidgetWithDay = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (isSameDayAtPreviousMessage == false)
          Container(
            width: double.maxFinite,
            alignment: AlignmentDirectional.center,
            padding: EdgeInsets.only(
              top: messageIndex == messageList.length - 1 ? 16.h : 8.h,
              bottom: 8.h,
            ),
            child: Container(
              padding: EdgeInsets.only(
                left: 10.w,
                top: 4.h,
                right: 10.w,
                bottom: 4.h,
              ),
              decoration: BoxDecoration(
                color: isLightTheme
                    ? SBUColors.overlayLight
                    : SBUColors.overlayDark,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: SBUTextComponent(
                text: formatPtBrTitleCase(
                  DateTime.fromMillisecondsSinceEpoch(message.createdAt),
                ),
                textType: SBUTextType.caption1,
                textColorType: SBUTextColorType.messageDate,
              ),
            ),
          ),
        if (hasNewMessageLine) _newMessageLineWidget(isLightTheme, strings),
        if (messageWidget != null) messageWidget,
      ],
    );

    return messageWidget != null ? messageWidgetWithDay : Container();
  }

  Widget _newMessageLineWidget(bool isLightTheme, SBUStrings strings) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      // height: 12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              height: 1.h,
              color: isLightTheme
                  ? SBUColors.primaryMain
                  : SBUColors.primaryLight,
            ),
          ),
          SizedBox(width: 4.w),
          SBUTextComponent(
            text: strings.newMessages,
            textType: SBUTextType.caption3,
            textColorType: SBUTextColorType.primary,
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Container(
              height: 1.h,
              color: isLightTheme
                  ? SBUColors.primaryMain
                  : SBUColors.primaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _adminMessageWidget(
    MessageCollection collection,
    List<BaseMessage> messageList,
    int messageIndex,
    AdminMessage message,
    bool isLightTheme,
    SBUStrings strings,
  ) {
    return Container(
      width: double.maxFinite,
      alignment: AlignmentDirectional.center,
      padding: EdgeInsets.only(
        left: 30.w,
        top: 8.h,
        right: 30.w,
        bottom: (messageIndex == 0) ? 16.h : 8.h,
      ),
      child: SBUTextComponent(
        text: message.message,
        textType: SBUTextType.caption2,
        textColorType: SBUTextColorType.text02,
        textOverflowType: null,
        maxLines: null,
      ),
    );
  }

  Widget? _otherUserMessageWidget(
    MessageCollection collection,
    List<BaseMessage> messageList,
    int messageIndex,
    UserMessage message,
    bool isLightTheme,
    SBUStrings strings,
  ) {
    final isSameMinuteAtPreviousMessage = _isSameMinuteAtPreviousMessage(
      messageList,
      messageIndex,
    );
    final isSameMinuteAtNextMessage = _isSameMinuteAtNextMessage(
      messageList,
      messageIndex,
    );
    final timeString = _messageCreatedAtString(message);

    return _messageItemPadding(
      message: message,
      messageIndex: messageIndex,
      isSameMinuteAtPreviousMessage: isSameMinuteAtPreviousMessage,
      isSameMinuteAtNextMessage: isSameMinuteAtNextMessage,
      child: _replyToChannel(
        collection: collection,
        message: message,
        isSameMinuteAtPreviousMessage: isSameMinuteAtPreviousMessage,
        isSameMinuteAtNextMessage: isSameMinuteAtNextMessage,
        timeString: timeString,
        isLightTheme: isLightTheme,
        strings: strings,
        isMyMessage: false,
        child: _otherUserMessageItemWidget(
          collection: collection,
          message: message,
          isSameMinuteAtPreviousMessage: isSameMinuteAtPreviousMessage,
          isSameMinuteAtNextMessage: isSameMinuteAtNextMessage,
          timeString: timeString,
          isLightTheme: isLightTheme,
          strings: strings,
        ),
      ),
    );
  }

  Widget? _myUserMessageWidget(
    MessageCollection collection,
    List<BaseMessage> messageList,
    int messageIndex,
    UserMessage message,
    bool isLightTheme,
    SBUStrings strings,
  ) {
    final isSameMinuteAtPreviousMessage = _isSameMinuteAtPreviousMessage(
      messageList,
      messageIndex,
    );
    final isSameMinuteAtNextMessage = _isSameMinuteAtNextMessage(
      messageList,
      messageIndex,
    );
    final timeString = _messageCreatedAtString(message);

    return _messageItemPadding(
      message: message,
      messageIndex: messageIndex,
      isSameMinuteAtPreviousMessage: isSameMinuteAtPreviousMessage,
      isSameMinuteAtNextMessage: isSameMinuteAtNextMessage,
      child: _replyToChannel(
        collection: collection,
        message: message,
        isSameMinuteAtPreviousMessage: isSameMinuteAtPreviousMessage,
        isSameMinuteAtNextMessage: isSameMinuteAtNextMessage,
        timeString: timeString,
        isLightTheme: isLightTheme,
        strings: strings,
        isMyMessage: true,
        child: _myUserMessageItemWidget(
          collection: collection,
          message: message,
          isSameMinuteAtPreviousMessage: isSameMinuteAtPreviousMessage,
          isSameMinuteAtNextMessage: isSameMinuteAtNextMessage,
          timeString: timeString,
          isLightTheme: isLightTheme,
          strings: strings,
        ),
      ),
    );
  }

  Widget? _otherFileMessageWidget(
    MessageCollection collection,
    List<BaseMessage> messageList,
    int messageIndex,
    FileMessage message,
    bool isLightTheme,
    SBUStrings strings,
  ) {
    final isSameMinuteAtPreviousMessage = _isSameMinuteAtPreviousMessage(
      messageList,
      messageIndex,
    );
    final isSameMinuteAtNextMessage = _isSameMinuteAtNextMessage(
      messageList,
      messageIndex,
    );
    final timeString = _messageCreatedAtString(message);

    return _messageItemPadding(
      message: message,
      messageIndex: messageIndex,
      isSameMinuteAtPreviousMessage: isSameMinuteAtPreviousMessage,
      isSameMinuteAtNextMessage: isSameMinuteAtNextMessage,
      child: _replyToChannel(
        collection: collection,
        message: message,
        isSameMinuteAtPreviousMessage: isSameMinuteAtPreviousMessage,
        isSameMinuteAtNextMessage: isSameMinuteAtNextMessage,
        timeString: timeString,
        isLightTheme: isLightTheme,
        strings: strings,
        isMyMessage: false,
        child: _otherFileMessageItemWidget(
          collection: collection,
          message: message,
          isSameMinuteAtPreviousMessage: isSameMinuteAtPreviousMessage,
          isSameMinuteAtNextMessage: isSameMinuteAtNextMessage,
          timeString: timeString,
          isLightTheme: isLightTheme,
          strings: strings,
        ),
      ),
    );
  }

  Widget? _myFileMessageWidget(
    MessageCollection collection,
    List<BaseMessage> messageList,
    int messageIndex,
    FileMessage message,
    bool isLightTheme,
    SBUStrings strings,
  ) {
    final isSameMinuteAtPreviousMessage = _isSameMinuteAtPreviousMessage(
      messageList,
      messageIndex,
    );
    final isSameMinuteAtNextMessage = _isSameMinuteAtNextMessage(
      messageList,
      messageIndex,
    );
    final timeString = _messageCreatedAtString(message);

    return _messageItemPadding(
      message: message,
      messageIndex: messageIndex,
      isSameMinuteAtPreviousMessage: isSameMinuteAtPreviousMessage,
      isSameMinuteAtNextMessage: isSameMinuteAtNextMessage,
      child: _replyToChannel(
        collection: collection,
        message: message,
        isSameMinuteAtPreviousMessage: isSameMinuteAtPreviousMessage,
        isSameMinuteAtNextMessage: isSameMinuteAtNextMessage,
        timeString: timeString,
        isLightTheme: isLightTheme,
        strings: strings,
        isMyMessage: true,
        child: _myFileMessageItemWidget(
          collection: collection,
          message: message,
          isSameMinuteAtPreviousMessage: isSameMinuteAtPreviousMessage,
          isSameMinuteAtNextMessage: isSameMinuteAtNextMessage,
          timeString: timeString,
          isLightTheme: isLightTheme,
          strings: strings,
        ),
      ),
    );
  }

  bool _isMyMessage(BaseMessage message) {
    final senderId = message.sender?.userId;
    final isMyMessage =
        (senderId != null && senderId == SendbirdChat.currentUser?.userId) ||
        (senderId == null) ||
        (message.sendingStatus == SendingStatus.failed);
    return isMyMessage;
  }

  bool _isSameDayAtPreviousMessage(
    MessageCollection collection,
    List<BaseMessage> messageList,
    int messageIndex,
  ) {
    final message = messageList[messageIndex];

    if (messageIndex == messageList.length - 1) {
      if (collection.isLoading) {
        return true; // Do not draw date.
      }

      // reverse
      if (collection.hasPrevious) {
        return true; // Do not draw date.
      }
    }

    // reverse
    if (messageIndex + 1 < messageList.length) {
      final prevMessage = messageList[messageIndex + 1];
      return _isSameDay(message.createdAt, prevMessage.createdAt);
    }
    return false;
  }

  bool _isSameDay(int ts1, int ts2) {
    final dt1 = DateTime.fromMillisecondsSinceEpoch(ts1);
    final dt2 = DateTime.fromMillisecondsSinceEpoch(ts2);

    if (dt1.year == dt2.year && dt1.month == dt2.month && dt1.day == dt2.day) {
      return true;
    }
    return false;
  }

  bool _isSameMinuteAtPreviousMessage(
    List<BaseMessage> messageList,
    int messageIndex,
  ) {
    final message = messageList[messageIndex];

    // reverse
    if (messageIndex + 1 < messageList.length) {
      final prevMessage = messageList[messageIndex + 1];
      return _isSameMinute(message.createdAt, prevMessage.createdAt) &&
          _isSameSender(message, prevMessage);
    }
    return false;
  }

  bool _isSameMinuteAtNextMessage(
    List<BaseMessage> messageList,
    int messageIndex,
  ) {
    final message = messageList[messageIndex];

    // reverse
    if (messageIndex - 1 >= 0) {
      final nextMessage = messageList[messageIndex - 1];
      return _isSameMinute(message.createdAt, nextMessage.createdAt) &&
          _isSameSender(message, nextMessage);
    }
    return false;
  }

  bool _isSameMinute(int ts1, int ts2) {
    final dt1 = DateTime.fromMillisecondsSinceEpoch(ts1);
    final dt2 = DateTime.fromMillisecondsSinceEpoch(ts2);

    if (dt1.year == dt2.year &&
        dt1.month == dt2.month &&
        dt1.day == dt2.day &&
        dt1.hour == dt2.hour &&
        dt1.minute == dt2.minute) {
      return true;
    }
    return false;
  }

  bool _isSameSender(BaseMessage m1, BaseMessage m2) {
    return m1.sender?.userId == m2.sender?.userId;
  }

  Widget? _getThumbnail({
    required FileMessage message,
    required bool isLightTheme,
    required bool isParentMessage,
  }) {
    final fileType = widget.getFileType(message);

    Widget? thumbnailWidget;
    if (fileType == SBUFileType.image || fileType == SBUFileType.video) {
      thumbnailWidget = SBUThumbnailManager().getThumbnail(
        message: message,
        fileType: fileType,
        isLightTheme: isLightTheme,
        addGifIcon: true,
        isParentMessage: isParentMessage,
      );

      final size = isParentMessage ? 31.2.r : 48.r;
      final iconSize = isParentMessage ? 18.2.r : 28.r;

      if (thumbnailWidget != null) {
        if (fileType == SBUFileType.image) {
          return thumbnailWidget;
        } else if (fileType == SBUFileType.video) {
          return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: imageWidth, // Check
                height: imageHeight,
                child: thumbnailWidget,
              ),
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
                iconData: SBUIcons.play,
                iconColor: SBUColors.lightThemeTextMidEmphasis,
              ),
            ],
          );
        }
      }
    }
    return null;
  }

  String _messageCreatedAtString(BaseMessage message) {
    // MARK: rhino updated
    // 24h format: HH:mm
    return DateFormat(
      'HH:mm',
    ).format(DateTime.fromMillisecondsSinceEpoch(message.createdAt));
  }

  Widget _fileWidget({
    required FileMessage message,
    required bool isLightTheme,
    required bool isMyMessage,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(right: 8.w),
          child: SBUFileIconComponent(
            size: 28.r,
            backgroundColor: isLightTheme
                ? SBUColors.background50
                : SBUColors.background600,
            iconSize: 24.r,
            iconData: SBUIcons.fileDocument,
            iconColor: isLightTheme
                ? SBUColors.primaryMain
                : SBUColors.primaryLight,
          ),
        ),
        Flexible(
          child: SBUTextComponent(
            text: message.name ?? '',
            textType: SBUTextType.body3,
            textColorType: isMyMessage
                ? SBUTextColorType.message
                : SBUTextColorType.text01,
            // SBUTextOverflowType.ellipsisMiddle
            textOverflowType: null,
            maxLines: null, // 1
          ),
        ),
      ],
    );
  }

  Widget _otherUserMessageItemWidget({
    required MessageCollection collection,
    required UserMessage message,
    required bool isSameMinuteAtPreviousMessage,
    required bool isSameMinuteAtNextMessage,
    required String timeString,
    required bool isLightTheme,
    required SBUStrings strings,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: EdgeInsets.only(right: 12.w, bottom: 2.h),
          child: (isSameMinuteAtNextMessage == false)
              ? Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(13.r),
                    onTap: () async {
                      final onUserIconClicked = widget.onUserIconClicked;
                      final sender = message.sender;
                      if (onUserIconClicked != null) {
                        if (sender != null) {
                          onUserIconClicked(sender);
                          return;
                        }
                      }

                      if (sender != null) {
                        widget.unfocus();
                        final themeProvider = context.read<SBUThemeProvider>();
                        final stringProvider = context
                            .read<SBUStringProvider>();

                        await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8.r),
                              topRight: Radius.circular(8.r),
                            ),
                          ),
                          builder: (innerContext) {
                            return MultiProvider(
                              providers: [
                                ChangeNotifierProvider.value(
                                  value: themeProvider,
                                ),
                                ChangeNotifierProvider.value(
                                  value: stringProvider,
                                ),
                              ],
                              child: SBUBottomSheetUserComponent(
                                user: sender,
                                on1On1ChannelCreated:
                                    widget.on1On1ChannelCreated,
                              ),
                            );
                          },
                        );
                      }
                    },
                    child: widget.getAvatarComponent(
                      isLightTheme: isLightTheme,
                      size: 26.r,
                      user: message.sender,
                    ),
                  ),
                )
              : SizedBox(width: 26.w),
        ),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSameMinuteAtPreviousMessage == false)
                if (message.isReplyToChannel == false &&
                    message.parentMessageId == null)
                  Padding(
                    padding: EdgeInsets.only(left: 12.w, bottom: 4.h),
                    child: SBUTextComponent(
                      // text: widget.getNickname(message.sender, strings),
                      text: 'Test driver name',
                      textType: SBUTextType.caption1,
                      textColorType: SBUTextColorType.text02,
                    ),
                  ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16.r),
                  onTap: () async {
                    if (widget.onListItemClicked != null) {
                      widget.onListItemClicked!(collection.channel, message);
                    }
                  },
                  onLongPress: () => 
                    widget.onListItemClicked?.call(collection.channel, message),
                  child:
                      SBUOGTagManager().getOGTagMessageItemWidget(
                        message: message,
                        collection: collection,
                        isLightTheme: isLightTheme,
                        strings: strings,
                        isMyMessage: false,
                      ) ??
                      Container(
                        padding: EdgeInsets.only(top: 6.h),
                        decoration: BoxDecoration(
                          color: isLightTheme
                              ? SBUColors.background100
                              : SBUColors.background400,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: 12.w,
                            right: 12.w,
                            bottom: 6.h,
                          ),
                          child: SBUTextComponent(
                              text: message.message,
                              textType: SBUTextType.body3,
                              textColorType: SBUTextColorType.text01,
                              textOverflowType: null,
                              maxLines: null,
                            ),
                        ),
                      ),
                ),
              ),
              Container(
                height: 16.h,
                alignment: AlignmentDirectional.center,
                padding: EdgeInsets.only(left: 4.w),
                child: SBUTextComponent(
                  text: timeString,
                  textType: SBUTextType.caption4,
                  textColorType: SBUTextColorType.text03,
                  transparent: isSameMinuteAtNextMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _myUserMessageItemWidget({
    required MessageCollection collection,
    required UserMessage message,
    required bool isSameMinuteAtPreviousMessage,
    required bool isSameMinuteAtNextMessage,
    required String timeString,
    required bool isLightTheme,
    required SBUStrings strings,
  }) {
    final readStatusIcon = widget.getReadStatusIcon(
      collection.channel,
      message,
      isLightTheme,
    );
    final isDisabled = widget.isDisabled(collection.channel);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if ((message.sendingStatus?.isTimeAvailable ?? false) &&
            isSameMinuteAtNextMessage)
          Container(
            height: 16.h,
            alignment: AlignmentDirectional.center,
            padding: EdgeInsets.only(right: 4.w),
            child: SBUTextComponent(
              text: timeString,
              textType: SBUTextType.caption4,
              textColorType: SBUTextColorType.text03,
              transparent: isSameMinuteAtNextMessage,
            ),
          ),
        if (readStatusIcon != null)
          Padding(
            padding: EdgeInsets.only(right: 4.w, bottom: 2.h),
            child: readStatusIcon,
          ),
        if (message.sendingStatus == SendingStatus.pending)
          Padding(
            padding: EdgeInsets.only(right: 4.w, bottom: 2.h),
            child: SizedBox(
              width: 16.r,
              height: 16.r,
              child: CircularProgressIndicator(
                color: isLightTheme
                    ? SBUColors.primaryMain
                    : SBUColors.primaryLight,
                strokeWidth: 1.4,
              ),
            ),
          ),
        if (message.sendingStatus == SendingStatus.failed)
          Padding(
            padding: EdgeInsets.only(right: 4.w, bottom: 2.h),
            child: SBUIconComponent(
              iconSize: 16.r,
              iconData: SBUIcons.error,
              iconColor: isLightTheme
                  ? SBUColors.errorMain
                  : SBUColors.errorLight,
            ),
          ),
        if ((message.sendingStatus?.isTimeAvailable ?? false) &&
            isSameMinuteAtNextMessage == false)
          Container(
            height: 16.h,
            alignment: AlignmentDirectional.center,
            padding: EdgeInsets.only(right: 4.w),
            child: SBUTextComponent(
              text: timeString,
              textType: SBUTextType.caption4,
              textColorType: SBUTextColorType.text03,
            ),
          ),
        Flexible(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16.r),
              onTap: () async {
                if (widget.onListItemClicked != null) {
                  widget.onListItemClicked!(collection.channel, message);
                }
              },
              onLongPress: () async {
                widget.onListItemClicked?.call(collection.channel, message);
                return;
                if (message.sendingStatus == SendingStatus.succeeded) {
                  widget.unfocus();
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
                      return SBUBottomSheetMenuComponent(
                        channel: collection.channel,
                        message: message,
                        iconNames: [
                          SBUIcons.copy,
                          if (!isDisabled) SBUIcons.edit,
                          if (SBUMarkAsUnreadManager().isOn())
                            SBUIcons.markAsUnread,
                          if (!isDisabled)
                            if (SBUMessageCollectionProvider().canDeleteMessage(
                              widget.messageCollectionNo,
                              message,
                            ))
                              SBUIcons.delete,
                          if (SBUReplyManager().isQuoteReplyAvailable(
                            collection.channel,
                          ))
                            SBUIcons.reply,
                        ],
                        buttonNames: [
                          strings.copy,
                          if (!isDisabled) strings.edit,
                          if (SBUMarkAsUnreadManager().isOn())
                            strings.markAsUnread,
                          if (!isDisabled)
                            if (SBUMessageCollectionProvider().canDeleteMessage(
                              widget.messageCollectionNo,
                              message,
                            ))
                              strings.delete,
                          if (SBUReplyManager().isQuoteReplyAvailable(
                            collection.channel,
                          ))
                            strings.reply,
                        ],
                        onButtonClicked: (buttonName) async {
                          if (buttonName == strings.copy) {
                            await widget.copyTextToClipboard(
                              message.message,
                              strings,
                            );
                          } else if (buttonName == strings.edit) {
                            SBUMessageCollectionProvider().setEditingMessage(
                              widget.messageCollectionNo,
                              message,
                            );
                          } else if (buttonName == strings.markAsUnread) {
                            await _markAsUnread(collection.channel, message);
                          } else if (buttonName == strings.delete) {
                            await showDialog(
                              context: context,
                              barrierDismissible: true,
                              builder: (context) => SBUDialogMenuComponent(
                                title: strings.deleteMessage,
                                buttonNames: [strings.cancel, strings.delete],
                                onButtonClicked: (buttonName) async {
                                  if (buttonName == strings.cancel) {
                                    // Cancel
                                  } else if (buttonName == strings.delete) {
                                    runZonedGuarded(
                                      () async {
                                        await collection.channel.deleteMessage(
                                          message.messageId,
                                        );
                                      },
                                      (error, stack) {
                                        // TODO: Check error
                                      },
                                    );
                                  }
                                },
                                isYesOrNo: true,
                              ),
                            );
                          } else if (buttonName == strings.reply) {
                            SBUMessageCollectionProvider().setReplyingToMessage(
                              widget.messageCollectionNo,
                              message,
                            );
                          }
                        },
                        disabledNames: [
                          if (message.isReplyToChannel) strings.reply,
                          if (message.threadInfo != null &&
                              message.threadInfo!.replyCount > 0)
                            strings.delete,
                        ],
                      );
                    },
                  );
                } else if (message.sendingStatus == SendingStatus.failed) {
                  widget.unfocus();
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
                      return SBUBottomSheetMenuComponent(
                        buttonNames: [
                          if (!isDisabled) strings.retry,
                          strings.remove,
                        ],
                        onButtonClicked: (buttonName) async {
                          if (buttonName == strings.retry) {
                            try {
                              collection.channel.resendUserMessage(message);
                            } catch (e) {
                              // TODO: Check error
                            }
                          } else if (buttonName == strings.remove) {
                            await collection.removeFailedMessages(
                              messages: [message],
                            );
                          }
                        },
                        errorColorIndex: 1,
                      );
                    },
                  );
                }
              },
              child: Column(
                children: [
                  SBUOGTagManager().getOGTagMessageItemWidget(
                        message: message,
                        collection: collection,
                        isLightTheme: isLightTheme,
                        strings: strings,
                        isMyMessage: true,
                      ) ??
                      Container(
                        padding: EdgeInsets.only(top: 10.h),
                        decoration: BoxDecoration(
                          color: isLightTheme
                              ? SBUColors.primaryMain
                              : SBUColors.primaryLight,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              // bottom padding for message
                              padding: EdgeInsets.only(
                                left: 14.w,
                                right: 14.w,
                                bottom: 10.h,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Flexible(
                                    child: SBUTextComponent(
                                      text: message.message,
                                      textType: SBUTextType.body3,
                                      textColorType: SBUTextColorType.myMessage,
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
                                        textColorType:
                                            SBUTextColorType.messageEdited,
                                        textOverflowType: null,
                                        maxLines: null,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            SBUReactionComponent(
                              channel: collection.channel,
                              message: message,
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _otherFileMessageItemWidget({
    required MessageCollection collection,
    required FileMessage message,
    required bool isSameMinuteAtPreviousMessage,
    required bool isSameMinuteAtNextMessage,
    required String timeString,
    required bool isLightTheme,
    required SBUStrings strings,
  }) {
    final thumbnailWidget = _getThumbnail(
      message: message,
      isLightTheme: isLightTheme,
      isParentMessage: false,
    );
    final fileWidget = _fileWidget(
      message: message,
      isLightTheme: isLightTheme,
      isMyMessage: false,
    );

    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: EdgeInsets.only(right: 12.w, bottom: 2.h),
          child: (isSameMinuteAtNextMessage == false)
              ? Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(13.r),
                    onTap: () async {
                      final onUserIconClicked = widget.onUserIconClicked;
                      final sender = message.sender;
                      if (onUserIconClicked != null) {
                        if (sender != null) {
                          onUserIconClicked(sender);
                          return;
                        }
                      }

                      if (sender != null) {
                        widget.unfocus();

                        final themeProvider = context.read<SBUThemeProvider>();
                        final stringProvider = context
                            .read<SBUStringProvider>();

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
                            return MultiProvider(
                              providers: [
                                ChangeNotifierProvider.value(
                                  value: themeProvider,
                                ),
                                ChangeNotifierProvider.value(
                                  value: stringProvider,
                                ),
                              ],
                              child: SBUBottomSheetUserComponent(
                                user: sender,
                                on1On1ChannelCreated:
                                    widget.on1On1ChannelCreated,
                              ),
                            );
                          },
                        );
                      }
                    },
                    child: widget.getAvatarComponent(
                      isLightTheme: isLightTheme,
                      size: 26.r,
                      user: message.sender,
                    ),
                  ),
                )
              : SizedBox(width: 26.w),
        ),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSameMinuteAtPreviousMessage == false)
                if (message.isReplyToChannel == false &&
                    message.parentMessageId == null)
                  Padding(
                    padding: EdgeInsets.only(left: 12.w, bottom: 4.h),
                    child: SBUTextComponent(
                      text: widget.getNickname(message.sender, strings),
                      textType: SBUTextType.caption1,
                      textColorType: SBUTextColorType.text02,
                    ),
                  ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16.r),
                  onTap: () async {
                    if (widget.onListItemClicked != null) {
                      widget.onListItemClicked!(collection.channel, message);
                    }
                  },
                  onLongPress: () async {
                    return;
                    if (!SBUReactionManager().isReactionAvailable(
                          collection.channel,
                          message,
                        ) &&
                        SendbirdUIKit().downloadFile == null &&
                        !SBUReplyManager().isQuoteReplyAvailable(
                          collection.channel,
                        ) &&
                        !SBUMarkAsUnreadManager().isOn()) {
                      return;
                    }

                    widget.unfocus();
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
                        return SBUBottomSheetMenuComponent(
                          channel: collection.channel,
                          message: message,
                          iconNames: [
                            if (SendbirdUIKit().downloadFile != null)
                              SBUIcons.download,
                            if (SBUMarkAsUnreadManager().isOn())
                              SBUIcons.markAsUnread,
                            if (SBUReplyManager().isQuoteReplyAvailable(
                              collection.channel,
                            ))
                              SBUIcons.reply,
                          ],
                          buttonNames: [
                            if (SendbirdUIKit().downloadFile != null)
                              strings.save,
                            if (SBUMarkAsUnreadManager().isOn())
                              strings.markAsUnread,
                            if (SBUReplyManager().isQuoteReplyAvailable(
                              collection.channel,
                            ))
                              strings.reply,
                          ],
                          onButtonClicked: (buttonName) async {
                            if (buttonName == strings.save) {
                              SendbirdUIKit().downloadFile!(
                                message.secureUrl,
                                message.name,
                                () => widget.showToast(
                                  isLightTheme: isLightTheme,
                                  text: strings.fileSaved,
                                ),
                              );
                            } else if (buttonName == strings.markAsUnread) {
                              await _markAsUnread(collection.channel, message);
                            } else if (buttonName == strings.reply) {
                              SBUMessageCollectionProvider()
                                  .setReplyingToMessage(
                                    widget.messageCollectionNo,
                                    message,
                                  );
                            }
                          },
                          disabledNames: message.isReplyToChannel
                              ? [strings.reply]
                              : null,
                        );
                      },
                    );
                  },
                  child: Container(
                    padding: thumbnailWidget != null
                        ? EdgeInsets.zero
                        : EdgeInsets.only(top: 8.h),
                    decoration: BoxDecoration(
                      color: thumbnailWidget != null
                          ? isLightTheme
                                ? SBUColors.background100
                                : SBUColors.background400
                          : isLightTheme
                          ? SBUColors.background100
                          : SBUColors.background400,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: thumbnailWidget != null
                        ? Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: SBUColors.fileImageStroke,
                                    width: 1.r,
                                  ),
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16.r),
                                  child: SizedBox(
                                    width: imageWidth, // Check
                                    height: imageHeight,
                                    child: thumbnailWidget,
                                  ),
                                ),
                              ),
                              SBUReactionComponent(
                                channel: collection.channel,
                                message: message,
                                width: imageWidth, // Check
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.only(
                                  left: 12.w,
                                  right: 12.w,
                                  bottom: 8.h,
                                ),
                                child: fileWidget,
                              ),
                              SBUReactionComponent(
                                channel: collection.channel,
                                message: message,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 16.h,
          alignment: AlignmentDirectional.center,
          padding: EdgeInsets.only(left: 4.w),
          child: SBUTextComponent(
            text: timeString,
            textType: SBUTextType.caption4,
            textColorType: SBUTextColorType.text03,
            transparent: isSameMinuteAtNextMessage,
          ),
        ),
      ],
    );
  }

  Widget _myFileMessageItemWidget({
    required MessageCollection collection,
    required FileMessage message,
    required bool isSameMinuteAtPreviousMessage,
    required bool isSameMinuteAtNextMessage,
    required String timeString,
    required bool isLightTheme,
    required SBUStrings strings,
  }) {
    final readStatusIcon = widget.getReadStatusIcon(
      collection.channel,
      message,
      isLightTheme,
    );
    final isDisabled = widget.isDisabled(collection.channel);

    final thumbnailWidget = _getThumbnail(
      message: message,
      isLightTheme: isLightTheme,
      isParentMessage: false,
    );
    final fileWidget = _fileWidget(
      message: message,
      isLightTheme: isLightTheme,
      isMyMessage: true,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if ((message.sendingStatus?.isTimeAvailable ?? false) &&
            isSameMinuteAtNextMessage)
          Container(
            height: 16.h,
            alignment: AlignmentDirectional.center,
            padding: EdgeInsets.only(right: 4.w),
            child: SBUTextComponent(
              text: timeString,
              textType: SBUTextType.caption4,
              textColorType: SBUTextColorType.text03,
              transparent: isSameMinuteAtNextMessage,
            ),
          ),
        if (readStatusIcon != null)
          Padding(
            padding: EdgeInsets.only(right: 4.w, bottom: 2.h),
            child: readStatusIcon,
          ),
        if (message.sendingStatus == SendingStatus.pending)
          Padding(
            padding: EdgeInsets.only(right: 4.w, bottom: 2.h),
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
        if (message.sendingStatus == SendingStatus.failed)
          Padding(
            padding: EdgeInsets.only(right: 4.w, bottom: 2.h),
            child: SBUIconComponent(
              iconSize: 16.r,
              iconData: SBUIcons.error,
              iconColor: isLightTheme
                  ? SBUColors.errorMain
                  : SBUColors.errorLight,
            ),
          ),
        if ((message.sendingStatus?.isTimeAvailable ?? false) &&
            isSameMinuteAtNextMessage == false)
          Container(
            height: 16.h,
            alignment: AlignmentDirectional.center,
            padding: EdgeInsets.only(right: 4.w),
            child: SBUTextComponent(
              text: timeString,
              textType: SBUTextType.caption4,
              textColorType: SBUTextColorType.text03,
            ),
          ),
        Flexible(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16.r),
              onTap: () async {
                if (widget.onListItemClicked != null) {
                  widget.onListItemClicked!(collection.channel, message);
                }
              },
              onLongPress: () async {
                return;
                if (message.sendingStatus == SendingStatus.succeeded) {
                  if (!SBUReactionManager().isReactionAvailable(
                        collection.channel,
                        message,
                      ) &&
                      SendbirdUIKit().downloadFile == null &&
                      isDisabled &&
                      !SBUReplyManager().isQuoteReplyAvailable(
                        collection.channel,
                      ) &&
                      !SBUMarkAsUnreadManager().isOn()) {
                    return;
                  }

                  widget.unfocus();
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
                      return SBUBottomSheetMenuComponent(
                        channel: collection.channel,
                        message: message,
                        iconNames: [
                          if (SendbirdUIKit().downloadFile != null)
                            SBUIcons.download,
                          if (SBUMarkAsUnreadManager().isOn())
                            SBUIcons.markAsUnread,
                          if (!isDisabled)
                            if (SBUMessageCollectionProvider().canDeleteMessage(
                              widget.messageCollectionNo,
                              message,
                            ))
                              SBUIcons.delete,
                          if (SBUReplyManager().isQuoteReplyAvailable(
                            collection.channel,
                          ))
                            SBUIcons.reply,
                        ],
                        buttonNames: [
                          if (SendbirdUIKit().downloadFile != null)
                            strings.save,
                          if (SBUMarkAsUnreadManager().isOn())
                            strings.markAsUnread,
                          if (!isDisabled)
                            if (SBUMessageCollectionProvider().canDeleteMessage(
                              widget.messageCollectionNo,
                              message,
                            ))
                              strings.delete,
                          if (SBUReplyManager().isQuoteReplyAvailable(
                            collection.channel,
                          ))
                            strings.reply,
                        ],
                        onButtonClicked: (buttonName) async {
                          if (buttonName == strings.save) {
                            SendbirdUIKit().downloadFile!(
                              message.secureUrl,
                              message.name,
                              () => widget.showToast(
                                isLightTheme: isLightTheme,
                                text: strings.fileSaved,
                              ),
                            );
                          } else if (buttonName == strings.markAsUnread) {
                            await _markAsUnread(collection.channel, message);
                          } else if (buttonName == strings.delete) {
                            await showDialog(
                              context: context,
                              barrierDismissible: true,
                              builder: (context) => SBUDialogMenuComponent(
                                title: strings.deleteMessage,
                                buttonNames: [strings.cancel, strings.delete],
                                onButtonClicked: (buttonName) async {
                                  if (buttonName == strings.cancel) {
                                    // Cancel
                                  } else if (buttonName == strings.delete) {
                                    if (message.sendingStatus ==
                                        SendingStatus.succeeded) {
                                      runZonedGuarded(
                                        () async {
                                          await collection.channel
                                              .deleteMessage(message.messageId);
                                        },
                                        (error, stack) {
                                          // TODO: Check error
                                        },
                                      );
                                    } else if (message.sendingStatus ==
                                        SendingStatus.failed) {
                                      await collection.removeFailedMessages(
                                        messages: [message],
                                      );
                                    }
                                  }
                                },
                                isYesOrNo: true,
                              ),
                            );
                          } else if (buttonName == strings.reply) {
                            SBUMessageCollectionProvider().setReplyingToMessage(
                              widget.messageCollectionNo,
                              message,
                            );
                          }
                        },
                        disabledNames: [
                          if (message.isReplyToChannel) strings.reply,
                          if (message.threadInfo != null &&
                              message.threadInfo!.replyCount > 0)
                            strings.delete,
                        ],
                      );
                    },
                  );
                } else if (message.sendingStatus == SendingStatus.failed) {
                  widget.unfocus();
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
                      return SBUBottomSheetMenuComponent(
                        buttonNames: [
                          if (!isDisabled) strings.retry,
                          strings.remove,
                        ],
                        onButtonClicked: (buttonName) async {
                          if (buttonName == strings.retry) {
                            try {
                              collection.channel.resendFileMessage(message);
                            } catch (e) {
                              if (e is FileSizeLimitExceededException) {
                                // TODO: Check error
                              } else {
                                // TODO: Check error
                              }
                            }
                          } else if (buttonName == strings.remove) {
                            await collection.removeFailedMessages(
                              messages: [message],
                            );
                          }
                        },
                        errorColorIndex: 1,
                      );
                    },
                  );
                }
              },
              child: Container(
                padding: thumbnailWidget != null
                    ? EdgeInsets.zero
                    : EdgeInsets.only(top: 7.h),
                decoration: BoxDecoration(
                  color: thumbnailWidget != null
                      ? isLightTheme
                            ? SBUColors.background100
                            : SBUColors.background400
                      : isLightTheme
                      ? SBUColors.primaryMain
                      : SBUColors.primaryLight,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: thumbnailWidget != null
                    ? Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              // Use the custom border from the theme if available
                              border: Border.all(
                                color: SBUColors.fileImageStroke,
                                width: 1.r,
                              ),
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16.r),
                              child: SizedBox(
                                width: imageWidth, // Check
                                height: imageHeight,
                                child: thumbnailWidget,
                              ),
                            ),
                          ),
                          SBUReactionComponent(
                            channel: collection.channel,
                            message: message,
                            width: imageWidth, // Check
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              left: 12.w,
                              right: 12.w,
                              bottom: 7.h,
                            ),
                            child: fileWidget,
                          ),
                          SBUReactionComponent(
                            channel: collection.channel,
                            message: message,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _messageItemPadding({
    required BaseMessage message,
    required int messageIndex,
    required bool isSameMinuteAtPreviousMessage,
    required bool isSameMinuteAtNextMessage,
    required Widget child,
  }) {
    Widget result = child;

    result = Padding(
      padding: EdgeInsets.only(
        left: 12.w,
        top: widget.isReplyMessageToChannel(message)
            ? 8.h // Check
            : isSameMinuteAtPreviousMessage
            ? 1.h
            : 8.h,
        right: 12.w,
        bottom: widget.isReplyMessageToChannel(message)
            ? (messageIndex == 0)
                  ? 16.h - 6.h
                  : 8.h - 6.h
            : isSameMinuteAtNextMessage
            ? 1.h
            : (messageIndex == 0)
            ? 16.h
            : 8.h,
      ),
      child: child,
    );

    return result;
  }

  Widget _parentMessageItemWidget({
    required MessageCollection collection,
    required BaseMessage message,
    required bool isSameMinuteAtPreviousMessage,
    required bool isSameMinuteAtNextMessage,
    required String timeString,
    required bool isLightTheme,
    required SBUStrings strings,
    required bool isMyMessage,
  }) {
    if (message is UserMessage) {
      final parentUserMessageWidget = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () {
            _moveToParentMessage(message);
          },
          child: Container(
            padding: EdgeInsets.only(
              left: 12.w,
              top: 6.h,
              right: 12.w,
              bottom: 12.h,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              color: isLightTheme
                  ? SBUColors.background100
                  : SBUColors.background400,
            ),
            child: SBUTextComponent(
              text: message.message,
              textType: SBUTextType.body3,
              textColorType: SBUTextColorType.text03,
              textOverflowType: null,
              maxLines: null,
            ),
          ),
        ),
      );

      if (isMyMessage) {
        return parentUserMessageWidget;
      } else {
        return Padding(
          padding: EdgeInsets.only(left: 38.w),
          child: parentUserMessageWidget,
        );
      }
    } else if (message is FileMessage) {
      final thumbnailWidget = _getThumbnail(
        message: message,
        isLightTheme: isLightTheme,
        isParentMessage: true,
      );

      final parentFileMessageWidget = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () {
            _moveToParentMessage(message);
          },
          child: (thumbnailWidget != null)
              ? Container(
                  decoration: BoxDecoration(
                    // Use the custom border from the theme if available
                    border: Border.all(
                      color: SBUColors.fileImageStroke,
                      width: 1.r,
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: Stack(
                      children: [
                        SizedBox(
                          width: 156.w,
                          height: 104.h,
                          child: thumbnailWidget,
                        ),
                        Container(
                          width: 156.w,
                          height: 104.h,
                          color: const Color(0x00FFFFFF).withOpacity(0.4),
                        ),
                      ],
                    ),
                  ),
                )
              : Container(
                  height: 38.h,
                  padding: EdgeInsets.only(
                    left: 12.w,
                    top: 6.h,
                    right: 12.w,
                    bottom: 12.h,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    color: isLightTheme
                        ? SBUColors.background100
                        : SBUColors.background400,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: 4.w),
                        child: SBUIconComponent(
                          iconSize: 16.r,
                          iconData: SBUIcons.fileDocument,
                          iconColor: isLightTheme
                              ? SBUColors.lightThemeTextLowEmphasis
                              : SBUColors.darkThemeTextLowEmphasis,
                        ),
                      ),
                      Flexible(
                        child: SBUTextComponent(
                          text: message.name ?? '',
                          textType: SBUTextType.body3,
                          textColorType: SBUTextColorType.text03,
                          // SBUTextOverflowType.ellipsisMiddle
                          textOverflowType: null,
                          maxLines: null, // 1
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      );

      if (isMyMessage) {
        return parentFileMessageWidget;
      } else {
        return Padding(
          padding: EdgeInsets.only(left: 38.w),
          child: parentFileMessageWidget,
        );
      }
    }

    return Container();
  }

  void _moveToParentMessage(BaseMessage message) {
    if (widget.onParentMessageClicked != null) {
      widget.onParentMessageClicked!(message);
    }
  }

  Widget _replyToChannel({
    required MessageCollection collection,
    required BaseMessage message,
    required bool isSameMinuteAtPreviousMessage,
    required bool isSameMinuteAtNextMessage,
    required String timeString,
    required bool isLightTheme,
    required SBUStrings strings,
    required bool isMyMessage,
    required Widget child,
  }) {
    Widget result = child;

    if (widget.isReplyMessageToChannel(message)) {
      BaseMessage parentMessage = message.parentMessage!;
      if (message.parentMessageId != null) {
        final updatableMessage = collection.messageList.firstWhereOrNull(
          (m) => m.messageId == message.parentMessageId,
        );
        if (updatableMessage != null) {
          parentMessage = updatableMessage;
        }
      }

      Widget parentMessageItemWidget = _parentMessageItemWidget(
        collection: collection,
        message: parentMessage,
        isSameMinuteAtPreviousMessage: isSameMinuteAtPreviousMessage,
        isSameMinuteAtNextMessage: isSameMinuteAtNextMessage,
        timeString: timeString,
        isLightTheme: isLightTheme,
        strings: strings,
        isMyMessage: isMyMessage,
      );

      String userA = widget.getNicknameOrYou(message.sender, strings);
      String userB = widget.getNicknameOrYou(
        message.parentMessage?.sender,
        strings,
      );
      String repliedToString = strings.repliedTo(userA, userB);

      result = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: isMyMessage
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMyMessage
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              SizedBox(width: isMyMessage ? 0 : 50.w),
              SBUIconComponent(
                iconSize: 12.r,
                iconData: SBUIcons.replyFilled,
                iconColor: isLightTheme
                    ? SBUColors.lightThemeTextLowEmphasis
                    : SBUColors.darkThemeTextLowEmphasis,
              ),
              SizedBox(width: 4.w),
              SBUTextComponent(
                text: repliedToString,
                textType: SBUTextType.caption1,
                textColorType: SBUTextColorType.text03,
              ),
              SizedBox(width: isMyMessage ? 12.w : 0),
            ],
          ),
          SizedBox(height: 4.h),
          parentMessageItemWidget,
          Transform(
            transform: Matrix4.identity()..translate(0.0, -6.h),
            child: child,
          ),
        ],
      );
    }

    return result;
  }

  Future<void> _markAsUnread(GroupChannel channel, BaseMessage message) async {
    await SBUMarkAsUnreadManager().markAsUnread(channel, message);
  }
}

extension _TimeAvailable on SendingStatus {
  bool get isTimeAvailable {
    return this == SendingStatus.succeeded || this == SendingStatus.failed;
  }
}
