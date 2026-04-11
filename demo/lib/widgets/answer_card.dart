import 'package:flutter/material.dart';
import 'package:demo/models/answer.dart';
import 'package:demo/models/reaction.dart';
import 'package:intl/intl.dart';

class AnswerCard extends StatelessWidget {
  final Answer answer;
  final Function(ReactionType)? onReaction;
  final String? currentUserId;
  final VoidCallback? onDelete;
  final bool isQuestionAuthor;
  final VoidCallback? onMarkHelpful;

  const AnswerCard({
    super.key,
    required this.answer,
    this.onReaction,
    this.currentUserId,
    this.onDelete,
    this.isQuestionAuthor = false,
    this.onMarkHelpful,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: answer.isHelpful
          ? RoundedRectangleBorder(
          side: const BorderSide(color: Colors.green, width: 2),
          borderRadius: BorderRadius.circular(12))
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // API Response (Helpful Badge)
            if (answer.isHelpful)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 4),
                    Text(
                      "Helpful Answer",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

            // Author info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(answer.userAvatar),
                        radius: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              answer.userName,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              DateFormat(
                                'MMM d, yyyy - HH:mm',
                              ).format(answer.createdAt),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Row(
                  children: [
                    // Mark as Helpful Button (Only for Question Author)
                    if (isQuestionAuthor && !answer.isHelpful)
                      TextButton.icon(
                        onPressed: onMarkHelpful,
                        icon: const Icon(Icons.check, size: 16, color: Colors.green),
                        label: const Text('Mark Helpful', style: TextStyle(color: Colors.green, fontSize: 12)),
                      ),

                    if (answer.userId == currentUserId)
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: const Text('Delete'),
                            onTap: onDelete,
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Answer content
            Text(answer.content, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),

            // Reactions
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Renamed 'Helpful' to 'Like' to avoid confusion with the new feature
                _ReactionButton(
                  icon: Icons.thumb_up_outlined,
                  count: answer.likeCount,
                  label: 'Like',
                  onPressed: onReaction != null
                      ? () => onReaction!(ReactionType.like)
                      : null,
                  isActive: answer.reactions.any(
                        (r) =>
                    r.userId == currentUserId &&
                        r.type == ReactionType.like,
                  ),
                ),
                const SizedBox(width: 8),
                _ReactionButton(
                  icon: Icons.favorite_outline,
                  count: answer.heartCount,
                  label: 'Love',
                  onPressed: onReaction != null
                      ? () => onReaction!(ReactionType.heart)
                      : null,
                  isActive: answer.reactions.any(
                        (r) =>
                    r.userId == currentUserId &&
                        r.type == ReactionType.heart,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReactionButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final VoidCallback? onPressed;
  final bool isActive;

  const _ReactionButton({
    required this.icon,
    required this.count,
    required this.label,
    this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isActive ? Colors.red : null),
            const SizedBox(width: 4),
            Text(
              count > 0 ? '$count' : label,
              style: TextStyle(
                color: isActive ? Colors.red : null,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}