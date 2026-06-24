import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminNotifications extends StatefulWidget {
  const AdminNotifications({super.key});

  @override
  State<AdminNotifications> createState() => _AdminNotificationsState();
}

class _AdminNotificationsState extends State<AdminNotifications> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedAudience = 'all';
  String _selectedType = 'general';
  bool _isSending = false;

  final List<String> _audienceOptions = ['All Users', 'Customers Only', 'Entrepreneurs Only'];
  final List<String> _typeOptions = ['General', 'Maintenance', 'Promotion', 'Product Announcement'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Create Announcement
          const Text('Create Announcement', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildCreateAnnouncement(),
          
          const SizedBox(height: 16),
          
          // Notification History
          const Text('Notification History', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildNotificationHistory(),
          
          const SizedBox(height: 16),
          
          // Notification Analytics
          const Text('Notification Analytics', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildNotificationAnalytics(),
        ],
      ),
    );
  }

  Widget _buildCreateAnnouncement() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  labelStyle: TextStyle(fontSize: 12),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _messageController,
                style: const TextStyle(fontSize: 12),
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Message *',
                  labelStyle: TextStyle(fontSize: 12),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedAudience,
                decoration: const InputDecoration(
                  labelText: 'Audience *',
                  labelStyle: TextStyle(fontSize: 12),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: _audienceOptions.map((option) => DropdownMenuItem(
                  value: option.toLowerCase().replaceAll(' ', '_'),
                  child: Text(option, style: const TextStyle(fontSize: 12)),
                )).toList(),
                onChanged: (value) => setState(() => _selectedAudience = value!),
                validator: (v) => v == null ? 'Select audience' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type *',
                  labelStyle: TextStyle(fontSize: 12),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: _typeOptions.map((option) => DropdownMenuItem(
                  value: option.toLowerCase().replaceAll(' ', '_'),
                  child: Text(option, style: const TextStyle(fontSize: 12)),
                )).toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
                validator: (v) => v == null ? 'Select type' : null,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _sendNotification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF59F797),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSending
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Send Announcement', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSending = true);
    
    try {
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement sent successfully!', style: TextStyle(fontSize: 12)),
            backgroundColor: Colors.green,
          ),
        );
        _titleController.clear();
        _messageController.clear();
        setState(() {
          _selectedAudience = 'all';
          _selectedType = 'general';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: TextStyle(fontSize: 12)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  Widget _buildNotificationHistory() {
    final notifications = [
      {'title': 'Maintenance Notice', 'message': 'System maintenance on Sunday', 'audience': 'All Users', 'date': 'Today', 'read': 45},
      {'title': 'New Product Announcement', 'message': 'New electronics collection launched', 'audience': 'Customers', 'date': 'Yesterday', 'read': 89},
      {'title': 'Promotion Alert', 'message': 'End of month sale up to 30% off', 'audience': 'All Users', 'date': '2 days ago', 'read': 234},
    ];
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: notifications.map((notif) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF59F797).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.notifications, size: 16, color: Color(0xFF59F797)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notif['title'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                      Text(notif['message'] as String, style: TextStyle(fontSize: 9, color: Colors.grey[600]), maxLines: 1),
                      Row(
                        children: [
                          Text(notif['audience'] as String, style: TextStyle(fontSize: 8, color: Colors.grey[500])),
                          const SizedBox(width: 8),
                          Text(notif['date'] as String, style: TextStyle(fontSize: 8, color: Colors.grey[500])),
                          const SizedBox(width: 8),
                          Text('${notif['read']} read', style: TextStyle(fontSize: 8, color: const Color(0xFF59F797))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildNotificationAnalytics() {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      children: [
        _buildAnalyticCard('Total Sent', '45', Icons.send, Colors.blue),
        _buildAnalyticCard('Open Rate', '78%', Icons.visibility, Colors.green),
        _buildAnalyticCard('Read Rate', '65%', Icons.check_circle, const Color(0xFF59F797)),
      ],
    );
  }

  Widget _buildAnalyticCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: TextStyle(fontSize: 9, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}