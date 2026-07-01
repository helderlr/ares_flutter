import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_assets.dart';
import '../constants/app_colors.dart';

class UserAvatar extends StatefulWidget {
  final double radius;
  final bool showCameraButton;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.radius = 40,
    this.showCameraButton = false,
    this.onTap,
  });

  @override
  State<UserAvatar> createState() => UserAvatarState();
}

class UserAvatarState extends State<UserAvatar> {
  static const String _userAvatarKey = 'user_avatar_path';
  File? _userAvatarFile;

  @override
  void initState() {
    super.initState();
    reloadAvatar();
  }

  Future<void> reloadAvatar() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? savedPath = prefs.getString(_userAvatarKey);
    if (savedPath == null || savedPath.isEmpty) {
      if (mounted) {
        setState(() => _userAvatarFile = null);
      }
      return;
    }
    final File file = File(savedPath);
    if (await file.exists()) {
      if (mounted) {
        setState(() => _userAvatarFile = file);
      }
      return;
    }
    await prefs.remove(_userAvatarKey);
    if (mounted) {
      setState(() => _userAvatarFile = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ImageProvider avatarImage;
    if (_userAvatarFile != null) {
      avatarImage = FileImage(_userAvatarFile!);
    } else {
      avatarImage = const AssetImage(AppAssets.defaultUserAvatar);
    }
    final Widget avatar = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.lightBlue,
          width: widget.radius > 44 ? 3 : 2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.lightBlue.withOpacity(0.22),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: widget.radius,
        backgroundColor: AppColors.lightBlue.withOpacity(0.08),
        backgroundImage: avatarImage,
      ),
    );
    if (!widget.showCameraButton) {
      if (widget.onTap == null) {
        return avatar;
      }
      return InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(widget.radius + 8),
        child: avatar,
      );
    }
    return Stack(
      alignment: Alignment.bottomRight,
      children: <Widget>[
        avatar,
        InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            padding: const EdgeInsets.all(6),
            child: const Icon(
              Icons.camera_alt,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }
}
