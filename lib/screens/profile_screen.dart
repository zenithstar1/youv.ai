import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../Bloc/auth_bloc.dart';
import '../Bloc/auth_event.dart';
import '../Bloc/auth_state.dart';
import '../models/activity_model.dart';
import '../services/history_service.dart';
import '../services/profile_service.dart';
import '../utils/responsive.dart';
import '../widgets/history_card.dart';
import '../widgets/empty_activity_widget.dart';
import '../main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AuthBloc _authBloc;

  String _name = '';
  String _phone = '';
  String _email = '';
  String _city = '';
  String _clinic = '';
  String _avatarUrl = '';
  List<ActivityModel> _activities = [];
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc();
    _loadData();
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    // Load cached profile immediately so UI isn't blank while fetching.
    final cached = await ProfileService.getCachedProfile();
    if (cached != null && mounted) {
      _applyProfileData(cached);
    }

    // Parallel fetch: profile + first history page.
    final results = await Future.wait([
      ProfileService.getProfile(),
      HistoryService.getHistory(page: 1, perPage: 15),
    ]);

    if (!mounted) return;

    final profileData = results[0] as Map<String, dynamic>?;
    final historyResult = results[1] as HistoryResult;

    if (profileData != null) {
      _applyProfileData(profileData);
    }

    setState(() {
      _activities = historyResult.items
          .map((e) => ActivityModel.fromJson(e))
          .toList();
      _isLoading = false;
    });
  }

  void _applyProfileData(Map<String, dynamic> data) {
    _name = (data['name'] as String?) ?? '';
    _phone = (data['phone'] as String?) ?? '';
    _email = (data['email'] as String?) ?? '';
    _city = (data['city'] as String?) ?? '';
    _clinic = (data['clinic_name'] as String?) ?? '';
    _avatarUrl = (data['avatar_url'] as String?) ?? '';
  }

  String get _initials {
    final parts = _name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await showModalBottomSheet<XFile?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AvatarSourceSheet(picker: picker),
    );

    if (picked == null || !mounted) return;

    setState(() => _isUploading = true);

    final newUrl = await ProfileService.uploadAvatar(picked);

    if (!mounted) return;
    setState(() {
      _isUploading = false;
      if (newUrl != null && newUrl.isNotEmpty) {
        _avatarUrl = newUrl;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: newUrl != null
            ? const Color(0xFF4CAF50)
            : const Color(0xFFF44336),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          newUrl != null
              ? 'Profile photo updated!'
              : 'Failed to update photo. Please try again.',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      ),
    );
  }

  void _onLogoutPressed() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Logout',
          style: GoogleFonts.lora(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3B1F1F)),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.poppins(
              color: const Color(0xFF8A7A72), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('Cancel',
                style: GoogleFonts.poppins(
                    color: const Color(0xFF8A7A72))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD79096),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _authBloc.add(LogoutRequested());
            },
            child: Text('Logout',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return BlocProvider.value(
      value: _authBloc,
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthLogout) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AuthGate()),
              (_) => false,
            );
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFFDEDED),
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFD79096),
                  ),
                )
              : Column(
                  children: [
                    // ── Header hero ──────────────────────────────────────
                    _ProfileHero(
                      initials: _initials,
                      name: _name,
                      subtitle: _email.isNotEmpty ? _email : _phone,
                      avatarUrl: _avatarUrl,
                      isUploading: _isUploading,
                      onBack: () => Navigator.of(context).pop(),
                      onEditAvatar: _pickAndUploadAvatar,
                      r: r,
                    ),

                    // ── Scrollable body ──────────────────────────────────
                    Expanded(
                      child: RefreshIndicator(
                        color: const Color(0xFFD79096),
                        onRefresh: _loadData,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                              r.w(20), r.h(22), r.w(20), r.h(30)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionHeader(
                                  label: 'Personal Information', r: r),
                              SizedBox(height: r.h(10)),
                              _InfoCard(r: r, children: [
                                _InfoRow(
                                  icon: Icons.person_outline_rounded,
                                  label: 'Full Name',
                                  value:
                                      _name.isNotEmpty ? _name : '—',
                                  r: r,
                                ),
                                _CardDivider(),
                                _InfoRow(
                                  icon: Icons.phone_outlined,
                                  label: 'Phone',
                                  value:
                                      _phone.isNotEmpty ? _phone : '—',
                                  r: r,
                                ),
                                _CardDivider(),
                                _InfoRow(
                                  icon: Icons.email_outlined,
                                  label: 'Email',
                                  value:
                                      _email.isNotEmpty ? _email : '—',
                                  r: r,
                                ),
                              ]),

                              SizedBox(height: r.h(20)),

                              _SectionHeader(
                                  label: 'Location & Clinic', r: r),
                              SizedBox(height: r.h(10)),
                              _InfoCard(r: r, children: [
                                _InfoRow(
                                  icon: Icons.location_city_outlined,
                                  label: 'City',
                                  value:
                                      _city.isNotEmpty ? _city : '—',
                                  r: r,
                                ),
                                _CardDivider(),
                                _InfoRow(
                                  icon: Icons.local_hospital_outlined,
                                  label: 'Clinic',
                                  value: _clinic.isNotEmpty
                                      ? _clinic
                                      : '—',
                                  r: r,
                                ),
                              ]),

                              SizedBox(height: r.h(24)),

                              _SectionHeader(
                                label: 'Scan History',
                                r: r,
                                badge: _activities.isNotEmpty
                                    ? '${_activities.length}'
                                    : null,
                              ),
                              SizedBox(height: r.h(12)),

                              if (_activities.isEmpty)
                                const EmptyActivityWidget()
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  itemCount: _activities.length,
                                  separatorBuilder: (_, __) =>
                                      SizedBox(height: r.h(0)),
                                  itemBuilder: (_, i) => HistoryCard(
                                    activity: _activities[i],
                                  ),
                                ),

                              SizedBox(height: r.h(24)),

                              _LogoutButton(
                                  onPressed: _onLogoutPressed, r: r),

                              SizedBox(height: r.h(16)),

                              Center(
                                child: Text(
                                  'Powered by YOUV.AI',
                                  style: GoogleFonts.poppins(
                                    fontSize: r.sp(11),
                                    color: const Color(0xFFB0A0A0),
                                  ),
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
      ),
    );
  }
}

// ── Avatar source bottom sheet ────────────────────────────────────────────────

class _AvatarSourceSheet extends StatelessWidget {
  final ImagePicker picker;
  const _AvatarSourceSheet({required this.picker});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Update Profile Photo',
              style: GoogleFonts.lora(
                  fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: Color(0xFFD79096)),
              title: Text('Choose from Gallery',
                  style: GoogleFonts.poppins()),
              onTap: () async {
                final xFile = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 85,
                  maxWidth: 1024,
                );
                if (context.mounted) Navigator.of(context).pop(xFile);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: Color(0xFFD79096)),
              title:
                  Text('Take a Photo', style: GoogleFonts.poppins()),
              onTap: () async {
                final xFile = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 85,
                  maxWidth: 1024,
                );
                if (context.mounted) Navigator.of(context).pop(xFile);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Profile hero header ───────────────────────────────────────────────────────

class _ProfileHero extends StatelessWidget {
  final String initials;
  final String name;
  final String subtitle;
  final String avatarUrl;
  final bool isUploading;
  final Responsive r;
  final VoidCallback onBack;
  final VoidCallback onEditAvatar;

  const _ProfileHero({
    required this.initials,
    required this.name,
    required this.subtitle,
    required this.avatarUrl,
    required this.isUploading,
    required this.r,
    required this.onBack,
    required this.onEditAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF5C6CA), Color(0xFFFDE8E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              r.w(8), r.h(8), r.w(20), r.h(28)),
          child: Column(
            children: [
              // Back row
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFF3B1F1F), size: 20),
                    onPressed: onBack,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Profile',
                        style: GoogleFonts.lora(
                          fontSize: r.sp(18),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3B1F1F),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),

              SizedBox(height: r.h(12)),

              // Avatar with edit button
              GestureDetector(
                onTap: isUploading ? null : onEditAvatar,
                child: Stack(
                  children: [
                    Container(
                      width: r.w(84),
                      height: r.w(84),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE4B3B8), Color(0xFFD79096)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border:
                            Border.all(color: Colors.white, width: 3.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD79096)
                                .withValues(alpha: 0.45),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: isUploading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : ClipOval(
                              child: avatarUrl.isNotEmpty
                                  ? Image.network(
                                      avatarUrl,
                                      fit: BoxFit.cover,
                                      width: r.w(84),
                                      height: r.w(84),
                                      loadingBuilder: (_, child, progress) {
                                        if (progress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                            value: progress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? progress
                                                        .cumulativeBytesLoaded /
                                                    progress
                                                        .expectedTotalBytes!
                                                : null,
                                          ),
                                        );
                                      },
                                      errorBuilder: (_, __, ___) =>
                                          _InitialsContent(
                                              initials: initials, r: r),
                                    )
                                  : _InitialsContent(
                                      initials: initials, r: r),
                            ),
                    ),

                    // Edit badge
                    if (!isUploading)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD79096),
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white,
                            size: r.sp(12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: r.h(12)),

              Text(
                name.isNotEmpty ? name : '—',
                style: GoogleFonts.lora(
                  fontSize: r.sp(20),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3B1F1F),
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),

              if (subtitle.isNotEmpty) ...[
                SizedBox(height: r.h(4)),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: r.sp(12.5),
                    color: const Color(0xFF8A7A72),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InitialsContent extends StatelessWidget {
  final String initials;
  final Responsive r;
  const _InitialsContent({required this.initials, required this.r});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.lora(
          fontSize: r.sp(28),
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final String? badge;
  final Responsive r;
  const _SectionHeader(
      {required this.label, required this.r, this.badge});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.lora(
            fontSize: r.sp(14),
            fontWeight: FontWeight.w700,
            color: const Color(0xFF3B1F1F),
          ),
        ),
        if (badge != null) ...[
          SizedBox(width: r.w(8)),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: r.w(8), vertical: r.h(2)),
            decoration: BoxDecoration(
              color: const Color(0xFFD79096).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge!,
              style: GoogleFonts.poppins(
                fontSize: r.sp(10.5),
                fontWeight: FontWeight.w600,
                color: const Color(0xFFD79096),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  final Responsive r;
  const _InfoCard({required this.children, required this.r});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r.w(18)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD79096).withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Responsive r;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.r,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: r.w(16), vertical: r.h(13)),
      child: Row(
        children: [
          Container(
            width: r.w(38),
            height: r.w(38),
            decoration: BoxDecoration(
              color: const Color(0xFFFCE7E7),
              borderRadius: BorderRadius.circular(r.w(11)),
            ),
            child: Icon(icon,
                size: r.sp(18), color: const Color(0xFFD79096)),
          ),
          SizedBox(width: r.w(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                      fontSize: r.sp(10.5),
                      color: const Color(0xFF8A7A72),
                    )),
                SizedBox(height: r.h(1)),
                Text(value,
                    style: GoogleFonts.poppins(
                      fontSize: r.sp(14),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3B1F1F),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
        height: 1,
        thickness: 1,
        indent: 70,
        color: Color(0xFFF0E8E8));
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Responsive r;
  const _LogoutButton({required this.onPressed, required this.r});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: r.h(15)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r.w(18)),
          border: Border.all(
            color: const Color(0xFFD79096).withValues(alpha: 0.45),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD79096).withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded,
                color: const Color(0xFFD79096), size: r.sp(20)),
            SizedBox(width: r.w(10)),
            Text('Logout',
                style: GoogleFonts.lora(
                  fontSize: r.sp(15),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFD79096),
                )),
          ],
        ),
      ),
    );
  }
}
