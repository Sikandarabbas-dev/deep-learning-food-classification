import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:url_launcher/url_launcher.dart';

class ImageAnalysisScreen extends StatefulWidget {
  final VoidCallback onBackPressed;

  const ImageAnalysisScreen({super.key, required this.onBackPressed});

  @override
  _ImageAnalysisScreenState createState() => _ImageAnalysisScreenState();
}

class _ImageAnalysisScreenState extends State<ImageAnalysisScreen> {
  File? _imageFile;
  String? _predictedLabel;
  double? _confidence;
  Interpreter? _interpreter;
  bool _dialogOpen = true;
  bool _isPredicting = false;
  bool _isLoadingFirebaseData = false;

  String? ingredients;
  String? nutrients;
  String? recipe;
  String? videoLink;
  final TextEditingController _feedbackController = TextEditingController();

  static const List<String> classNames = [
    'Bhindi',
    'Chicken Biryani',
    'Chicken Tikka Leg Piece',
    'Chicken Karahi',
    'Gajar Halva',
    'Gulab Jamun',
    'Haleem',
    'Saagh',
    'Sabat Masar',
    'Kheer'
  ];

  @override
  void initState() {
    super.initState();
    loadModel();
    _openImagePickerDialog();
  }

  Future<void> loadModel() async {
    try {
      final customModel = await FirebaseModelDownloader.instance.getModel(
        'Model89',
        FirebaseModelDownloadType.localModel,
        FirebaseModelDownloadConditions(),
      );
      _interpreter = await Interpreter.fromFile(customModel.file);
      print("Model loaded successfully.");
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  List preprocessImage(File imageFile) {
    final image = img.decodeImage(imageFile.readAsBytesSync())!;
    final resizedImage = img.copyResize(image, width: 224, height: 224, interpolation: img.Interpolation.nearest);

    List inputImage = List.filled(224 * 224 * 3, 0.0);
    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        var pixel = resizedImage.getPixel(x, y);
        int idx = (y * 224 + x) * 3;
        inputImage[idx + 0] = img.getRed(pixel) / 255.0;   // R
        inputImage[idx + 1] = img.getGreen(pixel) / 255.0; // G
        inputImage[idx + 2] = img.getBlue(pixel) / 255.0;  // B
      }
    }
    print("Input sample: ${inputImage.sublist(0, 10)}");
    return inputImage;
  }

  Future<void> predictImage(File image) async {
    setState(() {
      _isPredicting = true;
    });

    if (_interpreter == null) {
      await loadModel();
      setState(() {
        _isPredicting = false;
      });
      return;
    }

    var inputImage = preprocessImage(image);
    var input = inputImage.reshape([1, 224, 224, 3]);
    var output = List.filled(1 * 10, 0.0).reshape([1, 10]);

    _interpreter!.run(input, output);

    List<double> probabilities = List<double>.from(output[0]);
    double maxProbability = probabilities.reduce((a, b) => a > b ? a : b);
    int predictedIndex = probabilities.indexOf(maxProbability);

    print("Raw output: $output");
    print("Probabilities: $probabilities");
    print("Predicted: ${classNames[predictedIndex]} with confidence: $maxProbability");

    await Future.delayed(Duration(seconds: 3));

    String predictedLabel;
    if (classNames[predictedIndex] == 'Kheer') {
      predictedLabel = maxProbability >= 1.0 ? 'Kheer' : 'Apologizes! Try Again';
    } else {
      predictedLabel = maxProbability >= 0.80 ? classNames[predictedIndex] : 'Apologizes! Try Again';
    }

    setState(() {
      _predictedLabel = predictedLabel;
      _confidence = maxProbability;
      _isPredicting = false;
      _isLoadingFirebaseData = predictedLabel != 'Apologizes! Try Again';
    });

    if (predictedLabel != 'Apologizes! Try Again') {
      await fetchDishDataFromFirestore(_predictedLabel!);
    } else {
      setState(() {
        _isLoadingFirebaseData = false;
      });
    }
  }

  Future<void> _getImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _isPredicting = true;
      });
      await predictImage(_imageFile!);
    } else {
      setState(() {
        _dialogOpen = false;
      });
    }
  }

  Future<void> _openImagePickerDialog() async {
    await Future.delayed(Duration.zero);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Select Image'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera),
              title: Text('Camera'),
              onTap: () {
                _getImage(ImageSource.camera);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Gallery'),
              onTap: () {
                _getImage(ImageSource.gallery);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    ).then((_) => setState(() => _dialogOpen = false));
  }

  Future<void> fetchDishDataFromFirestore(String dish) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('dishes').doc(dish).get();
      await Future.delayed(Duration(seconds: 3));
      setState(() {
        ingredients = snapshot['ingredients'];
        nutrients = snapshot['nutrients'];
        recipe = snapshot['recipe'];
        videoLink = snapshot['link'];
        _isLoadingFirebaseData = false;
      });
      await saveToHistory(_predictedLabel!, ingredients!, nutrients!, recipe!, videoLink!);
    } catch (e) {
      print('Error fetching Firestore data: $e');
      await Future.delayed(Duration(seconds: 3));
      setState(() => _isLoadingFirebaseData = false);
    }
  }

  Future<void> saveToHistory(String label, String ingredients, String nutrients, String recipe, String videoLink) async {
    try {
      final userEmail = FirebaseAuth.instance.currentUser?.email;
      if (userEmail != null) {
        final imageUrl = await uploadImageToFirebase(_imageFile!);
        if (imageUrl.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userEmail)
              .collection('history')
              .add({
            'label': label,
            'ingredients': ingredients,
            'nutrients': nutrients,
            'recipe': recipe,
            'videoLink': videoLink,
            'imageUrl': imageUrl,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      print('Error saving to history: $e');
    }
  }

  Future<void> saveFeedback(String feedback) async {
    try {
      final userEmail = FirebaseAuth.instance.currentUser?.email;
      if (userEmail != null && feedback.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userEmail)
            .collection('feedback')
            .add({
          'label': _predictedLabel,
          'feedback': feedback,
          'timestamp': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Feedback submitted successfully!')),
        );
        _feedbackController.clear();
      }
    } catch (e) {
      print('Error saving feedback: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting feedback.')),
      );
    }
  }

  Future<String> uploadImageToFirebase(File imageFile) async {
    try {
      final filePath = 'images/${DateTime.now().millisecondsSinceEpoch}.png';
      final snapshot = await FirebaseStorage.instance.ref(filePath).putFile(imageFile);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: widget.onBackPressed, // Use the callback for back navigation
        ),
        backgroundColor: Colors.orange,
        centerTitle: true,
        title: const Text(
          'Image Analysis',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        automaticallyImplyLeading: false,
      ),
      body: _dialogOpen
          ? Container()
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 10),
              if (_imageFile != null)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.orangeAccent, width: 3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(_imageFile!, width: 350, height: 250, fit: BoxFit.cover),
                  ),
                ),
              SizedBox(height: 20),
              if (_imageFile != null)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(color: Colors.grey, blurRadius: 8, spreadRadius: 2, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Text('Dish', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white)),
                      ),
                      Container(
                        width: double.infinity,
                        height: 60,
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        child: Center(
                          child: _isPredicting
                              ? CircularProgressIndicator(color: Colors.orange)
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _predictedLabel ?? '',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 20),
              _isLoadingFirebaseData
                  ? CircularProgressIndicator(color: Colors.orange)
                  : Column(
                children: [
                  if (ingredients != null) buildFirebaseDataContainer('Ingredients', ingredients!),
                  if (nutrients != null) buildFirebaseDataContainer('Nutrients', nutrients!),
                  if (recipe != null) buildFirebaseDataContainer('Recipe of $_predictedLabel', recipe!),
                  if (videoLink != null) buildFirebaseDataContainer('Video Link', videoLink!),
                  if (_predictedLabel != null && _predictedLabel != 'Apologizes! Try Again')
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(bottom: 10),
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 5),
                            child: Text('Feedback', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white)),
                          ),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                            ),
                            child: Column(
                              children: [
                                TextField(
                                  controller: _feedbackController,
                                  maxLines: 4,
                                  decoration: InputDecoration(
                                    hintText: 'Enter your feedback about the detection',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () => saveFeedback(_feedbackController.text),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text('Submit'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildFirebaseDataContainer(String title, String content) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white)),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: title == 'Video Link'
                ? GestureDetector(
              onTap: () => _launchUrl(content),
              child: Text(content, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.blue, decoration: TextDecoration.underline)),
            )
                : Text(
              title == 'Ingredients' || title == 'Nutrients' ? content.replaceAll('Ingredient', '\n').trim() : content.replaceAll('Step', '\n\nStep').trim(),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      print('Could not launch $url');
    }
  }

  @override
  void dispose() {
    _interpreter?.close();
    _feedbackController.dispose();
    super.dispose();
  }
}