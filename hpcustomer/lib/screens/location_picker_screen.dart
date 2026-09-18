import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/address_service.dart';
import '../services/branch_service.dart';
import '../widgets/interactive_map_view.dart';
import 'main_navigation_screen.dart';

/// Default map center when no better starting point is known (Islamabad).
const double _kDefaultLat = 33.6844;
const double _kDefaultLng = 73.0479;

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  String _selectedAddress = '';
  double _selectedLat = _kDefaultLat;
  double _selectedLng = _kDefaultLng;

  @override
  void initState() {
    super.initState();

    final savedLat = AddressService().selectedAddress?.latitude;
    final savedLng = AddressService().selectedAddress?.longitude;
    final tempLat = AddressService().temporaryLatitude;
    final tempLng = AddressService().temporaryLongitude;

    // Only seed this from a location that's actually *this user's*, never a
    // branch's address/name — InteractiveMapView reverse-geocodes the real
    // pin position within moments of opening, but a branch fallback here
    // could get confirmed as the user's location in that brief window,
    // silently overwriting their saved Home/Work address everywhere.
    final active = AddressService().customLocationNotifier.value ??
        AddressService().selectedAddress?.address;

    _selectedAddress = (active != null && active.isNotEmpty) ? active : 'Locating your position…';

    if (tempLat != null && tempLng != null) {
      _selectedLat = tempLat;
      _selectedLng = tempLng;
    } else if (savedLat != null && savedLng != null) {
      _selectedLat = savedLat;
      _selectedLng = savedLng;
    } else if (BranchService().selectedBranch != null) {
      _selectedLat = BranchService().selectedBranch!.lat;
      _selectedLng = BranchService().selectedBranch!.lng;
    } else if (BranchService().allBranches.isNotEmpty) {
      _selectedLat = BranchService().allBranches.first.lat;
      _selectedLng = BranchService().allBranches.first.lng;
    }
  }

  void _onLocationChanged(double lat, double lng, String address) {
    setState(() {
      _selectedLat = lat;
      _selectedLng = lng;
      _selectedAddress = address;
    });
  }

  void _confirmLocation() {
    AddressService().setTemporaryLocation(
      _selectedAddress,
      latitude: _selectedLat,
      longitude: _selectedLng,
    );
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  /// Fallback for when the map/search doesn't have what the user needs —
  /// lets them type a free-text address with no coordinates attached.
  Future<void> _showAddressInputModal() async {
    final addressController = TextEditingController(text: _selectedAddress);
    final formKey = GlobalKey<FormState>();
    bool submitted = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Please type address',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E1B4B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: addressController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E1B4B),
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. Swabi or House123',
                      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primaryYellow, width: 1.8),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter your address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFE054), Color(0xFFFFC727)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          final address = addressController.text.trim();
                          // A manually-typed address has no known coordinates.
                          AddressService().setTemporaryLocation(address);
                          submitted = true;
                          Navigator.of(dialogContext).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'CONTINUE',
                        style: TextStyle(
                          color: Color(0xFF1E1B4B),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    if (submitted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 180,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pop(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.arrow_back, color: Color(0xFF1E1B4B), size: 24),
                SizedBox(width: 6),
                Text(
                  'Choose Location',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1B4B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // ─── Real interactive map ───────────────────────────────
          Expanded(
            child: InteractiveMapView(
              initialLat: _selectedLat,
              initialLng: _selectedLng,
              onLocationChanged: _onLocationChanged,
            ),
          ),

          // ─── Bottom Panel ──────────────────────────────────────
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Center(
                    child: Text(
                      'Choose Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1B4B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF3ED),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primaryOrange,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _selectedAddress,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF4B5563),
                              height: 1.45,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _selectedAddress == 'Locating your position…' ? null : _confirmLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryYellow,
                        disabledBackgroundColor: AppColors.primaryYellow.withValues(alpha: 0.4),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'CONFIRM LOCATION',
                        style: TextStyle(
                          color: Color(0xFF1E1B4B),
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: _showAddressInputModal,
                      child: const Text(
                        "Can't find it on the map? Type it instead",
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryOrange,
                        ),
                      ),
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
}
