import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../models/my_ticket.dart';
import '../services/ocr_service.dart';
import '../services/ticket_storage.dart';
import '../widgets/lotto_widgets.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isScanning = false;
  OcrScanResult? _result;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = '카메라를 사용할 수 없습니다.';
        });
        return;
      }
      final camera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      _initializeControllerFuture = controller.initialize();
      setState(() {
        _controller = controller;
      });
    } catch (error) {
      setState(() {
        _errorMessage = '카메라 초기화에 실패했습니다.';
      });
    }
  }

  Future<void> _scanTicket() async {
    if (_controller == null || _initializeControllerFuture == null) {
      return;
    }
    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });
    try {
      await _initializeControllerFuture;
      final file = await _controller!.takePicture();
      final result = await OcrService.instance.recognizeLottoNumbers(file.path);
      if (!mounted) {
        return;
      }
      setState(() {
        _result = result;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = '스캔에 실패했습니다.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _saveTicket() async {
    final result = _result;
    if (result == null || result.numbers.isEmpty) {
      return;
    }
    final round = await _promptRound();
    if (!mounted) {
      return;
    }
    final ticket = MyTicket(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      numbers: result.numbers,
      purchaseDate: DateTime.now(),
      round: round,
    );
    await TicketStorage.instance.saveTicket(ticket);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('내 티켓에 저장했습니다.')),
    );
  }

  Future<int?> _promptRound() async {
    final controller = TextEditingController();
    final result = await showDialog<int?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('회차 입력'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: '예: 1120',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('건너뛰기'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = int.tryParse(controller.text.trim());
                Navigator.pop(context, value);
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
    return result;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const SectionTitle(
            title: '로또 용지 스캔',
            subtitle: '카메라로 찍고 번호를 인식합니다.',
          ),
          const SizedBox(height: 16),
          _CameraPreviewCard(
            controller: _controller,
            initializeFuture: _initializeControllerFuture,
            errorMessage: _errorMessage,
          ),
          const SizedBox(height: 16),
          if (_isScanning) const LinearProgressIndicator(),
          if (_isScanning) const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isScanning ? null : _scanTicket,
            icon: const Icon(Icons.document_scanner_rounded),
            label: const Text('스캔'),
          ),
          const SizedBox(height: 12),
          if (result != null) _ScanResultCard(result: result),
          if (result != null && result.numbers.isNotEmpty) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _saveTicket,
              icon: const Icon(Icons.save_rounded),
              label: const Text('내 티켓에 저장'),
            ),
          ]
        ],
      ),
    );
  }
}

class _CameraPreviewCard extends StatelessWidget {
  const _CameraPreviewCard({
    required this.controller,
    required this.initializeFuture,
    required this.errorMessage,
  });

  final CameraController? controller;
  final Future<void>? initializeFuture;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0D6C6)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (errorMessage != null) {
      return Center(
        child: Text(
          errorMessage!,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    if (controller == null || initializeFuture == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return FutureBuilder<void>(
      future: initializeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              '카메라 프리뷰를 준비하지 못했어요.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }
        return AspectRatio(
          aspectRatio: controller!.value.aspectRatio,
          child: CameraPreview(controller!),
        );
      },
    );
  }
}

class _ScanResultCard extends StatelessWidget {
  const _ScanResultCard({required this.result});

  final OcrScanResult result;

  @override
  Widget build(BuildContext context) {
    final numbers = result.numbers;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '인식 결과',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          if (numbers.isEmpty)
            Text(
              '번호를 찾지 못했습니다. 다시 시도해주세요.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: numbers
                  .map((number) => NumberBall(number: number, isBonus: false))
                  .toList(),
            ),
          if (result.rawText.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              result.rawText.trim(),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                  ),
            ),
          ]
        ],
      ),
    );
  }
}
