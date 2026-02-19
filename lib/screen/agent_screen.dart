import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/sync_service.dart';
import '../services/local_database.dart';

class AgentScreen extends StatefulWidget {
  const AgentScreen({super.key});

  @override
  State<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _purchaserOwnerController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _completeAddressController = TextEditingController();
  String? _selectedTerritory;
  final _storeClassificationController = TextEditingController();
  final _tinController = TextEditingController();
  final _paymentTermController = TextEditingController();
  final _priceLevelController = TextEditingController();
  final _agentCodeController = TextEditingController();
  final _salesPersonController = TextEditingController();

  File? _storePicture;
  File? _businessPermit;
  double? _mapLatitude;
  double? _mapLongitude;

  final ImagePicker _picker = ImagePicker();

  int _totalStores = 0;
  int _thisMonthStores = 0;
  bool _isLoadingStats = false;
  List<int> _monthlyStores = List.filled(12, 0);

  // Offline sync
  final SyncService _syncService = SyncService.instance;
  int _pendingUploads = 0;
  SyncStatus _syncStatus = SyncStatus.idle;
  String _agentFullName = '';

  // Western Visayas Region 6 - All Municipalities and Cities
  final List<String> _territories = [
    // Aklan
    'Altavas, Aklan',
    'Balete, Aklan',
    'Banga, Aklan',
    'Batan, Aklan',
    'Buruanga, Aklan',
    'Ibajay, Aklan',
    'Kalibo, Aklan',
    'Lezo, Aklan',
    'Libacao, Aklan',
    'Madalag, Aklan',
    'Makato, Aklan',
    'Malay, Aklan',
    'Malinao, Aklan',
    'Nabas, Aklan',
    'New Washington, Aklan',
    'Numancia, Aklan', 'Tangalan, Aklan',
    // Antique
    'Anini-y, Antique',
    'Barbaza, Antique',
    'Belison, Antique',
    'Bugasong, Antique',
    'Caluya, Antique',
    'Culasi, Antique',
    'Hamtic, Antique',
    'Laua-an, Antique',
    'Libertad, Antique',
    'Pandan, Antique',
    'Patnongon, Antique',
    'San Jose, Antique',
    'San Remigio, Antique',
    'Sebaste, Antique',
    'Sibalom, Antique',
    'Tibiao, Antique', 'Tobias Fornier, Antique', 'Valderrama, Antique',
    // Capiz
    'Cuartero, Capiz',
    'Dao, Capiz',
    'Dumalag, Capiz',
    'Dumarao, Capiz',
    'Ivisan, Capiz',
    'Jamindan, Capiz',
    'Maayon, Capiz',
    'Mambusao, Capiz',
    'Panay, Capiz',
    'Panitan, Capiz',
    'Pilar, Capiz',
    'Pontevedra, Capiz',
    'President Roxas, Capiz',
    'Sapi-an, Capiz',
    'Sigma, Capiz',
    'Tapaz, Capiz', 'Roxas City, Capiz',
    // Guimaras
    'Buenavista, Guimaras',
    'Jordan, Guimaras',
    'Nueva Valencia, Guimaras',
    'San Lorenzo, Guimaras',
    'Sibunag, Guimaras',
    // Iloilo
    'Ajuy, Iloilo',
    'Alimodian, Iloilo',
    'Anilao, Iloilo',
    'Badiangan, Iloilo',
    'Balasan, Iloilo',
    'Banate, Iloilo',
    'Barotac Nuevo, Iloilo',
    'Barotac Viejo, Iloilo',
    'Batad, Iloilo',
    'Bingawan, Iloilo',
    'Cabatuan, Iloilo',
    'Calinog, Iloilo',
    'Carles, Iloilo',
    'Concepcion, Iloilo',
    'Dingle, Iloilo',
    'Dueñas, Iloilo',
    'Dumangas, Iloilo',
    'Estancia, Iloilo',
    'Guimbal, Iloilo',
    'Igbaras, Iloilo',
    'Janiuay, Iloilo',
    'Lambunao, Iloilo',
    'Leganes, Iloilo',
    'Lemery, Iloilo',
    'Leon, Iloilo',
    'Maasin, Iloilo',
    'Miagao, Iloilo',
    'Mina, Iloilo',
    'New Lucena, Iloilo',
    'Oton, Iloilo',
    'Pavia, Iloilo',
    'Pototan, Iloilo',
    'San Dionisio, Iloilo',
    'San Enrique, Iloilo',
    'San Joaquin, Iloilo',
    'San Miguel, Iloilo',
    'San Rafael, Iloilo',
    'Santa Barbara, Iloilo',
    'Sara, Iloilo',
    'Tigbauan, Iloilo',
    'Tubungan, Iloilo',
    'Zarraga, Iloilo',
    'Iloilo City, Iloilo',
    'Passi City, Iloilo',
    // Negros Occidental
    'Bacolod City, Negros Occidental',
    'Bago City, Negros Occidental',
    'Cadiz City, Negros Occidental',
    'Escalante City, Negros Occidental',
    'Himamaylan City, Negros Occidental',
    'Kabankalan City, Negros Occidental',
    'La Carlota City, Negros Occidental',
    'Sagay City, Negros Occidental',
    'San Carlos City, Negros Occidental',
    'Silay City, Negros Occidental',
    'Sipalay City, Negros Occidental',
    'Talisay City, Negros Occidental',
    'Victorias City, Negros Occidental',
    'Binalbagan, Negros Occidental',
    'Calatrava, Negros Occidental',
    'Candoni, Negros Occidental',
    'Cauayan, Negros Occidental',
    'Enrique B. Magalona, Negros Occidental',
    'Hinigaran, Negros Occidental',
    'Hinoba-an, Negros Occidental',
    'Ilog, Negros Occidental',
    'Isabela, Negros Occidental',
    'La Castellana, Negros Occidental',
    'Manapla, Negros Occidental',
    'Moises Padilla, Negros Occidental',
    'Murcia, Negros Occidental',
    'Pontevedra, Negros Occidental',
    'Pulupandan, Negros Occidental',
    'Salvador Benedicto, Negros Occidental',
    'San Enrique, Negros Occidental',
    'Toboso, Negros Occidental',
    'Valladolid, Negros Occidental',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadStats();
    _initializeSync();
  }

  void _initializeSync() {
    _syncService.startListening();
    _updatePendingCount();

    _syncService.syncStatusStream.listen((status) {
      if (mounted) {
        setState(() {
          _syncStatus = status;
        });
        _updatePendingCount();
      }
    });
  }

  Future<void> _updatePendingCount() async {
    final count = await _syncService.getPendingCount();
    if (mounted) {
      setState(() {
        _pendingUploads = count;
      });
    }
  }

  Future<void> _loadUserInfo() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      final cachedFullname = prefs.getString('user_fullname');
      final cachedAgentCode = prefs.getString('user_agent_code');

      // Set cached values immediately
      if (mounted) {
        setState(() {
          if (cachedAgentCode != null && cachedAgentCode.isNotEmpty) {
            _agentCodeController.text = cachedAgentCode;
          }
          if (cachedFullname != null && cachedFullname.isNotEmpty) {
            _salesPersonController.text = cachedFullname;
            _agentFullName = cachedFullname;
          }
        });
      }

      // Try to fetch fresh data from Supabase
      try {
        final response = await Supabase.instance.client
            .from('users_db')
            .select('fullname, agent_code')
            .eq('user_id', user.id)
            .single();

        final fullname = response['fullname'] ?? '';
        final agentCode = response['agent_code'] ?? '';

        // Cache the fullname and agent_code
        await prefs.setString('user_fullname', fullname);
        await prefs.setString('user_agent_code', agentCode);

        if (mounted) {
          setState(() {
            _salesPersonController.text = fullname;
            _agentFullName = fullname;
            _agentCodeController.text = agentCode;
          });
        }
      } catch (e) {
        // If offline or error, cached values are already set above
        if (mounted && (cachedFullname == null || cachedAgentCode == null)) {
          setState(() {
            if (cachedAgentCode == null) {
              _agentCodeController.text = user.id;
            }
          });
        }
      }
    }
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final currentYear = now.year;

      // Get all stores for this year to calculate monthly data
      final yearStart = DateTime(currentYear, 1, 1);
      final allStoresResponse = await Supabase.instance.client
          .from('store_information')
          .select('created_at')
          .eq('agent_id', user.id)
          .gte('created_at', yearStart.toIso8601String());

      // Count stores by month
      final monthlyData = List.filled(12, 0);
      for (var store in allStoresResponse) {
        final createdAt = DateTime.parse(store['created_at']);
        if (createdAt.year == currentYear) {
          monthlyData[createdAt.month - 1]++;
        }
      }

      // Get total stores
      final totalResponse = await Supabase.instance.client
          .from('store_information')
          .select('store_id')
          .eq('agent_id', user.id)
          .count(CountOption.exact);

      if (mounted) {
        setState(() {
          _totalStores = totalResponse.count;
          _thisMonthStores = monthlyData[now.month - 1];
          _monthlyStores = monthlyData;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _storeNameController.dispose();
    _purchaserOwnerController.dispose();
    _contactNumberController.dispose();
    _completeAddressController.dispose();
    _storeClassificationController.dispose();
    _tinController.dispose();
    _paymentTermController.dispose();
    _priceLevelController.dispose();
    _agentCodeController.dispose();
    _salesPersonController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String type) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        switch (type) {
          case 'store':
            _storePicture = File(image.path);
            break;
          case 'permit':
            _businessPermit = File(image.path);
            break;
        }
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    // Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied'),
          ),
        );
      }
      return;
    }

    // Show loading
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Getting current location...')),
      );
    }

    // Get current location
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _mapLatitude = position.latitude;
        _mapLongitude = position.longitude;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location captured successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dateController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) throw Exception('Not authenticated');

        // Prepare store data
        final storeData = {
          'date': _dateController.text,
          'store_name': _storeNameController.text,
          'purchaser_owner': _purchaserOwnerController.text,
          'contact_number': _contactNumberController.text,
          'complete_address': _completeAddressController.text,
          'territory': _selectedTerritory,
          'store_classification': _storeClassificationController.text,
          'tin': _tinController.text,
          'payment_term': _paymentTermController.text,
          'price_level': _priceLevelController.text,
          'agent_code': _agentCodeController.text,
          'sales_person': _salesPersonController.text,
          'store_picture_url': null,
          'business_permit_url': null,
          'map_latitude': _mapLatitude,
          'map_longitude': _mapLongitude,
          'agent_id': user.id,
        };

        // Save offline first (always succeeds, syncs when online)
        await _syncService.saveStoreOffline(storeData);

        if (mounted) {
          Navigator.pop(context); // Close loading dialog

          // Clear form
          _formKey.currentState!.reset();
          _dateController.clear();
          _storeNameController.clear();
          _purchaserOwnerController.clear();
          _contactNumberController.clear();
          _completeAddressController.clear();
          _storeClassificationController.clear();
          _tinController.clear();
          _paymentTermController.clear();
          _priceLevelController.clear();

          setState(() {
            _selectedTerritory = null;
            _storePicture = null;
            _businessPermit = null;
            _mapLatitude = null;
            _mapLongitude = null;
          });

          // Reload user info to restore agent code and sales person
          _loadUserInfo();

          // Update pending count
          _updatePendingCount();

          final hasInternet = await _syncService.hasInternetConnection();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                hasInternet
                    ? 'Store saved and syncing to server!'
                    : 'Store saved offline. Will sync when online.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (error) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving data: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Welcome - ${_salesPersonController.text}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF00529B),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_pendingUploads > 0)
            Stack(
              children: [
                IconButton(
                  icon: Icon(
                    _syncStatus == SyncStatus.syncing
                        ? Icons.sync
                        : Icons.cloud_upload_outlined,
                  ),
                  onPressed: () => _syncService.syncPendingStores(),
                  tooltip: 'Sync pending stores',
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _syncStatus == SyncStatus.error
                          ? Colors.red
                          : Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _pendingUploads > 9 ? '9+' : '$_pendingUploads',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
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
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Action Cards
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      'New Store',
                      Icons.add_business_rounded,
                      Colors.green,
                      () => _showStoreForm(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionCard(
                      'View All Stores',
                      Icons.list_alt_rounded,
                      const Color(0xFF00529B),
                      () => _viewAllStores(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Pending Sync Card
              if (_pendingUploads > 0)
                _buildActionCard(
                  'Pending Sync ($_pendingUploads)',
                  Icons.cloud_upload_outlined,
                  Colors.orange,
                  () => _viewPendingStores(),
                ),
              const SizedBox(height: 32),

              // Analytics Section
              Text(
                'Analytics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[900],
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 20),

              // Summary Stats
              _isLoadingStats
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Stores',
                            _totalStores.toString(),
                            Icons.store_rounded,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'This Month',
                            _thisMonthStores.toString(),
                            Icons.calendar_today_rounded,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 24),

              // Monthly Chart
              if (!_isLoadingStats)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly Overview ${DateTime.now().year}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 250,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY:
                                  (_monthlyStores.reduce(
                                            (a, b) => a > b ? a : b,
                                          ) +
                                          2)
                                      .toDouble(),
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipColor: (group) => Colors.black87,
                                  getTooltipItem:
                                      (group, groupIndex, rod, rodIndex) {
                                        final monthNames = [
                                          'Jan',
                                          'Feb',
                                          'Mar',
                                          'Apr',
                                          'May',
                                          'Jun',
                                          'Jul',
                                          'Aug',
                                          'Sep',
                                          'Oct',
                                          'Nov',
                                          'Dec',
                                        ];
                                        return BarTooltipItem(
                                          '${monthNames[group.x.toInt()]}\n${rod.toY.toInt()} stores',
                                          const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      const months = [
                                        'J',
                                        'F',
                                        'M',
                                        'A',
                                        'M',
                                        'J',
                                        'J',
                                        'A',
                                        'S',
                                        'O',
                                        'N',
                                        'D',
                                      ];
                                      if (value.toInt() >= 0 &&
                                          value.toInt() < 12) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8.0,
                                          ),
                                          child: Text(
                                            months[value.toInt()],
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                                    reservedSize: 30,
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: const TextStyle(fontSize: 12),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 1,
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: Colors.grey.shade200,
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              barGroups: List.generate(12, (index) {
                                final isCurrentMonth =
                                    index == DateTime.now().month - 1;
                                return BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: _monthlyStores[index].toDouble(),
                                      color: isCurrentMonth
                                          ? Colors.orange
                                          : const Color(0xFF00529B),
                                      width: 16,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(6),
                                        topRight: Radius.circular(6),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.15), color.withOpacity(0.25)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.95),
            ),
          ),
        ],
      ),
    );
  }

  void _showStoreForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoreFormScreen(
          onSuccess: () {
            _loadStats(); // Reload stats after adding store
          },
        ),
      ),
    );
  }

  void _viewAllStores() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StoresListScreen()),
    );
  }

  void _viewPendingStores() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PendingSyncScreen()),
    );
  }
}

// Store Form Screen
class StoreFormScreen extends StatefulWidget {
  final VoidCallback onSuccess;

  const StoreFormScreen({super.key, required this.onSuccess});

  @override
  State<StoreFormScreen> createState() => _StoreFormScreenState();
}

class _StoreFormScreenState extends State<StoreFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _purchaserOwnerController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _completeAddressController = TextEditingController();
  String? _selectedTerritory;
  final _storeClassificationController = TextEditingController();
  final _tinController = TextEditingController();
  final _paymentTermController = TextEditingController();
  final _priceLevelController = TextEditingController();
  final _agentCodeController = TextEditingController();
  final _salesPersonController = TextEditingController();

  File? _storePicture;
  File? _businessPermit;
  double? _mapLatitude;
  double? _mapLongitude;

  final ImagePicker _picker = ImagePicker();

  // Western Visayas Region 6 - All Municipalities and Cities
  final List<String> _territories = [
    // Aklan
    'Altavas, Aklan',
    'Balete, Aklan',
    'Banga, Aklan',
    'Batan, Aklan',
    'Buruanga, Aklan',
    'Ibajay, Aklan',
    'Kalibo, Aklan',
    'Lezo, Aklan',
    'Libacao, Aklan',
    'Madalag, Aklan',
    'Makato, Aklan',
    'Malay, Aklan',
    'Malinao, Aklan',
    'Nabas, Aklan',
    'New Washington, Aklan',
    'Numancia, Aklan', 'Tangalan, Aklan',
    // Antique
    'Anini-y, Antique',
    'Barbaza, Antique',
    'Belison, Antique',
    'Bugasong, Antique',
    'Caluya, Antique',
    'Culasi, Antique',
    'Hamtic, Antique',
    'Laua-an, Antique',
    'Libertad, Antique',
    'Pandan, Antique',
    'Patnongon, Antique',
    'San Jose, Antique',
    'San Remigio, Antique',
    'Sebaste, Antique',
    'Sibalom, Antique',
    'Tibiao, Antique', 'Tobias Fornier, Antique', 'Valderrama, Antique',
    // Capiz
    'Cuartero, Capiz',
    'Dao, Capiz',
    'Dumalag, Capiz',
    'Dumarao, Capiz',
    'Ivisan, Capiz',
    'Jamindan, Capiz',
    'Maayon, Capiz',
    'Mambusao, Capiz',
    'Panay, Capiz',
    'Panitan, Capiz',
    'Pilar, Capiz',
    'Pontevedra, Capiz',
    'President Roxas, Capiz',
    'Sapi-an, Capiz',
    'Sigma, Capiz',
    'Tapaz, Capiz', 'Roxas City, Capiz',
    // Guimaras
    'Buenavista, Guimaras',
    'Jordan, Guimaras',
    'Nueva Valencia, Guimaras',
    'San Lorenzo, Guimaras',
    'Sibunag, Guimaras',
    // Iloilo
    'Ajuy, Iloilo',
    'Alimodian, Iloilo',
    'Anilao, Iloilo',
    'Badiangan, Iloilo',
    'Balasan, Iloilo',
    'Banate, Iloilo',
    'Barotac Nuevo, Iloilo',
    'Barotac Viejo, Iloilo',
    'Batad, Iloilo',
    'Bingawan, Iloilo',
    'Cabatuan, Iloilo',
    'Calinog, Iloilo',
    'Carles, Iloilo',
    'Concepcion, Iloilo',
    'Dingle, Iloilo',
    'Dueñas, Iloilo',
    'Dumangas, Iloilo',
    'Estancia, Iloilo',
    'Guimbal, Iloilo',
    'Igbaras, Iloilo',
    'Janiuay, Iloilo',
    'Lambunao, Iloilo',
    'Leganes, Iloilo',
    'Lemery, Iloilo',
    'Leon, Iloilo',
    'Maasin, Iloilo',
    'Miagao, Iloilo',
    'Mina, Iloilo',
    'New Lucena, Iloilo',
    'Oton, Iloilo',
    'Pavia, Iloilo',
    'Pototan, Iloilo',
    'San Dionisio, Iloilo',
    'San Enrique, Iloilo',
    'San Joaquin, Iloilo',
    'San Miguel, Iloilo',
    'San Rafael, Iloilo',
    'Santa Barbara, Iloilo',
    'Sara, Iloilo',
    'Tigbauan, Iloilo',
    'Tubungan, Iloilo',
    'Zarraga, Iloilo',
    'Iloilo City, Iloilo',
    'Passi City, Iloilo',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      final cachedFullname = prefs.getString('user_fullname');
      final cachedAgentCode = prefs.getString('user_agent_code');

      // Set cached values immediately
      if (mounted) {
        setState(() {
          if (cachedAgentCode != null && cachedAgentCode.isNotEmpty) {
            _agentCodeController.text = cachedAgentCode;
          }
          if (cachedFullname != null && cachedFullname.isNotEmpty) {
            _salesPersonController.text = cachedFullname;
          }
        });
      }

      // Try to fetch fresh data from Supabase
      try {
        final response = await Supabase.instance.client
            .from('users_db')
            .select('fullname, agent_code')
            .eq('user_id', user.id)
            .single();

        final fullname = response['fullname'] ?? '';
        final agentCode = response['agent_code'] ?? '';

        // Cache the fullname and agent_code
        await prefs.setString('user_fullname', fullname);
        await prefs.setString('user_agent_code', agentCode);

        if (mounted) {
          setState(() {
            _salesPersonController.text = fullname;
            _agentCodeController.text = agentCode;
          });
        }
      } catch (e) {
        // If offline or error, cached values are already set above
        if (mounted && (cachedFullname == null || cachedAgentCode == null)) {
          setState(() {
            if (cachedAgentCode == null) {
              _agentCodeController.text = user.id;
            }
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _storeNameController.dispose();
    _purchaserOwnerController.dispose();
    _contactNumberController.dispose();
    _completeAddressController.dispose();
    _storeClassificationController.dispose();
    _tinController.dispose();
    _paymentTermController.dispose();
    _priceLevelController.dispose();
    _agentCodeController.dispose();
    _salesPersonController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String type) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        switch (type) {
          case 'store':
            _storePicture = File(image.path);
            break;
          case 'permit':
            _businessPermit = File(image.path);
            break;
        }
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied'),
          ),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Getting current location...')),
      );
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _mapLatitude = position.latitude;
        _mapLongitude = position.longitude;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location captured successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dateController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) throw Exception('Not authenticated');

        // Prepare store data
        final storeData = {
          'date': _dateController.text,
          'store_name': _storeNameController.text,
          'purchaser_owner': _purchaserOwnerController.text,
          'contact_number': _contactNumberController.text,
          'complete_address': _completeAddressController.text,
          'territory': _selectedTerritory ?? '',
          'store_classification': _storeClassificationController.text,
          'tin': _tinController.text,
          'payment_term': _paymentTermController.text,
          'price_level': _priceLevelController.text,
          'agent_code': _agentCodeController.text,
          'sales_person': _salesPersonController.text,
          'map_latitude': _mapLatitude,
          'map_longitude': _mapLongitude,
          'agent_id': user.id,
          'store_picture_url': null,
          'business_permit_url': null,
        };

        // Use SyncService to save offline-first
        await SyncService.instance.saveStoreOffline(storeData);

        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          widget.onSuccess(); // Callback to refresh stats
          Navigator.pop(context); // Go back to dashboard

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Store saved! Will sync when online.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (error) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving data: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'New Store Information',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF00529B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Form content (reusing the same form structure)
                // This will be the same form fields as before
                // I'll add a simplified version for brevity
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date
                        TextFormField(
                          controller: _dateController,
                          decoration: InputDecoration(
                            labelText: 'Date',
                            prefixIcon: const Icon(
                              Icons.calendar_today_rounded,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          readOnly: true,
                          onTap: _selectDate,
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),

                        // Store Name
                        TextFormField(
                          controller: _storeNameController,
                          decoration: InputDecoration(
                            labelText: 'Store Name',
                            prefixIcon: const Icon(Icons.store_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),

                        // Purchaser/Owner
                        TextFormField(
                          controller: _purchaserOwnerController,
                          decoration: InputDecoration(
                            labelText: 'Purchaser/Owner',
                            prefixIcon: const Icon(Icons.person_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),

                        // Contact Number
                        TextFormField(
                          controller: _contactNumberController,
                          decoration: InputDecoration(
                            labelText: 'Contact Number',
                            prefixIcon: const Icon(Icons.phone_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),

                        // Complete Address
                        TextFormField(
                          controller: _completeAddressController,
                          decoration: InputDecoration(
                            labelText: 'Complete Address',
                            prefixIcon: const Icon(Icons.location_on_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          maxLines: 2,
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),

                        // Territory
                        DropdownButtonFormField<String>(
                          value: _selectedTerritory,
                          decoration: InputDecoration(
                            labelText: 'Territory',
                            prefixIcon: const Icon(Icons.map_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          items: _territories.map((String territory) {
                            return DropdownMenuItem<String>(
                              value: territory,
                              child: Text(territory),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedTerritory = newValue;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),

                        // Store Classification
                        TextFormField(
                          controller: _storeClassificationController,
                          decoration: InputDecoration(
                            labelText: 'Store Classification',
                            prefixIcon: const Icon(Icons.category_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),

                        // TIN
                        TextFormField(
                          controller: _tinController,
                          decoration: InputDecoration(
                            labelText: 'TIN',
                            prefixIcon: const Icon(Icons.badge_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),

                        // Payment Term
                        TextFormField(
                          controller: _paymentTermController,
                          decoration: InputDecoration(
                            labelText: 'Payment Term',
                            prefixIcon: const Icon(Icons.payment_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),

                        // Price Level
                        TextFormField(
                          controller: _priceLevelController,
                          decoration: InputDecoration(
                            labelText: 'Price Level',
                            prefixIcon: const Icon(Icons.attach_money_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),

                        // Agent Code
                        TextFormField(
                          controller: _agentCodeController,
                          decoration: InputDecoration(
                            labelText: 'Agent Code',
                            prefixIcon: const Icon(Icons.qr_code_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          enabled: false,
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),

                        // Sales Person
                        TextFormField(
                          controller: _salesPersonController,
                          decoration: InputDecoration(
                            labelText: 'Sales Person',
                            prefixIcon: const Icon(Icons.person_pin_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          enabled: false,
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _submitForm,
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text(
                      'Submit Form',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00529B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Stores List Screen
class StoresListScreen extends StatefulWidget {
  const StoresListScreen({super.key});

  @override
  State<StoresListScreen> createState() => _StoresListScreenState();
}

class _StoresListScreenState extends State<StoresListScreen> {
  List<Map<String, dynamic>> stores = [];
  List<Map<String, dynamic>> filteredStores = [];
  bool isLoading = false;
  dynamic _realtimeChannel;
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 0;
  final int _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _loadStores();
    _setupRealtimeSubscription();
    _searchController.addListener(_filterStores);
  }

  void _setupRealtimeSubscription() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _realtimeChannel = Supabase.instance.client
        .channel('store_information_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'store_information',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'agent_id',
            value: user.id,
          ),
          callback: (payload) {
            // Reload stores when any change occurs
            _loadStores();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  void _filterStores() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredStores = stores;
      } else {
        filteredStores = stores.where((store) {
          final storeName = (store['store_name'] ?? '')
              .toString()
              .toLowerCase();
          final owner = (store['purchaser_owner'] ?? '')
              .toString()
              .toLowerCase();
          return storeName.contains(query) || owner.contains(query);
        }).toList();
      }
      _currentPage = 0;
    });
  }

  Future<void> _loadStores() async {
    setState(() => isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('store_information')
          .select()
          .eq('agent_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          stores = List<Map<String, dynamic>>.from(response);
          filteredStores = stores;
          _currentPage = 0;
          isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'My Stores',
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
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Box
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by store name or owner...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF00529B),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF00529B),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                // Content
                Expanded(
                  child: filteredStores.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.store_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchController.text.isEmpty
                                    ? 'No stores found'
                                    : 'No matching stores',
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
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: (() {
                                  final startIndex =
                                      _currentPage * _itemsPerPage;
                                  final endIndex = startIndex + _itemsPerPage;
                                  return endIndex > filteredStores.length
                                      ? filteredStores.length - startIndex
                                      : _itemsPerPage;
                                })(),
                                itemBuilder: (context, index) {
                                  final storeIndex =
                                      _currentPage * _itemsPerPage + index;
                                  final store = filteredStores[storeIndex];
                                  final status = store['status'] ?? 1;
                                  Color backgroundColor;
                                  String statusText;

                                  // Determine background color and status text based on status
                                  if (status == 1) {
                                    backgroundColor = Colors.red.shade50;
                                    statusText = 'Pending for approval';
                                  } else if (status == 2) {
                                    backgroundColor = Colors.green.shade50;
                                    statusText = 'Approve for Encoding';
                                  } else if (status == 3) {
                                    backgroundColor = Colors.yellow.shade50;
                                    statusText = 'Encoded';
                                  } else {
                                    backgroundColor = Colors.grey.shade50;
                                    statusText = 'Unknown';
                                  }

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    elevation: 2,
                                    color: backgroundColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(16),
                                      leading: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF00529B,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.store_rounded,
                                          color: Color(0xFF00529B),
                                        ),
                                      ),
                                      title: Text(
                                        store['store_name'] ?? 'N/A',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: status == 1
                                                  ? Colors.red.shade100
                                                  : status == 2
                                                  ? Colors.green.shade100
                                                  : Colors.yellow.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              statusText,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: status == 1
                                                    ? Colors.red.shade900
                                                    : status == 2
                                                    ? Colors.green.shade900
                                                    : Colors.yellow.shade900,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Owner: ${store['purchaser_owner'] ?? 'N/A'}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            'Territory: ${store['territory'] ?? 'N/A'}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            'Date: ${store['date'] ?? 'N/A'}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: const Icon(
                                        Icons.chevron_right_rounded,
                                      ),
                                      onTap: () {
                                        // Show store details
                                        _showStoreDetails(store);
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                            // Pagination Controls
                            if (filteredStores.length > _itemsPerPage)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.shade300,
                                      blurRadius: 4,
                                      offset: const Offset(0, -2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.chevron_left),
                                      onPressed: _currentPage > 0
                                          ? () {
                                              setState(() {
                                                _currentPage--;
                                              });
                                            }
                                          : null,
                                    ),
                                    Text(
                                      'Page ${_currentPage + 1} of ${(filteredStores.length / _itemsPerPage).ceil()}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.chevron_right),
                                      onPressed:
                                          (_currentPage + 1) * _itemsPerPage <
                                              filteredStores.length
                                          ? () {
                                              setState(() {
                                                _currentPage++;
                                              });
                                            }
                                          : null,
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

  void _showStoreDetails(Map<String, dynamic> store) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(store['store_name'] ?? 'Store Details'),
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
              if (store['map_latitude'] != null &&
                  store['map_longitude'] != null)
                _buildDetailRow(
                  'Coordinates:',
                  'Lat: ${store['map_latitude']}, Lng: ${store['map_longitude']}',
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value?.toString() ?? 'N/A')),
        ],
      ),
    );
  }
}

// Pending Sync Screen
class PendingSyncScreen extends StatefulWidget {
  const PendingSyncScreen({super.key});

  @override
  State<PendingSyncScreen> createState() => _PendingSyncScreenState();
}

class _PendingSyncScreenState extends State<PendingSyncScreen> {
  List<Map<String, dynamic>> pendingStores = [];
  bool isLoading = false;
  final SyncService _syncService = SyncService.instance;
  SyncStatus _syncStatus = SyncStatus.idle;

  @override
  void initState() {
    super.initState();
    _loadPendingStores();

    // Listen to sync status
    _syncService.syncStatusStream.listen((status) {
      if (mounted) {
        setState(() {
          _syncStatus = status;
        });
        if (status == SyncStatus.success) {
          _loadPendingStores(); // Reload after successful sync
        }
      }
    });
  }

  Future<void> _loadPendingStores() async {
    setState(() => isLoading = true);

    try {
      final stores = await _syncService.getAllLocalStores();
      if (mounted) {
        setState(() {
          pendingStores = stores;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading pending stores: $e')),
        );
      }
    }
  }

  Future<void> _syncNow() async {
    await _syncService.syncPendingStores();
  }

  Future<void> _deleteStore(int localId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Store'),
        content: const Text(
          'Are you sure you want to delete this pending store?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await LocalDatabase.instance.deleteStore(localId.toString());
      _loadPendingStores();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Store deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Pending Sync',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF00529B),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (pendingStores.isNotEmpty)
            IconButton(
              icon: Icon(
                _syncStatus == SyncStatus.syncing
                    ? Icons.sync
                    : Icons.cloud_upload_outlined,
              ),
              onPressed: _syncStatus == SyncStatus.syncing ? null : _syncNow,
              tooltip: 'Sync All',
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadPendingStores,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pendingStores.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_done_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'All synced!',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No pending stores to sync',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pendingStores.length,
              itemBuilder: (context, index) {
                final store = pendingStores[index];
                final syncStatus = store['sync_status'] ?? 'pending';
                Color statusColor;
                IconData statusIcon;
                String statusText;

                switch (syncStatus) {
                  case 'synced':
                    statusColor = Colors.green;
                    statusIcon = Icons.check_circle;
                    statusText = 'Synced';
                    break;
                  case 'failed':
                    statusColor = Colors.red;
                    statusIcon = Icons.error;
                    statusText = 'Failed';
                    break;
                  default:
                    statusColor = Colors.orange;
                    statusIcon = Icons.pending;
                    statusText = 'Pending';
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  color: statusColor.withOpacity(0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: statusColor.withOpacity(0.3)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(statusIcon, color: statusColor),
                    ),
                    title: Text(
                      store['store_name'] ?? 'N/A',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusText,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Owner: ${store['purchaser_owner'] ?? 'N/A'}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        Text(
                          'Territory: ${store['territory'] ?? 'N/A'}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        if (store['error_message'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Error: ${store['error_message']}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          _deleteStore(store['local_id']);
                        } else if (value == 'retry') {
                          _syncNow();
                        }
                      },
                      itemBuilder: (context) => [
                        if (syncStatus == 'failed')
                          const PopupMenuItem(
                            value: 'retry',
                            child: Row(
                              children: [
                                Icon(Icons.refresh, size: 20),
                                SizedBox(width: 8),
                                Text('Retry Sync'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
