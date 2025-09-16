// lib/presentation/widgets/desktop/plan_status_widget.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class PlanStatusWidget extends StatefulWidget {
  final Map<String, dynamic> userData;
  final bool isSmallScreen;
  final VoidCallback? onUpgradePressed;
  final VoidCallback? onRefreshPressed;

  const PlanStatusWidget({
    super.key,
    required this.userData,
    this.isSmallScreen = false,
    this.onUpgradePressed,
    this.onRefreshPressed,
  });

  @override
  State<PlanStatusWidget> createState() => _PlanStatusWidgetState();
}

class _PlanStatusWidgetState extends State<PlanStatusWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );

    _pulseController.repeat(reverse: true);
    _progressController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  String get planType => widget.userData['plan_type'] ?? 'trial';
  String get planStatus => widget.userData['plan_status'] ?? 'active';
  int get dailyUsesRemaining => widget.userData['daily_uses_remaining'] ?? 0;
  int get dailyLimit => widget.userData['daily_limit'] ?? 1;
  double get planPrice => widget.userData['plan_price']?.toDouble() ?? 0.0;

  String get planDisplayName => AppConstants.getPlanDisplayName(planType);
  Color get planColor => AppConstants.getPlanColor(planType);

  double get usageProgress {
    if (dailyLimit <= 0) return 0.0;
    if (dailyLimit == -1) return 1.0; // Admin unlimited
    return (dailyLimit - dailyUsesRemaining) / dailyLimit;
  }

  bool get isLowUsage =>
      dailyUsesRemaining <= 1 && planType != AppConstants.adminPlan;
  bool get isUnlimited => dailyLimit == -1;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isLowUsage && planStatus == 'active'
              ? _pulseAnimation.value
              : 1.0,
          child: Container(
            margin: EdgeInsets.symmetric(
              vertical: widget.isSmallScreen ? 8 : 12,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  planColor.withOpacity(0.1),
                  planColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: planColor.withOpacity(0.3), width: 1.5),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: planColor.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(widget.isSmallScreen ? 16 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  SizedBox(height: widget.isSmallScreen ? 12 : 16),
                  _buildUsageInfo(),
                  SizedBox(height: widget.isSmallScreen ? 12 : 16),
                  _buildProgressBar(),
                  if (planType != AppConstants.adminPlan) ...[
                    SizedBox(height: widget.isSmallScreen ? 12 : 16),
                    _buildActionButtons(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(widget.isSmallScreen ? 8 : 10),
          decoration: BoxDecoration(
            color: planColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getPlanIcon(),
            color: Colors.white,
            size: widget.isSmallScreen ? 20 : 24,
          ),
        ),
        SizedBox(width: widget.isSmallScreen ? 12 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                planDisplayName,
                style: TextStyle(
                  fontSize: widget.isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: planColor,
                ),
              ),
              if (planPrice > 0) ...[
                SizedBox(height: 2),
                Text(
                  '\$${planPrice.toStringAsFixed(2)}/month',
                  style: TextStyle(
                    fontSize: widget.isSmallScreen ? 12 : 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildStatusBadge() {
    final isActive = planStatus == 'active';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isSmallScreen ? 8 : 10,
        vertical: widget.isSmallScreen ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[100] : Colors.red[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.green[300]! : Colors.red[300]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.error,
            color: isActive ? Colors.green[700] : Colors.red[700],
            size: widget.isSmallScreen ? 12 : 14,
          ),
          SizedBox(width: 4),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: widget.isSmallScreen ? 10 : 12,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.green[700] : Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Usage',
              style: TextStyle(
                fontSize: widget.isSmallScreen ? 12 : 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              isUnlimited
                  ? 'Unlimited Access'
                  : '$dailyUsesRemaining of $dailyLimit remaining',
              style: TextStyle(
                fontSize: widget.isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: isLowUsage ? Colors.orange[700] : Colors.grey[800],
              ),
            ),
          ],
        ),
        if (widget.onRefreshPressed != null)
          IconButton(
            onPressed: widget.onRefreshPressed,
            icon: Icon(
              Icons.refresh,
              color: planColor,
              size: widget.isSmallScreen ? 20 : 24,
            ),
            tooltip: 'Refresh usage data',
          ),
      ],
    );
  }

  Widget _buildProgressBar() {
    if (isUnlimited) {
      return AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          return Container(
            height: widget.isSmallScreen ? 24 : 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[600]!, Colors.green[400]!],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Text(
                'UNLIMITED ACCESS ∞',
                style: TextStyle(
                  fontSize: widget.isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          );
        },
      );
    }

    return Column(
      children: [
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return LinearProgressIndicator(
              value: usageProgress * _progressAnimation.value,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                isLowUsage ? Colors.orange[600]! : planColor,
              ),
              borderRadius: BorderRadius.circular(8),
              minHeight: widget.isSmallScreen ? 6 : 8,
            );
          },
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '0',
              style: TextStyle(
                fontSize: widget.isSmallScreen ? 10 : 12,
                color: Colors.grey[500],
              ),
            ),
            Text(
              '$dailyLimit uses',
              style: TextStyle(
                fontSize: widget.isSmallScreen ? 10 : 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (isLowUsage && planType != AppConstants.enterprisePlan)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: widget.onUpgradePressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: widget.isSmallScreen ? 8 : 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(Icons.upgrade, size: widget.isSmallScreen ? 16 : 18),
              label: Text(
                'Upgrade Plan',
                style: TextStyle(
                  fontSize: widget.isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        if (isLowUsage && planType != AppConstants.enterprisePlan) ...[
          SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // Contact WhatsApp action
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: planColor,
                side: BorderSide(color: planColor),
                padding: EdgeInsets.symmetric(
                  vertical: widget.isSmallScreen ? 8 : 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(Icons.chat, size: widget.isSmallScreen ? 16 : 18),
              label: Text(
                'Contact Us',
                style: TextStyle(
                  fontSize: widget.isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  IconData _getPlanIcon() {
    switch (planType) {
      case AppConstants.adminPlan:
        return Icons.admin_panel_settings;
      case AppConstants.enterprisePlan:
        return Icons.business;
      case AppConstants.businessPlan:
        return Icons.work;
      case AppConstants.proPlan:
        return Icons.star;
      case AppConstants.basicPlan:
        return Icons.person;
      case AppConstants.trialPlan:
      default:
        return Icons.free_breakfast;
    }
  }
}
