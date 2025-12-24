import 'package:flutter/material.dart' show BuildContext;
import 'package:flutter/services.dart' show SystemChannels;

void dismissKeyboard(BuildContext context) => SystemChannels.textInput.invokeMethod('TextInput.hide');
