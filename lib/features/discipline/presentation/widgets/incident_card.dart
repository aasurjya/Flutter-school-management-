import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/discipline.dart';
import 'severity_badge.dart';

class IncidentCard extends StatelessWidget {
  final BehaviorIncident incident;
  final VoidCallback? onTap;

  const IncidentCard({
    super.key,
    required this.incident,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy').format(incident.incidentDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: student + severity
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: incident.studentPhotoUrl != null
                        ? NetworkImage(incident.studentPhotoUrl!)
                        : null,
                    child: incident.studentPhotoUrl == null
                        ? Text(
                            (incident.studentName ?? 'S')
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          incident.studentName ?? 'Unknown Student',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SeverityBadge(severity: incident.severity),
                ],
              ),
              const SizedBox(height: 10),

              // Description
              Text(
                incident.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),

              // Footer: category + status
              Row(
                children: [
                  if (incident.categoryName != null) ...[
                    Icon(
                      Icons.label_outline,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      incident.categoryName!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (incident.location != null) ...[
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        incident.location!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const Spacer(),
                  StatusBadge(status: incident.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
