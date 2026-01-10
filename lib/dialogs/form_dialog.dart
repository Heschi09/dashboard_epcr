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
  final _dropdownValues = <String?>[];

  @override
  void initState() {
    super.initState();
    for (var field in widget.fields) {
      final key = field['key'] ?? field['label'] ?? 'field';
      final initial = widget.initialValues?[key] ?? '';
      _controllers.add(TextEditingController(text: initial));
      
      // Initialize dropdown value if it's a dropdown field
      if (field['type'] == 'dropdown') {
        final options = field['options']?.split(',').map((e) => e.trim()).toList() ?? [];
        _dropdownValues.add(options.contains(initial) ? initial : (options.isNotEmpty ? options[0] : null));
      } else {
        _dropdownValues.add(null);
      }
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
                
                // Check if this is a dropdown field
                if (field['type'] == 'dropdown') {
                  final options = field['options']?.split(',').map((e) => e.trim()).toList() ?? [];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: DropdownButtonFormField<String>(
                      value: _dropdownValues[index],
                      decoration: InputDecoration(
                        labelText: field['label'],
                        hintText: field['hint'],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: options.map((option) {
                        return DropdownMenuItem<String>(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _dropdownValues[index] = value;
                          _controllers[index].text = value ?? '';
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  );
                }
                
                // Regular text field
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
                          // For dropdown fields, use the dropdown value; otherwise use text controller
                          if (field['type'] == 'dropdown') {
                            data[_keyForField(field)] = _dropdownValues[i] ?? '';
                          } else {
                            data[_keyForField(field)] = _controllers[i].text.trim();
                          }
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