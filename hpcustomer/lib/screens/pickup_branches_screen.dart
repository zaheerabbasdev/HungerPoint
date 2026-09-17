import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/branch_service.dart';

class PickupBranchesScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const PickupBranchesScreen({super.key, this.onBackToHome});

  @override
  State<PickupBranchesScreen> createState() => _PickupBranchesScreenState();
}

class _PickupBranchesScreenState extends State<PickupBranchesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Branch? _highlightedBranch;

  @override
  void initState() {
    super.initState();
    final list = BranchService().allBranches;
    _highlightedBranch = BranchService().selectedBranch ?? (list.isNotEmpty ? list.first : null);
    BranchService().fetchBranchesFromBackend().then((_) {
      if (mounted) {
        setState(() {
          final updated = BranchService().allBranches;
          if (_highlightedBranch == null && updated.isNotEmpty) {
            _highlightedBranch = BranchService().selectedBranch ?? updated.first;
          }
        });
      }
    });
    BranchService().branchesNotifier.addListener(_onBranchesChanged);
  }

  void _onBranchesChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    BranchService().branchesNotifier.removeListener(_onBranchesChanged);
    _searchController.dispose();
    super.dispose();
  }

  List<Branch> get _filteredBranches {
    final all = BranchService().allBranches;
    final selected = BranchService().selectedBranch;

    // Show the selected branch on the top of the list
    final list = List<Branch>.from(all);
    if (selected != null) {
      list.removeWhere((b) => b.id == selected.id);
      list.insert(0, selected);
    }

    if (_searchQuery.trim().isEmpty) return list;
    return list.where((b) {
      return b.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.address.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _showConfirmBranchDialog(Branch branch) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text(
                  'Confirm Branch Selection',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E1B4B),
                  ),
                ),
                const SizedBox(height: 12),

                // Subtitle
                const Text(
                  'You have selected:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),

                // Yellow card with branch name & address
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7D6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        branch.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E1B4B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        branch.address,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4B5563),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Confirmation question
                const Text(
                  'Would you like to continue with this branch?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1E1B4B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),

                // Action buttons: CANCEL & PROCEED
                Row(
                  children: [
                    // CANCEL
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.pop(dialogCtx),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFD1D5DB), width: 1.5),
                          ),
                          child: const Center(
                            child: Text(
                              'CANCEL',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E1B4B),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // PROCEED
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          // Select branch and set pickup mode
                          BranchService().selectBranch(branch);
                          Navigator.pop(dialogCtx); // close dialog

                          if (Navigator.canPop(context)) {
                            Navigator.pop(context); // pop back to Home
                          } else if (widget.onBackToHome != null) {
                            widget.onBackToHome!();
                          }
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD600),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD600).withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'PROCEED',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E1B4B),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final branches = _filteredBranches;
    final selectedBranch = BranchService().selectedBranch;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1B4B), size: 24),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else if (widget.onBackToHome != null) {
                        widget.onBackToHome!();
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Branches',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E1B4B),
                    ),
                  ),
                ],
              ),
            ),

            // ─── MAP VIEW (Real OpenStreetMap with branch pins) ────────────
            SizedBox(
              height: 250,
              child: _BranchesOverviewMap(
                branches: BranchService().allBranches,
                highlightedBranchId: _highlightedBranch?.id ?? selectedBranch?.id,
                buildPin: _buildMapPin,
                onBranchTap: (branch) {
                  setState(() => _highlightedBranch = branch);
                  _showConfirmBranchDialog(branch);
                },
              ),
            ),

            // ─── SEARCH BY BRANCH ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: const InputDecoration(
                    hintText: 'Search by Branch',
                    hintStyle: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),

            // ─── "All Branches" HEADER ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'All Branches',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E1B4B),
                  ),
                ),
              ),
            ),

            // ─── BRANCHES LIST ────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFFFF5722),
                onRefresh: () async {
                  await BranchService().fetchBranchesFromBackend();
                  if (mounted) setState(() {});
                },
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  itemCount: branches.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFF3F4F6),
                  ),
                  itemBuilder: (context, index) {
                    final branch = branches[index];
                    final isCurrentlySelected = selectedBranch?.id == branch.id ||
                        (selectedBranch == null && index == 0);

                    return InkWell(
                      onTap: () {
                        setState(() => _highlightedBranch = branch);
                        _showConfirmBranchDialog(branch);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isCurrentlySelected ? const Color(0xFFFFD600) : Colors.transparent,
                                shape: BoxShape.circle,
                                border: isCurrentlySelected
                                    ? null
                                    : Border.all(color: const Color(0xFF1E1B4B), width: 1.5),
                              ),
                              child: Icon(
                                Icons.storefront_outlined,
                                color: const Color(0xFF1E1B4B),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    branch.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E1B4B),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  const Text(
                                    'Open Now',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    branch.distance,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF9CA3AF),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: isCurrentlySelected
                                  ? const Color(0xFFFFD600)
                                  : const Color(0xFF1E1B4B),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPin({required bool isActive, double size = 32}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFFD600) : const Color(0xFF78716C).withValues(alpha: 0.85),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.storefront_rounded,
          color: isActive ? const Color(0xFF1E1B4B) : Colors.white,
          size: size * 0.55,
        ),
      ),
    );
  }
}

/// Real OpenStreetMap overview showing every branch as a tappable pin,
/// auto-fitted to bounds so all branches are visible at once.
class _BranchesOverviewMap extends StatelessWidget {
  final List<Branch> branches;
  final String? highlightedBranchId;
  final Widget Function({required bool isActive, double size}) buildPin;
  final void Function(Branch) onBranchTap;

  const _BranchesOverviewMap({
    required this.branches,
    required this.highlightedBranchId,
    required this.buildPin,
    required this.onBranchTap,
  });

  @override
  Widget build(BuildContext context) {
    if (branches.isEmpty) {
      return Container(
        color: const Color(0xFFF1EFEA),
        child: const Center(
          child: Text('No branches available', style: TextStyle(color: Color(0xFF9CA3AF))),
        ),
      );
    }

    final points = branches.map((b) => LatLng(b.lat, b.lng)).toList();
    final bounds = LatLngBounds.fromPoints(points);

    return FlutterMap(
      options: MapOptions(
        initialCameraFit: CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50),
        ),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.example.hpcustomer',
          maxZoom: 19,
          errorTileCallback: (tile, error, stackTrace) {
            debugPrint('Map tile failed to load (${tile.coordinates}): $error');
          },
        ),
        MarkerLayer(
          markers: branches.map((branch) {
            final isSelected = branch.id == highlightedBranchId ||
                (highlightedBranchId == null && branch.id == branches.first.id);
            return Marker(
              point: LatLng(branch.lat, branch.lng),
              width: 90,
              height: 70,
              alignment: Alignment.topCenter,
              child: GestureDetector(
                onTap: () => onBranchTap(branch),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildPin(isActive: isSelected, size: isSelected ? 36 : 30),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF1E1B4B) : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFFFD600) : const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
                        ],
                      ),
                      child: Text(
                        branch.name.replaceAll('HungerPoint ', '').split('-').first.trim(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? const Color(0xFFFFD600) : const Color(0xFF1E1B4B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
