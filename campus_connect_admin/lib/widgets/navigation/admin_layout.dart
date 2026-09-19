import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/services/admin_repository.dart';
import '../../screens/complaints/complaint_details_screen.dart';
import '../../screens/complaints/complaints_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/events/add_event_screen.dart';
import '../../screens/events/events_screen.dart';
import '../../screens/profile/admin_profile_screen.dart';
import '../../screens/users/add_user_screen.dart';
import '../../screens/users/users_screen.dart';
import '../common/admin_top_bar.dart';
import 'admin_sidebar.dart';

/// Master responsive admin layout shell containing the fixed left sidebar and content area.
class AdminLayout extends StatefulWidget {
  final AdminRepository repository;

  const AdminLayout({super.key, required this.repository});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  AdminNavDestination _currentDestination = AdminNavDestination.dashboard;
  ComplaintModel? _selectedComplaint;
  bool _isAddingEvent = false;

  void _onSelectDestination(AdminNavDestination destination) {
    setState(() {
      _currentDestination = destination;
      _selectedComplaint = null;
      _isAddingEvent = false;
    });
    // Close drawer if open on mobile
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  void _onSelectComplaint(ComplaintModel complaint) {
    setState(() {
      _currentDestination = AdminNavDestination.complaints;
      _selectedComplaint = complaint;
      _isAddingEvent = false;
    });
  }

  String _getPageTitle() {
    if (_selectedComplaint != null) {
      return 'Complaint Details';
    }
    if (_isAddingEvent) {
      return 'Add Campus Event';
    }

    switch (_currentDestination) {
      case AdminNavDestination.dashboard:
        return 'Dashboard Overview';
      case AdminNavDestination.users:
        return 'Users Management';
      case AdminNavDestination.addUser:
        return 'Add Authorized Member';
      case AdminNavDestination.complaints:
        return 'Campus Complaints';
      case AdminNavDestination.events:
        return 'Campus Events';
      case AdminNavDestination.profile:
        return 'Administrator Profile';
    }
  }

  String? _getPageSubtitle() {
    if (_selectedComplaint != null) {
      return 'Complaint #${_selectedComplaint!.id}';
    }
    if (_isAddingEvent) {
      return 'Schedule a new event';
    }

    switch (_currentDestination) {
      case AdminNavDestination.dashboard:
        return 'CampusConnect Central Administration';
      case AdminNavDestination.users:
        return 'Directory of authorized students and staff';
      case AdminNavDestination.addUser:
        return 'Pre-authorize college member credentials';
      case AdminNavDestination.complaints:
        return 'Review and update status of reported issues';
      case AdminNavDestination.events:
        return 'Manage and publish college events';
      case AdminNavDestination.profile:
        return 'Active session and credentials';
    }
  }

  Widget _buildContent() {
    if (_selectedComplaint != null) {
      return ComplaintDetailsScreen(
        complaint: _selectedComplaint!,
        repository: widget.repository,
        onBack: () {
          setState(() {
            _selectedComplaint = null;
          });
        },
      );
    }

    if (_isAddingEvent) {
      return AddEventScreen(
        repository: widget.repository,
        onEventAdded: () {
          setState(() {
            _isAddingEvent = false;
          });
        },
        onCancel: () {
          setState(() {
            _isAddingEvent = false;
          });
        },
      );
    }

    switch (_currentDestination) {
      case AdminNavDestination.dashboard:
        return DashboardScreen(
          repository: widget.repository,
          onNavigate: _onSelectDestination,
          onSelectComplaint: _onSelectComplaint,
        );
      case AdminNavDestination.users:
        return UsersScreen(
          repository: widget.repository,
          onAddUser: () =>
              _onSelectDestination(AdminNavDestination.addUser),
        );
      case AdminNavDestination.addUser:
        return AddUserScreen(
          repository: widget.repository,
          onUserAdded: () =>
              _onSelectDestination(AdminNavDestination.users),
          onCancel: () =>
              _onSelectDestination(AdminNavDestination.users),
        );
      case AdminNavDestination.complaints:
        return ComplaintsScreen(
          repository: widget.repository,
          onSelectComplaint: _onSelectComplaint,
        );
      case AdminNavDestination.events:
        return EventsScreen(
          repository: widget.repository,
          onAddEvent: () {
            setState(() {
              _isAddingEvent = true;
            });
          },
        );
      case AdminNavDestination.profile:
        return AdminProfileScreen(
          repository: widget.repository,
          onLogout: () {},
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.background,
          drawer: isDesktop
              ? null
              : Drawer(
                  child: AdminSidebar(
                    currentDestination: _currentDestination,
                    onDestinationSelected: _onSelectDestination,
                    repository: widget.repository,
                  ),
                ),
          body: Row(
            children: [
              // Fixed Desktop Sidebar
              if (isDesktop)
                AdminSidebar(
                  currentDestination: _currentDestination,
                  onDestinationSelected: _onSelectDestination,
                  repository: widget.repository,
                ),

              // Main Content Area
              Expanded(
                child: Column(
                  children: [
                    AdminTopBar(
                      title: _getPageTitle(),
                      subtitle: _getPageSubtitle(),
                      onMenuPressed: isDesktop
                          ? null
                          : () => _scaffoldKey.currentState?.openDrawer(),
                      repository: widget.repository,
                      onProfilePressed: () =>
                          _onSelectDestination(AdminNavDestination.profile),
                    ),
                    Expanded(
                      child: _buildContent(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
