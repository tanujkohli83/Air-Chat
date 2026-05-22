import 'dart:convert';

import 'package:chatapp/core/models/chat_user.dart';
import 'package:chatapp/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.user,
    this.radius = 24,
    this.showOnlineDot = false,
  });

  final ChatUser? user;
  final double radius;
  final bool showOnlineDot;

  @override
  Widget build(BuildContext context) {
    final imageProvider = _imageProvider(user);
    final initials = user?.initials ?? 'U';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: imageProvider == null ? AppGradients.indigoViolet : null,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: radius,
            backgroundColor: Colors.transparent,
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? Text(
                    initials,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : null,
          ),
        ),
        if (showOnlineDot)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  ImageProvider? _imageProvider(ChatUser? user) {
    final photoBase64 = user?.photoBase64;
    if (photoBase64 != null && photoBase64.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(photoBase64));
      } on FormatException {
        return null;
      }
    }

    final photoUrl = user?.photoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return NetworkImage(photoUrl);
    }

    return null;
  }
}
