import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EncoderScreen extends StatefulWidget {
  const EncoderScreen({super.key});

  @override
  State<EncoderScreen> createState() => _EncoderScreenState();
}

class _EncoderScreenState extends State<EncoderScreen> {
  List<Map<String, dynamic>> stores = [];
  bool isLoading = false;
  dynamic _realtimeChannel;
  int _currentPage = 0;
  final int _itemsPerPage = 5;
  Map<String, Map<String, int>> _agentAnalytics = {};
  int _totalStores = 0;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadStores();
    _setupRealtimeSubscription();
  }

  Future<void> _loadUserName() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final response = await Supabase.instance.client
            .from('users_db')
            .select('fullname')
            .eq('user_id', userId)
            .single();
        if (mounted) {
          setState(() {
            _userName = response['fullname'] ?? 'Encoder';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = 'Encoder';
        });
      }
    }
  }

  void _setupRealtimeSubscription() {
    _realtimeChannel = Supabase.instance.client
        .channel('encoder_store_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'store_information',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'status',
            value: 2,
          ),
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
      // Load stores with status = 2 (Approved)
      final response = await Supabase.instance.client
          .from('store_information')
          .select('''
            *,
            users_db!store_information_agent_id_fkey(fullname)
          ''')
          .eq('status', 2)
          .order('created_at', ascending: false);

      final allStores = List<Map<String, dynamic>>.from(response);
      final Map<String, Map<String, int>> agentStats = {};

      // Calculate agent analytics
      for (var store in allStores) {
        final agentName = store['users_db']?['fullname'] ?? 'Unknown';
        if (!agentStats.containsKey(agentName)) {
          agentStats[agentName] = {'total': 0};
        }
        agentStats[agentName]!['total'] =
            (agentStats[agentName]!['total'] ?? 0) + 1;
      }

      if (mounted) {
        setState(() {
          stores = allStores;
          _agentAnalytics = agentStats;
          _totalStores = allStores.length;
          isLoading = false;
          _currentPage = 0;
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

  Future<void> _encodeStore(Map<String, dynamic> store) async {
    try {
      final currentDate = DateTime.now().toString().split(' ')[0];
      final existingRemarks = store['remarks']?.toString() ?? '';
      final newRemarks = existingRemarks.isEmpty
          ? '$currentDate - Encoded'
          : '$existingRemarks - $currentDate - Encoded';

      await Supabase.instance.client
          .from('store_information')
          .update({'status': 3, 'remarks': newRemarks})
          .eq('store_id', store['store_id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Store encoded successfully!'),
            backgroundColor: Colors.blue,
          ),
        );
        _loadStores();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error encoding store: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Status: Approved for Encoding',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
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
          ElevatedButton.icon(
            onPressed: () async {
              await _encodeStore(store);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.edit_note),
            label: const Text('Encoded'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Encoder Dashboard',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (_userName.isNotEmpty)
              Text(
                _userName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                ),
              ),
          ],
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
          // Status Card Section
          Container(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.green.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 48, color: Colors.white),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Approved for Encoding',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_totalStores store(s) ready to encode',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _totalStores.toString(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Agent Analytics Section
          if (_agentAnalytics.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
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
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _agentAnalytics.length,
                      itemBuilder: (context, index) {
                        final agentName = _agentAnalytics.keys.elementAt(index);
                        final stats = _agentAnalytics[agentName]!;
                        return Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.withOpacity(0.1),
                                Colors.green.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                agentName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.green,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${stats['total']} stores',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
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
                : stores.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No stores to encode',
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
                                    Colors.green.shade50,
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
                      if (stores.length > _itemsPerPage)
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

  List<Map<String, dynamic>> _getPaginatedStores() {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, stores.length);
    return stores.sublist(startIndex, endIndex);
  }

  int _getTotalPages() {
    return (stores.length / _itemsPerPage).ceil();
  }
}
