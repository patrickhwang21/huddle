import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/huddle_event.dart';
import '../theme/app_theme.dart';

void showInviteSheet(BuildContext context, HuddleEvent event) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Invite people', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text('Share this code so others can join "${event.title}".',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: Text(
                  event.eventCode,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 10),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: event.eventCode));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied.')));
                        }
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        SharePlus.instance.share(
                          ShareParams(
                            text: 'Join my Huddle event "${event.title}"! '
                                'Open Huddle, tap "Join with Event Code", and enter code: ${event.eventCode}',
                          ),
                        );
                      },
                      icon: const Icon(Icons.ios_share_rounded, size: 18),
                      label: const Text('Share'),
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
