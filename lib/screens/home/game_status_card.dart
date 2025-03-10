import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_theme.dart';
import '../../models/game_model.dart';
import '../../models/game_status_model.dart';
import '../../providers/game_status_provider.dart';

class GameStatusCard extends StatefulWidget {
  final GameModel game;
  final String userId;

  const GameStatusCard({
    super.key,
    required this.game,
    required this.userId,
  });

  @override
  State<GameStatusCard> createState() => _GameStatusCardState();
}

class _GameStatusCardState extends State<GameStatusCard> {
  bool _isLoading = false;
  GameStatusModel? _status;
  bool _isDown = false;
  DateTime? _availableUntil;
  String? _note;
  late TextEditingController _noteController;
  
  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _loadStatus();
  }
  
  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
  
  Future<void> _loadStatus() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final gameStatusProvider = Provider.of<GameStatusProvider>(context, listen: false);
      _status = await gameStatusProvider.getGameStatus(widget.userId, widget.game.id);
      
      if (_status != null) {
        setState(() {
          _isDown = _status!.isDown;
          _availableUntil = _status!.availableUntil;
          _note = _status!.note;
          _noteController.text = _status!.note ?? '';
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _toggleStatus() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final gameStatusProvider = Provider.of<GameStatusProvider>(context, listen: false);
      
      final success = await gameStatusProvider.setGameStatus(
        userId: widget.userId,
        gameId: widget.game.id,
        isDown: !_isDown,
        availableUntil: _availableUntil,
        note: _note,
      );
      
      if (success) {
        setState(() {
          _isDown = !_isDown;
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _showStatusOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildStatusOptionsSheet(),
    );
  }
  
  Widget _buildStatusOptionsSheet() {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Set Status for ${widget.game.name}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Status toggle
          SwitchListTile(
            title: const Text('Down to Play'),
            value: _isDown,
            onChanged: (value) {
              setState(() {
                _isDown = value;
              });
            },
          ),
          
          // Available until
          ListTile(
            title: const Text('Available Until'),
            subtitle: _availableUntil != null
                ? Text(_formatDateTime(_availableUntil!))
                : const Text('Not set'),
            trailing: const Icon(Icons.access_time),
            onTap: () => _selectAvailableUntil(),
          ),
          
          // Note
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g., "Looking for a squad"',
              ),
              onChanged: (value) {
                setState(() {
                  _note = value.isEmpty ? null : value;
                });
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Save button
          ElevatedButton(
            onPressed: () {
              _saveStatus();
              Navigator.pop(context);
            },
            child: const Text('Save Status'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  Future<void> _selectAvailableUntil() async {
    final now = DateTime.now();
    final initialTime = _availableUntil ?? now.add(const Duration(hours: 2));
    
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialTime,
      firstDate: now,
      lastDate: now.add(const Duration(days: 7)),
    );
    
    if (selectedDate != null) {
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialTime),
      );
      
      if (selectedTime != null && mounted) {
        setState(() {
          _availableUntil = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            selectedTime.hour,
            selectedTime.minute,
          );
        });
      }
    }
  }
  
  Future<void> _saveStatus() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final gameStatusProvider = Provider.of<GameStatusProvider>(context, listen: false);
      
      await gameStatusProvider.setGameStatus(
        userId: widget.userId,
        gameId: widget.game.id,
        isDown: _isDown,
        availableUntil: _availableUntil,
        note: _noteController.text.isEmpty ? null : _noteController.text,
      );
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    String prefix;
    if (date == today) {
      prefix = 'Today';
    } else if (date == tomorrow) {
      prefix = 'Tomorrow';
    } else {
      prefix = '${dateTime.month}/${dateTime.day}';
    }
    
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$prefix at $hour:$minute $period';
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: _showStatusOptions,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Game image or icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: widget.game.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.game.imageUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        Icons.sports_esports,
                        size: 30,
                        color: Theme.of(context).colorScheme.primary,
                      ),
              ),
              const SizedBox(width: 16),
              
              // Game info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.game.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Players: ${widget.game.minPlayers}${widget.game.maxPlayers != null ? ' - ${widget.game.maxPlayers}' : '+'} | ${widget.game.platforms.join(", ")}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    if (_note != null && _note!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _note!,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Status indicator
              _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : Switch(
                      value: _isDown,
                      onChanged: (_) => _toggleStatus(),
                      activeColor: AppTheme.downToPlayColor,
                    ),
            ],
          ),
        ),
      ),
    );
  }
} 