// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_types/visual_media_message/visual_media_content.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';

class VisualMediaCustomGrid extends StatelessWidget {
  VisualMediaCustomGrid({
    required this.messageMedias,
    required this.eventMessage,
    double? customHeight,
    double? customSpacing,
    this.isReply = false,
    super.key,
  }) {
    _height1 = customHeight ?? 146.0.s;
    _height2 = customHeight ?? 110.0.s;
    _height3 = customHeight ?? 80.0.s;
    _spacing = customSpacing ?? 4.0.s;
  }

  late final double _height1;
  late final double _height2;
  late final double _height3;
  late final double _spacing;

  final List<MessageMediaTableData> messageMedias;
  final EventMessage eventMessage;
  final bool isReply;
  @override
  Widget build(BuildContext context) {
    final mediaCount = messageMedias.length;

    if (mediaCount == 1) {
      return VisualMediaContent(
        key: ValueKey(messageMedias.first.id),
        messageMediaTableData: messageMedias.first,
        eventMessage: eventMessage,
        height: _height1,
        isReply: isReply,
      );
    }

    if (mediaCount == 2) {
      return Row(
        children: [
          Expanded(
            child: VisualMediaContent(
              key: ValueKey(messageMedias.first.id),
              messageMediaTableData: messageMedias.first,
              eventMessage: eventMessage,
              height: _height1,
              isReply: isReply,
            ),
          ),
          SizedBox(width: _spacing),
          Expanded(
            child: VisualMediaContent(
              key: ValueKey(messageMedias.last.id),
              messageMediaTableData: messageMedias.last,
              eventMessage: eventMessage,
              height: _height1,
              isReply: isReply,
            ),
          ),
        ],
      );
    }

    if (mediaCount == 3) {
      return Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: VisualMediaContent(
                  key: ValueKey(messageMedias[0].id),
                  messageMediaTableData: messageMedias[0],
                  eventMessage: eventMessage,
                  height: _height1,
                  isReply: isReply,
                ),
              ),
              SizedBox(width: _spacing),
              Expanded(
                child: VisualMediaContent(
                  key: ValueKey(messageMedias[1].id),
                  messageMediaTableData: messageMedias[1],
                  eventMessage: eventMessage,
                  height: _height1,
                  isReply: isReply,
                ),
              ),
            ],
          ),
          SizedBox(height: _spacing),
          Row(
            children: <Widget>[
              Expanded(
                child: VisualMediaContent(
                  key: ValueKey(messageMedias[2].id),
                  messageMediaTableData: messageMedias[2],
                  eventMessage: eventMessage,
                  height: _height1,
                  isReply: isReply,
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (mediaCount == 4) {
      return Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[0],
                  eventMessage: eventMessage,
                  height: _height1,
                  isReply: isReply,
                ),
              ),
              SizedBox(width: _spacing),
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[1],
                  eventMessage: eventMessage,
                  height: _height1,
                  isReply: isReply,
                ),
              ),
            ],
          ),
          SizedBox(height: _spacing),
          Row(
            children: <Widget>[
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[2],
                  eventMessage: eventMessage,
                  height: _height1,
                  isReply: isReply,
                ),
              ),
              SizedBox(width: _spacing),
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[3],
                  eventMessage: eventMessage,
                  height: _height1,
                  isReply: isReply,
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (mediaCount == 5) {
      return Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[0],
                  eventMessage: eventMessage,
                  height: _height1,
                  isReply: isReply,
                ),
              ),
              SizedBox(width: _spacing),
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[1],
                  eventMessage: eventMessage,
                  height: _height1,
                  isReply: isReply,
                ),
              ),
            ],
          ),
          SizedBox(height: _spacing),
          Row(
            children: <Widget>[
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[2],
                  eventMessage: eventMessage,
                  height: _height2,
                  isReply: isReply,
                ),
              ),
              SizedBox(width: _spacing),
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[3],
                  eventMessage: eventMessage,
                  height: _height2,
                  isReply: isReply,
                ),
              ),
              SizedBox(width: _spacing),
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[4],
                  eventMessage: eventMessage,
                  height: _height2,
                  isReply: isReply,
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (mediaCount == 6) {
      return Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[0],
                  eventMessage: eventMessage,
                  height: _height2,
                  isReply: isReply,
                ),
              ),
              SizedBox(width: _spacing),
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[1],
                  eventMessage: eventMessage,
                  height: _height2,
                  isReply: isReply,
                ),
              ),
              SizedBox(width: _spacing),
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[2],
                  eventMessage: eventMessage,
                  height: _height2,
                  isReply: isReply,
                ),
              ),
            ],
          ),
          SizedBox(height: _spacing),
          Row(
            children: <Widget>[
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[3],
                  eventMessage: eventMessage,
                  height: _height2,
                  isReply: isReply,
                ),
              ),
              SizedBox(width: _spacing),
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[4],
                  eventMessage: eventMessage,
                  height: _height2,
                  isReply: isReply,
                ),
              ),
              SizedBox(width: _spacing),
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[5],
                  eventMessage: eventMessage,
                  height: _height2,
                  isReply: isReply,
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (mediaCount == 7) {
      return Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[0],
                  eventMessage: eventMessage,
                  height: _height1,
                  isReply: isReply,
                ),
              ),
            ],
          ),
          SizedBox(height: _spacing),
          Row(
            children: <Widget>[
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[1],
                  eventMessage: eventMessage,
                  height: _height2,
                  isReply: isReply,
                ),
              ),
              SizedBox(width: _spacing),
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[2],
                  eventMessage: eventMessage,
                  height: _height2,
                  isReply: isReply,
                ),
              ),
              SizedBox(width: _spacing),
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[3],
                  eventMessage: eventMessage,
                  height: _height2,
                  isReply: isReply,
                ),
              ),
            ],
          ),
          SizedBox(height: _spacing),
          Row(
            children: <Widget>[
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[4],
                  eventMessage: eventMessage,
                  height: _height2,
                  isReply: isReply,
                ),
              ),
              SizedBox(width: _spacing),
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[5],
                  eventMessage: eventMessage,
                  height: _height2,
                  isReply: isReply,
                ),
              ),
              SizedBox(width: _spacing),
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[6],
                  eventMessage: eventMessage,
                  height: _height2,
                  isReply: isReply,
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (mediaCount == 8) {
      return Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[0],
                  eventMessage: eventMessage,
                  height: _height1,
                  isReply: isReply,
                ),
              ),
              SizedBox(width: _spacing),
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[1],
                  eventMessage: eventMessage,
                  height: _height1,
                  isReply: isReply,
                ),
              ),
            ],
          ),
          SizedBox(height: _spacing),
          Row(
            children: <Widget>[
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[2],
                  eventMessage: eventMessage,
                  height: _height2,
                  isReply: isReply,
                ),
              ),
              SizedBox(width: _spacing),
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[3],
                  eventMessage: eventMessage,
                  height: _height2,
                  isReply: isReply,
                ),
              ),
              SizedBox(width: _spacing),
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[4],
                  eventMessage: eventMessage,
                  height: _height2,
                  isReply: isReply,
                ),
              ),
            ],
          ),
          SizedBox(height: _spacing),
          Row(
            children: <Widget>[
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[5],
                  eventMessage: eventMessage,
                  height: _height2,
                  isReply: isReply,
                ),
              ),
              SizedBox(width: _spacing),
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[6],
                  eventMessage: eventMessage,
                  height: _height2,
                  isReply: isReply,
                ),
              ),
              SizedBox(width: _spacing),
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[7],
                  eventMessage: eventMessage,
                  height: _height2,
                  isReply: isReply,
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (mediaCount == 9) {
      return Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[0],
                  eventMessage: eventMessage,
                  height: _height2,
                  isReply: isReply,
                ),
              ),
              SizedBox(width: _spacing),
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[1],
                  eventMessage: eventMessage,
                  height: _height2,
                  isReply: isReply,
                ),
              ),
              SizedBox(width: _spacing),
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[2],
                  eventMessage: eventMessage,
                  height: _height2,
                  isReply: isReply,
                ),
              ),
            ],
          ),
          SizedBox(height: _spacing),
          Row(
            children: <Widget>[
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[3],
                  eventMessage: eventMessage,
                  height: _height2,
                  isReply: isReply,
                ),
              ),
              SizedBox(width: _spacing),
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[4],
                  eventMessage: eventMessage,
                  height: _height2,
                  isReply: isReply,
                ),
              ),
              SizedBox(width: _spacing),
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[5],
                  eventMessage: eventMessage,
                  height: _height2,
                  isReply: isReply,
                ),
              ),
            ],
          ),
          SizedBox(height: _spacing),
          Row(
            children: <Widget>[
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[6],
                  eventMessage: eventMessage,
                  height: _height2,
                  isReply: isReply,
                ),
              ),
              SizedBox(width: _spacing),
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[7],
                  eventMessage: eventMessage,
                  height: _height2,
                  isReply: isReply,
                ),
              ),
              SizedBox(width: _spacing),
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[8],
                  eventMessage: eventMessage,
                  height: _height2,
                  isReply: isReply,
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (mediaCount == 10) {
      return Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[0],
                  eventMessage: eventMessage,
                  height: _height2,
                  isReply: isReply,
                ),
              ),
              SizedBox(width: _spacing),
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[1],
                  eventMessage: eventMessage,
                  height: _height2,
                  isReply: isReply,
                ),
              ),
              SizedBox(width: _spacing),
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[2],
                  eventMessage: eventMessage,
                  height: _height2,
                  isReply: isReply,
                ),
              ),
            ],
          ),
          SizedBox(height: _spacing),
          Row(
            children: <Widget>[
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[3],
                  eventMessage: eventMessage,
                  height: _height3,
                  isReply: isReply,
                ),
              ),
              SizedBox(width: _spacing),
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[4],
                  eventMessage: eventMessage,
                  height: _height3,
                ),
              ),
              SizedBox(width: _spacing),
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[5],
                  eventMessage: eventMessage,
                  height: _height3,
                  isReply: isReply,
                ),
              ),
              SizedBox(width: _spacing),
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[6],
                  eventMessage: eventMessage,
                  height: _height3,
                  isReply: isReply,
                ),
              ),
            ],
          ),
          SizedBox(height: _spacing),
          Row(
            children: <Widget>[
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[7],
                  eventMessage: eventMessage,
                  height: _height2,
                  isReply: isReply,
                ),
              ),
              SizedBox(width: _spacing),
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[8],
                  eventMessage: eventMessage,
                  height: _height2,
                  isReply: isReply,
                ),
              ),
              SizedBox(width: _spacing),
              Expanded(
                child: VisualMediaContent(
                  messageMediaTableData: messageMedias[9],
                  eventMessage: eventMessage,
                  height: _height2,
                  isReply: isReply,
                ),
              ),
            ],
          ),
        ],
      );
    }
    return Container();
  }
}
