import 'dart:async';
import 'dart:developer';

import 'package:flutter/services.dart';

/// default size when the overlay match the parent size
/// basically it will take the full screen width and height
const int matchParent = -1;

class PipFlutter {
  PipFlutter._();

  static final StreamController _controller = StreamController.broadcast();
  static const MethodChannel _channel =
      MethodChannel("com.example.tub_app_overlays/overlayChannel");

  static const BasicMessageChannel _overlayMessageChannel = BasicMessageChannel(
      "com.example.tub_app_overlays/overlay_messenger", JSONMessageCodec());

  static void disposeOverlayListener() {
    _controller.close();
  }

  static Future<bool?> _show({
    int height = matchParent,
    int width = matchParent,
    NotificationVisibility visibility =
        NotificationVisibility.visibilityPrivate,
    String overlayTitle = "overlay activated",
    String? overlayContent,
    bool enableDrag = true,
  }) async {
    await _channel.invokeMethod(
      'show',
      {
        "height": height,
        "width": width,
        "overlayTitle": overlayTitle,
        "overlayContent": overlayContent,
        "enableDrag": enableDrag,
        "notificationVisibility": visibility.name,
      },
    );
  }

  ///[url] link of video
  ///[position] current time of video send to popup
  /// [height] height of popup, must be convert to Pixel
  /// [width] width of popup, must be convert to Pixel
  /// [visibility] the detail displayed in notifications on the lock screen and default is [NotificationVisibility.visibilityPrivate]
  /// [overlayTitle] title of notification when show popup
  /// [overlayContent] content of notification when show popup
  /// [enableDrag] if you want to drag popup be set enableDrag = true else false

  static Future<bool?> showPopup(
    String url,
    int position, {
    int height = matchParent,
    int width = matchParent,
    NotificationVisibility visibility =
        NotificationVisibility.visibilityPrivate,
    String overlayTitle = "overlay activated",
    String? overlayContent,
    bool enableDrag = true,
  }) async {
    bool? isShowSuccess;
    var isActive = await PipFlutter.isActive();
    if (!isActive) {
      isShowSuccess = await _show(
        overlayTitle: "Tub App",
        overlayContent: 'Overlay Video',
        width: width,
        height: height,
      );

      await PipFlutter.pushArguments(
        {
          "url": url,
          "position": position,
        },
      );
    }
    return isShowSuccess;
  }

  ///close popup
  ///this had bug : if using only [ _channel.invokeMethod('close')] then show
  ///MissingPluginException('No implementation found for method $method on channel $name');
  static Future<void> close() async {
    // await PipFlutter.pushArguments("close");
    await _channel.invokeMethod('close');
  }

  ///share Argument between Dart UI and Overlays
  ///when send from Flutter UI then Android Native has receive data at Method onMessage
  ///and send to Overlays this data
  ///when send from Overlays then Service has receive data at setMessageHandler
  ///and send to Flutter UI this data
  ///You can listen only one place
  static Future<void> pushArguments(dynamic arguments) async {
    return await _overlayMessageChannel.send(arguments);
  }

  /// check Service active or non-active
  /// return true if active and false if non-active
  static Future<bool> isActive() async {
    return await _channel.invokeMethod("isActive");
  }

  ///request Permission android.permission.SYSTEM_ALERT_WINDOW
  static Future<bool> requestP() async {
    return await _channel.invokeMethod('requestPermission');
  }

  ///check permission android.permission.SYSTEM_ALERT_WINDOW is accept or decline
  static Future<bool>  isPermissionGranted() async {
    return await _channel.invokeMethod('isPermissionGranted');
  }

  static Stream<dynamic> get overlayListener {
    _overlayMessageChannel.setMessageHandler((message) async {
      _controller.add(message);
    });

    return _controller.stream;
  }
}

/// The level of detail displayed in notifications on the lock screen.
enum NotificationVisibility {
  /// Show this notification in its entirety on all lockscreens.
  visibilityPublic,

  /// Do not reveal any part of this notification on a secure lockscreen.
  visibilitySecret,

  /// Show this notification on all lockscreens, but conceal sensitive or private information on secure lockscreens.
  visibilityPrivate
}
