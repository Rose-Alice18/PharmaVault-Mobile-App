import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_colors.dart';
import '../utils/validators.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  static final _db  = Supabase.instance.client;
  static String? get _uid => _db.auth.currentUser?.id;

  List<_Address> _addresses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    if (_uid == null) { setState(() => _loading = false); return; }
    setState(() => _loading = true);
    try {
      final data = await _db
          .from('user_addresses')
          .select()
          .eq('user_id', _uid!)
          .order('created_at', ascending: true);
      if (mounted) {
        setState(() {
          _addresses = (data as List)
              .map((e) => _Address.fromMap(e as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAddDialog({_Address? existing}) {
    final labelCtrl   = TextEditingController(text: existing?.label   ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');
    String iconType   = existing?.iconType ?? 'home';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
              // Icon type selector
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
                  onPressed: () async {
                    final label   = labelCtrl.text.trim();
                    final address = addressCtrl.text.trim();
                    if (label.isEmpty || address.isEmpty) return;
                    Navigator.pop(ctx);
                    await _saveAddress(
                      id:       existing?.id,
                      label:    label,
                      address:  address,
                      iconType: iconType,
                    );
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

  Future<void> _saveAddress({
    String? id,
    required String label,
    required String address,
    required String iconType,
  }) async {
    if (_uid == null) return;
    try {
      if (id != null) {
        await _db.from('user_addresses').update({
          'label':     label,
          'address':   address,
          'icon_type': iconType,
        }).eq('id', id);
      } else {
        await _db.from('user_addresses').insert({
          'user_id':   _uid!,
          'label':     label,
          'address':   address,
          'icon_type': iconType,
        });
      }
      await _loadAddresses();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _deleteAddress(String id) async {
    try {
      await _db.from('user_addresses').delete().eq('id', id);
      setState(() => _addresses.removeWhere((a) => a.id == id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  IconData _iconForType(String type) => switch (type) {
    'home'   => Icons.home_rounded,
    'office' => Icons.business_rounded,
    _        => Icons.location_on_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Saved Addresses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Address', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _addresses.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_off_rounded, size: 56, color: AppColors.divider),
                      SizedBox(height: 12),
                      Text('No saved addresses',
                          style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      SizedBox(height: 4),
                      Text('Add an address for faster checkout',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAddresses,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _addresses.length,
                    itemBuilder: (context, i) {
                      final addr = _addresses[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(12)),
                              child: Icon(_iconForType(addr.iconType),
                                  color: AppColors.primary, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(addr.label,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: Theme.of(context).colorScheme.onSurface)),
                                  const SizedBox(height: 3),
                                  Text(addr.address,
                                      style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                                          fontSize: 13)),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert,
                                  color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
                                  size: 20),
                              onSelected: (value) {
                                if (value == 'delete' && addr.id != null) {
                                  _deleteAddress(addr.id!);
                                } else if (value == 'edit') {
                                  _showAddDialog(existing: addr);
                                }
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(value: 'edit',   child: Text('Edit')),
                                const PopupMenuItem(value: 'delete',
                                    child: Text('Delete', style: TextStyle(color: AppColors.error))),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _Address {
  final String? id;
  final String  label;
  final String  address;
  final String  iconType;

  const _Address({this.id, required this.label, required this.address, this.iconType = 'home'});

  factory _Address.fromMap(Map<String, dynamic> m) => _Address(
    id:       m['id']       as String?,
    label:    m['label']    as String,
    address:  m['address']  as String,
    iconType: m['icon_type'] as String? ?? 'home',
  );
}
