import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/entities/entities.dart';
import '../../../data/datasources/provider_datasource.dart';
import '../../bloc/services/services_bloc.dart';
import '../../bloc/services/services_event_state.dart';
import '../../bloc/categories/categories_bloc.dart';
import '../../bloc/categories/categories_event_state.dart';
import '../../widgets/minimalist_widgets.dart';

// Helper to safely parse int
int _safeInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

// Helper to safely parse double
double _safeDouble(dynamic value, {double defaultValue = 0.0}) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

class ProviderServicesScreen extends StatefulWidget {
  const ProviderServicesScreen({super.key});

  @override
  State<ProviderServicesScreen> createState() => _ProviderServicesScreenState();
}

class _ProviderServicesScreenState extends State<ProviderServicesScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _services = [];
  final ProviderDataSource _providerDataSource = ProviderDataSource();

  @override
  void initState() {
    super.initState();
    _loadServices();
    context.read<CategoriesBloc>().add(LoadCategories());
    context.read<ServicesBloc>().add(const LoadServices());
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    try {
      final services = await _providerDataSource.getMyServices();
      setState(() {
        _services = services;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddServiceSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddServiceSheet(onServiceAdded: () {
        Navigator.pop(context);
        _loadServices();
      }),
    );
  }

  void _showEditServiceSheet(Map<String, dynamic> service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditServiceSheet(
        service: service,
        onServiceUpdated: () {
          Navigator.pop(context);
          _loadServices();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: false,
            expandedHeight: 180,
            backgroundColor: AppColors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: EdgeInsets.fromLTRB(24, topPadding + 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.divider.withOpacity(0.5)),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded,
                                size: 18, color: AppColors.textPrimary),
                          ),
                        ),
                        GestureDetector(
                          onTap: _loadServices,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.divider.withOpacity(0.5)),
                            ),
                            child: const Icon(Icons.refresh_rounded,
                                size: 20, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Dịch vụ của tôi',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_services.length} dịch vụ đang được cung cấp bởi bạn',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child:
                  Divider(height: 1, color: AppColors.divider.withOpacity(0.3)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            sliver: _isLoading
                ? const SliverFillRemaining(
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary)),
                  )
                : _services.isEmpty
                    ? SliverFillRemaining(child: _buildEmptyState())
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _buildServiceCard(_services[index]),
                          childCount: _services.length,
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton.extended(
          onPressed: _showAddServiceSheet,
          backgroundColor: AppColors.primary,
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('Thêm dịch vụ',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontSize: 14)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                size: 64, color: AppColors.primary),
          ),
          const SizedBox(height: 32),
          const Text(
            'Chưa có dịch vụ nào',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Hãy thêm các dịch vụ sở trường để khách hàng\ncó thể tìm thấy và đặt lịch với bạn.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: 240,
            child: ElevatedButton.icon(
              onPressed: _showAddServiceSheet,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Thêm dịch vụ ngay',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final isActive =
        service['isActive'] as bool? ?? service['is_active'] as bool? ?? true;
    final serviceName = (service['service']?['name'] ?? 'Dịch vụ').toString();
    final categoryName =
        (service['service']?['category']?['name'] ?? '').toString();
    final price = _safeDouble(service['price']);
    final currency = (service['currency'] ?? 'VND').toString();
    final serviceId = _safeInt(service['serviceId'] ?? service['service_id']);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.shelf,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.home_repair_service_rounded,
                    color:
                        isActive ? AppColors.primary : AppColors.textTertiary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (categoryName.isNotEmpty)
                        Text(
                          categoryName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textTertiary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            _formatPrice(price),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            currency,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isActive ? 'ĐANG BẬT' : 'TẠM NGƯNG',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: isActive ? AppColors.primary : AppColors.warning,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.divider.withOpacity(0.3)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.edit_rounded,
                    label: 'Chỉnh sửa',
                    color: AppColors.info,
                    onTap: () => _showEditServiceSheet(service),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    icon: isActive
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    label: isActive ? 'Tạm ngưng' : 'Kích hoạt',
                    color: isActive ? AppColors.warning : AppColors.primary,
                    onTap: () => _toggleService(serviceId, !isActive),
                  ),
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.delete_outline_rounded,
                  label: '',
                  color: AppColors.error,
                  onTap: () => _confirmDelete(serviceId, serviceName),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return price.toStringAsFixed(0);
  }

  Future<void> _toggleService(int serviceId, bool isActive) async {
    try {
      await _providerDataSource.updateService(
          serviceId: serviceId, isActive: isActive);
      await _loadServices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                isActive ? 'Đã kích hoạt dịch vụ' : 'Đã tạm ngưng dịch vụ'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmDelete(int serviceId, String serviceName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade400),
            const SizedBox(width: 8),
            const Text('Xác nhận xóa'),
          ],
        ),
        content: Text('Bạn có chắc muốn xóa "$serviceName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _providerDataSource.deleteService(serviceId);
                await _loadServices();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Đã xóa dịch vụ'),
                        backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

/// Add Service Sheet - Modern Design
class _AddServiceSheet extends StatefulWidget {
  final VoidCallback onServiceAdded;
  const _AddServiceSheet({required this.onServiceAdded});

  @override
  State<_AddServiceSheet> createState() => _AddServiceSheetState();
}

class _AddServiceSheetState extends State<_AddServiceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final ProviderDataSource _providerDataSource = ProviderDataSource();

  Category? _selectedCategory;
  Service? _selectedService;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng điền đầy đủ thông tin'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _providerDataSource.addService(
        serviceId: _selectedService!.id,
        price: double.parse(_priceController.text.replaceAll(',', '')),
      );
      widget.onServiceAdded();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Thêm dịch vụ thành công!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.add_task_rounded,
                        color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Thêm dịch vụ mới',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildLabel('Danh mục dịch vụ'),
              BlocBuilder<CategoriesBloc, CategoriesState>(
                builder: (context, state) {
                  if (state is CategoriesLoaded) {
                    return _buildDropdown<Category>(
                      value: _selectedCategory,
                      hint: 'Chọn một danh mục',
                      items: state.categories,
                      itemBuilder: (cat) => Text(cat.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      onChanged: (cat) => setState(() {
                        _selectedCategory = cat;
                        _selectedService = null;
                      }),
                    );
                  }
                  return const Center(
                      child: LinearProgressIndicator(color: AppColors.primary));
                },
              ),
              const SizedBox(height: 24),
              _buildLabel('Tên dịch vụ cụ thể'),
              BlocBuilder<ServicesBloc, ServicesState>(
                builder: (context, state) {
                  if (state is ServicesLoaded) {
                    final Map<int, Service> uniqueServices = {};
                    for (var ps in state.services) {
                      if (_selectedCategory == null ||
                          ps.service.categoryId == _selectedCategory!.id) {
                        uniqueServices[ps.service.id] = ps.service;
                      }
                    }
                    final services = uniqueServices.values.toList();

                    return _buildDropdown<Service>(
                      value: _selectedService,
                      hint: _selectedCategory == null
                          ? 'Vui lòng chọn danh mục trước'
                          : 'Chọn một dịch vụ',
                      items: services,
                      itemBuilder: (svc) => Text(svc.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      onChanged: _selectedCategory == null
                          ? null
                          : (svc) => setState(() => _selectedService = svc),
                    );
                  }
                  return const SizedBox();
                },
              ),
              const SizedBox(height: 24),
              MinTextField(
                label: 'Giá dịch vụ của bạn (VND)',
                hint: 'Ví dụ: 150,000',
                controller: _priceController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.payments_rounded,
                    color: AppColors.textTertiary, size: 20),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Vui lòng nhập giá';
                  if (double.tryParse(v.replaceAll(',', '')) == null) {
                    return 'Giá không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 48),
              MinButton(
                text: 'Xác nhận thêm dịch vụ',
                isLoading: _isSubmitting,
                isFullWidth: true,
                onPressed: _submit,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: TextStyle(
              fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required Widget Function(T) itemBuilder,
    required void Function(T?)? onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: items
          .map(
              (item) => DropdownMenuItem(value: item, child: itemBuilder(item)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

/// Edit Service Sheet - Modern Design
class _EditServiceSheet extends StatefulWidget {
  final Map<String, dynamic> service;
  final VoidCallback onServiceUpdated;
  const _EditServiceSheet(
      {required this.service, required this.onServiceUpdated});

  @override
  State<_EditServiceSheet> createState() => _EditServiceSheetState();
}

class _EditServiceSheetState extends State<_EditServiceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final ProviderDataSource _providerDataSource = ProviderDataSource();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _priceController.text =
        _safeDouble(widget.service['price']).toStringAsFixed(0);
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final serviceId =
          _safeInt(widget.service['serviceId'] ?? widget.service['service_id']);
      await _providerDataSource.updateService(
        serviceId: serviceId,
        price: double.parse(_priceController.text.replaceAll(',', '')),
      );
      widget.onServiceUpdated();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Cập nhật thành công!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceName =
        (widget.service['service']?['name'] ?? 'Dịch vụ').toString();

    return Container(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.edit_note_rounded,
                        color: AppColors.info),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chỉnh sửa giá',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary),
                        ),
                        Text(
                          serviceName,
                          style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              MinTextField(
                label: 'Cập nhật giá mới (VND)',
                hint: 'Ví dụ: 180,000',
                controller: _priceController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.payments_rounded,
                    color: AppColors.textTertiary, size: 20),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Vui lòng nhập giá';
                  if (double.tryParse(v.replaceAll(',', '')) == null) {
                    return 'Giá không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 48),
              MinButton(
                text: 'Lưu thay đổi',
                isLoading: _isSubmitting,
                isFullWidth: true,
                onPressed: _submit,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
