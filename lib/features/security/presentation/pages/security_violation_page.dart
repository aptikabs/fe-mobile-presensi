import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';

class SecurityViolationPage extends StatelessWidget {
  final String reason;
  final Map<String, String>? deviceDetails;

  const SecurityViolationPage({
    super.key,
    this.reason =
        'Aplikasi e-Presensi tidak dapat dijalankan pada perangkat virtual atau emulator.',
    this.deviceDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  _Header(),
                  const SizedBox(height: 24),

                  Text(
                    reason,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.neutral600,
                    ),
                  ),

                  if (deviceDetails?.isNotEmpty == true) ...[
                    const SizedBox(height: 24),
                    _DeviceDetails(deviceDetails!),
                  ],

                  const SizedBox(height: 16),
                  _Warning(),

                  const SizedBox(height: 24),
                  _CloseButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: AppColors.danger50,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.phonelink_erase_rounded,
            size: 36,
            color: AppColors.danger600,
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'Akses Ditolak',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.neutral900,
          ),
        ),

        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.danger100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Emulator Terdeteksi',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.danger700,
            ),
          ),
        ),
      ],
    );
  }
}

class _DeviceDetails extends StatelessWidget {
  final Map<String, String> details;

  const _DeviceDetails(this.details);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.devices_rounded,
                size: 18,
                color: AppColors.neutral600,
              ),
              SizedBox(width: 8),
              Text(
                'Detail Perangkat',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutral900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          ...details.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutral800,
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

class _Warning extends StatelessWidget {
  const _Warning();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning100.withAlpha(120),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.warning900,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Demi menjamin keabsahan data presensi, aplikasi hanya dapat digunakan pada HP fisik asli (Real Device).',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.warning900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: SystemNavigator.pop,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary500,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Tutup Aplikasi',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
