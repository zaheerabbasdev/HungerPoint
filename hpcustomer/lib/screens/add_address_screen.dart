import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/address_service.dart';
import '../services/branch_service.dart';
import '../widgets/interactive_map_view.dart';
import 'new_address_form_screen.dart';

/// Default map center when no better starting point is known (Islamabad).
const double _kDefaultLat = 33.6844;
const double _kDefaultLng = 73.0479;

class AddAddressScreen extends StatefulWidget {
  final SavedAddress? existingAddress;

  const AddAddressScreen({
    super.key,
    this.existingAddress,
  });

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  String _selectedMapAddress = '';
  double _selectedLat = _kDefaultLat;
  double _selectedLng = _kDefaultLng;

  @override
  void initState() {
    super.initState();
    if (widget.existingAddress != null) {
      _selectedMapAddress = widget.existingAddress!.address;
      _selectedLat = widget.existingAddress!.latitude ?? _kDefaultLat;
      _selectedLng = widget.existingAddress!.longitude ?? _kDefaultLng;
    } else if (AddressService().selectedAddress != null) {
      final sel = AddressService().selectedAddress!;
      _selectedMapAddress = sel.address;
      _selectedLat = sel.latitude ?? _kDefaultLat;
      _selectedLng = sel.longitude ?? _kDefaultLng;
    } else if (BranchService().selectedBranch != null) {
      final branch = BranchService().selectedBranch!;
      _selectedMapAddress = branch.address.isNotEmpty ? branch.address : branch.name;
      _selectedLat = branch.lat;
      _selectedLng = branch.lng;
    } else if (BranchService().allBranches.isNotEmpty) {
      final branch = BranchService().allBranches.first;
      _selectedMapAddress = branch.address.isNotEmpty ? branch.address : branch.name;
      _selectedLat = branch.lat;
      _selectedLng = branch.lng;
    } else {
      _selectedMapAddress = 'Select Location';
    }
  }

  void _onLocationChanged(double lat, double lng, String address) {
    setState(() {
      _selectedLat = lat;
      _selectedLng = lng;
      _selectedMapAddress = address;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1B4B), size: 22),
            onPressed: () => Navigator.pop(context),
          ),
          titleSpacing: 0,
          title: const Text(
            'Add Address',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1B4B),
            ),
          ),
        ),
        body: Column(
          children: [
            // ─── Real interactive map ──────────────────────────────
            Expanded(
              child: InteractiveMapView(
                initialLat: _selectedLat,
                initialLng: _selectedLng,
                onLocationChanged: _onLocationChanged,
              ),
            ),

            // ─── Bottom Panel ────────────────────────────────────
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
                    Center(
                      child: Text(
                        widget.existingAddress != null ? 'Update Location' : 'Add Location',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1B4B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (widget.existingAddress != null) ...[
                      // Location icon + address details row (Image 2)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF3F4F6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.existingAddress!.label.toLowerCase() == 'work'
                                  ? Icons.work_outline
                                  : (widget.existingAddress!.label.toLowerCase() == 'home'
                                      ? Icons.home_outlined
                                      : Icons.location_on_outlined),
                              color: const Color(0xFF1E1B4B),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.existingAddress!.label,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E1B4B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedMapAddress,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B7280),
                                    height: 1.35,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // UPDATE ADDRESS button (Image 2)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NewAddressFormScreen(
                                mapAddress: _selectedMapAddress,
                                mapLatitude: _selectedLat,
                                mapLongitude: _selectedLng,
                                existingAddress: widget.existingAddress,
                              ),
                            ),
                          );
                        },
                        child: const Center(
                          child: Text(
                            'UPDATE ADDRESS',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFF5722),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Location icon row (Default Add)
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFF3ED),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on_outlined,
                              color: AppColors.primaryOrange,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // + ADD NEW ADDRESS button
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NewAddressFormScreen(
                                mapAddress: _selectedMapAddress,
                                mapLatitude: _selectedLat,
                                mapLongitude: _selectedLng,
                              ),
                            ),
                          );
                        },
                        child: const Center(
                          child: Text(
                            '+ ADD NEW ADDRESS',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryOrange,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }
}

