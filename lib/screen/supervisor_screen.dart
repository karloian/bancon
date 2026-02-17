import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupervisorScreen extends StatefulWidget {
  const SupervisorScreen({super.key});

  @override
  State<SupervisorScreen> createState() => _SupervisorScreenState();
}

class _SupervisorScreenState extends State<SupervisorScreen> {
  List<Map<String, dynamic>> stores = [];
  bool isLoading = false;
  dynamic _realtimeChannel;
  int _currentPage = 0;
  final int _itemsPerPage = 5;
  int _selectedStatus = 1; // 1=Pending, 2=Approved, 3=Encode, 4=Disapproved
  Map<int, int> _statusCounts = {1: 0, 2: 0, 3: 0, 4: 0};
  Map<String, Map<String, int>> _agentAnalytics = {};

  @override
  void initState() {
    super.initState();
    _loadStores();
    _setupRealtimeSubscription();
  }

  void _setupRealtimeSubscription() {
    _realtimeChannel = Supabase.instance.client
        .channel('supervisor_store_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'store_information',
          callback: (payload) {
            _loadStores();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadStores() async {
    setState(() => isLoading = true);

    try {
      // Load all stores
      final response = await Supabase.instance.client
          .from('store_information')
          .select('''
            *,
            users_db!store_information_agent_id_fkey(fullname)
          ''')
          .inFilter('status', [1, 2, 3, 4])
          .order('created_at', ascending: false);

      // Count stores by status
      final Map<int, int> counts = {1: 0, 2: 0, 3: 0, 4: 0};
      final allStores = List<Map<String, dynamic>>.from(response);
      final Map<String, Map<String, int>> agentStats = {};

      for (var store in allStores) {
        final status = store['status'] as int?;
        if (status != null && counts.containsKey(status)) {
          counts[status] = counts[status]! + 1;
        }

        // Calculate agent analytics
        final agentName = store['users_db']?['fullname'] ?? 'Unknown';
        if (!agentStats.containsKey(agentName)) {
          agentStats[agentName] = {
            'total': 0,
            'pending': 0,
            'approved': 0,
            'encode': 0,
            'disapproved': 0,
          };
        }

        agentStats[agentName]!['total'] =
            (agentStats[agentName]!['total'] ?? 0) + 1;

        if (status == 1) {
          agentStats[agentName]!['pending'] =
              (agentStats[agentName]!['pending'] ?? 0) + 1;
        } else if (status == 2) {
          agentStats[agentName]!['approved'] =
              (agentStats[agentName]!['approved'] ?? 0) + 1;
        } else if (status == 3) {
          agentStats[agentName]!['encode'] =
              (agentStats[agentName]!['encode'] ?? 0) + 1;
        } else if (status == 4) {
          agentStats[agentName]!['disapproved'] =
              (agentStats[agentName]!['disapproved'] ?? 0) + 1;
        }
      }

      if (mounted) {
        setState(() {
          stores = allStores;
          _statusCounts = counts;
          _agentAnalytics = agentStats;
          isLoading = false;
          _currentPage = 0; // Reset to first page
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading stores: $e')));
      }
    }
  }

  Future<void> _approveStore(Map<String, dynamic> store) async {
    try {
      final currentDate = DateTime.now().toString().split(' ')[0];
      await Supabase.instance.client
          .from('store_information')
          .update({'status': 2, 'remarks': '$currentDate - Approve'})
          .eq('store_id', store['store_id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Store approved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadStores();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving store: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _disapproveStore(Map<String, dynamic> store) async {
    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disapprove Store'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please state the reason for disapproval:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter reason...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Disapprove'),
          ),
        ],
      ),
    );

    if (result == true && reasonController.text.trim().isNotEmpty) {
      try {
        final currentDate = DateTime.now().toString().split(' ')[0];
        await Supabase.instance.client
            .from('store_information')
            .update({
              'status': 4,
              'remarks': '$currentDate - ${reasonController.text.trim()}',
            })
            .eq('store_id', store['store_id']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Store disapproved'),
              backgroundColor: Colors.red,
            ),
          );
          _loadStores();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error disapproving store: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else if (result == true && reasonController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please provide a reason for disapproval'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    reasonController.dispose();
  }

  void _viewStoreDetails(Map<String, dynamic> store) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.store, color: Color(0xFF00529B)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                store['store_name'] ?? 'Store Details',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Date:', store['date']),
              _buildDetailRow('Owner:', store['purchaser_owner']),
              _buildDetailRow('Contact:', store['contact_number']),
              _buildDetailRow('Address:', store['complete_address']),
              _buildDetailRow('Territory:', store['territory']),
              _buildDetailRow('Classification:', store['store_classification']),
              _buildDetailRow('TIN:', store['tin']),
              _buildDetailRow('Payment Term:', store['payment_term']),
              _buildDetailRow('Price Level:', store['price_level']),
              _buildDetailRow('Agent Code:', store['agent_code']),
              _buildDetailRow('Sales Person:', store['sales_person']),
              _buildDetailRow(
                'Agent Name:',
                store['users_db']?['fullname'] ?? 'N/A',
              ),
              if (store['map_latitude'] != null &&
                  store['map_longitude'] != null)
                _buildDetailRow(
                  'Coordinates:',
                  'Lat: ${store['map_latitude']}, Lng: ${store['map_longitude']}',
                ),
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatusColor(store['status'] ?? 1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getStatusBorderColor(store['status'] ?? 1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getStatusIcon(store['status'] ?? 1),
                      color: _getStatusTextColor(store['status'] ?? 1),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Status: ${_getStatusText(store['status'] ?? 1)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getStatusTextColor(store['status'] ?? 1),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (store['status'] == 1) ...[
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _disapproveStore(store);
              },
              icon: const Icon(Icons.cancel),
              label: const Text('Disapprove'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _approveStore(store);
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Approve'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Supervisor Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF00529B),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadStores,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Cards Section
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    title: 'Pending',
                    count: _statusCounts[1] ?? 0,
                    icon: Icons.pending_actions,
                    color: Colors.orange,
                    status: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusCard(
                    title: 'Approved',
                    count: _statusCounts[2] ?? 0,
                    icon: Icons.check_circle,
                    color: Colors.green,
                    status: 2,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusCard(
                    title: 'Encode',
                    count: _statusCounts[3] ?? 0,
                    icon: Icons.edit_note,
                    color: Colors.blue,
                    status: 3,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusCard(
                    title: 'Disapproved',
                    count: _statusCounts[4] ?? 0,
                    icon: Icons.cancel,
                    color: Colors.red,
                    status: 4,
                  ),
                ),
              ],
            ),
          ),
          // Agent Analytics Section
          if (_agentAnalytics.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.analytics,
                        color: const Color(0xFF00529B),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Agent Analytics',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00529B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _agentAnalytics.length,
                      itemBuilder: (context, index) {
                        final agentName = _agentAnalytics.keys.elementAt(index);
                        final stats = _agentAnalytics[agentName]!;
                        return Container(
                          width: 140,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF00529B).withOpacity(0.1),
                                const Color(0xFF00529B).withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF00529B).withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                agentName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF00529B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Total: ${stats['total']}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.pending_actions,
                                    size: 12,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${stats['pending']}',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.check_circle,
                                    size: 12,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${stats['approved']}',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.edit_note,
                                    size: 12,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${stats['encode']}',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.cancel,
                                    size: 12,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${stats['disapproved']}',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          // Table Section
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _getFilteredStores().isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No stores found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(
                                const Color(0xFF00529B).withOpacity(0.1),
                              ),
                              border: TableBorder.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                              columns: const [
                                DataColumn(
                                  label: Text(
                                    'Store Name',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Remarks',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              rows: _getPaginatedStores().map((store) {
                                return DataRow(
                                  color: WidgetStateProperty.all(
                                    _getStatusColor(_selectedStatus),
                                  ),
                                  cells: [
                                    DataCell(
                                      Text(
                                        store['store_name'] ?? 'N/A',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        store['remarks']?.toString() ?? 'N/A',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                  onSelectChanged: (_) =>
                                      _viewStoreDetails(store),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                      // Pagination controls
                      if (_getFilteredStores().length > _itemsPerPage)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Page ${_currentPage + 1} of ${_getTotalPages()}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: _currentPage > 0
                                        ? () {
                                            setState(() => _currentPage--);
                                          }
                                        : null,
                                    icon: const Icon(Icons.chevron_left),
                                    style: IconButton.styleFrom(
                                      backgroundColor: _currentPage > 0
                                          ? const Color(0xFF00529B)
                                          : Colors.grey.shade300,
                                      foregroundColor: _currentPage > 0
                                          ? Colors.white
                                          : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed:
                                        _currentPage < _getTotalPages() - 1
                                        ? () {
                                            setState(() => _currentPage++);
                                          }
                                        : null,
                                    icon: const Icon(Icons.chevron_right),
                                    style: IconButton.styleFrom(
                                      backgroundColor:
                                          _currentPage < _getTotalPages() - 1
                                          ? const Color(0xFF00529B)
                                          : Colors.grey.shade300,
                                      foregroundColor:
                                          _currentPage < _getTotalPages() - 1
                                          ? Colors.white
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredStores() {
    return stores.where((store) => store['status'] == _selectedStatus).toList();
  }

  List<Map<String, dynamic>> _getPaginatedStores() {
    final filteredStores = _getFilteredStores();
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(
      0,
      filteredStores.length,
    );
    return filteredStores.sublist(startIndex, endIndex);
  }

  int _getTotalPages() {
    final filteredStores = _getFilteredStores();
    return (filteredStores.length / _itemsPerPage).ceil();
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.orange.shade50;
      case 2:
        return Colors.green.shade50;
      case 3:
        return Colors.blue.shade50;
      case 4:
        return Colors.red.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  Color _getStatusBorderColor(int status) {
    switch (status) {
      case 1:
        return Colors.orange.shade200;
      case 2:
        return Colors.green.shade200;
      case 3:
        return Colors.blue.shade200;
      case 4:
        return Colors.red.shade200;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _getStatusTextColor(int status) {
    switch (status) {
      case 1:
        return Colors.orange.shade700;
      case 2:
        return Colors.green.shade700;
      case 3:
        return Colors.blue.shade700;
      case 4:
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _getStatusIcon(int status) {
    switch (status) {
      case 1:
        return Icons.pending_actions;
      case 2:
        return Icons.check_circle;
      case 3:
        return Icons.edit_note;
      case 4:
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case 1:
        return 'Pending for Approval';
      case 2:
        return 'Approved';
      case 3:
        return 'Encode';
      case 4:
        return 'Disapproved';
      default:
        return 'Unknown';
    }
  }

  Widget _buildStatusCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required int status,
  }) {
    final isSelected = _selectedStatus == status;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedStatus = status;
          _currentPage = 0; // Reset to first page
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 6 : 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: isSelected ? Colors.white : color),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
