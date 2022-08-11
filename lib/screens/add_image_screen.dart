import 'dart:ffi';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:path/path.dart' as Path;

class AddImageScreen extends StatefulWidget {
  const AddImageScreen({Key? key}) : super(key: key);

  @override
  State<AddImageScreen> createState() => _AddImageScreenState();
}

class _AddImageScreenState extends State<AddImageScreen> {
  bool uploading = false;
  double value = 0;
  final List<File> _images = [];
  final picker = ImagePicker();
  late CollectionReference imageReference;
  late firebase_storage.Reference reference;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Image'),
        actions: [
          ElevatedButton(
              onPressed: () {
                setState(() {
                  uploading = true;
                });
                uploadImages().whenComplete(() => Navigator.of(context).pop());
              },
              child: const Text(
                'Upload',
                style: TextStyle(color: Colors.white),
              )),
        ],
      ),
      body: Stack(children: [
        GridView.builder(
          itemCount: _images.length + 1,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3),
          itemBuilder: (context, index) {
            return index == 0
                ? Center(
                    child: IconButton(
                    onPressed: () => !uploading ? selectImage():null,
                    icon: const Icon(Icons.add),
                  ))
                : Container(
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                        image: DecorationImage(
                            image: FileImage(_images[index - 1]),
                            fit: BoxFit.cover)),
                  );
          },
        ),
        uploading
            ? Center(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    child: const Text(
                      'Uploading!',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  CircularProgressIndicator(
                    value: value,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.lightBlueAccent),
                  ),
                ],
              ))
            : Container(),
      ]),
    );
  }

  selectImage() async {
    final selectFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _images.add(File(selectFile!.path));
    });
    if (selectFile?.path == null) retrieveLostData();
  }

  Future<void> retrieveLostData() async {
    final LostData response = (await picker.retrieveLostData()) as LostData;
    if (response.isEmpty) {
      return;
    }
    if (response.file != null) {
      setState(() {
        _images.add(File(response.file!.path));
      });
    } else {
      print(response.file);
    }
  }

  Future uploadImages() async {
    int i = 1;
    for (var img in _images) {
      setState(() {
        value = i / _images.length;
      });
      reference = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('images/${Path.basename(img.path)}');
      await reference.putFile(img).whenComplete(() async {
        await reference.getDownloadURL().then((value) {
          imageReference.add({'url': value});
          i++;
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();
    imageReference = FirebaseFirestore.instance.collection('imageURLs');
  }
}
