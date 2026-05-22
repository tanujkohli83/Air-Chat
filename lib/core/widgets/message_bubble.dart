import 'package:chatapp/core/models/chat_message.dart';
import 'package:chatapp/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.isStacked,
    required this.timeLabel,
  });

  final ChatMessage message;
  final bool isMine;
  final bool isStacked;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final bubbleRadius = isMine
        ? const BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
            bottomLeft: Radius.circular(22),
            bottomRight: Radius.circular(6),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(22),
          );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.only(
        top: isStacked ? 4 : 12,
        left: isMine ? 44 : 0,
        right: isMine ? 0 : 44,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: isMine ? AppGradients.indigoViolet : null,
              color: isMine ? null : AppColors.recipientBubble,
              borderRadius: bubbleRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isMine ? 0.12 : 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.text,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isMine ? Colors.white : AppColors.recipientText,
                      height: 1.32,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    timeLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isMine
                          ? Colors.white.withValues(alpha: 0.68)
                          : AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
