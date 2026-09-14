import 'package:flutter/material.dart';
import 'package:demo/widgets/ui/cc_loading_animation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../widgets/cc_breadcrumb_bar.dart';

class TeacherResourcesScreen extends StatefulWidget {
  final String classId;
  final String? className;

  const TeacherResourcesScreen({super.key, required this.classId, this.className});

  @override
  State<TeacherResourcesScreen> createState() => _TeacherResourcesScreenState();
}

class _TeacherResourcesScreenState extends State<TeacherResourcesScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _isUploading = false;
  String _selectedFilter = 'all'; // all, link, file

  IconData _resourceIcon(String type, String ext) {
    if (type == 'link') return Icons.link;
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image;
      case 'doc':
      case 'docx':
      case 'txt':
      case 'rtf':
        return Icons.description;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return Icons.table_chart;
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
        return Icons.videocam;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getTypeColor(String type, String ext) {
    if (type == 'link') return const Color(0xFF2E6BFF);
    switch (ext) {
      case 'pdf':
        return Colors.red;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Colors.purple;
      case 'doc':
      case 'docx':
      case 'txt':
      case 'rtf':
        return Colors.blue;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return Colors.green;
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
        return Colors.indigo;
      default:
        return const Color(0xFF5C6B8C);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    return DateFormat('MMM d').format(timestamp.toDate());
  }

  void _showAddResourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Color(0xFFF4F8FF),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E6BFF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add Resource',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D1B3D),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Color(0xFF0D1B3D),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Add Link Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0x1A2E6BFF),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF2E6BFF,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.link,
                                        color: Color(0xFF2E6BFF),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Add Link',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0D1B3D),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _descriptionController,
                                  style: const TextStyle(
                                    color: Color(0xFF0D1B3D),
                                  ),
                                  cursorColor: const Color(0xFF2E6BFF),
                                  decoration: InputDecoration(
                                    labelText: 'Title (Optional)',
                                    labelStyle: const TextStyle(
                                      color: Color(0xFF5C6B8C),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0x1A2E6BFF),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF2E6BFF),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _urlController,
                                  style: const TextStyle(
                                    color: Color(0xFF0D1B3D),
                                  ),
                                  cursorColor: const Color(0xFF2E6BFF),
                                  decoration: InputDecoration(
                                    labelText: 'Resource URL',
                                    labelStyle: const TextStyle(
                                      color: Color(0xFF5C6B8C),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0x1A2E6BFF),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF2E6BFF),
                                      ),
                                    ),
                                  ),
                                  keyboardType: TextInputType.url,
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isUploading
                                        ? null
                                        : () async {
                                            setModalState(
                                              () => _isUploading = true,
                                            );
                                            await _addLinkResource();
                                            setModalState(
                                              () => _isUploading = false,
                                            );
                                            if (mounted &&
                                                Navigator.canPop(context)) {
                                              Navigator.pop(context);
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2E6BFF),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isUploading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CcLoadingAnimation(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'ADD LINK',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Add File Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0x1A2E6BFF),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF2E6BFF,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.upload_file,
                                        color: Color(0xFF2E6BFF),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Upload File',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0D1B3D),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _descriptionController,
                                  style: const TextStyle(
                                    color: Color(0xFF0D1B3D),
                                  ),
                                  cursorColor: const Color(0xFF2E6BFF),
                                  decoration: InputDecoration(
                                    labelText: 'Title (Optional)',
                                    labelStyle: const TextStyle(
                                      color: Color(0xFF5C6B8C),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0x1A2E6BFF),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF2E6BFF),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isUploading
                                        ? null
                                        : () async {
                                            setModalState(
                                              () => _isUploading = true,
                                            );
                                            await _uploadFileResource();
                                            setModalState(
                                              () => _isUploading = false,
                                            );
                                            if (mounted &&
                                                Navigator.canPop(context)) {
                                              Navigator.pop(context);
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2E6BFF),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isUploading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CcLoadingAnimation(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'UPLOAD FILE',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      return _buildDesktopLayout();
    }

    return _buildMobileLayout();
  }

  Widget _buildDesktopLayout() {
    final currentClassName = widget.className ?? 'Class';
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          CCBreadcrumbBar(
            items: [
              BreadcrumbItem(
                label: 'Classes',
                onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
              ),
              BreadcrumbItem(
                label: currentClassName,
                onTap: () => Navigator.pop(context),
              ),
              const BreadcrumbItem(
                label: 'Resources',
              ),
            ],
            actions: [
              ElevatedButton.icon(
                onPressed: () => _showAddResourceBottomSheet(),
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: const Text(
                  'Add Resource',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          Expanded(
            child: _buildDesktopContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 1)),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopContent() {
    return Column(
      children: [
        // Filter & Search bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              _buildDesktopFilterChip('All', 'all'),
              const SizedBox(width: 8),
              _buildDesktopFilterChip('Links', 'link'),
              const SizedBox(width: 8),
              _buildDesktopFilterChip('Files', 'file'),
              const SizedBox(width: 24),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Color(0xFF1E293B)),
                  cursorColor: const Color(0xFF3B82F6),
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search resources by name or URL...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF3B82F6), size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Color(0xFF94A3B8), size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Resources list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('classes')
                .doc(widget.classId)
                .collection('resources')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CcLoadingAnimation(color: Color(0xFF3B82F6)),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                );
              }

              var docs = snapshot.data?.docs ?? [];

              // Apply filter
              docs = docs.where((doc) {
                final type = (doc['type'] ?? 'link') as String;
                if (_selectedFilter == 'all') return true;
                return type == _selectedFilter;
              }).toList();

              // Apply search
              if (_searchController.text.isNotEmpty) {
                final query = _searchController.text.toLowerCase();
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final description = (data['description'] ?? '').toString().toLowerCase();
                  final fileName = (data['fileName'] ?? '').toString().toLowerCase();
                  final url = (data['url'] ?? '').toString().toLowerCase();
                  return description.contains(query) ||
                      fileName.contains(query) ||
                      url.contains(query);
                }).toList();
              }

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _selectedFilter == 'file'
                              ? Icons.folder_open
                              : _selectedFilter == 'link'
                              ? Icons.link
                              : Icons.inventory_2,
                          color: const Color(0xFF94A3B8),
                          size: 56,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'No resources found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add your first resource by clicking the button above',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.4,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final url = data['url'] ?? '';
                  final description = data['description'] ?? '';
                  final type = (data['type'] ?? 'link') as String;
                  final fileName = (data['fileName'] ?? '') as String;
                  final ext = (data['extension'] ?? '') as String;
                  final size = (data['size'] ?? 0) as int;
                  final createdAt = data['createdAt'] as Timestamp?;
                  final resourceId = docs[index].id;

                  final title = description.isNotEmpty
                      ? description
                      : (fileName.isNotEmpty ? fileName : 'Untitled Resource');

                  final subtitle = type == 'file' ? fileName : url;
                  final typeColor = _getTypeColor(type, ext);

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _launchUrl(url),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: typeColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _resourceIcon(type, ext),
                                      color: typeColor,
                                      size: 20,
                                    ),
                                  ),
                                  const Spacer(),
                                  PopupMenuButton(
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        child: const Text('Delete'),
                                        onTap: () => _deleteResource(resourceId),
                                      ),
                                    ],
                                    icon: const Icon(
                                      Icons.more_vert,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 11,
                                ),
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  if (type == 'file' && ext.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: typeColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        ext.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: typeColor,
                                        ),
                                      ),
                                    ),
                                  const Spacer(),
                                  if (createdAt != null)
                                    Text(
                                      _formatDate(createdAt),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        title: const Text(
          'Class Resources',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D1B3D),
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: const Color(0xFF2E6BFF).withValues(alpha: 0.1),
        foregroundColor: const Color(0xFF0D1B3D),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Color(0xFF0D1B3D)),
              cursorColor: const Color(0xFF2E6BFF),
              onChanged: (value) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search resources...',
                hintStyle: const TextStyle(color: Color(0xFF8DA6D8)),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search, color: Color(0xFF2E6BFF)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Color(0xFF8DA6D8)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0x1A2E6BFF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF2E6BFF),
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0x1A2E6BFF)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Links', 'link'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Files', 'file'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('classes')
                  .doc(widget.classId)
                  .collection('resources')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CcLoadingAnimation(color: Color(0xFF2E6BFF)),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Color(0xFF5C6B8C)),
                    ),
                  );
                }

                var docs = snapshot.data?.docs ?? [];

                docs = docs.where((doc) {
                  final type = (doc['type'] ?? 'link') as String;
                  if (_selectedFilter == 'all') return true;
                  return type == _selectedFilter;
                }).toList();

                if (_searchController.text.isNotEmpty) {
                  final query = _searchController.text.toLowerCase();
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final description = (data['description'] ?? '').toString().toLowerCase();
                    final fileName = (data['fileName'] ?? '').toString().toLowerCase();
                    final url = (data['url'] ?? '').toString().toLowerCase();
                    return description.contains(query) ||
                        fileName.contains(query) ||
                        url.contains(query);
                  }).toList();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E6BFF).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            _selectedFilter == 'file'
                                ? Icons.folder_open
                                : _selectedFilter == 'link'
                                ? Icons.link
                                : Icons.inventory_2,
                            color: const Color(0xFF2E6BFF),
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No resources found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D1B3D),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add your first resource by tapping the button below',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF5C6B8C),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final url = data['url'] ?? '';
                    final description = data['description'] ?? '';
                    final type = (data['type'] ?? 'link') as String;
                    final fileName = (data['fileName'] ?? '') as String;
                    final ext = (data['extension'] ?? '') as String;
                    final size = (data['size'] ?? 0) as int;
                    final createdAt = data['createdAt'] as Timestamp?;
                    final resourceId = docs[index].id;

                    final title = description.isNotEmpty
                        ? description
                        : (fileName.isNotEmpty ? fileName : 'Untitled Resource');

                    final subtitle = type == 'file' ? fileName : url;
                    final typeColor = _getTypeColor(type, ext);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0x1A2E6BFF)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2E6BFF).withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _launchUrl(url),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: typeColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        _resourceIcon(type, ext),
                                        color: typeColor,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0D1B3D),
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            subtitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Color(0xFF5C6B8C),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton(
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          child: const Text('Delete'),
                                          onTap: () => _deleteResource(resourceId),
                                        ),
                                      ],
                                      icon: const Icon(
                                        Icons.more_vert,
                                        color: Color(0xFF8DA6D8),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    if (type == 'file' && size > 0) ...[
                                      Icon(
                                        Icons.storage,
                                        size: 16,
                                        color: const Color(0xFF8DA6D8),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _formatFileSize(size),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF8DA6D8),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                    ],
                                    if (type == 'file' && ext.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: typeColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          ext.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: typeColor,
                                          ),
                                        ),
                                      ),
                                    const Spacer(),
                                    if (createdAt != null)
                                      Text(
                                        _formatDate(createdAt),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF8DA6D8),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddResourceBottomSheet,
        backgroundColor: const Color(0xFF2E6BFF),
        elevation: 4,
        label: const Text(
          'Add Resource',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : const Color(0xFF2E6BFF),
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF2E6BFF),
      side: BorderSide(
        color: isSelected ? const Color(0xFF2E6BFF) : const Color(0x1A2E6BFF),
        width: 1.5,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Future<void> _addLinkResource() async {
    final url = _urlController.text.trim();
    final description = _descriptionController.text.trim();

    if (url.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a URL')));
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('resources')
          .add({
            'type': 'link',
            'url': url,
            'description': description,
            'createdAt': FieldValue.serverTimestamp(),
          });

      _urlController.clear();
      _descriptionController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding resource: $e')));
      }
    }
  }

  Future<void> _ensureSupabaseSession() async {
    final supabase = Supabase.instance.client;
    if (supabase.auth.currentSession != null) return;
    try {
      await supabase.auth.signInAnonymously();
    } on AuthException {
      // Anonymous auth may be disabled; continue with anon role requests.
    }
  }

  Future<void> _uploadFileResource() async {
    final description = _descriptionController.text.trim();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;
    final fileName = file.name;
    final ext = (file.extension ?? '').toLowerCase();

    if (file.bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read selected file')),
        );
      }
      return;
    }

    try {
      await _ensureSupabaseSession();

      final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final storagePath =
          'class_resources/${widget.classId}/${DateTime.now().millisecondsSinceEpoch}_$safeName';

      final supabase = Supabase.instance.client;

      // Upload to Supabase
      await supabase.storage
          .from('resources')
          .uploadBinary(storagePath, file.bytes!);

      // Get public URL
      final downloadUrl = supabase.storage
          .from('resources')
          .getPublicUrl(storagePath);

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('resources')
          .add({
            'type': 'file',
            'url': downloadUrl,
            'description': description,
            'fileName': fileName,
            'extension': ext,
            'size': file.size,
            'storagePath': storagePath,
            'createdAt': FieldValue.serverTimestamp(),
          });

      _descriptionController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File uploaded successfully')),
        );
      }
    } on StorageException catch (e) {
      final msg = e.toString().toLowerCase();
      final isRls =
          msg.contains('row-level security') || msg.contains('violates');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isRls
                  ? 'Upload blocked by Supabase Storage policy. Please enable upload policy for bucket "resources".'
                  : 'Storage error: $e',
            ),
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Supabase auth error: ${e.message}. Enable Anonymous provider or add Storage policy for anon role.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading file: $e')));
      }
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $urlString';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch URL: $urlString')),
        );
      }
    }
  }

  Future<void> _deleteResource(String resourceId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('resources')
          .doc(resourceId)
          .get();

      final data = doc.data();
      final storagePath = data?['storagePath'] as String?;

      if (storagePath != null && storagePath.isNotEmpty) {
        try {
          await _ensureSupabaseSession();
          final supabase = Supabase.instance.client;
          await supabase.storage.from('resources').remove([storagePath]);
        } catch (_) {
          // File may already be removed; continue deleting metadata.
        }
      }

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('resources')
          .doc(resourceId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Resource deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting resource: $e')));
      }
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
