import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'chatbot_service.dart';

class ChatbotController extends GetxController {
  final ChatbotService _chatbotService = ChatbotService();
  
  var messages = <Map<String, String>>[].obs;
  var isLoading = false.obs;
  late ScrollController scrollController;

  @override
  void onInit() {
    super.onInit();
    scrollController = ScrollController();
    // Thêm tin nhắn chào mừng
    addWelcomeMessage();
  }

  void addWelcomeMessage() {
    messages.add({
      'role': 'assistant',
      'content': 'Xin chào! Tôi là trợ lý AI của ViPT. Tôi có thể giúp bạn với các câu hỏi về tập luyện, dinh dưỡng, và sức khỏe. Bạn cần hỗ trợ gì hôm nay? 😊'
    });
    
    // Thêm system instruction vào đầu conversation (ẩn với user)
    // Điều này giúp AI hiểu context và trả lời chính xác hơn
  }

  void addMessage(String role, String content) {
    messages.add({'role': role, 'content': content});
    // Scroll xuống tin nhắn mới nhất
    Future.delayed(Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty) return;
    
    // Thêm tin nhắn người dùng
    addMessage('user', userMessage.trim());
    isLoading.value = true;
    
    try {
      // Gửi đến API - chỉ gửi 10 tin nhắn gần nhất để tiết kiệm token
      // Bỏ qua welcome message
      List<Map<String, String>> recentHistory = [];
      List<Map<String, String>> filteredMessages = messages.where((msg) {
        return msg['role'] != null && 
               msg['content'] != null && 
               (msg['role'] == 'user' || msg['role'] == 'assistant');
      }).toList();
      
      if (filteredMessages.length > 10) {
        recentHistory = filteredMessages.sublist(filteredMessages.length - 10).toList();
      } else {
        recentHistory = filteredMessages.toList();
      }
      
      // Loại bỏ tin nhắn user vừa thêm khỏi history (vì sẽ gửi riêng)
      recentHistory.removeWhere((msg) => 
        msg['role'] == 'user' && msg['content'] == userMessage.trim()
      );
      
      String response = await _chatbotService.sendMessage(
        userMessage.trim(), 
        recentHistory
      );
      
      // Thêm phản hồi từ bot
      addMessage('assistant', response);
    } catch (e) {
      String errorMessage = 'Không thể gửi tin nhắn. Vui lòng thử lại sau.';
      
      // Hiển thị lỗi cụ thể nếu có
      if (e.toString().contains('API Error')) {
        String apiError = e.toString().replaceAll('Exception: API Error: ', '');
        if (apiError.contains('API key')) {
          errorMessage = 'Lỗi API key. Vui lòng kiểm tra cấu hình.';
        } else if (apiError.contains('quota') || apiError.contains('limit')) {
          errorMessage = 'Đã vượt quá giới hạn API. Vui lòng thử lại sau.';
        } else {
          errorMessage = 'Lỗi API: $apiError';
        }
      }
      
      Get.snackbar(
        'Lỗi',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 4),
      );
    } finally {
      isLoading.value = false;
    }
  }

  void clearChat() {
    messages.clear();
    addWelcomeMessage();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}

