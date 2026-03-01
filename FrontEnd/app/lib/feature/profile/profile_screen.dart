import 'package:flutter/material.dart';
import '../../routes/app_router.dart';
import '../../share/services/auth_api_service.dart';
import '../../share/services/storage_service.dart';
import '../../share/widgets/app_button.dart';
import '../../share/widgets/app_card.dart';
import '../../share/widgets/app_scaffold.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final response = await AuthApiService.getProfile();
    if (!mounted) return;

    if (response['success'] == true) {
      final data = response['data'];
      setState(() {
        _isLoading = false;
        _profile = data is Map<String, dynamic> ? data : null;
        _errorMessage = null;
      });
      return;
    }

    final message = response['message']?.toString() ?? 'Failed to load profile';
    setState(() {
      _isLoading = false;
      _errorMessage = message;
      _profile = null;
    });
  }

  Future<void> _goToEditProfile() async {
    final profileData = _profile;
    if (profileData == null) return;

    final result = await Navigator.pushNamed(
      context,
      AppRouter.updateProfile,
      arguments: profileData,
    );

    if (!mounted) return;

    if (result == true) {
      await _loadProfile();
    }
  }

  Future<void> _logout() async {
    await StorageService.clearAuth();
    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRouter.login,
      (route) => false,
    );
  }

  String? _firstText(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key]?.toString();
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  Map<String, dynamic>? _extractUserMap(Map<String, dynamic>? root) {
    if (root == null) return null;

    final nestedData = root['data'];
    if (nestedData is Map<String, dynamic>) {
      return nestedData;
    }

    final nestedUser = root['user'];
    if (nestedUser is Map<String, dynamic>) {
      return nestedUser;
    }

    return root;
  }

  @override
  Widget build(BuildContext context) {
    final profileMap = _extractUserMap(_profile);

    final name = _firstText(profileMap ?? const {}, [
      'fullName',
      'name',
      'username',
    ]);
    final email = _firstText(profileMap ?? const {}, ['email']);
    final phone = _firstText(profileMap ?? const {}, ['phone', 'phoneNumber']);
    final role = _firstText(profileMap ?? const {}, ['role']);
    final avatar = _firstText(profileMap ?? const {}, ['avatarUrl', 'avatar']);

    return AppScaffold(
      centerContent: false,
      title: 'Profile',
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadProfile,
              child: ListView(
                children: [
                  if (_isLoading)
                    const _CenteredState(child: CircularProgressIndicator())
                  else if (_errorMessage != null)
                    _CenteredState(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_errorMessage!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          AppButton(
                            label: 'Retry',
                            expand: false,
                            onPressed: _loadProfile,
                          ),
                        ],
                      ),
                    )
                  else if (profileMap == null || profileMap.isEmpty)
                    const _CenteredState(
                      child: Text('No profile data available.'),
                    )
                  else
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Avatar(avatarUrl: avatar, name: name),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name ?? 'Unknown user',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 6),
                                    if (role != null) Chip(label: Text(role)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _InfoRow(label: 'Email', value: email),
                          _InfoRow(label: 'Phone', value: phone),
                          _InfoRow(
                            label: 'Address',
                            value: _firstText(profileMap, ['address']),
                          ),
                          const SizedBox(height: 16),
                          AppButton(
                            label: 'Edit Profile',
                            onPressed: _goToEditProfile,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _logout,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                foregroundColor: Theme.of(context).colorScheme.error,
                backgroundColor: Colors.white,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 280, child: Center(child: child));
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.avatarUrl, required this.name});

  final String? avatarUrl;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final initials = (name == null || name!.trim().isEmpty)
        ? 'U'
        : name!
              .trim()
              .split(' ')
              .where((e) => e.isNotEmpty)
              .take(2)
              .map((e) => e[0].toUpperCase())
              .join();

    final hasAvatar = avatarUrl != null && avatarUrl!.trim().isNotEmpty;
    return CircleAvatar(
      radius: 32,
      backgroundImage: hasAvatar ? NetworkImage(avatarUrl!.trim()) : null,
      child: hasAvatar ? null : Text(initials),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
          Expanded(child: Text(value ?? '-')),
        ],
      ),
    );
  }
}

