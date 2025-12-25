import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vipt/app/core/values/colors.dart';
import 'package:vipt/app/routes/pages.dart';

class FloatingChatButton extends StatefulWidget {
  const FloatingChatButton({Key? key}) : super(key: key);

  @override
  State<FloatingChatButton> createState() => _FloatingChatButtonState();
}

class _FloatingChatButtonState extends State<FloatingChatButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Bắt đầu animation lặp lại
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tính toán vị trí bottom dựa trên bottom navigation bar
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final bottomNavBarHeight = kBottomNavigationBarHeight;
    final buttonBottom = bottomPadding + bottomNavBarHeight + 16;
    
    return Positioned(
      right: 16,
      bottom: buttonBottom,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FloatingActionButton(
          heroTag: "chatbot_button",
          backgroundColor: AppColor.primaryColor,
          onPressed: () {
            Get.toNamed(Routes.chatbot);
          },
          child: Icon(
            Icons.chat_bubble,
            color: Colors.white,
          ),
          elevation: 4,
        ),
      ),
    );
  }
}

