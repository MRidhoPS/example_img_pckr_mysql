import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Upload',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ImageUploadScreen(),
    );
  }
}

class ImageUploadScreen extends StatefulWidget {
  const ImageUploadScreen({super.key});

  @override
  _ImageUploadScreenState createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  File? _imageFile;
  final _picker = ImagePicker();
  String? _uploadedImageUrl;
  List<dynamic> _uploadedImages = []; // Store list of uploaded images

  @override
  void initState() {
    super.initState();
    _fetchUploadedImages(); // Fetch images on init
  }

  // Function to pick image from gallery
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Function to upload image to the server
  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    final uri = Uri.parse(
        'http://192.168.18.17:3000/upload'); // Change to your server URL
    final request = http.MultipartRequest('POST', uri);

    request.files
        .add(await http.MultipartFile.fromPath('image', _imageFile!.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final json = jsonDecode(responseData);
      setState(() {
        _uploadedImageUrl = json['imagePath']; // Store image path from server
        _fetchUploadedImages(); // Refresh list of uploaded images
      });
    } else {
      print('Failed to upload image');
    }
  }

  // Fetch list of uploaded images from the server
  Future<void> _fetchUploadedImages() async {
    final response = await http.get(Uri.parse(
        'http://192.168.18.17:3000/images')); // Change to your server URL
    if (response.statusCode == 200) {
      setState(() {
        _uploadedImages = jsonDecode(response.body); // Parse the JSON response
      });
    } else {
      print('Failed to load images');
    }
  }

  // Function to edit/replace an image on the server
  Future<void> _editImage(int imageId) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final newImageFile = File(pickedFile.path);
    final uri = Uri.parse(
        'http://192.168.18.17:3000/edit-image/$imageId'); // Update with your server URL
    final request = http.MultipartRequest('PUT', uri);
    request.files
        .add(await http.MultipartFile.fromPath('image', newImageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      setState(() {
        _fetchUploadedImages(); // Refresh the image list after update
      });
    } else {
      print('Failed to update image');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Upload and Edit'),
      ),
      body: Column(
        children: [
          _imageFile != null
              ? Image.file(_imageFile!, height: 200, width: 200)
              : const Text('No image selected'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _pickImage,
            child: const Text('Pick Image'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _uploadImage,
            child: const Text('Upload Image'),
          ),
          const SizedBox(height: 20),
          const Text('Uploaded Images:'),
          Expanded(
            child: _uploadedImages.isNotEmpty
                ? ListView.builder(
                    itemCount: _uploadedImages.length,
                    itemBuilder: (context, index) {
                      final image = _uploadedImages[index];
                      return ListTile(
                        leading: Image.network(
                            'http://192.168.18.17:3000${image['image_path']}',
                            fit: BoxFit.cover),
                        title: Text(image['image_name']),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            final imageId = image['image_id'];
                            if (imageId != null) {
                              _editImage(
                                  imageId); // Proceed if the id is not null
                            } else {
                              print(
                                  'Image ID is null'); // Debugging: Log if the id is null
                            }
                          },
                        ),
                      );
                    },
                  )
                : const Text('No images uploaded'),
          ),
        ],
      ),
    );
  }
}
