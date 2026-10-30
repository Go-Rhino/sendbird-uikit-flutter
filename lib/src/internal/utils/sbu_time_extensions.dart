// Copyright (c) 2025 Sendbird, Inc. All rights reserved.

extension SBUTimeExtensions on int {
  String toTimeString() {
    final int hours = this ~/ 3600;
    final int minutes = (this % 3600) ~/ 60;
    final int seconds = this % 60;

    if (hours == 0) {
      return '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}
