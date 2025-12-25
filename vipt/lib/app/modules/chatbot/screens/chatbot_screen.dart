import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vipt/app/core/values/colors.dart';
import '../chatbot_controller.dart';

class ChatbotScreen extends StatelessWidget {
  ChatbotScreen({Key? key}) : super(key: key);

  final TextEditingController _textController = TextEditingController();

  // Hàm để loại bỏ markdown formatting và các ký tự lạ
  String _cleanMarkdown(String text) {
    // Loại bỏ các ký tự lạ và markdown formatting
    String cleaned = text
        // Loại bỏ $1, $2, etc. (ký tự đặc biệt từ AI)
        .replaceAll(RegExp(r'\$\d+'), '') // $1, $2, etc.
        .replaceAll(RegExp(r'#\d+'), '') // #1, #2, etc.
        // Loại bỏ markdown formatting - dùng replacement đúng cách
        .replaceAllMapped(RegExp(r'\*\*(.*?)\*\*'), (match) => match.group(1) ?? '') // **bold**
        .replaceAllMapped(RegExp(r'(?<!\*)\*([^*]+?)\*(?!\*)'), (match) => match.group(1) ?? '') // *italic* (không phải **)
        .replaceAllMapped(RegExp(r'_(.*?)_'), (match) => match.group(1) ?? '') // _italic_
        .replaceAllMapped(RegExp(r'`(.*?)`'), (match) => match.group(1) ?? '') // `code`
        .replaceAll(RegExp(r'#{1,6}\s+'), '') // Headers
        .replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), (match) => match.group(1) ?? '') // Links
        // Loại bỏ numbered lists nhưng giữ nội dung
        .replaceAll(RegExp(r'^\d+\.\s+', multiLine: true), '') // Numbered lists
        .replaceAll(RegExp(r'^\$\d+\s+', multiLine: true), '') // $1, $2 at start of line
        // Giữ bullet lists (gạch đầu dòng) vì đó là format mong muốn
        // Không xóa gạch đầu dòng (-)
        // Loại bỏ khoảng trắng thừa
        .replaceAll(RegExp(r'\s+'), ' ') // Multiple spaces to single
        .replaceAll(RegExp(r'\n\s*\n'), '\n') // Multiple newlines to single
        .trim();

    return cleaned;
  }

  @override
  Widget build(BuildContext context) {
    final _controller = Get.find<ChatbotController>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0.5,
        title: Text(
          'Chatbot AI',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline),
            onPressed: () {
              Get.dialog(
                AlertDialog(
                  title: Text('Xóa cuộc trò chuyện'),
                  content: Text('Bạn có chắc muốn xóa toàn bộ cuộc trò chuyện?'),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () {
                        _controller.clearChat();
                        Get.back();
                      },
                      child: Text('Xóa', style: TextStyle(color: AppColor.errorColor)),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Xóa cuộc trò chuyện',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() => _controller.messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade400),
                        SizedBox(height: 16),
                        Text(
                          'Bắt đầu cuộc trò chuyện',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _controller.scrollController,
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    itemCount: _controller.messages.length + (_controller.isLoading.value ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _controller.messages.length) {
                        // Loading indicator
                        return Padding(
                          padding: EdgeInsets.all(16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Đang suy nghĩ...'),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      final message = _controller.messages[index];
                      final isUser = message['role'] == 'user';
                      
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: isUser 
                                    ? AppColor.primaryColor 
                                    : AppColor.textFieldFill,
                                borderRadius: BorderRadius.circular(16).copyWith(
                                  bottomRight: isUser ? Radius.circular(4) : null,
                                  bottomLeft: !isUser ? Radius.circular(4) : null,
                                ),
                              ),
                              child: SelectableText(
                                _cleanMarkdown(message['content'] ?? ''),
                                style: TextStyle(
                                  color: isUser ? Colors.white : AppColor.textColor,
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  )),
          ),
          Obx(() => _controller.isLoading.value 
              ? Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: LinearProgressIndicator(),
                )
              : SizedBox.shrink()
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColor.textFieldFill,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _textController,
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          decoration: InputDecoration(
                            hintText: 'Nhập tin nhắn...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (value) {
                            _controller.sendMessage(value);
                            _textController.clear();
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Obx(() => Container(
                      decoration: BoxDecoration(
                        color: _controller.isLoading.value 
                            ? AppColor.disableButtonColor
                            : AppColor.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: _controller.isLoading.value
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Icon(Icons.send, color: Colors.white),
                        onPressed: _controller.isLoading.value
                            ? null
                            : () {
                                if (_textController.text.trim().isNotEmpty) {
                                  _controller.sendMessage(_textController.text);
                                  _textController.clear();
                                }
                              },
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

