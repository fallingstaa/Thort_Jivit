import 'package:aba_deeplink/membership/data/string_helper.dart';
import 'package:flutter/material.dart';

import '../../data/ink_well_helper.dart';
import '../../data/registration_step_helper.dart';
import '../../data/text_field_helper.dart';


class MembershipRegistrationStepOne extends StatefulWidget {
  final GlobalKey<FormState> formKey;

  MembershipRegistrationStepOne(this.formKey);

  @override
  _MembershipRegistrationStepOneState createState() => _MembershipRegistrationStepOneState();
}

class _MembershipRegistrationStepOneState extends State<MembershipRegistrationStepOne> {
  final TextEditingController _cardInfoController = TextEditingController();

  MembershipRegistrationCardType? _type;

  @override
  void initState() {
    super.initState();
    _cardInfoController.text = MembershipRegistrationStepsHelper.shared.cardNumber ?? '';
    _type = MembershipRegistrationStepsHelper.shared.cardType ?? MembershipRegistrationCardType.nationalID;
  }

  @override
  void dispose() {
    super.dispose();
    _cardInfoController.dispose();
    MembershipRegistrationStepsHelper.shared.setRegistrationFields(
      field: MembershipRegistrationFormFields.cardNumber,
      value: _cardInfoController.text,
    );
    MembershipRegistrationStepsHelper.shared.setRegistrationFields(
      field: MembershipRegistrationFormFields.cardType,
      value: _type,
    );
  }

  void _updateType(MembershipRegistrationCardType type) {
    if (_type != type) {
      widget.formKey.currentState!.reset();
      _cardInfoController.clear();
      setState(() => _type = type);
      FocusScope.of(context).requestFocus(FocusNode());
      MembershipRegistrationStepsHelper.shared.setRegistrationFields(
        field: MembershipRegistrationFormFields.cardType,
        value: _type,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10),
      padding: EdgeInsets.symmetric(vertical: 20),
      color: Colors.white,
      child: Column(
        children: [
          Image.asset('assets/registration/registration.png'),
          SizedBox(height: 10),
          Text(
            'Please Fill In The Registration Form',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            'Select Your Card Type',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MembershipRegistrationCardTypeSelector(
                type: MembershipRegistrationCardType.nationalID,
                updateType: _updateType,
              ),
              _MembershipRegistrationCardTypeSelector(
                type: MembershipRegistrationCardType.passport,
                updateType: _updateType,
              ),
            ],
          ),
          Text(
            _type == MembershipRegistrationCardType.nationalID
                ? 'Enter Your National ID Card Number'
                : 'Enter Your Passport Number',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          createTextField(
            type: _type == MembershipRegistrationCardType.nationalID ? TextInputType.number : TextInputType.text,
            onChanged: (value) => widget.formKey.currentState!.validate(),
            controller: _cardInfoController,
            labelText: _type == MembershipRegistrationCardType.nationalID
                ? 'Enter Your National ID Card Number'
                : 'Enter Your Passport Number',
            helperText: _type == MembershipRegistrationCardType.nationalID
                ? 'Enter Your National ID Card Number Here'
                : 'Enter Your Passport Number Here',
            validator: (value) {
              if (value == null || value.isEmpty)
                return _type == MembershipRegistrationCardType.nationalID
                    ? 'National ID Card Number Cannot Be Empty'
                    : 'Passport Number Cannot Be Empty';

              if (_type == MembershipRegistrationCardType.nationalID) {
                if (!value.isNumeric())
                  return 'National ID Card Should Be A Number';
                else if (value.length != 9) return 'National ID Card Should Be 9 Digits';
              } else {
                if (value.isNumeric())
                  return 'Passport Number Should Have One Letter';
                else if (value.hasSpecialCharacters())
                  return 'Passport Number Cannot Have Special Characters';
                else if (!value.hasNumber()) return 'Passport Number Should Contain Numbers';
              }

              return null;
            },
          ),
        ],
      ),
    );
  }
}

class _MembershipRegistrationCardTypeSelector extends StatelessWidget {
  final MembershipRegistrationCardType? _currentType = MembershipRegistrationStepsHelper.shared.cardType;
  final MembershipRegistrationCardType type;
  final void Function(MembershipRegistrationCardType) updateType;

  _MembershipRegistrationCardTypeSelector({required this.type, required this.updateType});

  @override
  Widget build(BuildContext context) {
    return createInkWell(
      onTap: () => updateType(type),
      child: Container(
        margin: EdgeInsets.all(10),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        width: MediaQuery.of(context).size.width * 0.4,
        decoration: BoxDecoration(
          border: _currentType == type
              ? Border.all(
            color: Theme.of(context).primaryColor,
            width: 2,
          )
              : Border.all(color: Colors.black),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                children: [
                  Image.asset(
                    type == MembershipRegistrationCardType.nationalID
                        ? 'assets/registration/national_id.png'
                        : 'assets/registration/passport.png',
                  ),
                  Text(
                    type == MembershipRegistrationCardType.nationalID ? 'National ID' : 'Passport',
                  ),
                ],
              ),
            ),
            _currentType == type
                ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.check,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            )
                : SizedBox(),
          ],
        ),
      ),
    );
  }
}
