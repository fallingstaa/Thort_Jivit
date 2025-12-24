import 'dart:typed_data' show Uint8List;

import 'package:flutter/material.dart';

import '../../data/focus_node_helper.dart';
import '../../data/image_picker_helper.dart';
import '../../data/registration_step_helper.dart';

class MembershipRegistrationStepThree extends StatefulWidget {
  final GlobalKey<FormState> formKey;

  MembershipRegistrationStepThree(this.formKey);

  @override
  _MembershipRegistrationStepThreeState createState() => _MembershipRegistrationStepThreeState();
}

class _MembershipRegistrationStepThreeState extends State<MembershipRegistrationStepThree> {
  MembershipRegistrationCardType? _cardType;
  Uint8List? _selfieImage;

  @override
  void initState() {
    super.initState();
    _cardType = MembershipRegistrationStepsHelper.shared.cardType;
    _selfieImage = MembershipRegistrationStepsHelper.shared.selfieImage;
  }

  @override
  void dispose() {
    super.dispose();
    MembershipRegistrationStepsHelper.shared.setRegistrationFields(
      field: MembershipRegistrationFormFields.selfieImage,
      value: _selfieImage,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 10),
      child: Column(
        children: [
          Text(
            _cardType == MembershipRegistrationCardType.nationalID
                ? 'Selfie With National ID Card'
                : 'Selfie With Passport',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Container(
            margin: EdgeInsets.only(top: 30, bottom: 20),
            padding: EdgeInsets.symmetric(vertical: 20),
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            foregroundDecoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/registration/selfie_placeholder.png'),
                fit: BoxFit.fill,
              ),
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Stack(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  height: MediaQuery.of(context).size.height * 0.3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey.shade300,
                  ),
                  foregroundDecoration: BoxDecoration(
                    image: _selfieImage != null
                        ? DecorationImage(
                      image: MemoryImage(_selfieImage!),
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
                              ? 'Selfie Your National ID Card'
                              : 'Selfie With Your Passport',
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextFormField(
                        onTap: () => showImagePicker(
                          context: context,
                          onImageSelected: (image, byte, base64) {
                            widget.formKey.currentState!.reset();
                            setState(() => _selfieImage = byte);
                            MembershipRegistrationStepsHelper.shared.setRegistrationFields(
                              field: MembershipRegistrationFormFields.selfieImage,
                              value: _selfieImage,
                            );
                          },
                        ),
                        focusNode: AlwaysDisabledFocusNode(),
                        style: TextStyle(fontSize: 0),
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.only(
                            top: MediaQuery.of(context).size.height * 0.3,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(),
                          ),
                        ),
                        validator: (value) {
                          if (_selfieImage == null) return 'Selfie Image Cannot Be Empty';

                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
