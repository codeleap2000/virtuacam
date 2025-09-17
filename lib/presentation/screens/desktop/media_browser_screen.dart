// lib/presentation/screens/desktop/media_browser_screen.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/auth_service.dart';

class VirtuCamMediaBrowserScreen extends StatefulWidget {
  const VirtuCamMediaBrowserScreen({super.key});

  @override
  State<VirtuCamMediaBrowserScreen> createState() =>
      _VirtuCamMediaBrowserScreenState();
}

class _VirtuCamMediaBrowserScreenState extends State<VirtuCamMediaBrowserScreen>
    with TickerProviderStateMixin {
  final _authService = AuthService();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  List<String> _recentFiles = [];
  String? _selectedFile;
  bool _isLoading = false;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _disposeVideoController() async {
    if (_videoController != null) {
      await _videoController!.dispose();
      _videoController = null;
    }
  }

  Future<void> _openFilePickerAndStream() async {
    try {
      setState(() => _isLoading = true);

      final canUse = await _authService.canUseService();
      if (!canUse) {
        _showError(
          'Usage limit reached. Please upgrade your plan or contact support.',
        );
        setState(() => _isLoading = false);
        return;
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          ...AppConstants.supportedVideoFormats,
          ...AppConstants.supportedImageFormats,
          ...AppConstants.supportedDocumentFormats,
        ],
        allowMultiple: false,
        dialogTitle: 'Select Media File for VirtuCam Streaming',
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;

        // Verify file exists and is readable
        final file = File(filePath);
        if (!await file.exists()) {
          _showError('Selected file does not exist or is not accessible.');
          setState(() => _isLoading = false);
          return;
        }

        // Check file size (limit to 100MB)
        final fileSize = await file.length();
        if (fileSize > 100 * 1024 * 1024) {
          _showError('File size too large. Maximum size is 100MB.');
          setState(() => _isLoading = false);
          return;
        }

        final success = await _authService.decrementDailyUsage();
        if (!success) {
          _showError('Failed to start streaming. Please try again.');
          setState(() => _isLoading = false);
          return;
        }

        // Add to recent files
        if (!_recentFiles.contains(filePath)) {
          setState(() {
            _recentFiles.insert(0, filePath);
            if (_recentFiles.length > 10) {
              _recentFiles.removeLast();
            }
            _selectedFile = filePath;
          });
        }

        _showSuccess('Streaming $fileName via VirtuCam virtual camera');
        // TODO: Implement actual streaming
        // await VirtuCamPlugin.streamFile(filePath);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to select file: $e');
    }
  }

  IconData _getFileIcon(String filePath) {
    final extension = path.extension(filePath).toLowerCase().substring(1);

    if (AppConstants.supportedVideoFormats.contains(extension)) {
      return Icons.movie;
    } else if (AppConstants.supportedImageFormats.contains(extension)) {
      return Icons.image;
    } else if (AppConstants.supportedDocumentFormats.contains(extension)) {
      return Icons.description;
    } else {
      return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red[600]),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green[600]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('VirtuCam Media Browser'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Row(
          children: [
            // Left side - Finder button and recent files
            Expanded(flex: 2, child: _buildLeftPanel(isSmallScreen)),
            Container(width: 1, color: Colors.grey[300]),
            // Right side - Preview panel
            Expanded(flex: 2, child: _buildPreviewPanel(isSmallScreen)),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftPanel(bool isSmallScreen) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Finder button section
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 20 : 32),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Platform.isMacOS ? Icons.folder : Icons.file_open,
                    size: isSmallScreen ? 32 : 48,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 16 : 24),
                Text(
                  'Select Media File',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Choose videos, images, or documents to stream via VirtuCam',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: isSmallScreen ? 20 : 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _openFilePickerAndStream,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 16 : 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    icon: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Icon(
                            Platform.isMacOS ? Icons.folder : Icons.file_open,
                            size: isSmallScreen ? 20 : 24,
                          ),
                    label: Text(
                      _isLoading
                          ? 'Loading...'
                          : Platform.isMacOS
                          ? 'Open Finder'
                          : 'Browse Files',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Recent files section
          if (_recentFiles.isNotEmpty) ...[
            Divider(color: Colors.grey[300]),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Files',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _recentFiles.length,
                        itemBuilder: (context, index) {
                          final filePath = _recentFiles[index];
                          final fileName = path.basename(filePath);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Icon(
                                _getFileIcon(filePath),
                                color: Colors.blue[600],
                              ),
                              title: Text(
                                fileName,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                ),
                              ),
                              subtitle: Text(
                                filePath,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 13,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () async {
                                await _disposeVideoController();
                                setState(() => _selectedFile = filePath);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewPanel(bool isSmallScreen) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Icon(Icons.preview, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  'File Preview',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedFile != null
                ? _buildFilePreview(isSmallScreen)
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Select a file to preview'),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreview(bool isSmallScreen) {
    final extension = path.extension(_selectedFile!).toLowerCase().substring(1);
    final fileName = path.basename(_selectedFile!);
    final file = File(_selectedFile!);

    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fileName,
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Type: ${extension.toUpperCase()}',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              color: Colors.grey[600],
            ),
          ),
          FutureBuilder<FileStat>(
            future: file.stat(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text(
                  'Size: ${_formatFileSize(snapshot.data!.size)}',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.grey[600],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildPreviewContent(extension, file, isSmallScreen)),
        ],
      ),
    );
  }

  Widget _buildPreviewContent(String extension, File file, bool isSmallScreen) {
    // Image Preview
    if (AppConstants.supportedImageFormats.contains(extension)) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Failed to load image',
                      style: TextStyle(color: Colors.red[600]),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }

    // Video Preview
    if (AppConstants.supportedVideoFormats.contains(extension)) {
      return VideoPreviewWidget(
        file: file,
        isSmallScreen: isSmallScreen,
        onVideoControllerCreated: (controller) {
          _videoController = controller;
        },
      );
    }

    // PDF Preview - Replace this section in _buildPreviewContent method
    if (extension == 'pdf') {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text('PDF Preview'),
            const SizedBox(height: 8),
            Text(
              'PDF preview not available on macOS\nFile will be streamed directly',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }
    // Default placeholder for unsupported formats
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getFileIcon(file.path), size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Preview not available',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'File will be streamed directly',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class VideoPreviewWidget extends StatefulWidget {
  final File file;
  final bool isSmallScreen;
  final Function(VideoPlayerController)? onVideoControllerCreated;

  const VideoPreviewWidget({
    super.key,
    required this.file,
    required this.isSmallScreen,
    this.onVideoControllerCreated,
  });

  @override
  State<VideoPreviewWidget> createState() => _VideoPreviewWidgetState();
}

class _VideoPreviewWidgetState extends State<VideoPreviewWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.file(widget.file);
      widget.onVideoControllerCreated?.call(_controller!);

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _hasError
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Failed to load video',
                      style: TextStyle(color: Colors.red[600]),
                    ),
                  ],
                ),
              )
            : !_isInitialized
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Loading video...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              )
            : Stack(
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.black54,
                      onPressed: () {
                        setState(() {
                          if (_controller!.value.isPlaying) {
                            _controller!.pause();
                          } else {
                            _controller!.play();
                          }
                        });
                      },
                      child: Icon(
                        _controller!.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Video Preview',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
