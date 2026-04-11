import 'package:flutter/material.dart';
import 'package:demo/models/question.dart';
import 'package:demo/models/reaction.dart';
import 'package:demo/widgets/tag_widget.dart';
import 'package:intl/intl.dart';

class QuestionCard extends StatelessWidget {
  final Question question;
  final VoidCallback onTap;
  final Function(ReactionType)? onReaction;
  final String? currentUserId;

  const QuestionCard({
    super.key,
    required this.question,
    required this.onTap,
    this.onReaction,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0x1A2E6BFF)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                question.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0D1B3D),
                ),
              ),
              const SizedBox(height: 8),

              // Description preview
              Text(
                question.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF5C6B8C)),
              ),
              const SizedBox(height: 12),

              // Tags (assuming TagWidget already styled, else tell me)
              Wrap(
                spacing: 8,
                children: question.tags
                    .map((tag) => TagWidget(tag: tag, isClickable: false))
                    .toList(),
              ),
              const SizedBox(height: 12),

              // Author info and stats
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(question.userAvatar),
                          radius: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                question.userName,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(color: const Color(0xFF0D1B3D)),
                              ),
                              Text(
                                DateFormat(
                                  'MMM d, yyyy',
                                ).format(question.createdAt),
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: const Color(0xFF7A89A8)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Stats
                  SizedBox(
                    width: 100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _StatItem(
                          icon: Icons.chat_bubble_outline,
                          count: question.answerCount,
                          label: 'answers',
                        ),
                        const SizedBox(height: 4),
                        _StatItem(
                          icon: Icons.visibility_outlined,
                          count: question.views,
                          label: 'views',
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Reactions row
              if (onReaction != null) ...[
                const SizedBox(height: 12),
                const Divider(color: Color(0x1A2E6BFF)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _ReactionButton(
                      icon: Icons.thumb_up_outlined,
                      count: question.likeCount,
                      label: 'Like',

                      onPressed: () => onReaction!(ReactionType.like),
                    ),
                    const SizedBox(width: 12),
                    _ReactionButton(
                      icon: Icons.favorite_outline,
                      count: question.heartCount,
                      label: 'Heart',

                      onPressed: () => onReaction!(ReactionType.heart),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;

  const _StatItem({
    required this.icon,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 4),
        Text(
          '$count $label',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: const Color(0xFF7A89A8)),
        ),
      ],
    );
  }
}

class _ReactionButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final VoidCallback onPressed;

  const _ReactionButton({
    required this.icon,
    required this.count,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF7A89A8)),
            const SizedBox(width: 4),
            Text(
              count > 0 ? '$count' : label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: const Color(0xFF7A89A8)),
            ),
          ],
        ),
      ),
    );
  }
}
