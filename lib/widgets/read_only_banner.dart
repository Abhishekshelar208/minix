import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Banner widget to display when user is in read-only mode (not a team leader)
class ReadOnlyBanner extends StatelessWidget {
  final String? message;
  
  const ReadOnlyBanner({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xfff59e0b).withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xfff59e0b).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.visibility,
            color: Color(0xfff59e0b),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message ?? 'Read-Only Mode: Only team leaders can make changes',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xff92400e),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xfff59e0b).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'VIEWER',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: const Color(0xff92400e),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
