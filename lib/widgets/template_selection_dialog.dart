// lib/widgets/template_selection_dialog.dart

import 'package:flutter/material.dart';
import '../models/recap_template.dart';

class TemplateSelectionDialog extends StatefulWidget {
  final RecapPreferences? currentPreferences;

  const TemplateSelectionDialog({
    super.key,
    this.currentPreferences,
  });

  @override
  State<TemplateSelectionDialog> createState() => _TemplateSelectionDialogState();
}

class _TemplateSelectionDialogState extends State<TemplateSelectionDialog> {
  late RecapTemplateStyle _selectedTemplate;
  late double _targetDuration;

  @override
  void initState() {
    super.initState();
    
    final prefs = widget.currentPreferences ?? RecapPreferences();
    _selectedTemplate = prefs.defaultTemplate;
    _targetDuration = prefs.targetDuration;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Simple header with close button
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Create Weekly Recap',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Template options - simplified
                    const Text(
                      'Choose Style',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSimpleTemplateOption(
                      style: RecapTemplateStyle.highlight,
                      icon: Icons.flash_on,
                      title: 'Highlight',
                    ),
                    const SizedBox(height: 10),
                    _buildSimpleTemplateOption(
                      style: RecapTemplateStyle.cinematic,
                      icon: Icons.movie,
                      title: 'Cinematic',
                    ),
                    const SizedBox(height: 10),
                    _buildSimpleTemplateOption(
                      style: RecapTemplateStyle.timeline,
                      icon: Icons.view_day,
                      title: 'Timeline',
                    ),

                    const SizedBox(height: 24),

                    // Duration - simplified
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Duration',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          '${_targetDuration.toInt()} seconds',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF009688),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF009688),
                        inactiveTrackColor: Colors.grey[300],
                        thumbColor: const Color(0xFF009688),
                        overlayColor: const Color(0xFF009688).withOpacity(0.2),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _targetDuration,
                        min: 30.0,
                        max: 60.0,
                        divisions: 6,
                        onChanged: (value) {
                          setState(() => _targetDuration = value);
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('30s', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        Text('60s', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),

            // Footer buttons - simplified
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        final result = RecapPreferences(
                          defaultTemplate: _selectedTemplate,
                          targetDuration: _targetDuration,
                          autoGenerate: false,
                          effects: RecapEffectsConfig(
                            transitions: true,
                            textOverlays: false, // Disabled for now
                            colorFilters: true,
                            musicSync: true,
                          ),
                        );
                        Navigator.of(context).pop(result);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF009688),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Generate',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleTemplateOption({
    required RecapTemplateStyle style,
    required IconData icon,
    required String title,
  }) {
    final isSelected = _selectedTemplate == style;

    return InkWell(
      onTap: () => setState(() => _selectedTemplate = style),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF009688).withOpacity(0.08) : Colors.grey[50],
          border: Border.all(
            color: isSelected ? const Color(0xFF009688) : Colors.grey[200]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF009688) : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? const Color(0xFF009688) : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    style.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF009688),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

