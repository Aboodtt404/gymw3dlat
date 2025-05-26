import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/supabase_service.dart';
import '../../services/food_recognition_service.dart';
import '../../models/food_model.dart';
import '../../styles/styles.dart';

class FoodImageRecognitionScreen extends StatefulWidget {
  const FoodImageRecognitionScreen({super.key});

  @override
  State<FoodImageRecognitionScreen> createState() =>
      _FoodImageRecognitionScreenState();
}

class _FoodImageRecognitionScreenState
    extends State<FoodImageRecognitionScreen> {
  final ImagePicker _picker = ImagePicker();
  final FoodRecognitionService _foodRecognitionService =
      FoodRecognitionService();
  File? _imageFile;
  String? _uploadedImageUrl;
  bool _isLoading = false;
  String? _error;
  List<Food>? _detectedFoods;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      if (kIsWeb) {
        setState(() {
          _imageFile = null;
          _uploadedImageUrl = pickedFile.path;
          _detectedFoods = null;
          _error = null;
        });
        await _uploadAndAnalyzeImage();
        return;
      }

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 85,
        maxWidth: 1800,
        maxHeight: 1800,
        compressFormat: ImageCompressFormat.jpg,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile == null) return;

      setState(() {
        _imageFile = File(croppedFile.path);
        _uploadedImageUrl = null;
        _detectedFoods = null;
        _error = null;
      });

      await _uploadAndAnalyzeImage();
    } catch (e) {
      setState(() => _error = 'Failed to pick image: $e');
    }
  }

  Future<void> _uploadAndAnalyzeImage() async {
    if (_imageFile == null && _uploadedImageUrl == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String imageUrl;

      if (kIsWeb) {
        imageUrl = _uploadedImageUrl!;
      } else {
        // Upload to Supabase Storage
        final userId = SupabaseService.client.auth.currentUser?.id;
        if (userId == null) throw Exception('User not authenticated');

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final path = 'food_images/$userId/$timestamp.jpg';

        await SupabaseService.client.storage
            .from('food-images')
            .upload(path, _imageFile!);

        imageUrl = SupabaseService.client.storage
            .from('food-images')
            .getPublicUrl(path);
      }

      setState(() => _uploadedImageUrl = imageUrl);

      final foods = await _foodRecognitionService.analyzeFoodImage(imageUrl);

      setState(() {
        _detectedFoods = foods;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to analyze image: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Recognition'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_imageFile == null && _uploadedImageUrl == null) ...[
              const Text(
                'Take a photo of your food or upload one from your gallery',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Upload Photo'),
                  ),
                ],
              ),
            ],
            if (_imageFile != null || _uploadedImageUrl != null) ...[
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _uploadedImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: _uploadedImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.error,
                            size: 48,
                            color: Colors.red,
                          ),
                        )
                      : Image.file(
                          _imageFile!,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.refresh),
                label: const Text('Take Another Photo'),
              ),
            ],
            if (_isLoading) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
              const Text(
                'Analyzing your food...',
                textAlign: TextAlign.center,
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
            if (_detectedFoods != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Detected Foods:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...(_detectedFoods!.map((food) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(food.name),
                      subtitle: Text(
                        '${food.calories.round()} cal • '
                        '${food.protein.round()}g protein • '
                        '${food.carbs.round()}g carbs • '
                        '${food.fat.round()}g fat',
                      ),
                    ),
                  ))),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, _detectedFoods);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save to Meal Log'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
