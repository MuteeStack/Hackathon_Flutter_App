import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart' as ap;
import '../models/service_models.dart' hide Provider;
import 'results_screen.dart';

class HomeTab extends StatefulWidget {
  final Function(int)? onSwitchTab; // Call to switch active navigation tab
  const HomeTab({super.key, this.onSwitchTab});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  int _selectedCategoryIndex = -1;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Plumber', 'icon': Icons.plumbing_rounded, 'search': 'Need a Plumber nearby'},
    {'name': 'Electric', 'icon': Icons.electrical_services_rounded, 'search': 'Need an Electrician nearby'},
    {'name': 'AC Tech', 'icon': Icons.ac_unit_rounded, 'search': 'Need an AC Technician'},
    {'name': 'Tutor', 'icon': Icons.school_rounded, 'search': 'Need a Tutor'},
    {'name': 'Painter', 'icon': Icons.format_paint_rounded, 'search': 'Need a Painter nearby'},
    {'name': 'Carpenter', 'icon': Icons.construction_rounded, 'search': 'Need a Carpenter nearby'},
    {'name': 'Cleaner', 'icon': Icons.cleaning_services_rounded, 'search': 'Need a Cleaner/Maid nearby'},
    {'name': 'Gardener', 'icon': Icons.grass_rounded, 'search': 'Need a Gardener nearby'},
    {'name': 'Mechanic', 'icon': Icons.build_circle_rounded, 'search': 'Need a Mechanic nearby'},
    {'name': 'Beautician', 'icon': Icons.face_rounded, 'search': 'Need a Beautician nearby'},
    {'name': 'Driver', 'icon': Icons.directions_car_rounded, 'search': 'Need a Driver nearby'},
    {'name': 'Chef', 'icon': Icons.restaurant_rounded, 'search': 'Need a Home Chef nearby'},
    {'name': 'Babysitter', 'icon': Icons.child_care_rounded, 'search': 'Need a Babysitter nearby'},
    {'name': 'Tailor', 'icon': Icons.checkroom_rounded, 'search': 'Need a Tailor nearby'},
    {'name': 'Pest Control', 'icon': Icons.pest_control_rounded, 'search': 'Need Pest Control nearby'},
    {'name': 'Photographer', 'icon': Icons.camera_alt_rounded, 'search': 'Need a Photographer nearby'},
  ];

  final List<Map<String, dynamic>> _nearbyProviders = [
    {
      'name': 'Ali Plumbing Works',
      'category': 'Plumber',
      'location': 'F-8, Islamabad',
      'rating': 4.8,
      'reviews': 120,
      'distance': '1.2 km',
      'time': '15 min',
      'price': 'Rs 800/hr',
      'verified': true
    },
    {
      'name': 'Zafar Electric',
      'category': 'Electrician',
      'location': 'G-11, Islamabad',
      'rating': 4.6,
      'reviews': 95,
      'distance': '2.1 km',
      'time': '20 min',
      'price': 'Rs 1000/hr',
      'verified': true
    },
    {
      'name': 'Cool Breeze AC',
      'category': 'AC Technician',
      'location': 'G-13, Islamabad',
      'rating': 4.5,
      'reviews': 88,
      'distance': '3.4 km',
      'time': '30 min',
      'price': 'Rs 1500/hr',
      'verified': false
    },
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _triggerSearch(String query) {
    if (query.trim().isEmpty) return;

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    appProvider.setPendingSearchQuery(query);
    widget.onSwitchTab?.call(1); // Switch to AI Chat tab (index 1)
  }

  void _openBookingForm(BuildContext context, String categoryName) async {
    final user = FirebaseAuth.instance.currentUser;
    String displayName = user?.displayName ?? '';
    String defaultPhone = '';
    String defaultAddress = 'F-8, Islamabad';
    
    if (user != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
      try {
        final snapshot = await FirebaseDatabase.instance.ref('users/${user.uid}').get();
        if (snapshot.value != null) {
          final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
          defaultPhone = data['phone'] as String? ?? '';
          defaultAddress = data['activeLocation'] as String? ?? 'F-8, Islamabad';
          displayName = data['displayName'] as String? ?? displayName;
        }
      } catch (_) {}
      if (context.mounted) Navigator.pop(context); // close loader
    }
    
    if (!context.mounted) return;
    
    final nameCtrl = TextEditingController(text: displayName);
    final phoneCtrl = TextEditingController(text: defaultPhone);
    final addressCtrl = TextEditingController(text: defaultAddress);
    final descCtrl = TextEditingController();
    
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    String selectedUrgency = 'Normal';
    
    // Choose a mock provider based on category
    String providerName = 'Best Match Provider';
    if (categoryName == 'Plumber') providerName = 'Ali Plumbing Works';
    else if (categoryName == 'Electric') providerName = 'Zafar Electric';
    else if (categoryName == 'AC Tech') providerName = 'Cool Breeze AC';
    else if (categoryName == 'Tutor') providerName = 'Elite Tutors Academy';
    else if (categoryName == 'Painter') providerName = 'Spectrum Painters';
    else if (categoryName == 'Carpenter') providerName = 'TimberCraft Woodworks';
    else if (categoryName == 'Cleaner') providerName = 'ShinyClean Maid Services';
    else if (categoryName == 'Gardener') providerName = 'GreenThumb Landscaping';
    else if (categoryName == 'Mechanic') providerName = 'QuickFix Auto Care';
    else if (categoryName == 'Beautician') providerName = 'Glitz & Glamour Beauty Salon';
    else if (categoryName == 'Driver') providerName = 'Safe Journey Drivers';
    else if (categoryName == 'Chef') providerName = 'Gourmet Home Chefs';
    else if (categoryName == 'Babysitter') providerName = 'Care Nurture Nannies';
    else if (categoryName == 'Tailor') providerName = 'Perfect Fit Tailors';
    else if (categoryName == 'Pest Control') providerName = 'BugFree Solutions';
    else if (categoryName == 'Photographer') providerName = 'Lens Magic Studios';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pull indicator
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.assignment_turned_in_rounded, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Book $categoryName',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Fill details to confirm instantly',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: 16),
                    
                    // Name Field
                    _buildFormLabel('Full Name'),
                    _buildFormField(nameCtrl, Icons.person_outline_rounded, 'Enter your name'),
                    const SizedBox(height: 14),

                    // Phone Field
                    _buildFormLabel('Phone Number'),
                    _buildFormField(phoneCtrl, Icons.phone_android_rounded, 'Enter phone number', keyboardType: TextInputType.phone),
                    const SizedBox(height: 14),

                    // Date & Time Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormLabel('Date'),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 30)),
                                  );
                                  if (picked != null) {
                                    setModalState(() {
                                      selectedDate = picked;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textSecondary),
                                      const SizedBox(width: 10),
                                      Text(
                                        DateFormat('MMM dd, yyyy').format(selectedDate),
                                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormLabel('Time'),
                              InkWell(
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: selectedTime,
                                  );
                                  if (picked != null) {
                                    setModalState(() {
                                      selectedTime = picked;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, size: 16, color: AppColors.textSecondary),
                                      const SizedBox(width: 10),
                                      Text(
                                        selectedTime.format(context),
                                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Urgency Select
                    _buildFormLabel('Urgency Level'),
                    Row(
                      children: ['Urgent', 'Normal', 'Flexible'].map((urgency) {
                        final isSelected = selectedUrgency == urgency;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(urgency),
                              selected: isSelected,
                              labelStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                              ),
                              selectedColor: AppColors.primary,
                              backgroundColor: AppColors.surfaceElevated,
                              onSelected: (selected) {
                                if (selected) {
                                  setModalState(() {
                                    selectedUrgency = urgency;
                                  });
                                }
                              },
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Address
                    _buildFormLabel('Service Address'),
                    _buildFormField(addressCtrl, Icons.location_on_outlined, 'Enter full address'),
                    const SizedBox(height: 14),

                    // Description
                    _buildFormLabel('Describe details of work'),
                    _buildFormField(
                      descCtrl, 
                      Icons.description_outlined, 
                      'E.g. Leaking kitchen tap, need replacement',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Confirm Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (phoneCtrl.text.isEmpty || addressCtrl.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill out Phone Number and Address.'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }
                          
                          Navigator.pop(context); // Close bottom sheet
                          
                          final finalDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute);
                          final scheduledStr = DateFormat('MMM dd - hh:mm a').format(finalDate);
                          
                          final prompt = 'I need a $categoryName at ${addressCtrl.text}. Details: ${descCtrl.text}. Urgency: $selectedUrgency. Schedule time: $scheduledStr.';
                          
                          _triggerSearch(prompt);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          'Find Providers',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }



  void _showAllCategoriesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pull indicator
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.grid_view_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'All Categories',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Select a category to book instantly',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.95,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _openBookingForm(context, category['name']);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.border.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              category['icon'],
                              color: AppColors.primary,
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            category['name'],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          ),
        );
      },
    );
  }

  Widget _buildFormLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildFormField(
    TextEditingController ctrl, 
    IconData icon, 
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
          prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.split(' ').first ?? 'there';
    
    // Greeting depending on time of day
    final hour = DateTime.now().hour;
    String greeting = "Good morning";
    if (hour >= 12 && hour < 17) {
      greeting = "Good afternoon";
    } else if (hour >= 17) {
      greeting = "Good evening";
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting,',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              // Gemini Sparkle Logo on Header
              GestureDetector(
                onTap: () => widget.onSwitchTab?.call(1), // Switch to AI Chat tab (index 1)
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border.withOpacity(0.5)),
                  ),
                  child: Center(
                    child: ShaderMask(
                      shaderCallback: (bounds) => AppColors.geminiGradient.createShader(bounds),
                      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 500.ms),

          const SizedBox(height: 24),

          // ── Search Section ──────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border.withOpacity(0.6), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: TextField(
              controller: _searchCtrl,
              style: GoogleFonts.inter(fontSize: 15, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Search or describe your need...',
                hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 15),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 22),
                suffixIcon: Container(
                  margin: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.mic_none_rounded, color: AppColors.primary, size: 20),
                    onPressed: () => widget.onSwitchTab?.call(1), // Microphone switches to assistant chat tab (index 1)
                  ),
                ),
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (val) => _triggerSearch(val),
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 500.ms).slideY(begin: 0.1),

          const SizedBox(height: 28),

          // ── Categories Header ──────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categories',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              GestureDetector(
                onTap: () => _showAllCategoriesSheet(context),
                child: Text(
                  'See more',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 14),

          // ── Categories wrap grid (no horizontal scroll) ─────────────────
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.9,
            children: [
              ...List.generate(11, (index) {
                final category = _categories[index];
                return GestureDetector(
                  onTap: () {
                    _openBookingForm(context, category['name']);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.border.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            category['icon'],
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          category['name'],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: (200 + index * 40).ms).scale(begin: const Offset(0.95, 0.95));
              }),
              // See More Button
              GestureDetector(
                onTap: () => _showAllCategoriesSheet(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.grid_view_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'See More',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: (200 + 7 * 40).ms).scale(begin: const Offset(0.95, 0.95)),
            ],
          ),

          const SizedBox(height: 32),

          // ── Nearby Providers Header ─────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nearby Providers',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              GestureDetector(
                onTap: () => _showAllProvidersSheet(context),
                child: Text(
                  'See all',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 350.ms),

          const SizedBox(height: 16),

          // ── Nearby Providers vertical list ──────────────────────────────
          ...List.generate(_nearbyProviders.length, (index) {
            final provider = _nearbyProviders[index];
            return _buildProviderCard(provider, index);
          }),
        ],
      ),
    );
  }

  Widget _buildProviderCard(Map<String, dynamic> provider, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Book directly instead of searching
            _directBookProvider(provider);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon or placeholder
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    provider['category'] == 'Plumber'
                        ? Icons.plumbing_rounded
                        : provider['category'] == 'Electrician'
                            ? Icons.electrical_services_rounded
                            : Icons.construction_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              provider['name'],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (provider['verified']) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified_rounded, color: AppColors.info, size: 16),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${provider['category']} • ${provider['location']}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Stats
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _smallBadge(Icons.star_rounded, '${provider['rating']}', AppColors.warning),
                          _smallBadge(Icons.near_me_rounded, provider['distance'], AppColors.secondary),
                          _smallBadge(Icons.payments_rounded, provider['price'], AppColors.textSecondary),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arrow detail
                Icon(Icons.chevron_right_rounded, color: AppColors.textMuted.withOpacity(0.7), size: 24),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (400 + index * 100).ms).slideY(begin: 0.08);
  }

  Widget _smallBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color == AppColors.textSecondary ? AppColors.textPrimary : color,
            ),
          ),
        ],
      ),
    );
  }

  void _showAllProvidersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'All Nearby Providers',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                ...List.generate(_nearbyProviders.length, (index) {
                  final provider = _nearbyProviders[index];
                  return _buildProviderCard(provider, index);
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _directBookProvider(Map<String, dynamic> provider) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final authProvider = Provider.of<ap.AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to book.'), backgroundColor: AppColors.error),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text('Securing direct booking...', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, decoration: TextDecoration.none, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 1));
    if (mounted) Navigator.pop(context); // close loader

    // Format Scheduled Time
    final scheduledStr = DateFormat('EEEE, MMM dd - hh:mm a').format(DateTime.now().add(const Duration(hours: 1)));
    final bookingId = 'QF-${1000 + (DateTime.now().millisecond % 9000)}';

    final responseJson = {
      'request_id': 'req_${DateTime.now().millisecondsSinceEpoch}',
      'parsed_intent': {
        'service_type': provider['category'].toLowerCase(),
        'location': provider['location'],
        'city': 'Islamabad',
        'time_preference': scheduledStr,
        'urgency': 'normal',
        'language_detected': 'english',
        'original_input': 'Direct Booking: ${provider['name']}',
      },
      'recommended_providers': [
        {
          'rank': 1,
          'distance_km': double.tryParse(provider['distance'].split(' ')[0]) ?? 1.5,
          'match_score': 99.0,
          'reasoning': 'Direct manual booking bypasses AI search.',
          'provider': {
            'id': 'prov_${provider['name'].replaceAll(' ', '').toLowerCase()}',
            'name': provider['name'],
            'service_type': provider['category'],
            'rating': provider['rating'],
            'price_range': provider['price'],
            'phone': '+92 300 0000000',
            'verified': provider['verified'],
            'location': {
              'area': provider['location'].split(',').first,
              'city': 'Islamabad',
              'lat': 33.6844,
              'lng': 73.0479,
            },
          },
        }
      ],
      'booking': {
        'booking_id': bookingId,
        'provider_name': provider['name'],
        'service_type': provider['category'].toLowerCase(),
        'location': provider['location'],
        'scheduled_time': scheduledStr,
        'status': 'confirmed',
        'confirmation_message': 'Your booking with ${provider['name']} has been successfully confirmed. The provider will contact you shortly.',
        'reminder_time': '15 minutes before scheduled arrival',
      },
      'followup': {
        'next_action': 'Ensure site accessibility.',
      },
      'agent_trace': {
        'steps': [
          {
            'step_number': 1,
            'agent_name': 'System',
            'action': 'Direct Booking',
            'input_summary': 'User clicked nearby provider',
            'output_summary': 'Bypassed search',
            'reasoning': 'User manually requested direct booking for ${provider['name']}.',
            'timestamp': DateTime.now().toIso8601String(),
          }
        ],
      },
      'total_processing_time': 0.1,
    };

    try {
      await authProvider.authService.saveToHistory(
        userId: userId,
        originalMessage: 'Direct Booking: ${provider['name']}',
        responseData: responseJson,
      );
      
      final responseObj = ServiceResponse.fromJson(responseJson);
      appProvider.setResponse(responseObj);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ResultsScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error securing booking: $e'), backgroundColor: AppColors.error));
    }
  }
}
