import 'package:flutter/material.dart';
import 'keyboard_helper.dart';

mixin FormStatefulMixin<T extends StatefulWidget> on State<T> {
  final formKey = GlobalKey<FormState>();

  Future<void> onFormCompleted(BuildContext context);
}

mixin FormStatelessMixin on StatelessWidget {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  Future<void> onFormCompleted(BuildContext context);
}

mixin FormViewMixin on StatelessWidget {
  late final Widget form;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => dismissKeyboard(context),
      child: Container(
        color: Theme.of(context).colorScheme.background,
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              child: form,
              color: Theme.of(context).colorScheme.background,
            ),
          ),
        ),
      ),
    );
  }
}
