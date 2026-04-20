import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';
import '../views/chat_view.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isStreaming;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.isStreaming = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accentCyan, AppColors.accentViolet],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: message.isUser
                    ? const LinearGradient(
                        colors: [AppColors.accentCyan, Color(0xFF0EA5E9)],
                      )
                    : null,
                color: message.isUser ? null : AppColors.surfaceCard,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(message.isUser ? 18 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 18),
                ),
                border: message.isUser
                    ? null
                    : Border.all(
                        color: message.isError
                            ? AppColors.error.withOpacity(0.5)
                            : AppColors.textMuted.withOpacity(0.1),
                      ),
                boxShadow: message.isUser
                    ? [
                        BoxShadow(
                          color: AppColors.accentCyan.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: SelectableText(
                          message.text,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: message.isUser
                                        ? Colors.white
                                        : message.isError
                                            ? AppColors.error
                                            : AppColors.textPrimary,
                                    height: 1.4,
                                  ),
                        ),
                      ),
                      if (isStreaming)
                        Container(
                          width: 8,
                          height: 16,
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentCyan,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat())
                            .fadeIn(duration: 500.ms)
                            .then()
                            .fadeOut(duration: 500.ms),
                    ],
                  ),
                  if (!message.isUser &&
                      !isStreaming &&
                      message.tokensPerSecond != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.speed_rounded,
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${message.tokensPerSecond!.toStringAsFixed(1)} tok/s',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                        ),
                        if (message.totalTokens != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.token_rounded,
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${message.totalTokens} tokens',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppColors.textMuted,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  if (message.wasCancelled) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cancel_outlined,
                            size: 12,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Cancelled',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppColors.warning,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 10),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
