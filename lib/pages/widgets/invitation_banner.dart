import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:minix/models/project_invitation.dart';
import 'package:minix/services/invitation_service.dart';

class InvitationBanner extends StatelessWidget {
  final InvitationService invitationService;
  final VoidCallback? onInvitationAccepted;

  const InvitationBanner({
    super.key,
    required this.invitationService,
    this.onInvitationAccepted,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProjectInvitation>>(
      stream: invitationService.getPendingInvitations(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final invitations = snapshot.data!;

        return Container(
          margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Pending Invitations (${invitations.length})',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              // Invitation cards
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: invitations.length,
                itemBuilder: (context, index) {
                  return InvitationCard(
                    invitation: invitations[index],
                    invitationService: invitationService,
                    onAccepted: onInvitationAccepted,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class InvitationCard extends StatefulWidget {
  final ProjectInvitation invitation;
  final InvitationService invitationService;
  final VoidCallback? onAccepted;

  const InvitationCard({
    super.key,
    required this.invitation,
    required this.invitationService,
    this.onAccepted,
  });

  @override
  State<InvitationCard> createState() => _InvitationCardState();
}

class _InvitationCardState extends State<InvitationCard> {
  bool _isProcessing = false;

  Future<void> _acceptInvitation() async {
    setState(() => _isProcessing = true);

    try {
      await widget.invitationService.acceptInvitation(widget.invitation);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Joined "${widget.invitation.teamName}" successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Notify parent to refresh
        widget.onAccepted?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to accept invitation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _rejectInvitation() async {
    setState(() => _isProcessing = true);

    try {
      await widget.invitationService.rejectInvitation(widget.invitation);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation declined'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to decline invitation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Team name and icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.folder, color: Colors.blue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.invitation.teamName,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: const Color(0xff1f2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.invitation.teamLeaderName} invited you to join',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Project details
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                Icons.phone_android,
                widget.invitation.targetPlatform,
                Colors.purple,
              ),
              _buildInfoChip(
                Icons.school,
                'Year ${widget.invitation.yearOfStudy}',
                Colors.orange,
              ),
              if (widget.invitation.projectName.isNotEmpty)
                _buildInfoChip(
                  Icons.description,
                  widget.invitation.projectName,
                  Colors.green,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Action buttons
          if (_isProcessing)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _acceptInvitation,
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _rejectInvitation,
                    icon: const Icon(Icons.cancel, size: 18),
                    label: const Text('Decline'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
