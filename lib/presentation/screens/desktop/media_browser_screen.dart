// lib/presentation/screens/desktop/media_browser_screen.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
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

  Directory? _currentDirectory;
  List<FileSystemEntity> _files = [];
  List<String> _recentFiles = [];
  String? _selectedFile;
  bool _isLoading = false;
  String? _errorMessage;
  String _sortBy = 'name';
  bool _ascending = true;

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

    _initializeDirectory();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _initializeDirectory() {
    setState(() {
      _isLoading = true;
    });

    try {
      if (Platform.isMacOS) {
        _currentDirectory = Directory(
          '/Users/${Platform.environment['USER']}/Desktop',
        );
      } else if (Platform.isWindows) {
        _currentDirectory = Directory(
          '${Platform.environment['USERPROFILE']}\\Desktop',
        );
      } else {
        _currentDirectory = Directory.current;
      }

      if (!_currentDirectory!.existsSync()) {
        _currentDirectory = Directory.current;
      }

      _loadDirectory(_currentDirectory!);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize directory: $e';
        _isLoading = false;
      });
    }
  }

  void _loadDirectory(Directory directory) {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final entities = directory.listSync()
        ..sort((a, b) {
          if (_sortBy == 'name') {
            final comparison = path
                .basename(a.path)
                .toLowerCase()
                .compareTo(path.basename(b.path).toLowerCase());
            return _ascending ? comparison : -comparison;
          } else if (_sortBy == 'modified') {
            final aStat = a.statSync();
            final bStat = b.statSync();
            final comparison = aStat.modified.compareTo(bStat.modified);
            return _ascending ? comparison : -comparison;
          } else if (_sortBy == 'size') {
            if (a is File && b is File) {
              final comparison = a.lengthSync().compareTo(b.lengthSync());
              return _ascending ? comparison : -comparison;
            }
          }
          return 0;
        });

      setState(() {
        _currentDirectory = directory;
        _files = entities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load directory: $e';
        _isLoading = false;
      });
    }
  }

  bool _isMediaFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase().substring(1);
    return AppConstants.supportedVideoFormats.contains(extension) ||
        AppConstants.supportedImageFormats.contains(extension) ||
        AppConstants.supportedDocumentFormats.contains(extension);
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

  Future<void> _streamSelectedFile() async {
    if (_selectedFile == null) return;

    try {
      final canUse = await _authService.canUseService();
      if (!canUse) {
        _showError(
          'Usage limit reached. Please upgrade your plan or contact support.',
        );
        return;
      }

      final success = await _authService.decrementDailyUsage();
      if (!success) {
        _showError('Failed to start streaming. Please try again.');
        return;
      }

      // Add to recent files
      if (!_recentFiles.contains(_selectedFile!)) {
        setState(() {
          _recentFiles.insert(0, _selectedFile!);
          if (_recentFiles.length > 10) {
            _recentFiles.removeLast();
          }
        });
      }

      _showSuccess('Streaming $_selectedFile via VirtuCam virtual camera');
      // Here you would implement the actual streaming logic
    } catch (e) {
      _showError('Failed to start streaming: $e');
    }
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
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              if (value == _sortBy) {
                setState(() => _ascending = !_ascending);
              } else {
                setState(() {
                  _sortBy = value;
                  _ascending = true;
                });
              }
              if (_currentDirectory != null) {
                _loadDirectory(_currentDirectory!);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'name', child: Text('Sort by Name')),
              const PopupMenuItem(
                value: 'modified',
                child: Text('Sort by Date'),
              ),
              const PopupMenuItem(value: 'size', child: Text('Sort by Size')),
            ],
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Row(
          children: [
            Expanded(flex: 3, child: _buildFileExplorer(isSmallScreen)),
            if (!isSmallScreen) Container(width: 1, color: Colors.grey[300]),
            if (!isSmallScreen)
              Expanded(flex: 2, child: _buildPreviewPanel(isSmallScreen)),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(isSmallScreen),
    );
  }

  Widget _buildFileExplorer(bool isSmallScreen) {
    return Column(
      children: [
        _buildNavigationBar(isSmallScreen),
        if (_recentFiles.isNotEmpty) _buildRecentFiles(isSmallScreen),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? _buildErrorView()
              : _buildFileGrid(isSmallScreen),
        ),
      ],
    );
  }

  Widget _buildNavigationBar(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _currentDirectory?.parent != null
                ? () => _loadDirectory(_currentDirectory!.parent)
                : null,
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Go back',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 8 : 12,
                vertical: isSmallScreen ? 6 : 8,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _currentDirectory?.path ?? '',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  fontFamily: 'monospace',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _currentDirectory != null
                ? () => _loadDirectory(_currentDirectory!)
                : null,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildRecentFiles(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Files',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _recentFiles.length,
              itemBuilder: (context, index) {
                final file = _recentFiles[index];
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: Icon(
                      _getFileIcon(file),
                      size: 16,
                      color: Colors.blue[600],
                    ),
                    label: Text(
                      path.basename(file),
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () {
                      setState(() => _selectedFile = file);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileGrid(bool isSmallScreen) {
    final mediaFiles = _files.where((file) {
      return file is File && _isMediaFile(file.path);
    }).toList();

    final directories = _files.where((file) => file is Directory).toList();

    return ListView(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      children: [
        if (directories.isNotEmpty) ...[
          Text(
            'Folders',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          ...directories.map(
            (dir) => _buildDirectoryTile(dir as Directory, isSmallScreen),
          ),
          const SizedBox(height: 16),
        ],
        if (mediaFiles.isNotEmpty) ...[
          Text(
            'Media Files (${mediaFiles.length})',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          ...mediaFiles.map(
            (file) => _buildFileTile(file as File, isSmallScreen),
          ),
        ],
        if (mediaFiles.isEmpty && directories.isEmpty)
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No media files found in this directory'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDirectoryTile(Directory directory, bool isSmallScreen) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(Icons.folder, color: Colors.orange[600]),
        title: Text(
          path.basename(directory.path),
          style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
        ),
        onTap: () => _loadDirectory(directory),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildFileTile(File file, bool isSmallScreen) {
    final isSelected = _selectedFile == file.path;
    final fileStats = file.statSync();

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      color: isSelected ? Colors.blue[50] : null,
      child: ListTile(
        leading: Icon(
          _getFileIcon(file.path),
          color: isSelected ? Colors.blue[600] : Colors.grey[600],
        ),
        title: Text(
          path.basename(file.path),
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          '${_formatFileSize(fileStats.size)} • ${_formatDate(fileStats.modified)}',
          style: TextStyle(fontSize: isSmallScreen ? 12 : 13),
        ),
        onTap: () {
          setState(() {
            _selectedFile = isSelected ? null : file.path;
          });
        },
        trailing: isSelected
            ? Icon(Icons.check_circle, color: Colors.blue[600])
            : null,
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

    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            path.basename(_selectedFile!),
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
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getFileIcon(_selectedFile!),
                    size: 64,
                    color: Colors.grey[400],
                  ),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          if (_selectedFile != null) ...[
            Expanded(
              child: Text(
                path.basename(_selectedFile!),
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 16),
          ],
          ElevatedButton.icon(
            onPressed: _selectedFile != null ? _streamSelectedFile : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 20,
                vertical: isSmallScreen ? 12 : 14,
              ),
            ),
            icon: const Icon(Icons.play_arrow),
            label: Text(
              'Stream via VirtuCam',
              style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Error loading directory',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(_errorMessage!),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initializeDirectory,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
