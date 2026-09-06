import 'package:flutter/material.dart';

/// Muestra un aviso centrado con botón "Aceptar", en vez de un
/// SnackBar en la parte inferior. Se usa para cualquier bloqueo o
/// validación importante (ej. "no puedes eliminar el único ingreso"),
/// para que se vea igual que las confirmaciones de eliminar.
Future<void> showErrorDialog(BuildContext context, String message, {String title = 'Aviso'}) {
  return showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Aceptar'),
        ),
      ],
    ),
  );
}