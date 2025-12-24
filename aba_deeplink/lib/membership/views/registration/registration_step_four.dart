import 'package:flutter/material.dart';

import '../../data/focus_node_helper.dart';


class MembershipRegistrationStepFour extends StatefulWidget {
  final GlobalKey<FormState> formKey;

  MembershipRegistrationStepFour(this.formKey);

  @override
  _MembershipRegistrationStepFourState createState() => _MembershipRegistrationStepFourState();
}

class _MembershipRegistrationStepFourState extends State<MembershipRegistrationStepFour> {
  bool _agreedToTermsAndConditions = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 10),
      child: Column(
        children: [
          Text(
            'Terms & Conditions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 10),
          Container(
            height: MediaQuery.of(context).size.height * 0.55,
            child: Text('Just random Agreement Text'),
          ),
          Stack(
            alignment: AlignmentDirectional.topCenter,
            children: [
              Container(
                margin: EdgeInsets.symmetric(horizontal: 10),
                child: TextFormField(
                  focusNode: AlwaysDisabledFocusNode(),
                  validator: (value) {
                    if (!_agreedToTermsAndConditions) return 'You Need To Agree To The\nTerms & Conditions';

                    return null;
                  },
                  decoration: InputDecoration(border: InputBorder.none),
                ),
              ),
              Row(
                children: [
                  Checkbox(
                    value: _agreedToTermsAndConditions,
                    onChanged: (value) {
                      setState(() => _agreedToTermsAndConditions = !_agreedToTermsAndConditions);
                      widget.formKey.currentState!.validate();
                    },
                  ),
                  Flexible(
                    child: Text(
                      'I Have Read And Agreed To The Terms & Conditions.',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.04 / MediaQuery.of(context).textScaleFactor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
