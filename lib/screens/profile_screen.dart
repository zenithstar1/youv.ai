import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Bloc/auth_bloc.dart';
import '../Bloc/auth_event.dart';
import '../Bloc/auth_state.dart';
import '../models/activity_model.dart';
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
  List<ActivityModel> _activities = [];
  bool _isLoading = true;

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
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('userInfo') ?? '{}';
    final activities = ActivityRepository.getMockActivities();

    try {
      final Map<String, dynamic> info = json.decode(raw);
      if (mounted) {
        setState(() {
          _name = info['name']?.toString() ?? '';
          _phone = info['phone']?.toString() ??
              info['mobile']?.toString() ?? '';
          _email = info['email']?.toString() ?? '';
          _city = info['city']?.toString() ?? '';
          _clinic = info['clinic_name']?.toString() ??
              info['clinic']?.toString() ?? '';
          _activities = activities;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _activities = activities; _isLoading = false; });
    }
  }

  String get _initials {
    final parts = _name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
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
              fontWeight: FontWeight.w700, color: const Color(0xFF3B1F1F)),
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
                style: GoogleFonts.poppins(color: const Color(0xFF8A7A72))),
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
                    color: Colors.white, fontWeight: FontWeight.w600)),
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
              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
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
                    // ── Header hero ──────────────────────────────────────────
                    _ProfileHero(
                      initials: _initials,
                      name: _name,
                      subtitle: _email.isNotEmpty ? _email : _phone,
                      r: r,
                      onBack: () => Navigator.of(context).pop(),
                    ),

                    // ── Scrollable body ──────────────────────────────────────
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                            r.w(20), r.h(22), r.w(20), r.h(30)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Personal Information
                            _SectionHeader(
                                label: 'Personal Information', r: r),
                            SizedBox(height: r.h(10)),
                            _InfoCard(r: r, children: [
                              _InfoRow(
                                icon: Icons.person_outline_rounded,
                                label: 'Full Name',
                                value: _name.isNotEmpty ? _name : '—',
                                r: r,
                              ),
                              _CardDivider(),
                              _InfoRow(
                                icon: Icons.phone_outlined,
                                label: 'Phone',
                                value: _phone.isNotEmpty ? _phone : '—',
                                r: r,
                              ),
                              _CardDivider(),
                              _InfoRow(
                                icon: Icons.email_outlined,
                                label: 'Email',
                                value: _email.isNotEmpty ? _email : '—',
                                r: r,
                              ),
                            ]),

                            SizedBox(height: r.h(20)),

                            // Location & Clinic
                            _SectionHeader(
                                label: 'Location & Clinic', r: r),
                            SizedBox(height: r.h(10)),
                            _InfoCard(r: r, children: [
                              _InfoRow(
                                icon: Icons.location_city_outlined,
                                label: 'City',
                                value: _city.isNotEmpty ? _city : '—',
                                r: r,
                              ),
                              _CardDivider(),
                              _InfoRow(
                                icon: Icons.local_hospital_outlined,
                                label: 'Clinic',
                                value: _clinic.isNotEmpty ? _clinic : '—',
                                r: r,
                              ),
                            ]),

                            SizedBox(height: r.h(24)),

                            // Scan History
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
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _activities.length,
                                separatorBuilder: (_, __) =>
                                    SizedBox(height: r.h(0)),
                                itemBuilder: (_, i) =>
                                    HistoryCard(activity: _activities[i]),
                              ),

                            SizedBox(height: r.h(24)),

                            // Logout
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
                  ],
                ),
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
  final Responsive r;
  final VoidCallback onBack;

  const _ProfileHero({
    required this.initials,
    required this.name,
    required this.subtitle,
    required this.r,
    required this.onBack,
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
                  // Spacer to keep title visually centered
                  const SizedBox(width: 48),
                ],
              ),

              SizedBox(height: r.h(12)),

              // Avatar
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
                  border: Border.all(color: Colors.white, width: 3.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD79096).withValues(alpha: 0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.lora(
                      fontSize: r.sp(28),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              SizedBox(height: r.h(12)),

              // Name
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

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final String? badge;
  final Responsive r;
  const _SectionHeader({required this.label, required this.r, this.badge});

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
            padding:
                EdgeInsets.symmetric(horizontal: r.w(8), vertical: r.h(2)),
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
      padding: EdgeInsets.symmetric(horizontal: r.w(16), vertical: r.h(13)),
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
        height: 1, thickness: 1, indent: 70, color: Color(0xFFF0E8E8));
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
