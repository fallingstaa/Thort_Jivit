// import 'dart:typed_data' show Uint8List;
//
// import 'package:aba_deeplink/membership/views/registration_footer.dart';
// import 'package:flutter/material.dart';
//
//
// import '../data/form_mixin.dart';
// import '../data/keyboard_helper.dart';
// import '../data/registration_step_helper.dart';
// import '../model/membership_registration_model.dart';
//
// class MembershipRegistrationSteps extends StatefulWidget {
//   final VoidCallback updateView;
//
//   MembershipRegistrationSteps(this.updateView);
//
//   @override
//   _MembershipRegistrationStepsState createState() => _MembershipRegistrationStepsState();
// }
//
// class _MembershipRegistrationStepsState extends State<MembershipRegistrationSteps> with FormStatefulMixin {
//   int _step = 1;
//
//   @override
//   Future<void> onFormCompleted(BuildContext context) async {
//     if (formKey.currentState!.validate()) {
//       MembershipRegistrationResponse? _response;
//       final MembershipRegistrationCardType _cardType =
//           MembershipRegistrationStepsHelper.shared.cardType ?? MembershipRegistrationCardType.nationalID;
//       final String _cardNumber = MembershipRegistrationStepsHelper.shared.cardNumber ?? '';
//       final Uint8List _cardImage = MembershipRegistrationStepsHelper.shared.cardImage ?? Uint8List(0);
//       final Uint8List _selfieImage = MembershipRegistrationStepsHelper.shared.selfieImage ?? Uint8List(0);
//
//       showLoadingDialog(
//         context: context,
//         asyncFunction: () async {
//           _response = await MembershipRegistrationHelper.shared.registerForMembership(
//             MembershipRegistrationRequestBody(
//               cardType: _cardType,
//               cardNumber: _cardNumber,
//               cardImage: _cardImage,
//               selfieImage: _selfieImage,
//             ),
//           );
//         },
//         onDismissed: () {
//           if (_response!.isSuccessful)
//             showAlertDialog(
//               context: context,
//               title: 'Successful',
//               message:
//               'You Have Successfully Submitted Your Membership Registration Form. Our Administrators Will Approve Your Registration Once They Review Your Form. We Reserve The Rights To Reject Your Registration If Given Any Reason.',
//               dismissText: 'Okay',
//               onDismissed: () => popToFirstRoute(context),
//             );
//           else
//             showAlertDialog(
//               context: context,
//               title: _response!.type,
//               message: _response!.message,
//               dismissText: 'Okay',
//             );
//         },
//       );
//     }
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     MembershipRegistrationStepsHelper.shared.setRegistrationFields(
//       field: MembershipRegistrationFormFields.cardType,
//       value: MembershipRegistrationCardType.nationalID,
//     );
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//     MembershipRegistrationStepsHelper.shared.clearRegistrationFields();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: GestureDetector(
//         onTap: () => dismissKeyboard(context),
//         child: Form(
//           key: formKey,
//           child: Column(
//             children: [
//               Expanded(
//                 child: SingleChildScrollView(
//                   child: Center(
//                     child: MembershipRegistrationStepsHelper.shared.getMembershipRegistrationStepView(
//                       step: _step,
//                       formKey: formKey,
//                     ),
//                   ),
//                 ),
//               ),
//               MemberhsipRegistrationStepFooter(
//                 step: _step,
//                 onNextPressed: () {
//                   if (formKey.currentState!.validate()) setState(() => _step += 1);
//                 },
//                 onPreviousPressed: () => setState(() => _step -= 1),
//                 onSubmit: () => onFormCompleted(context),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
