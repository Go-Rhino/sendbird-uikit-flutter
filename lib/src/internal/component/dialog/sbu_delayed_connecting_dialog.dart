// Copyright (c) 2025 Sendbird, Inc. All rights reserved.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sendbird_uikit/sendbird_uikit.dart';
import 'package:sendbird_uikit/src/internal/component/base/sbu_base_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_text_button_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_text_component.dart';
import 'package:sendbird_uikit/src/internal/resource/sbu_text_styles.dart';
import 'package:sendbird_uikit/src/internal/utils/sbu_time_extensions.dart';

class SBUDelayedConnectingDialog extends SBUStatefulComponent {
  final int retryAfter;
  final bool showCloseButton;
  final void Function()? onCloseButtonClicked;
  final String? closeButtonText;

  const SBUDelayedConnectingDialog({
    required this.retryAfter,
    this.showCloseButton = false,
    this.onCloseButtonClicked,
    this.closeButtonText,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => SBUDelayedConnectingDialogState();
}

class SBUDelayedConnectingDialogState
    extends State<SBUDelayedConnectingDialog> {
  late int currentRetryAfter;
  late final DateTime startTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    currentRetryAfter = widget.retryAfter;
    startTime = DateTime.now();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      updateRetryAfter();
      if (currentRetryAfter <= 0) {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void updateRetryAfter() {
    final now = DateTime.now();
    final elapsedTime = now.difference(startTime).inMilliseconds;
    final updatedRetryAfter = widget.retryAfter - elapsedTime / 1000;

    setState(() {
      currentRetryAfter = updatedRetryAfter > 0 ? updatedRetryAfter.ceil() : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLightTheme = context.watch<SBUThemeProvider>().isLight();
    final strings = context.watch<SBUStringProvider>().strings;

    return PopScope(
        canPop: false,
        child: Container(
          width: double.maxFinite,
          height: double.maxFinite,
          color: SBUColors.overlayLight,
          child: Center(
            child: Container(
              width: 280,
              decoration: BoxDecoration(
                color: isLightTheme
                    ? SBUColors.background50
                    : SBUColors.background500,
                borderRadius: const BorderRadius.all(Radius.circular(4)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: DefaultTextStyle.merge(
                      style: kIsWeb
                          ? const TextStyle(decoration: TextDecoration.none)
                          : null,
                      child: SBUTextComponent(
                        text: strings.youWillBeReconnectedShortly,
                        textType: SBUTextType.heading1,
                        textColorType: SBUTextColorType.text01,
                        maxLines: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: DefaultTextStyle.merge(
                      style: kIsWeb
                          ? const TextStyle(decoration: TextDecoration.none)
                          : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SBUTextComponent(
                            text: currentRetryAfter > 0
                                ? strings.estimatedWaitingTime
                                : '',
                            textType: SBUTextType.body3,
                            textColorType: SBUTextColorType.text02,
                          ),
                          const SizedBox(width: 4),
                          SBUTextComponent(
                            text: currentRetryAfter > 0
                                ? currentRetryAfter.toTimeString()
                                : '',
                            textType: SBUTextType.body3Bold,
                            textColorType: SBUTextColorType.text02,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (widget.showCloseButton)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 8, bottom: 4),
                          child: DefaultTextStyle.merge(
                            style: kIsWeb
                                ? const TextStyle(
                                    decoration: TextDecoration.none)
                                : null,
                            child: SBUTextButtonComponent(
                              height: 32,
                              padding: const EdgeInsets.all(8),
                              text: SBUTextComponent(
                                text: (widget.closeButtonText != null)
                                    ? widget.closeButtonText!
                                    : strings.close,
                                textType: SBUTextType.button,
                                textColorType: SBUTextColorType.primary,
                              ),
                              onButtonClicked: () async {
                                Navigator.pop(context);

                                if (widget.onCloseButtonClicked != null) {
                                  widget.onCloseButtonClicked!();
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ));
  }
}
