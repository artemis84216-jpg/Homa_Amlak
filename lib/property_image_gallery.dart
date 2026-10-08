import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'app_utils.dart';

class PropertyImageGallery extends StatefulWidget {
  final String? imagesJson;
  final double height;
  final bool showCounter;
  
  const PropertyImageGallery({
    super.key,
    this.imagesJson,
    this.height = 250,
    this.showCounter = true,
  });

  @override
  State<PropertyImageGallery> createState() => _PropertyImageGalleryState();
}

class _PropertyImageGalleryState extends State<PropertyImageGallery> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<String> _images = [];

  @override
  void initState() {
    super.initState();
    _parseImages();
    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentPage) {
        setState(() => _currentPage = page);
      }
    });
  }

  void _parseImages() {
    if (widget.imagesJson != null && widget.imagesJson!.isNotEmpty) {
      try {
        final List<dynamic> paths = jsonDecode(widget.imagesJson!);
        _images = paths.cast<String>();
      } catch (e) {
        _images = [];
      }
    }
  }

  void _openFullScreen(int index) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: InteractiveViewer(
                child: Image.file(File(_images[index]), fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: AppTheme.gold, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.gold, width: 1),
                  ),
                  child: Text(
                    '${toPersianDigits((_currentPage + 1).toString())} / ${toPersianDigits(_images.length.toString())}',
                    style: const TextStyle(color: AppTheme.gold, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_images.isEmpty) {
      return Container(
        height: widget.height,
        color: AppTheme.cardBlack,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 60, color: AppTheme.textGrey),
              const SizedBox(height: 8),
              Text('بدون تصویر', style: TextStyle(color: AppTheme.textGrey)),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _images.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _openFullScreen(index),
                child: Image.file(
                  File(_images[index]),
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              );
            },
          ),
          // نشانگر تعداد عکس
          if (widget.showCounter && _images.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.gold, width: 1),
                  ),
                  child: Text(
                    '${toPersianDigits((_currentPage + 1).toString())} / ${toPersianDigits(_images.length.toString())}',
                    style: const TextStyle(
                      color: AppTheme.gold,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          // دکمه‌های جهت‌نما
          if (_images.length > 1) ...[
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.chevron_right, color: AppTheme.gold, size: 32),
                  onPressed: _currentPage > 0
                      ? () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease)
                      : null,
                ),
              ),
            ),
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.chevron_left, color: AppTheme.gold, size: 32),
                  onPressed: _currentPage < _images.length - 1
                      ? () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease)
                      : null,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
