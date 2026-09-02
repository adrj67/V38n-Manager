import 'package:flutter/material.dart';

class DurationSelector extends StatefulWidget {
  final Function(int) onDurationSelected;
  final int initialDuration;

  const DurationSelector({
    Key? key,
    required this.onDurationSelected,
    this.initialDuration = 30,
  }) : super(key: key);

  @override
  State<DurationSelector> createState() => _DurationSelectorState();
}

class _DurationSelectorState extends State<DurationSelector> {
  late int _selectedDuration;
  final List<int> _durations = [10, 30, 60, 120, 300]; // 10s, 30s, 1min, 2min, 5min

  @override
  void initState() {
    super.initState();
    _selectedDuration = widget.initialDuration;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Duración: ', style: TextStyle(color: Colors.white70)),
        ..._durations.map((duration) {
          final isSelected = _selectedDuration == duration;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(
                duration >= 60
                    ? '${duration ~/ 60}min'
                    : '${duration}s',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedDuration = duration;
                  });
                  widget.onDurationSelected(duration);
                }
              },
              backgroundColor: Colors.grey[800],
              selectedColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          );
        }),
      ],
    );
  }
}