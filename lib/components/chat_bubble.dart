import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isCurrentUser;
  final bool isSeen;
  final Timestamp? timestamp;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.isSeen = false,
    this.timestamp,
  });

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '';
    final dateTime = ts.toDate();
    final formatter = DateFormat('HH:mm');
    return formatter.format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isCurrentUser
            ? Theme.of(context).colorScheme.primary
            : (isDark ? Colors.grey[800] : Colors.grey[300]),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      margin: const EdgeInsets.symmetric(vertical: 2.5, horizontal: 25),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  message,
                  style: TextStyle(
                    color: isCurrentUser
                        ? Theme.of(context).colorScheme.onPrimary
                        : (isDark ? Colors.white : Colors.black),
                    fontSize: 16,
                  ),
                ),
              ),
              if (isCurrentUser) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.done_all,
                  color: isSeen
                      ? (isDark ? Colors.blue[300] : Colors.blue[700])
                      : (isDark ? Colors.white54 : Colors.black54),
                  size: 16,
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _formatTime(timestamp),
            style: TextStyle(
              color: isCurrentUser
                  ? Theme.of(context)
                      .colorScheme
                      .onPrimary
                      .withValues(alpha: 0.7)
                  : (isDark ? Colors.white60 : Colors.black54),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
