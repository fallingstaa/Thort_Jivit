import 'package:flutter/material.dart';

class MemberhsipRegistrationStepFooter extends StatelessWidget {
  final int step;
  final VoidCallback onNextPressed;
  final VoidCallback onPreviousPressed;
  final VoidCallback onSubmit;

  MemberhsipRegistrationStepFooter({
    required this.step,
    required this.onNextPressed,
    required this.onPreviousPressed,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Step $step Out Of 4',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * 0.05 / MediaQuery.of(context).textScaleFactor,
            ),
          ),
          Row(
            children: [
              step == 1
                  ? SizedBox()
                  : TextButton(
                onPressed: onPreviousPressed,
                child: Text(
                  'Previous',
                  style: TextStyle(
                    fontSize: 15 / MediaQuery.of(context).textScaleFactor,
                  ),
                ),
              ),
              SizedBox(width: 10),
              step == 4
                  ? ElevatedButton(
                onPressed: onSubmit,
                child: Text(
                  'Submit',
                  style: TextStyle(
                    fontSize: 15 / MediaQuery.of(context).textScaleFactor,
                  ),
                ),
              )
                  : ElevatedButton(
                onPressed: onNextPressed,
                child: Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 15 / MediaQuery.of(context).textScaleFactor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
