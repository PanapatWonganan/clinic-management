import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/order.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/order_history_card.dart';
import '../widgets/order_filter_chip.dart';
import '../widgets/order_search_bar.dart';
import '../services/api_service.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<Order> allOrders = [];
  List<Order> filteredOrders = [];
  OrderStatus? selectedStatus;
  String searchQuery = '';
  String sortBy = 'date_desc'; // date_desc, date_asc, amount_desc, amount_asc
  bool isLoading = false;
  String? errorMessage;
  
  // For scroll indicator
  final ScrollController _scrollController = ScrollController();
  bool _showScrollIndicator = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _updateScrollIndicator();
        _scrollController.addListener(_updateScrollIndicator);
      }
    });
  }

  void _updateScrollIndicator() {
    if (_scrollController.hasClients) {
      final maxScrollExtent = _scrollController.position.maxScrollExtent;
      final currentPosition = _scrollController.position.pixels;
      final showIndicator = maxScrollExtent > 0 && currentPosition < maxScrollExtent - 10;
      
      if (_showScrollIndicator != showIndicator) {
        setState(() {
          _showScrollIndicator = showIndicator;
        });
      }
    }
  }

  Future<void> _loadOrders() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final ordersData = await ApiService.fetchUserOrders();
      final orders = ordersData.map((data) => Order.fromJson(data)).toList();
      
      setState(() {
        allOrders = orders;
        isLoading = false;
      });
      
      _applyFilters();
      
      // Update scroll indicator after data loads
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateScrollIndicator();
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
      
      // Fallback to mock data for development
      _loadMockOrders();
    }
  }

  void _loadMockOrders() {
    // Mock data - replace with actual API call
    allOrders = [
      Order(
        id: '1',
        orderNumber: 'EX240001',
        orderDate: DateTime.now().subtract(const Duration(days: 1)),
        totalAmount: 25050,
        subtotal: 25000,
        deliveryFee: 50,
        status: OrderStatus.shipped,
        deliveryMethod: 'มอเตอร์ไซค์',
        paymentMethod: 'บัตรเครดิต',
        trackingNumber: 'TH123456789',
        items: [
          OrderItem(
            id: '1',
            name: 'Fine บาง',
            quantity: 10,
            price: 2500,
            imagePath: 'assets/images/mask-group.png',
          ),
          OrderItem(
            id: '2',
            name: 'Implant แข็ง',
            quantity: 10,
            price: 2500,
            imagePath: 'assets/images/mask-group-3.png',
          ),
        ],
      ),
      Order(
        id: '2',
        orderNumber: 'EX240002',
        orderDate: DateTime.now().subtract(const Duration(days: 3)),
        totalAmount: 12500,
        subtotal: 12500,
        status: OrderStatus.processing,
        deliveryMethod: 'Grab',
        paymentMethod: 'พร้อมเพย์',
        items: [
          OrderItem(
            id: '3',
            name: 'Deep กลาง',
            quantity: 5,
            price: 2500,
            imagePath: 'assets/images/mask-group-1.png',
          ),
        ],
      ),
    ];

    _applyFilters();
    
    // Update scroll indicator after mock data loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScrollIndicator();
    });
  }

  void _applyFilters() {
    setState(() {
      filteredOrders = allOrders.where((order) {
        // Status filter
        if (selectedStatus != null && order.status != selectedStatus) {
          return false;
        }

        // Search filter
        if (searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          return order.orderNumber.toLowerCase().contains(query) ||
              order.items
                  .any((item) => item.name.toLowerCase().contains(query));
        }

        return true;
      }).toList();

      // Apply sorting
      _applySorting();
    });
  }

  void _applySorting() {
    switch (sortBy) {
      case 'date_desc':
        filteredOrders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
        break;
      case 'date_asc':
        filteredOrders.sort((a, b) => a.orderDate.compareTo(b.orderDate));
        break;
      case 'amount_desc':
        filteredOrders.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
        break;
      case 'amount_asc':
        filteredOrders.sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
        break;
    }
  }

  void _onStatusFilterChanged(OrderStatus? status) {
    setState(() {
      selectedStatus = status;
    });
    _applyFilters();
  }

  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
    });
    _applyFilters();
  }

  void _onSortChanged(String sort) {
    setState(() {
      sortBy = sort;
    });
    _applySorting();
  }

  void _navigateToOrderDetail(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(order: order),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'เรียงลำดับตาม',
              style: AppTextStyles.heading16Medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.purpleText,
              ),
            ),
            const SizedBox(height: 20),
            _buildSortOption('วันที่ล่าสุด', 'date_desc'),
            _buildSortOption('วันที่เก่าสุด', 'date_asc'),
            _buildSortOption('ยอดสูงสุด', 'amount_desc'),
            _buildSortOption('ยอดต่ำสุด', 'amount_asc'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String title, String value) {
    final isSelected = sortBy == value;
    return ListTile(
      title: Text(
        title,
        style: AppTextStyles.body14Medium.copyWith(
          color: isSelected ? AppColors.mainPurple : AppColors.purpleText,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: isSelected
          ? const Icon(
              Icons.check,
              color: AppColors.mainPurple,
              size: 20,
            )
          : null,
      onTap: () {
        _onSortChanged(value);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(showBackButton: true),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ประวัติการสั่งซื้อ',
                      style: AppTextStyles.heading16Medium.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.purpleText,
                      ),
                    ),
                    IconButton(
                      onPressed: _showSortOptions,
                      icon: const Icon(
                        Icons.sort,
                        color: AppColors.purpleText,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search bar
                OrderSearchBar(
                  onSearchChanged: _onSearchChanged,
                ),

                const SizedBox(height: 16),

                // Status filters with scroll indicator
                Stack(
                  children: [
                    SingleChildScrollView(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(right: 40), // Space for arrow
                      child: Row(
                        children: [
                          OrderFilterChip(
                            label: 'ทั้งหมด',
                            isSelected: selectedStatus == null,
                            onTap: () => _onStatusFilterChanged(null),
                          ),
                          const SizedBox(width: 8),
                          ...OrderStatus.values
                              .map((status) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: OrderFilterChip(
                                      label: status.displayName,
                                      isSelected: selectedStatus == status,
                                      onTap: () => _onStatusFilterChanged(status),
                                      color: status.color,
                                    ),
                                  ))
                              .toList(),
                        ],
                      ),
                    ),
                    
                    // Right scroll indicator
                    if (_showScrollIndicator)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.white.withValues(alpha:0.0),
                                Colors.white.withValues(alpha:0.8),
                                Colors.white,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.chevron_right,
                              color: AppColors.lightGray,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Orders list
          Expanded(
            child: _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.mainPurple,
        ),
      );
    }

    if (errorMessage != null && filteredOrders.isEmpty) {
      return _buildErrorState();
    }

    if (filteredOrders.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: AppColors.mainPurple,
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filteredOrders.length,
        itemBuilder: (context, index) {
          final order = filteredOrders[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: OrderHistoryCard(
              order: order,
              onTap: () => _navigateToOrderDetail(order),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 80,
            color: AppColors.lightGray,
          ),
          const SizedBox(height: 16),
          Text(
            'เกิดข้อผิดพลาด',
            style: AppTextStyles.heading16Medium.copyWith(
              color: AppColors.lightGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ไม่สามารถโหลดข้อมูลได้',
            style: AppTextStyles.body12Regular.copyWith(
              color: AppColors.lightGray,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadOrders,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('ลองใหม่'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            size: 80,
            color: AppColors.lightGray,
          ),
          const SizedBox(height: 16),
          Text(
            'ไม่พบประวัติการสั่งซื้อ',
            style: AppTextStyles.heading16Medium.copyWith(
              color: AppColors.lightGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ลองเปลี่ยนตัวกรองหรือค้นหาใหม่',
            style: AppTextStyles.body12Regular.copyWith(
              color: AppColors.lightGray,
            ),
          ),
        ],
      ),
    );
  }
}
