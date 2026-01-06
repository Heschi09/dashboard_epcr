import 'package:flutter/material.dart';

class FormDialog extends StatefulWidget {
  const FormDialog({
    super.key,
    required this.title,
    required this.fields,
    this.onSubmit,
    this.initialValues,
  });

  final String title;
  final List<Map<String, String>> fields;
  final void Function(Map<String, String>)? onSubmit;
  final Map<String, String>? initialValues;

  @override
  State<FormDialog> createState() => _FormDialogState();
}

class _FormDialogState extends State<FormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <TextEditingController>[];

  @override
  void initState() {
    super.initState();
    for (var field in widget.fields) {
      final key = field['key'] ?? field['label'] ?? 'field';
      final initial = widget.initialValues?[key] ?? '';
      _controllers.add(TextEditingController(text: initial));
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String _keyForField(Map<String, String> field) {
      return field['key'] ?? field['label'] ?? 'field';
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ...widget.fields.asMap().entries.map((entry) {
                final index = entry.key;
                final field = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    controller: _controllers[index],
                    decoration: InputDecoration(
                      labelText: field['label'],
                      hintText: field['hint'],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                );
              }),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final data = <String, String>{};
                        for (var i = 0; i < widget.fields.length; i++) {
                          final field = widget.fields[i];
                          data[_keyForField(field)] = _controllers[i].text.trim();
                        }
                        widget.onSubmit?.call(data);
                        Navigator.of(context).pop(data);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${widget.title} saved')),
                        );
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}