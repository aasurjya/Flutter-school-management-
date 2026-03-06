import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/communication.dart';

class ChannelSelector extends StatelessWidget {
  final List<CommunicationChannel> selectedChannels;
  final ValueChanged<List<CommunicationChannel>> onChanged;
  final bool allowMultiple;

  const ChannelSelector({
    super.key,
    required this.selectedChannels,
    required this.onChanged,
    this.allowMultiple = true,
  });

  static IconData iconForChannel(CommunicationChannel channel) {
    switch (channel) {
      case CommunicationChannel.sms:
        return Icons.sms_outlined;
      case CommunicationChannel.email:
        return Icons.email_outlined;
      case CommunicationChannel.push:
        return Icons.notifications_outlined;
      case CommunicationChannel.inApp:
        return Icons.phone_android_outlined;
      case CommunicationChannel.whatsapp:
        return Icons.chat_outlined;
    }
  }

  static Color colorForChannel(CommunicationChannel channel) {
    switch (channel) {
      case CommunicationChannel.sms:
        return AppColors.info;
      case CommunicationChannel.email:
        return AppColors.primary;
      case CommunicationChannel.push:
        return AppColors.warning;
      case CommunicationChannel.inApp:
        return AppColors.secondary;
      case CommunicationChannel.whatsapp:
        return const Color(0xFF25D366);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: CommunicationChannel.values.map((channel) {
        final isSelected = selectedChannels.contains(channel);
        final color = colorForChannel(channel);

        return FilterChip(
          selected: isSelected,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                iconForChannel(channel),
                size: 16,
                color: isSelected ? Colors.white : color,
              ),
              const SizedBox(width: 6),
              Text(channel.label),
            ],
          ),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
          backgroundColor: color.withValues(alpha: 0.1),
          selectedColor: color,
          checkmarkColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected ? color : color.withValues(alpha: 0.3),
            ),
          ),
          onSelected: (selected) {
            if (allowMultiple) {
              final newChannels = List<CommunicationChannel>.from(selectedChannels);
              if (selected) {
                newChannels.add(channel);
              } else {
                newChannels.remove(channel);
              }
              // Ensure at least one channel is selected
              if (newChannels.isNotEmpty) {
                onChanged(newChannels);
              }
            } else {
              onChanged([channel]);
            }
          },
        );
      }).toList(),
    );
  }
}

/// Compact inline version showing selected channels as icons
class ChannelIndicatorRow extends StatelessWidget {
  final List<CommunicationChannel> channels;
  final double iconSize;

  const ChannelIndicatorRow({
    super.key,
    required this.channels,
    this.iconSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: channels.map((channel) {
        final color = ChannelSelector.colorForChannel(channel);
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Tooltip(
            message: channel.label,
            child: Icon(
              ChannelSelector.iconForChannel(channel),
              size: iconSize,
              color: color,
            ),
          ),
        );
      }).toList(),
    );
  }
}
