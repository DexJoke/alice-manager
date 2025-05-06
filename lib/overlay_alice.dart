import 'package:alice_manager/alice_manager.dart';
import 'package:draggable_float_widget/draggable_float_widget.dart';
import 'package:flutter/material.dart';

class OverlayAlice {
  OverlayEntry? _overlayEntry;
  OverlayEntry get overlayEntry {
    _overlayEntry ??= _createOverlayEntry();
    return _overlayEntry!;
  }

  OverlayEntry _createOverlayEntry() => OverlayEntry(
        builder: (context) {
          return DraggableFloatWidget(
            height: 40,
            width: 40,
            config: const DraggableFloatWidgetBaseConfig(
              initPositionYInTop: false,
              initPositionXInLeft: false,
              borderTopContainTopBar: true,
              initPositionYMarginBorder: 50,
              appBarHeight: 0,
            ),
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: () {
                  AliceManager.instance.showInspector();
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );

  static bool isShow = false;

  void insertOverlay(
    BuildContext context,
  ) {
    close();

    return Overlay.of(context).insert(overlayEntry);
  }

  close() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
