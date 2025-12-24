import 'package:flutter/material.dart';

Widget createTextField({
  TextInputType type = TextInputType.text,
  TextInputAction action = TextInputAction.done,
  TextEditingController? controller,
  String? labelText,
  String? helperText,
  bool obscureText = false,
  String? Function(String?)? validator,
  bool autoValidate = false,
  void Function(String)? onChanged,
  void Function(String)? onSubmit,
}) {
  return TextFormField(
    keyboardType: type,
    textInputAction: action,
    autovalidateMode: autoValidate ? AutovalidateMode.onUserInteraction : null,
    onFieldSubmitted: onSubmit,
    onChanged: onChanged,
    controller: controller,
    decoration: InputDecoration(
      labelText: labelText,
      helperText: helperText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(),
      ),
    ),
    validator: validator,
    obscureText: obscureText,
    enableSuggestions: false,
    autocorrect: false,
  );
}

Widget createPinCodeTextField({
  required BuildContext context,
  required int length,
  required void Function(String) onCompleted,
  TextEditingController? controller,
  String? Function(String?)? validator,
  void Function(String)? onChanged,
  bool obscureText = true,
  bool enableAutofill = false,
}) {
  return Container();
}
