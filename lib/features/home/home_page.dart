import "dart:convert";

import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:http/http.dart" as http;

import "package:juststockadmin/core/auth_session.dart";
import "package:juststockadmin/core/http_client.dart" as http_client;
import "package:juststockadmin/core/session_store.dart";
import "package:juststockadmin/features/profile/profile_page.dart";
import "package:juststockadmin/features/mlm/mlm_page.dart";

import "../../theme.dart";

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.adminName,
    required this.adminEmail,
  });

  final String adminName;
  final String adminEmail;

  static const _actions = <_DashboardAction>[
    _DashboardAction(
      label: 'Nifty',
      icon: Icons.trending_up,
      endpoint: 'nifty',
    ),
    _DashboardAction(
      label: 'BankNifty',
      icon: Icons.account_balance,
      endpoint: 'banknifty',
    ),
    _DashboardAction(label: 'Stocks', icon: Icons.insights, endpoint: 'stocks'),
    _DashboardAction(
      label: 'Sensex',
      icon: Icons.show_chart,
      endpoint: 'sensex',
    ),
    _DashboardAction(
      label: 'Commodity',
      icon: Icons.auto_graph,
      endpoint: 'commodity',
    ),
  ];

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ProfilePage(
          adminName: widget.adminName,
          adminEmail: widget.adminEmail,
        ),
      ),
    );
  }

  void _openMlmPage() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => MlmPage(adminName: widget.adminName),
      ),
    );
  }

  Future<void> _handleComposeTap(_DashboardAction action) async {
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _ComposeMessageSheet(action: action),
    );

    if (!mounted || message == null || message.trim().isEmpty) {
      return;
    }

    await _sendMessage(action: action, message: message.trim());
  }

  Future<void> _openImageUploadSheet() async {
    final result = await showModalBottomSheet<_ImageUploadResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => const _ImageUploadSheet(),
    );

    if (!mounted || result == null) {
      return;
    }

    await _uploadImages(result);
  }

  Future<void> _uploadImages(_ImageUploadResult data) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) =>
          const Center(child: CircularProgressIndicator()),
    );

    final uploadResult = await _sendImageUploadRequest(data);

    if (navigator.canPop()) {
      navigator.pop();
    }

    if (!mounted) {
      return;
    }

    messenger.showSnackBar(SnackBar(content: Text(uploadResult.message)));
  }

  Future<({bool success, String message})> _sendImageUploadRequest(
    _ImageUploadResult data,
  ) async {
    final uri = Uri.parse(
      'https://backend-server-11f5.onrender.com/api/images/upload',
    );

    final files = [for (final image in data.images) image.asApiPayload()];

    final Map<String, dynamic> payload;
    if (files.length == 1) {
      payload = {'file': files.first};
    } else {
      payload = {'files': files};
    }

    try {
      final http.Client client = http_client.buildHttpClient();
      try {
        final http.Response response = await client.post(
          uri,
          headers: AuthSession.withAuth({'Content-Type': 'application/json'}),
          body: jsonEncode(payload),
        );

        final decoded = _parseResponse(response.body);
        final isCreated = response.statusCode == 201;

        final message =
            decoded.message ??
            (isCreated
                ? 'Images uploaded successfully.'
                : 'Image upload failed. (HTTP ${response.statusCode})');

        if (isCreated) {
          try {
            await SessionStore.touchLastActivityNow();
          } catch (_) {}
          return (success: true, message: message);
        }

        return (success: false, message: message);
      } finally {
        try {
          client.close();
        } catch (_) {}
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to upload images: $error');
      debugPrint('$stackTrace');
      return (success: false, message: 'Network error. Please try again.');
    }
  }

  Future<void> _sendMessage({
    required _DashboardAction action,
    required String message,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) =>
          const Center(child: CircularProgressIndicator()),
    );

    final result = await _sendSegmentMessage(
      endpoint: action.endpoint,
      message: message,
    );

    if (!mounted) {
      return;
    }

    final rootNavigator = Navigator.of(context, rootNavigator: true);
    if (rootNavigator.canPop()) {
      rootNavigator.pop();
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? '${action.label} sent successfully.'
              : result.message,
        ),
      ),
    );
  }

  Future<({bool success, String message})> _sendSegmentMessage({
    required String endpoint,
    required String message,
  }) async {
    final uri = Uri.parse(
      'https://backend-server-11f5.onrender.com/api/segments/$endpoint',
    );

    try {
      final http.Client client = http_client.buildHttpClient();
      try {
        final http.Response response = await client.post(
          uri,
          headers: AuthSession.withAuth({'Content-Type': 'application/json'}),
          body: jsonEncode({'message': message}),
        );

        final decoded = _parseResponse(response.body);
        final success =
            decoded.success ??
            (response.statusCode >= 200 && response.statusCode < 300);
        final serverMessage =
            decoded.message ??
            (success
                ? 'Message sent successfully.'
                : 'Unable to send message.');

        if (success) {
          try {
            await SessionStore.touchLastActivityNow();
          } catch (_) {}
        }

        return (success: success, message: serverMessage);
      } finally {
        try {
          client.close();
        } catch (_) {}
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to send segment message ($endpoint): $error');
      debugPrint('$stackTrace');
      return (success: false, message: 'Network error. Please try again.');
    }
  }

  ({bool? success, String? message}) _parseResponse(String body) {
    try {
      final dynamic decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        bool? success;
        final successValue = decoded['success'];
        if (successValue is bool) {
          success = successValue;
        }
        final okValue = decoded['ok'];
        if (success == null && okValue is bool) {
          success = okValue;
        }
        final statusValue = decoded['status'];
        if (success == null && statusValue is String) {
          final normalized = statusValue.toLowerCase();
          if (normalized == 'success' || normalized == 'ok') {
            success = true;
          } else if (normalized == 'error' ||
              normalized == 'failed' ||
              normalized == 'failure') {
            success = false;
          }
        }

        String? message;
        for (final key in ['message', 'msg', 'error', 'detail', 'status']) {
          final value = decoded[key];
          if (value is String && value.trim().isNotEmpty) {
            message = value;
            break;
          }
        }

        return (success: success, message: message);
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to parse response body: $error');
      debugPrint('$stackTrace');
    }
    return (success: null, message: null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmedName = widget.adminName.trim();
    final displayName = trimmedName.isEmpty ? 'Admin' : trimmedName;
    final initial = displayName[0].toUpperCase();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 88,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'JustStock',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Admin Dashboard',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Semantics(
              label: 'Open profile',
              button: true,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openProfile,
                  customBorder: const CircleBorder(),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: buildHeaderGradient()),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, $displayName!',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap a segment icon to compose and send a message, or upload marketing images below.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final action in HomePage._actions)
                  _ActionTile(
                    action: action,
                    onTap: () => _handleComposeTap(action),
                  ),
                _UploadImagesTile(onTap: _openImageUploadSheet),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Team growth tools',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 12),
            _MlmShortcut(onTap: _openMlmPage),
          ],
        ),
      ),
    );
  }
}

class _ComposeMessageSheet extends StatefulWidget {
  const _ComposeMessageSheet({required this.action});

  final _DashboardAction action;

  @override
  State<_ComposeMessageSheet> createState() => _ComposeMessageSheetState();
}

class _ComposeMessageSheetState extends State<_ComposeMessageSheet> {
  late final TextEditingController _controller;
  bool _showValidationError = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _showValidationError = true);
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: bottomInset + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    gradient: buildHeaderGradient(),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.action.icon, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Text(
                  'Compose for ${widget.action.label}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: '${widget.action.label} message',
                hintText: 'Enter update for ${widget.action.label}',
                errorText: _showValidationError
                    ? 'Please add a message.'
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleSubmit,
                child: const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action, required this.onTap});

  final _DashboardAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Open compose for ${action.label}',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: _ActionBadge(action: action),
        ),
      ),
    );
  }
}

class _ImageUploadSheet extends StatefulWidget {
  const _ImageUploadSheet();

  @override
  State<_ImageUploadSheet> createState() => _ImageUploadSheetState();
}

class _ImageUploadSheetState extends State<_ImageUploadSheet> {
  final List<_PendingImage> _images = <_PendingImage>[];
  bool _showImageError = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickImages() async {
    final remaining = 3 - _images.length;
    if (remaining <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can upload up to 3 images.')),
      );
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: remaining > 1,
        withData: true,
        type: FileType.image,
      );

      if (result == null) {
        return;
      }

      final selected = <_PendingImage>[];
      for (final file in result.files) {
        if (selected.length >= remaining) {
          break;
        }
        final bytes = file.bytes;
        if (bytes == null) {
          continue;
        }

        selected.add(
          _PendingImage(
            name: file.name,
            base64Data: base64Encode(bytes),
            sizeInBytes: bytes.length,
            mimeType: _inferMimeType(file.name),
          ),
        );
      }

      if (selected.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to read selected images.')),
        );
        return;
      }

      setState(() {
        _images.addAll(selected);
        _showImageError = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to pick images: $error');
      debugPrint('$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to pick images. Please try again.'),
        ),
      );
    }
  }

  void _removeImage(_PendingImage image) {
    setState(() {
      _images.remove(image);
    });
  }

  void _submit() {
    if (_images.isEmpty) {
      setState(() => _showImageError = true);
      return;
    }

    Navigator.of(context).pop(
      _ImageUploadResult(images: List<_PendingImage>.unmodifiable(_images)),
    );
  }

  String _formatSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  String? _inferMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.bmp')) return 'image/bmp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.svg')) return 'image/svg+xml';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: bottomInset + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload images',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose up to three images. Selected files upload to Cloudinary once you continue.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.file_upload_outlined),
              label: Text(
                _images.isEmpty ? 'Select images (max 3)' : 'Add more images',
              ),
            ),
            if (_showImageError)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Please select at least one image.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (_images.isNotEmpty) ...[
              ..._images.map(
                (image) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.image_outlined, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          image.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatSize(image.sizeInBytes),
                        style: theme.textTheme.bodySmall,
                      ),
                      IconButton(
                        tooltip: 'Remove image',
                        icon: const Icon(Icons.close),
                        onPressed: () => _removeImage(image),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Upload images'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageUploadResult {
  const _ImageUploadResult({required this.images});

  final List<_PendingImage> images;
}

class _PendingImage {
  const _PendingImage({
    required this.name,
    required this.base64Data,
    required this.sizeInBytes,
    this.mimeType,
  });

  final String name;
  final String base64Data;
  final int sizeInBytes;
  final String? mimeType;

  String asApiPayload() {
    final type = mimeType;
    if (type == null || type.isEmpty) {
      return base64Data;
    }
    return 'data:$type;base64,$base64Data';
  }
}

class _UploadImagesTile extends StatelessWidget {
  const _UploadImagesTile({required this.onTap});

  final VoidCallback onTap;

  static const _DashboardAction _visual = _DashboardAction(
    label: 'Upload',
    icon: Icons.cloud_upload_outlined,
    endpoint: 'images/upload',
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Upload images',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: _ActionBadge(action: _visual),
        ),
      ),
    );
  }
}

class _ActionBadge extends StatelessWidget {
  const _ActionBadge({required this.action});

  final _DashboardAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 90,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(139, 0, 0, 0.25),
                  blurRadius: 14,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              action.icon,
              color: theme.colorScheme.onPrimary,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            action.label.toUpperCase(),
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _MlmShortcut extends StatelessWidget {
  const _MlmShortcut({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        decoration: BoxDecoration(
          gradient: buildHeaderGradient(),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(139, 0, 0, 0.25),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_tree_rounded,
                  color: theme.colorScheme.secondary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MLM Levels',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'View level progress and open each layer in a dropdown tree.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardAction {
  const _DashboardAction({
    required this.label,
    required this.icon,
    required this.endpoint,
  });

  final String label;
  final IconData icon;
  final String endpoint;
}
