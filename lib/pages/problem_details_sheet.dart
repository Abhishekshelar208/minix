import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:minix/models/problem.dart';

class ProblemDetailsBottomSheet extends StatelessWidget {
  final Problem problem;
  final bool isBookmarked;
  final VoidCallback onSelect;
  final ValueChanged<bool> onBookmarkChanged;

  const ProblemDetailsBottomSheet({
    super.key,
    required this.problem,
    required this.isBookmarked,
    required this.onSelect,
    required this.onBookmarkChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), // Reduced top padding since SafeArea handles it
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      problem.title,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff1f2937),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => onBookmarkChanged(!isBookmarked),
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                      color: const Color(0xff2563eb),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Text(
                problem.hasDetailedInfo && problem.detailedDescription != null 
                    ? problem.detailedDescription!
                    : problem.description,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xff6b7280),
                  height: 1.5,
                ),
              ),
              
              // Real-life example section (if detailed info available)
              if (problem.hasDetailedInfo && problem.realLifeExample != null && problem.realLifeExample!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xfff0f9ff),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xffe0f2fe)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lightbulb_outline, color: Color(0xff0369a1), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Real-life Examples',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xff0369a1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...problem.realLifeExample!.map((example) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '• ',
                              style: TextStyle(
                                color: Color(0xff1e40af),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                example,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: const Color(0xff1e40af),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              _sectionTitle('Tags'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _tagChip(problem.domain),
                  _tagChip('Scope: ${problem.scope}'),
                  ...problem.platform.map(_tagChip),
                  ...problem.skills.map(_tagChip),
                  ...problem.year.map((y) => _tagChip('Year $y')),
                ],
              ),

              // Use detailed features if available, otherwise use basic features
              if ((problem.hasDetailedInfo ? problem.detailedFeatures : problem.features)?.isNotEmpty == true) ...[
                const SizedBox(height: 16),
                _sectionTitle(problem.hasDetailedInfo ? 'Detailed Features' : 'Sample Features'),
                ...(problem.hasDetailedInfo ? problem.detailedFeatures! : problem.features).map((f) => _bullet(f)),
              ],
              
              // Implementation steps (if detailed info available)
              if (problem.hasDetailedInfo && problem.implementationSteps?.isNotEmpty == true) ...[
                const SizedBox(height: 16),
                _sectionTitle('Implementation Steps'),
                ...problem.implementationSteps!.asMap().entries.map(
                  (entry) => _numberedBullet('${entry.key + 1}. ${entry.value}'),
                ),
              ],
              
              // Challenges (if detailed info available)
              if (problem.hasDetailedInfo && problem.challenges?.isNotEmpty == true) ...[
                const SizedBox(height: 16),
                _sectionTitle('Potential Challenges'),
                ...problem.challenges!.map((c) => _warningBullet(c)),
              ],
              
              // Learning outcomes (if detailed info available)
              if (problem.hasDetailedInfo && problem.learningOutcomes?.isNotEmpty == true) ...[
                const SizedBox(height: 16),
                _sectionTitle('What You\'ll Learn'),
                ...problem.learningOutcomes!.map((l) => _learningBullet(l)),
              ],

              if (problem.dataSources.isNotEmpty) ...[
                const SizedBox(height: 16),
                _sectionTitle('Data Sources'),
                ...problem.dataSources.map((d) => _bullet(d)),
              ],

              if (problem.beneficiaries.isNotEmpty) ...[
                const SizedBox(height: 16),
                _sectionTitle('Stakeholders'),
                Wrap(
                  spacing: 8,
                  children: problem.beneficiaries.map(_tagChip).toList(),
                ),
              ],

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onSelect,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    'Select this topic',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: const Color(0xff1f2937),
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: Color(0xff6b7280)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xff374151)),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _numberedBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 16), // Indent for numbered items
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14, 
                color: const Color(0xff374151),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _warningBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.warning_amber_outlined, size: 16, color: Color(0xfff59e0b)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14, 
                color: const Color(0xff92400e),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _learningBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.school_outlined, size: 16, color: Color(0xff059669)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14, 
                color: const Color(0xff065f46),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tagChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xffeef2ff),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffe5e7eb)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: const Color(0xff1f2937),
        ),
      ),
    );
  }
}
