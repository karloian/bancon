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

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('users_db')
          .select('user_id, email, fullname, role, status')
          .order('email');
      setState(() {
        users = List<Map<String, dynamic>>.from(response);
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

  void _showUserDialog({Map<String, dynamic>? user}) {
    final isEdit = user != null;
    final emailController = TextEditingController(text: user?['email']);
    final fullnameController = TextEditingController(text: user?['fullname']);
    final passwordController = TextEditingController();
    String selectedRole = user?['role'] ?? 'agent';
    int selectedStatus = user?['status'] ?? 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit User' : 'Add User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !isEdit,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: fullnameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: ['admin', 'supervisor', 'encoder', 'agent']
                      .map(
                        (role) => DropdownMenuItem(
                          value: role,
                          child: Text(
                            role[0].toUpperCase() + role.substring(1),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedRole = value!);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: isEdit
                        ? 'New Password (leave blank to keep current)'
                        : 'Password',
                    border: const OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Active')),
                    DropdownMenuItem(value: 2, child: Text('Inactive')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedStatus = value!);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (emailController.text.isEmpty ||
                    fullnameController.text.isEmpty ||
                    (!isEdit && passwordController.text.isEmpty)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all required fields'),
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
                    };

                    bool passwordUpdated = false;

                    // Update password using edge function if provided
                    if (passwordController.text.isNotEmpty) {
                      try {
                        final response = await Supabase
                            .instance
                            .client
                            .functions
                            .invoke(
                              'reset-user-password',
                              body: {
                                'user_id': user['user_id'],
                                'new_password': passwordController.text,
                              },
                            );

                        if (response.status == 200) {
                          passwordUpdated = true;
                        } else {
                          throw Exception('Failed to update password');
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Password update failed: ${e.toString()}. Profile will still be updated.',
                              ),
                              duration: const Duration(seconds: 4),
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
                          users[index]['fullname'] = fullnameController.text;
                          users[index]['role'] = selectedRole;
                          users[index]['status'] = selectedStatus;
                        }
                      });
                    }

                    // Show appropriate success message
                    if (mounted) {
                      String message = passwordUpdated
                          ? 'User and password updated successfully'
                          : 'User updated successfully';
                      Navigator.pop(context);
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(message)));
                    }
                    return; // Important: return to skip the general success message
                  } else {
                    // Save admin session before creating new user
                    final adminSession =
                        Supabase.instance.client.auth.currentSession;

                    if (adminSession == null) {
                      throw Exception('Admin session not found');
                    }

                    final adminRefreshToken = adminSession.refreshToken;
                    final userEmail = emailController.text.trim();
                    final userPassword = passwordController.text;

                    // Create user via signUp (this logs in the new user)
                    final authResponse = await Supabase.instance.client.auth
                        .signUp(email: userEmail, password: userPassword);

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
                    await Supabase.instance.client.from('users_db').insert({
                      'user_id': newUserId,
                      'email': userEmail.toLowerCase(),
                      'fullname': fullnameController.text,
                      'role': selectedRole,
                      'status': selectedStatus,
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
                        });
                      });
                    }
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEdit
                              ? 'User updated successfully'
                              : 'User added successfully',
                        ),
                      ),
                    );
                    _loadUsers();
                  }
                } catch (error) {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $error')));
                  }
                }
              },
              child: Text(isEdit ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteUser(String userId) async {
    final user = users.firstWhere((u) => u['user_id'] == userId);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete user: ${user['email']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Update status to 0 (inactive) instead of deleting
        await Supabase.instance.client
            .from('users_db')
            .update({'status': 0})
            .eq('user_id', userId);

        if (mounted) {
          // Update local list
          setState(() {
            final index = users.indexWhere((u) => u['user_id'] == userId);
            if (index != -1) {
              users[index]['status'] = 0;
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deactivated successfully.')),
          );
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
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/');
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
          ? const Center(child: Text('No users found'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: user['status'] == 1
                          ? Colors.green
                          : Colors.grey,
                      child: Text(
                        user['fullname']?[0]?.toUpperCase() ?? 'U',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(user['fullname'] ?? 'N/A'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user['email'] ?? 'N/A'),
                        Text(
                          'Role: ${user['role']?.toString().toUpperCase() ?? 'N/A'} | ${user['status'] == 1 ? 'Active' : 'Inactive'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showUserDialog(user: user),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteUser(user['user_id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add User'),
      ),
    );
  }
}
