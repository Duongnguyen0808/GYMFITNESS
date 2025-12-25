import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:vipt/app/core/values/colors.dart';
import 'package:vipt/app/core/values/values.dart';
import 'package:vipt/app/data/models/workout.dart';
import 'package:vipt/app/data/models/workout_equipment.dart';
import 'package:vipt/app/data/providers/workout_equipment_provider_api.dart';
import 'package:vipt/app/data/providers/workout_provider_api.dart';
import 'package:vipt/app/data/services/data_service.dart';
import 'package:vipt/app/global_widgets/network_image.dart';
import 'package:vipt/app/modules/loading/screens/loading_screen.dart';
import 'dart:async';

class ExerciseDetail extends StatefulWidget {
  const ExerciseDetail({Key? key}) : super(key: key);

  @override
  State<ExerciseDetail> createState() => _ExerciseDetailState();
}

class _ExerciseDetailState extends State<ExerciseDetail> {
  // Lấy workout ID từ arguments (có thể là Workout hoặc workout ID)
  final dynamic _argument = Get.arguments;

  Workout? workout;
  String categories = '';
  List<WorkoutEquipment> equipment = [];
  VideoPlayerController? _controller;
  String animationLink = '';
  bool isLoading = true;
  String? errorMessage;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  Timer? _updateTimer;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _loadWorkoutData();
  }

  // Fetch dữ liệu mới từ Firebase
  Future<void> _loadWorkoutData() async {
    try {
      String workoutId;

      // Nếu argument là Workout, lấy ID từ đó
      if (_argument is Workout) {
        workoutId = (_argument as Workout).id ?? '';
      } else if (_argument is String) {
        workoutId = _argument;
      } else {
        setState(() {
          errorMessage = 'Dữ liệu không hợp lệ';
          isLoading = false;
        });
        return;
      }

      // Fetch workout mới từ Firebase
      final workoutProvider = WorkoutProvider();
      final fetchedWorkout = await workoutProvider.fetch(workoutId);

      setState(() {
        workout = fetchedWorkout;
        isLoading = false;
      });

      // Sau khi có workout, load các dữ liệu liên quan
      _getCategories();
      _initVideoController();
      _getEquipmentList();
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi khi tải dữ liệu: $e';
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _updateTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_isDragging) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _showControlsTemporarily() {
    setState(() {
      _showControls = true;
    });
    _startHideControlsTimer();
  }

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero || duration.isNegative) {
      return '00:00';
    }
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final totalSeconds = duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  void _openFullscreen(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullscreenVideoPlayer(
          controller: _controller!,
        ),
      ),
    );
  }

  _getEquipmentList() async {
    if (workout == null) return;

    for (var item in workout!.equipmentIDs) {
      final element = await WorkoutEquipmentProvider().fetch(item);
      if (!equipment.contains(element)) {
        equipment.add(element);
        if (mounted) setState(() {});
      }
    }
  }

  void _initVideoController() async {
    var link = await _getAnimationLink();
    if (link == null) return;
    _controller = VideoPlayerController.network(link);

    try {
      await _controller!.initialize();

      int retryCount = 0;
      while (_controller!.value.duration == Duration.zero && retryCount < 30) {
        await Future.delayed(const Duration(milliseconds: 200));
        retryCount++;
        if (!_controller!.value.isInitialized) break;
      }

      if (mounted) {
        setState(() {
          _controller!.setLooping(true);
          _controller!.play();
        });

        _controller!.addListener(() {
          if (mounted) {
            setState(() {});
          }
        });

        _updateTimer?.cancel();
        _updateTimer =
            Timer.periodic(const Duration(milliseconds: 100), (timer) {
          if (mounted &&
              _controller != null &&
              _controller!.value.isInitialized) {
            setState(() {});
          } else {
            timer.cancel();
          }
        });

        _startHideControlsTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _getCategories() {
    if (workout == null) return;

    var list = workout!.categoryIDs
        .map((e) {
          final cate = DataService.instance.workoutCateList
              .firstWhereOrNull((element) => element.id == e);
          return cate?.name ?? '';
        })
        .where((name) => name.isNotEmpty)
        .toList();
    for (int i = 0; i < list.length; i++) {
      if (i == list.length - 1) {
        categories += list[i];
      } else {
        categories += list[i] + ',' + ' ';
      }
    }
    if (mounted) setState(() {});
  }

  Future<dynamic> _getAnimationLink() async {
    return workout?.animation;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const LoadingScreen();
    }

    if (errorMessage != null || workout == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                errorMessage ?? 'Không tìm thấy dữ liệu',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Hero(
            tag: 'leadingButtonAppBar',
            child: Icon(Icons.arrow_back_ios_new_rounded),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
      ),
      body: Container(
        padding: AppDecoration.screenPadding.copyWith(top: 8, bottom: 0),
        child: LayoutBuilder(builder: (context, constraints) {
          return ListView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            children: [
              Container(
                alignment: Alignment.center,
                child: Text(
                  workout!.name,
                  style: Theme.of(context).textTheme.displayMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  categories,
                  style: Theme.of(context).textTheme.titleSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth,
                  ),
                  child: _buildMediaPlayer(),
                ),
              ),
              if (equipment.isNotEmpty)
                Container(
                  padding: const EdgeInsets.only(
                    top: 24,
                    bottom: 8,
                  ),
                  child: Text(
                    'Trang thiết bị/dụng cụ',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              if (equipment.isNotEmpty)
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth,
                      maxHeight: constraints.maxHeight * 0.25,
                    ),
                    child: _buildEquipmentList(),
                  ),
                ),
              if (equipment.isNotEmpty)
                // Tên Equipment.
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    equipment[0].name,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              Container(
                padding: const EdgeInsets.only(
                  top: 24,
                  bottom: 8,
                ),
                child: Text(
                  'Gợi ý',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              Text(workout!.hints,
                  style: Theme.of(context).textTheme.bodyLarge),
              Container(
                padding: const EdgeInsets.only(top: 24, bottom: 8),
                child: Text(
                  'Hít thở',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              Text(workout!.breathing,
                  style: Theme.of(context).textTheme.bodyLarge),
              Container(
                padding: const EdgeInsets.only(top: 24, bottom: 8),
                child: Text(
                  'Nhóm cơ tập trung',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              _buildMuscleFocus(constraints),
              SizedBox(
                height: constraints.maxHeight * 0.03,
              )
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMuscleFocus(constraints) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: constraints.maxWidth,
          maxHeight: constraints.maxHeight * 0.5,
        ),
        child: MyNetworkImage(url: workout!.muscleFocusAsset),
      ),
    );
  }

  Widget _buildEquipmentList() {
    return MyNetworkImage(url: equipment[0].imageLink);
  }

  Widget _buildMediaPlayer() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColor.textFieldFill,
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        _showControlsTemporarily();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          ),
          if (_showControls)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black.withOpacity(0.3),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Play/Pause button
                    IconButton(
                      icon: Icon(
                        _controller!.value.isPlaying
                            ? Icons.pause_circle_outline
                            : Icons.play_circle_outline,
                        size: 64,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        _showControlsTemporarily();
                        if (_controller!.value.isPlaying) {
                          _controller!.pause();
                        } else {
                          _controller!.play();
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    // Progress bar and time
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // Progress slider
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: Colors.white,
                              inactiveTrackColor: Colors.white.withOpacity(0.3),
                              thumbColor: Colors.white,
                              overlayColor: Colors.white.withOpacity(0.2),
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8,
                              ),
                              trackHeight: 3,
                            ),
                            child: Slider(
                              value: _controller!.value.position.inMilliseconds
                                  .toDouble(),
                              min: 0,
                              max: _controller!.value.duration.inMilliseconds
                                  .toDouble(),
                              onChanged: (value) {
                                setState(() {
                                  _isDragging = true;
                                });
                                _controller!.seekTo(
                                    Duration(milliseconds: value.toInt()));
                              },
                              onChangeEnd: (value) {
                                setState(() {
                                  _isDragging = false;
                                });
                                _showControlsTemporarily();
                              },
                            ),
                          ),
                          // Time display and fullscreen button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Builder(
                                builder: (context) {
                                  if (_controller == null ||
                                      !_controller!.value.isInitialized) {
                                    return const Text(
                                      '00:00',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    );
                                  }
                                  final position = _controller!.value.position;
                                  final formatted = _formatDuration(position);
                                  return Text(
                                    formatted,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                              Row(
                                children: [
                                  Builder(
                                    builder: (context) {
                                      if (_controller == null ||
                                          !_controller!.value.isInitialized ||
                                          _controller!.value.duration ==
                                              Duration.zero) {
                                        return const Text(
                                          '00:00',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        );
                                      }
                                      final duration =
                                          _controller!.value.duration;
                                      final formatted =
                                          _formatDuration(duration);
                                      return Text(
                                        formatted,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.fullscreen,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    onPressed: () {
                                      _showControlsTemporarily();
                                      _openFullscreen(context);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FullscreenVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;

  const _FullscreenVideoPlayer({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  State<_FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<_FullscreenVideoPlayer> {
  bool _showControls = true;
  Timer? _hideControlsTimer;
  bool _isDragging = false;

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero || duration.isNegative) {
      return '00:00';
    }
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final totalSeconds = duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  void initState() {
    super.initState();
    _startHideControlsTimer();
    widget.controller.addListener(_onVideoUpdate);
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    widget.controller.removeListener(_onVideoUpdate);
    super.dispose();
  }

  void _onVideoUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_isDragging) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _showControlsTemporarily() {
    setState(() {
      _showControls = true;
    });
    _startHideControlsTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          _showControlsTemporarily();
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video player
            Center(
              child: AspectRatio(
                aspectRatio: widget.controller.value.aspectRatio,
                child: VideoPlayer(widget.controller),
              ),
            ),
            // Controls overlay
            if (_showControls)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Top bar with close button
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.fullscreen_exit,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Play/Pause button
                      IconButton(
                        icon: Icon(
                          widget.controller.value.isPlaying
                              ? Icons.pause_circle_outline
                              : Icons.play_circle_outline,
                          size: 80,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          _showControlsTemporarily();
                          if (widget.controller.value.isPlaying) {
                            widget.controller.pause();
                          } else {
                            widget.controller.play();
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      // Progress bar and time
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            // Progress slider
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: Colors.white,
                                inactiveTrackColor:
                                    Colors.white.withOpacity(0.3),
                                thumbColor: Colors.white,
                                overlayColor: Colors.white.withOpacity(0.2),
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 10,
                                ),
                                trackHeight: 4,
                              ),
                              child: Slider(
                                value: widget
                                    .controller.value.position.inMilliseconds
                                    .toDouble(),
                                min: 0,
                                max: widget
                                    .controller.value.duration.inMilliseconds
                                    .toDouble(),
                                onChanged: (value) {
                                  setState(() {
                                    _isDragging = true;
                                  });
                                  widget.controller.seekTo(
                                      Duration(milliseconds: value.toInt()));
                                },
                                onChangeEnd: (value) {
                                  setState(() {
                                    _isDragging = false;
                                  });
                                  _showControlsTemporarily();
                                },
                              ),
                            ),
                            // Time display
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Builder(
                                  builder: (context) {
                                    if (!widget
                                        .controller.value.isInitialized) {
                                      return const Text(
                                        '00:00',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      );
                                    }
                                    final position =
                                        widget.controller.value.position;
                                    return Text(
                                      _formatDuration(position),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    );
                                  },
                                ),
                                Builder(
                                  builder: (context) {
                                    if (!widget
                                            .controller.value.isInitialized ||
                                        widget.controller.value.duration ==
                                            Duration.zero) {
                                      return const Text(
                                        '00:00',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      );
                                    }
                                    final duration =
                                        widget.controller.value.duration;
                                    return Text(
                                      _formatDuration(duration),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
