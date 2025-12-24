import 'dart:typed_data' show Uint8List;

import 'package:flutter/material.dart';

import '../../data/focus_node_helper.dart';
import '../../data/image_picker_helper.dart';
import '../../data/registration_step_helper.dart';


class MembershipRegistrationStepTwo extends StatefulWidget {
  final GlobalKey<FormState> formKey;

  MembershipRegistrationStepTwo(this.formKey);

  @override
  _MembershipRegistrationStepTwoState createState() => _MembershipRegistrationStepTwoState();
}

class _MembershipRegistrationStepTwoState extends State<MembershipRegistrationStepTwo> {
  MembershipRegistrationCardType? _cardType;
  Uint8List? _cardImage;

  @override
  void initState() {
    super.initState();
    _cardType = MembershipRegistrationStepsHelper.shared.cardType;
    _cardImage = MembershipRegistrationStepsHelper.shared.cardImage;
  }

  @override
  void dispose() {
    super.dispose();
    MembershipRegistrationStepsHelper.shared.setRegistrationFields(
      field: MembershipRegistrationFormFields.cardImage,
      value: _cardImage,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 10),
      width: MediaQuery.of(context).size.width * 0.9,
      child: Column(
        children: [
          Text(
            _cardType == MembershipRegistrationCardType.nationalID ? 'Photo Of National ID Card' : 'Photo Of Passport',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Stack(
            children: [
              Container(
                margin: EdgeInsets.only(top: 30, bottom: 20),
                padding: EdgeInsets.symmetric(vertical: 20),
                height: MediaQuery.of(context).size.height * 0.3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey.shade300,
                ),
                foregroundDecoration: BoxDecoration(
                  image: _cardImage != null
                      ? DecorationImage(
                    image: MemoryImage(_cardImage!),
                    fit: BoxFit.fill,
                  )
                      : null,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Icon(
                        Icons.file_upload,
                        size: 40,
                      ),
                      Text(
                        _cardType == MembershipRegistrationCardType.nationalID
                            ? 'Photo Of Your National ID Card'
                            : 'Photo Of Your Passport',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Tap Here To Upload',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 30, bottom: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextFormField(
                      onTap: () => showImagePicker(
                        context: context,
                        onImageSelected: (image, byte, base64) {
                          widget.formKey.currentState!.reset();
                          setState(() => _cardImage = byte);
                          MembershipRegistrationStepsHelper.shared.setRegistrationFields(
                            field: MembershipRegistrationFormFields.cardImage,
                            value: _cardImage,
                          );
                        },
                      ),
                      focusNode: AlwaysDisabledFocusNode(),
                      style: TextStyle(fontSize: 0),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(),
                        ),
                      ),
                      validator: (value) {
                        if (_cardImage == null) return 'Card Image Cannot Be Empty';

                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
