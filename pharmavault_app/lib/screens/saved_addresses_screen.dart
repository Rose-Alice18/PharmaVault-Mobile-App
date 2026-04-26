import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../utils/validators.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  static const _prefsKey = 'saved_addresses';
  List<_Address> _addresses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    setState(() {
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _addresses = list.map((e) => _Address.fromMap(e as Map<String, dynamic>)).toList();
      }
      _loading = false;
    });
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_addresses.map((a) => a.toMap()).toList()));
  }

  void _showAddDialog({_Address? existing, int? index}) {
    final labelCtrl   = TextEditingController(text: existing?.label   ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');
    String iconType = existing?.iconType ?? 'home';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20, right: 20, top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                existing != null ? 'Edit Address' : 'Add New Address',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Row(
                children: ['home', 'office', 'other'].map((t) => GestureDetector(
                  onTap: () => setModal(() => iconType = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: iconType == t ? AppColors.primary : const Color(0xFFF4F6F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_iconForType(t), size: 15,
                            color: iconType == t ? Colors.white : AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          t[0].toUpperCase() + t.substring(1),
                          style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: iconType == t ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: labelCtrl,
                inputFormatters: AppFormatters.name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Address Label (e.g. Home, Office)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.label_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressCtrl,
                inputFormatters: AppFormatters.address,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Street Address',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final label   = labelCtrl.text.trim();
                    final address = addressCtrl.text.trim();
                    if (label.isEmpty || address.isEmpty) return;
                    final addr = _Address(label: label, address: address, iconType: iconType);
                    setState(() {
                      if (index != null) {
                        _addresses[index] = addr;
                      } else {
                        _addresses.add(addr);
                      }
                    });
                    _persist();
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Address', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) => switch (type) {
    'home'   => Icons.home_rounded,
    'office' => Icons.business_rounded,
    _        => Icons.location_on_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Saved Addresses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Address', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_off_rounded, size: 56, color: AppColors.divider),
                      SizedBox(height: 12),
                      Text('No saved addresses', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      SizedBox(height: 4),
                      Text('Add an address for faster checkout', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: _addresses.length,
                  itemBuilder: (context, i) {
                    final addr = _addresses[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                            child: Icon(_iconForType(addr.iconType), color: AppColors.primary, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(addr.label,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                                const SizedBox(height: 3),
                                Text(addr.address,
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
                            onSelected: (value) {
                              if (value == 'delete') {
                                setState(() => _addresses.removeAt(i));
                                _persist();
                              } else if (value == 'edit') {
                                _showAddDialog(existing: addr, index: i);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(value: 'edit', child: Text('Edit')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

class _Address {
  final String label;
  final String address;
  final String iconType;
  const _Address({required this.label, required this.address, this.iconType = 'home'});

  factory _Address.fromMap(Map<String, dynamic> m) => _Address(
    label:    m['label']     as String,
    address:  m['address']   as String,
    iconType: m['icon_type'] as String? ?? 'home',
  );

  Map<String, dynamic> toMap() => {
    'label':     label,
    'address':   address,
    'icon_type': iconType,
  };
}
