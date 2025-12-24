import 'dart:typed_data' show Uint8List;


import '../data/enum_helper.dart';
import '../data/registration_step_helper.dart';
import 'membership_api_model.dart';

class MembershipRegistrationRequestBody {
  static const String MEMBERSHIP_REGISTRATION_UID = 'uid';
  static const String MEMBERSHIP_REGISTRATION_CARD_TYPE = 'cardType';
  static const String MEMBERSHIP_REGISTRATION_CARD_NUMBER = 'cardNumber';
  static const String MEMBERSHIP_REGISTRATION_CARD_IMAGE = 'cardImage';
  static const String MEMBERSHIP_REGISTRATION_SELFIE_IMAGE = 'selfieImage';

  final String uid = '00000123';
  final MembershipRegistrationCardType cardType;
  final String cardNumber;
  final Uint8List cardImage;
  final Uint8List selfieImage;

  MembershipRegistrationRequestBody({
    required this.cardType,
    required this.cardNumber,
    required this.cardImage,
    required this.selfieImage,
  });

  Map<String, String> toMap() => {
    MEMBERSHIP_REGISTRATION_UID: this.uid,
    MEMBERSHIP_REGISTRATION_CARD_TYPE: getEnumRawValue(this.cardType),
    MEMBERSHIP_REGISTRATION_CARD_NUMBER: this.cardNumber,
  };

  Map<String, Uint8List> toFiles() => {
    MEMBERSHIP_REGISTRATION_CARD_IMAGE: this.cardImage,
    MEMBERSHIP_REGISTRATION_SELFIE_IMAGE: this.selfieImage,
  };
}

class MembershipRegistrationResponse extends MembershipApiResponse {
  static const String MEMBERSHIP_REGISTRATION_FORM_ID = 'registrationFormID';

  final String registrationFormID;

  MembershipRegistrationResponse.fromJson(Map<String, dynamic> data, int status)
      : this.registrationFormID = data[MEMBERSHIP_REGISTRATION_FORM_ID] ?? '',
        super.fromJson(data, status);
}
