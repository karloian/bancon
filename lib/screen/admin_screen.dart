import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<Map<String, dynamic>> users = [];
  bool isLoading = false;
  int selectedStatusFilter = 1; // 1 = Active, 2 = Inactive
  int currentPage = 0;
  final int itemsPerPage = 5;
  String adminName = '';
  String adminEmail = '';

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
    _loadUsers();
  }

  Future<void> _loadAdminInfo() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final response = await Supabase.instance.client
            .from('users_db')
            .select('fullname, email')
            .eq('user_id', user.id)
            .single();

        if (mounted) {
          setState(() {
            adminName = response['fullname'] ?? 'Admin';
            adminEmail = response['email'] ?? user.email ?? '';
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            adminEmail = user.email ?? '';
            adminName = 'Admin';
          });
        }
      }
    }
  }

  Future<void> _loadUsers() async {
    setState(() => isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('users_db')
          .select('user_id, email, fullname, role, status, agent_code')
          .eq('status', selectedStatusFilter)
          .order('email');
      setState(() {
        users = List<Map<String, dynamic>>.from(response);
        currentPage = 0; // Reset to first page when loading
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading users: $error')));
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> get paginatedUsers {
    final startIndex = currentPage * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, users.length);
    if (startIndex >= users.length) return [];
    return users.sublist(startIndex, endIndex);
  }

  int get totalPages => (users.length / itemsPerPage).ceil();

  void _showUserDialog({Map<String, dynamic>? user}) {
    final isEdit = user != null;
    final emailController = TextEditingController(text: user?['email']);
    final fullnameController = TextEditingController(text: user?['fullname']);
    final passwordController = TextEditingController();
    final agentCodeController = TextEditingController(
      text: user?['agent_code'],
    );
    String selectedRole = user?['role'] ?? 'agent';
    int selectedStatus = user?['status'] ?? 1;
    bool isPasswordVisible = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00529B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isEdit
                              ? Icons.edit_rounded
                              : Icons.person_add_rounded,
                          color: const Color(0xFF00529B),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEdit ? 'Edit User' : 'Add New User',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              isEdit
                                  ? 'Update user information'
                                  : 'Create a new user account',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),

                  // Form Fields
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'user@example.com',
                      prefixIcon: const Icon(Icons.email_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isEdit ? Colors.grey[100] : Colors.white,
                      enabled: !isEdit,
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: fullnameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'John Doe',
                      prefixIcon: const Icon(Icons.person_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: InputDecoration(
                      labelText: 'Role',
                      prefixIcon: Icon(_getRoleIcon(selectedRole)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: ['admin', 'supervisor', 'encoder', 'agent']
                        .map(
                          (role) => DropdownMenuItem(
                            value: role,
                            child: Row(
                              children: [
                                Icon(
                                  _getRoleIcon(role),
                                  size: 20,
                                  color: _getRoleColor(role),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  role[0].toUpperCase() + role.substring(1),
                                  style: TextStyle(color: _getRoleColor(role)),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() => selectedRole = value!);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Agent Code Field (only for agents)
                  if (selectedRole == 'agent') ...[
                    TextField(
                      controller: agentCodeController,
                      decoration: InputDecoration(
                        labelText: 'Agent Code *',
                        hintText: 'Enter agent code',
                        prefixIcon: const Icon(Icons.qr_code_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: isEdit
                          ? 'New Password (optional)'
                          : 'Password',
                      hintText: isEdit
                          ? 'Leave blank to keep current'
                          : 'Enter password',
                      prefixIcon: const Icon(Icons.lock_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            isPasswordVisible = !isPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    obscureText: !isPasswordVisible,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<int>(
                    value: selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      prefixIcon: Icon(
                        selectedStatus == 1
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: selectedStatus == 1 ? Colors.green : Colors.red,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 1,
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 20,
                              color: Colors.green,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Active',
                              style: TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 2,
                        child: Row(
                          children: [
                            Icon(
                              Icons.cancel_rounded,
                              size: 20,
                              color: Colors.red,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Inactive',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() => selectedStatus = value!);
                    },
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          if (emailController.text.isEmpty ||
                              fullnameController.text.isEmpty ||
                              (!isEdit && passwordController.text.isEmpty) ||
                              (selectedRole == 'agent' &&
                                  agentCodeController.text.isEmpty)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Please fill all required fields'),
                                  ],
                                ),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                            return;
                          }

                          try {
                            if (isEdit) {
                              final updateData = {
                                'fullname': fullnameController.text,
                                'role': selectedRole,
                                'status': selectedStatus,
                                if (selectedRole == 'agent')
                                  'agent_code': agentCodeController.text,
                              };

                              bool passwordUpdated = false;

                              // Update password using edge function if provided
                              if (passwordController.text.isNotEmpty) {
                                try {
                                  // Get the current user email
                                  final currentUser =
                                      Supabase.instance.client.auth.currentUser;
                                  if (currentUser == null ||
                                      currentUser.email == null) {
                                    throw Exception('No active user');
                                  }

                                  final response = await Supabase
                                      .instance
                                      .client
                                      .functions
                                      .invoke(
                                        'reset-user-password',
                                        body: {
                                          'user_id': user['user_id'],
                                          'new_password':
                                              passwordController.text,
                                          'admin_email': currentUser.email,
                                        },
                                      );

                                  print(
                                    'Password update response: ${response.status}',
                                  );
                                  print('Response data: ${response.data}');

                                  if (response.status == 200) {
                                    passwordUpdated = true;
                                  } else {
                                    final errorData = response.data;
                                    throw Exception(
                                      'Status ${response.status}: ${errorData['error'] ?? errorData['details'] ?? 'Unknown error'}',
                                    );
                                  }
                                } catch (e) {
                                  print('Password update error: $e');
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Password update failed: ${e.toString()}\nProfile will still be updated.',
                                        ),
                                        duration: const Duration(seconds: 5),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                }
                              }

                              // Update profile data in users_db
                              await Supabase.instance.client
                                  .from('users_db')
                                  .update(updateData)
                                  .eq('user_id', user['user_id']);

                              // Update local list immediately
                              if (mounted) {
                                setState(() {
                                  final index = users.indexWhere(
                                    (u) => u['user_id'] == user['user_id'],
                                  );
                                  if (index != -1) {
                                    users[index]['fullname'] =
                                        fullnameController.text;
                                    users[index]['role'] = selectedRole;
                                    users[index]['status'] = selectedStatus;
                                    if (selectedRole == 'agent') {
                                      users[index]['agent_code'] =
                                          agentCodeController.text;
                                    }
                                  }
                                });
                              }

                              // Show success message
                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      passwordUpdated
                                          ? 'User and password updated successfully'
                                          : 'User profile updated successfully',
                                    ),
                                    backgroundColor: passwordUpdated
                                        ? Colors.green
                                        : null,
                                  ),
                                );
                              }
                              return;
                            } else {
                              // Save admin session before creating new user
                              final adminSession =
                                  Supabase.instance.client.auth.currentSession;

                              if (adminSession == null) {
                                throw Exception('Admin session not found');
                              }

                              final adminRefreshToken =
                                  adminSession.refreshToken;
                              final userEmail = emailController.text.trim();
                              final userPassword = passwordController.text;

                              // Create user via signUp (this logs in the new user)
                              final authResponse = await Supabase
                                  .instance
                                  .client
                                  .auth
                                  .signUp(
                                    email: userEmail,
                                    password: userPassword,
                                  );

                              if (authResponse.user == null) {
                                throw Exception('Failed to create user');
                              }

                              final newUserId = authResponse.user!.id;

                              // Restore admin session immediately before inserting
                              if (adminRefreshToken != null) {
                                await Supabase.instance.client.auth.setSession(
                                  adminRefreshToken,
                                );
                              }

                              // Insert into users_db (now authenticated as admin)
                              await Supabase.instance.client
                                  .from('users_db')
                                  .insert({
                                    'user_id': newUserId,
                                    'email': userEmail.toLowerCase(),
                                    'fullname': fullnameController.text,
                                    'role': selectedRole,
                                    'status': selectedStatus,
                                    if (selectedRole == 'agent')
                                      'agent_code': agentCodeController.text,
                                  });

                              // Add to local list immediately
                              if (mounted) {
                                setState(() {
                                  users.add({
                                    'user_id': newUserId,
                                    'email': userEmail.toLowerCase(),
                                    'fullname': fullnameController.text,
                                    'role': selectedRole,
                                    'status': selectedStatus,
                                    if (selectedRole == 'agent')
                                      'agent_code': agentCodeController.text,
                                  });
                                });
                              }
                            }

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isEdit
                                            ? 'User updated successfully'
                                            : 'User added successfully',
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  action: SnackBarAction(
                                    label: 'OK',
                                    textColor: Colors.white,
                                    onPressed: () {},
                                  ),
                                ),
                              );
                              _loadUsers();
                            }
                          } catch (error) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text('Error: $error')),
                                    ],
                                  ),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        icon: Icon(
                          isEdit
                              ? Icons.check_rounded
                              : Icons.person_add_rounded,
                        ),
                        label: Text(isEdit ? 'Update User' : 'Add User'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            68,
                            2,
                            182,
                          ),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteUser(String userId) async {
    final user = users.firstWhere((u) => u['user_id'] == userId);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate User'),
        content: Text(
          'Set user ${user['email']} as inactive?\n\nThe user will not be able to login.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Update status to 2 (inactive) instead of deleting
        await Supabase.instance.client
            .from('users_db')
            .update({'status': 2})
            .eq('user_id', userId);

        if (mounted) {
          // Remove from local list (hide inactive users)
          setState(() {
            users.removeWhere((u) => u['user_id'] == userId);
          });

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('User is deactivated.')));
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deactivating user: $error')),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Dashboard',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            if (adminName.isNotEmpty)
              Text(
                adminName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF00529B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadUsers,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
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
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Stats Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF00529B),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard(
                      'Total Users',
                      users.length.toString(),
                      Icons.people_rounded,
                      Colors.white,
                    ),
                    _buildStatCard(
                      'Active',
                      users.where((u) => u['status'] == 1).length.toString(),
                      Icons.check_circle_rounded,
                      Colors.greenAccent,
                    ),
                    _buildStatCard(
                      'Inactive',
                      users.where((u) => u['status'] == 2).length.toString(),
                      Icons.cancel_rounded,
                      Colors.redAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () => _showUserDialog(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_add_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Add User',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter Tabs
          Container(
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (selectedStatusFilter != 1) {
                        setState(() {
                          selectedStatusFilter = 1;
                        });
                        _loadUsers();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: selectedStatusFilter == 1
                            ? const Color(0xFF00529B)
                            : Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            color: selectedStatusFilter == 1
                                ? const Color(0xFF00529B)
                                : Colors.grey.shade300,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 20,
                            color: selectedStatusFilter == 1
                                ? Colors.white
                                : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: selectedStatusFilter == 1
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (selectedStatusFilter != 2) {
                        setState(() {
                          selectedStatusFilter = 2;
                        });
                        _loadUsers();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: selectedStatusFilter == 2
                            ? const Color(0xFF00529B)
                            : Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            color: selectedStatusFilter == 2
                                ? const Color(0xFF00529B)
                                : Colors.grey.shade300,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cancel_rounded,
                            size: 20,
                            color: selectedStatusFilter == 2
                                ? Colors.white
                                : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Inactive',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: selectedStatusFilter == 2
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // User List
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF00529B),
                      ),
                    ),
                  )
                : users.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No users found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add your first user to get started',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadUsers,
                    color: const Color(0xFF00529B),
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: paginatedUsers.length,
                            itemBuilder: (context, index) {
                              final user = paginatedUsers[index];
                              return _buildUserCard(user);
                            },
                          ),
                        ),
                        // Pagination Controls
                        if (users.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, -2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Page ${currentPage + 1} of ${totalPages > 0 ? totalPages : 1}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.chevron_left_rounded,
                                      ),
                                      onPressed: currentPage > 0
                                          ? () {
                                              setState(() {
                                                currentPage--;
                                              });
                                            }
                                          : null,
                                      color: const Color(0xFF00529B),
                                    ),
                                    Text(
                                      'Showing ${(currentPage * itemsPerPage) + 1}-${((currentPage + 1) * itemsPerPage).clamp(0, users.length)} of ${users.length}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.chevron_right_rounded,
                                      ),
                                      onPressed: currentPage < totalPages - 1
                                          ? () {
                                              setState(() {
                                                currentPage++;
                                              });
                                            }
                                          : null,
                                      color: const Color(0xFF00529B),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final isActive = user['status'] == 1;
    final roleColor = _getRoleColor(user['role']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showUserDialog(user: user),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isActive
                        ? [const Color(0xFF00529B), const Color(0xFF0073D1)]
                        : [Colors.grey, Colors.grey.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isActive ? const Color(0xFF00529B) : Colors.grey)
                          .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    user['fullname']?[0]?.toUpperCase() ?? 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['fullname'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.email_rounded,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            user['email'] ?? 'N/A',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Role Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: roleColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: roleColor, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getRoleIcon(user['role']),
                                size: 12,
                                color: roleColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                user['role']?.toString().toUpperCase() ?? 'N/A',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: roleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isActive ? Colors.green : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isActive ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Buttons
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded),
                    color: Colors.blue,
                    iconSize: 22,
                    onPressed: () => _showUserDialog(user: user),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_rounded),
                    color: Colors.red,
                    iconSize: 22,
                    onPressed: () => _showDeleteConfirmation(user),
                    tooltip: 'Deactivate',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return const Color(0xFF00529B);
      case 'supervisor':
        return Colors.blue;
      case 'encoder':
        return Colors.orange;
      case 'agent':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'supervisor':
        return Icons.supervised_user_circle_rounded;
      case 'encoder':
        return Icons.keyboard_rounded;
      case 'agent':
        return Icons.support_agent_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  void _showDeleteConfirmation(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Text('Deactivate User'),
          ],
        ),
        content: Text(
          'Are you sure you want to deactivate ${user['fullname']}? This will set their status to inactive.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(user['user_id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }
}
