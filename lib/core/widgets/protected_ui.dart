import 'package:flutter/material.dart';

import '../app_context.dart';

Future<T?> showProtectedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) {
  AppContext.beginProtectedUi();
  return showDialog<T>(
    context: context,
    builder: builder,
    barrierDismissible: barrierDismissible,
    useRootNavigator: useRootNavigator,
  ).whenComplete(AppContext.endProtectedUi);
}

Future<DateTime?> showProtectedDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  DatePickerMode initialDatePickerMode = DatePickerMode.day,
}) async {
  AppContext.beginProtectedUi();
  try {
    return await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDatePickerMode: initialDatePickerMode,
      helpText: 'Selecione a data',
    );
  } finally {
    AppContext.endProtectedUi();
  }
}

Future<T?> showProtectedModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
}) {
  AppContext.beginProtectedUi();
  return showModalBottomSheet<T>(
    context: context,
    builder: builder,
    isScrollControlled: isScrollControlled,
  ).whenComplete(AppContext.endProtectedUi);
}

Future<TimeOfDay?> showProtectedTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) async {
  AppContext.beginProtectedUi();
  try {
    return await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
  } finally {
    AppContext.endProtectedUi();
  }
}
