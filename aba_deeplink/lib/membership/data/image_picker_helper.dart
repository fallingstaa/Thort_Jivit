import 'dart:convert' show base64Encode;
import 'dart:io' show File;
import 'dart:typed_data' show Uint8List;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void showImagePicker({
  required BuildContext context,
  required void Function(File?, Uint8List?, String?) onImageSelected,
}) {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return Container(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Photo Library'),
              onTap: () async {
                Navigator.of(context).pop();
                PickedFile? _pickedFile = (await ImagePicker().pickImage(source: ImageSource.gallery)) as PickedFile?;

                if (_pickedFile != null) {
                  File _image = File(_pickedFile.path);
                  Uint8List _imageBytes = await _pickedFile.readAsBytes();
                  String _base64 = base64Encode(_imageBytes);

                  onImageSelected(_image, _imageBytes, _base64);
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_camera),
              title: Text('Camera'),
              onTap: () async {
                Navigator.of(context).pop();
                PickedFile? _pickedFile = (await ImagePicker().pickImage(source: ImageSource.camera)) as PickedFile?;

                if (_pickedFile != null) {
                  File _image = File(_pickedFile.path);
                  Uint8List _imageBytes = await _pickedFile.readAsBytes();
                  String _base64 = base64Encode(_imageBytes);

                  onImageSelected(_image, _imageBytes, _base64);
                }
              },
            ),
          ],
        ),
      );
    },
  );
}
