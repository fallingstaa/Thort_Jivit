import 'dart:typed_data' show Uint8List;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show GlobalKey, FormState, Widget;


import '../views/registration/registration_step_four.dart';
import '../views/registration/registration_step_one.dart';
import '../views/registration/registration_step_three.dart';
import '../views/registration/registration_step_two.dart';

enum MembershipRegistrationCardType {
  nationalID,
  passport,
}

enum MembershipRegistrationFormFields {
  cardType,
  cardNumber,
  cardImage,
  selfieImage,
}

class MembershipRegistrationStepsHelper {
  static final MembershipRegistrationStepsHelper shared = MembershipRegistrationStepsHelper();

  MembershipRegistrationCardType? cardType;
  String? cardNumber;
  Uint8List? cardImage;
  Uint8List? selfieImage;

  Widget getMembershipRegistrationStepView({required int step, required GlobalKey<FormState> formKey}) {
    switch (step) {
      case 1:
        return MembershipRegistrationStepOne(formKey);
      // case 2:
      //   return MembershipRegistrationStepTwo(formKey);
      // case 3:
      //   return MembershipRegistrationStepThree(formKey);
      // case 4:
      //   return MembershipRegistrationStepFour(formKey);
      default:
        return Text('Error Message');
    }
  }

  void setRegistrationFields({
    required MembershipRegistrationFormFields field,
    required dynamic value,
  }) {
    switch (field) {
      case MembershipRegistrationFormFields.cardType:
        this.cardType = value;
        break;
      case MembershipRegistrationFormFields.cardNumber:
        this.cardNumber = value;
        break;
      case MembershipRegistrationFormFields.cardImage:
        this.cardImage = value;
        break;
      case MembershipRegistrationFormFields.selfieImage:
        this.selfieImage = value;
        break;
    }
  }

  void clearRegistrationFields() {
    this.cardType = null;
    this.cardNumber = null;
    this.cardImage = null;
    this.selfieImage = null;
  }
}
