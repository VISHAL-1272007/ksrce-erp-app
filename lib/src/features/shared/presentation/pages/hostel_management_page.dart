import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';

class HostelManagementModule extends StatefulWidget {
  final String userRole; // 'student', 'admin', 'hod'
  const HostelManagementModule({super.key, required this.userRole});

  @override
  State<HostelManagementModule> createState() =>
      _HostelManagementModuleState();
}

class _HostelManagementModuleState extends State<HostelManagementModule>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.userRole == 'student' ? 3 : 4,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(
      builder: (context, ds, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              // Header
              SliverAppBar(
                floating: true,
                pinned: true,
                backgroundColor: AppColors.background,
                elevation: 0,
                expandedHeight: 140,
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.apartment,
                                  color: AppColors.primary, size: 28),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Hostel Management',
                                      style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textDark)),
                                  Text('Accommodation & facilities',
                                      style: TextStyle(
                                          color: AppColors.textLight,
                                          fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Tab bar
              SliverToBoxAdapter(
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: widget.userRole == 'student'
                      ? const [
                          Tab(text: 'My Room'),
                          Tab(text: 'Complaints'),
                          Tab(text: 'Fees'),
                        ]
                      : const [
                          Tab(text: 'Overview'),
                          Tab(text: 'Allocations'),
                          Tab(text: 'Complaints'),
                          Tab(text: 'Maintenance'),
                        ],
                ),
              ),

              // Tab content
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: widget.userRole == 'student'
                      ? [
                          _buildStudentRoomTab(),
                          _buildComplaintsTab(),
                          _buildFeesTab(),
                        ]
                      : [
                          _buildAdminOverviewTab(),
                          _buildAllocationsTab(),
                          _buildComplaintsTab(),
                          _buildMaintenanceTab(),
                        ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Student view - My Room
  Widget _buildStudentRoomTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Room allocation card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Room Allocation',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      )),
                  Chip(
                    label: Text('Approved'),
                    backgroundColor: Color.fromARGB(255, 76, 175, 80),
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Hostel', 'Boys Hostel A'),
              _buildDetailRow('Room No', '205'),
              _buildDetailRow('Bed No', '2'),
              _buildDetailRow('Floor', '2nd Floor'),
              const SizedBox(height: 16),
              Divider(color: AppColors.border),
              const SizedBox(height: 16),
              const Text('Room Mates',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  )),
              const SizedBox(height: 12),
              _buildRoommateCard('Rahul Kumar', 'CSE', 'Year 2'),
              _buildRoommateCard('Vikram Singh', 'CSE', 'Year 2'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Facilities available
        const Text('Available Facilities',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            )),
        const SizedBox(height: 12),
        _buildFacilityItem('WiFi', Icons.wifi, 'High-speed internet'),
        _buildFacilityItem(
            'Laundry', Icons.local_laundry_service, 'Twice a week'),
        _buildFacilityItem('Mess', Icons.restaurant, 'Veg & Non-veg'),
        _buildFacilityItem('Gym', Icons.fitness_center, 'Fitness facility'),
        _buildFacilityItem('Study Room', Icons.library_books, 'Air-conditioned'),
      ],
    );
  }

  // Complaints tab
  Widget _buildComplaintsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // File new complaint button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Show dialog to file complaint
              _showFileComplaintDialog();
            },
            icon: const Icon(Icons.add),
            label: const Text('File New Complaint'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Recent Complaints',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            )),
        const SizedBox(height: 12),
        _buildComplaintCard(
          'Water leakage in room',
          'Maintenance',
          'In Progress',
          Colors.orange,
          'Filed on: 20 May 2026',
        ),
        _buildComplaintCard(
          'WiFi not working',
          'Internet',
          'Resolved',
          Colors.green,
          'Resolved on: 18 May 2026',
        ),
        _buildComplaintCard(
          'Broken chair in study room',
          'Furniture',
          'Pending',
          Colors.red,
          'Filed on: 22 May 2026',
        ),
      ],
    );
  }

  // Fees tab
  Widget _buildFeesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Fee summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Hostel Fee Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  )),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Fees',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          )),
                      SizedBox(height: 4),
                      Text('₹60,000',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          )),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Text('Paid',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          )),
                      SizedBox(height: 4),
                      Text('₹30,000',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          )),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 0.5,
                  minHeight: 8,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 4),
              const Text('50% Paid',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                  )),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Fee Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            )),
        const SizedBox(height: 12),
        _buildFeeItem('Room Rent', '₹30,000', 'Paid', Colors.green),
        _buildFeeItem('Mess Charges', '₹15,000', 'Paid', Colors.green),
        _buildFeeItem('Utility (Water/Electricity)', '₹10,000', 'Pending', Colors.orange),
        _buildFeeItem('Maintenance', '₹5,000', 'Pending', Colors.orange),
      ],
    );
  }

  // Admin view - Overview
  Widget _buildAdminOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Key stats
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Hostels',
                '4',
                Icons.apartment,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Occupancy',
                '92%',
                Icons.people,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Pending Complaints',
                '5',
                Icons.warning,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Fee Collection',
                '87%',
                Icons.payments,
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Recent Activity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            )),
        const SizedBox(height: 12),
        _buildActivityItem('New allocation approved', 'Room 301, Boys Hostel', Icons.check_circle, Colors.green),
        _buildActivityItem('Complaint filed', 'Electricity issue in Hall 2', Icons.warning, Colors.orange),
        _buildActivityItem('Fee payment received', 'Student: STU045', Icons.payment, Colors.green),
      ],
    );
  }

  // Admin - Allocations
  Widget _buildAllocationsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('New Allocation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildAllocationCard(
          'Rahul Kumar',
          'STU001',
          'Room 205, Boys Hostel A',
          'Active',
          Colors.green,
        ),
        _buildAllocationCard(
          'Priya Singh',
          'STU045',
          'Room 102, Girls Hostel B',
          'Active',
          Colors.green,
        ),
        _buildAllocationCard(
          'Amit Kumar',
          'STU089',
          'Waiting for allocation',
          'Pending',
          Colors.orange,
        ),
      ],
    );
  }

  // Admin - Maintenance
  Widget _buildMaintenanceTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Log Maintenance Task'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildMaintenanceCard(
          'Plumbing repair',
          'Boys Hostel A, Room 205',
          'In Progress',
          Colors.orange,
          'Started: 21 May',
        ),
        _buildMaintenanceCard(
          'Electricity issue',
          'Girls Hostel B, Hall 2',
          'Completed',
          Colors.green,
          'Completed: 20 May',
        ),
        _buildMaintenanceCard(
          'Paint touch-up',
          'Boys Hostel C, Corridor',
          'Scheduled',
          Colors.blue,
          'Scheduled: 25 May',
        ),
      ],
    );
  }

  // Helper widgets
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textLight,
              )),
          Text(value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              )),
        ],
      ),
    );
  }

  Widget _buildRoommateCard(String name, String dept, String year) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: const Icon(Icons.person, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    )),
                Text('$dept - $year',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textLight,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityItem(String name, IconData icon, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    )),
                Text(description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textLight,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(String title, String category, String status, Color statusColor, String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    )),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.tag, size: 12, color: AppColors.textLight),
              const SizedBox(width: 4),
              Text(category,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  )),
              const SizedBox(width: 12),
              Icon(Icons.access_time, size: 12, color: AppColors.textLight),
              const SizedBox(width: 4),
              Text(date,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeeItem(String feeType, String amount, String status, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(feeType,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  )),
              const SizedBox(height: 4),
              Text(amount,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  )),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              )),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textLight,
              )),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    )),
                Text(subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textLight,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationCard(String name, String id, String room, String status, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(id,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  )),
              const SizedBox(width: 12),
              Expanded(
                child: Text(room,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textLight,
                    ),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceCard(String title, String location, String status, Color statusColor, String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    )),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(location,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textLight,
              )),
          const SizedBox(height: 4),
          Text(date,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textLight,
              )),
        ],
      ),
    );
  }

  void _showFileComplaintDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File New Complaint'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Category',
                  hintText: 'Select category',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Brief title',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the issue',
                ),
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
