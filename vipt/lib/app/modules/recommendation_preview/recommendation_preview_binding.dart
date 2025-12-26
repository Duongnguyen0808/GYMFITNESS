import 'package:get/get.dart';
import 'package:vipt/app/modules/recommendation_preview/recommendation_preview_controller.dart';

class RecommendationPreviewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => RecommendationPreviewController());
  }
}

