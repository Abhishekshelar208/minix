import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:minix/models/problem.dart';

class ProblemDetailsPage extends StatelessWidget {
  final Problem problem;
  final bool isBookmarked;
  final VoidCallback onSelect;
  final ValueChanged<bool> onBookmarkChanged;

  const ProblemDetailsPage({
    super.key,
    required this.problem,
    required this.isBookmarked,
    required this.onSelect,
    required this.onBookmarkChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Project Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () => onBookmarkChanged(!isBookmarked),
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
              color: const Color(0xff2563eb),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              problem.title,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xff1f2937),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              problem.hasDetailedInfo && problem.detailedDescription != null 
                  ? problem.detailedDescription!
                  : problem.description,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: const Color(0xff6b7280),
                height: 1.5,
              ),
            ),
            
            // Real-life example section (if detailed info available)
            if (problem.hasDetailedInfo && problem.realLifeExample != null && problem.realLifeExample!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xfff0f9ff),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xffe0f2fe)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline, color: Color(0xff0369a1), size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Real-life Examples',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff0369a1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...problem.realLifeExample!.map((example) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(
                              color: Color(0xff1e40af),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              example,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: const Color(0xff1e40af),
                                height: 1.5,
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

            const SizedBox(height: 24),
            _sectionTitle('Tags'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
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
              const SizedBox(height: 24),
              _sectionTitle(problem.hasDetailedInfo ? 'Detailed Features' : 'Sample Features'),
              const SizedBox(height: 12),
              ...(problem.hasDetailedInfo ? problem.detailedFeatures! : problem.features).map((f) => _bullet(f)),
            ],
            
            // Implementation steps (if detailed info available)
            if (problem.hasDetailedInfo && problem.implementationSteps?.isNotEmpty == true) ...[
              const SizedBox(height: 24),
              _sectionTitle('Implementation Steps'),
              const SizedBox(height: 12),
              ...problem.implementationSteps!.asMap().entries.map(
                (entry) => _numberedBullet('${entry.key + 1}. ${entry.value}'),
              ),
            ],
            
            // Challenges (if detailed info available)
            if (problem.hasDetailedInfo && problem.challenges?.isNotEmpty == true) ...[
              const SizedBox(height: 24),
              _sectionTitle('Potential Challenges'),
              const SizedBox(height: 12),
              ...problem.challenges!.map((c) => _warningBullet(c)),
            ],
            
            // Learning outcomes (if detailed info available)
            if (problem.hasDetailedInfo && problem.learningOutcomes?.isNotEmpty == true) ...[
              const SizedBox(height: 24),
              _sectionTitle('What You\'ll Learn'),
              const SizedBox(height: 12),
              ...problem.learningOutcomes!.map((l) => _learningBullet(l)),
            ],

            if (problem.dataSources.isNotEmpty) ...[
              const SizedBox(height: 24),
              _sectionTitle('Data Sources'),
              const SizedBox(height: 12),
              ...problem.dataSources.map((d) => _bullet(d)),
            ],

            if (problem.beneficiaries.isNotEmpty) ...[
              const SizedBox(height: 24),
              _sectionTitle('Stakeholders'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: problem.beneficiaries.map(_tagChip).toList(),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: onSelect,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                'Select this topic',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff2563eb),
              ),
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
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: const Color(0xff1f2937),
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Icon(Icons.circle, size: 8, color: Color(0xff6b7280)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: const Color(0xff374151),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _numberedBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 20), // Indent for numbered items
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 16, 
                color: const Color(0xff374151),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _warningBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.warning_amber_outlined, size: 20, color: Color(0xfff59e0b)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 16, 
                color: const Color(0xff92400e),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _learningBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.school_outlined, size: 20, color: Color(0xff059669)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 16, 
                color: const Color(0xff065f46),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tagChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xffeef2ff),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffe5e7eb)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xff1f2937),
        ),
      ),
    );
  }
}