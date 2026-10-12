import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'app_utils.dart';

class PropertyImageGallery extends StatefulWidget {
  final String? imagesJson;
  final bool showCounter;
  
  const PropertyImageGallery({
    super.key,
    this.imagesJson,
    this.showCounter = true,
  });

  @override
  State<PropertyImageGallery> createState() => _PropertyImageGalleryState();
}

class _PropertyImageGalleryState extends State<PropertyImageGallery> {
  List<String> _images = [];

  @override
  void initState() {
    super.initState();
    _parseImages();
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
                    '${toPersianDigits((index + 1).toString())} / ${toPersianDigits(_images.length.toString())}',
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
  Widget build(BuildContext context) {
    if (_images.isEmpty) {
      return Container(
        height: 150,
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

    // نمایش عکس‌ها به صورت مربعی در کنار هم
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _images.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: GestureDetector(
                  onTap: () => _openFullScreen(index),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_images[index]),
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.showCounter && _images.length > 1) ...[
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.cardBlack,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.gold, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.photo_library, color: AppTheme.gold, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${toPersianDigits(_images.length.toString())} تصویر - برای بزرگنمایی کلیک کنید',
                    style: const TextStyle(color: AppTheme.gold, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
