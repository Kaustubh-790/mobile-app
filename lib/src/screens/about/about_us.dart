import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: AppTheme.beigeDefault,
      appBar: AppBar(
        title: Text(
          'ABOUT US',
          style: theme.textTheme.headlineMedium?.copyWith(
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: AppTheme.beigeDefault,
        foregroundColor: AppTheme.brown500,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.brown500),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Logo Section
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.sand50,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.beige10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.business, size: 60, color: AppTheme.brown400),
              ),
            ),
            const SizedBox(height: 24),

            // Company Name
            Center(
              child: Text(
                '[Company Name]',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.brown500,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Company Tagline
            Center(
              child: Text(
                '[Your innovative tagline here]',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.brown300,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // About Section
            Text(
              'Our Story',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.brown500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.sand40,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                '[Insert your company story here. Describe your mission, vision, and what makes your company unique. Talk about when you were founded, your core values, and your commitment to customers.]',
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  color: AppTheme.brown400,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Mission & Vision
            Text(
              'Mission & Vision',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.brown500,
              ),
            ),
            const SizedBox(height: 16),

            // Mission Card
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.sand40,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryDefault.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.flag, color: AppTheme.primaryDefault),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Our Mission',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.brown500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '[Your mission statement - what you do and why you do it]',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.5,
                        color: AppTheme.brown400,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Vision Card
            Container(
              decoration: BoxDecoration(
                color: AppTheme.sand40,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.clay.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.visibility, color: AppTheme.clay),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Our Vision',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.brown500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '[Your vision statement - where you see the company going in the future]',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.5,
                        color: AppTheme.brown400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Team Section
            Text(
              'Meet Our Team',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.brown500,
              ),
            ),
            const SizedBox(height: 16),

            // Team Members Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildTeamMember(
                  '[Team Member 1]',
                  '[Position/Title]',
                  Icons.person,
                  theme,
                ),
                _buildTeamMember(
                  '[Team Member 2]',
                  '[Position/Title]',
                  Icons.person,
                  theme,
                ),
                _buildTeamMember(
                  '[Team Member 3]',
                  '[Position/Title]',
                  Icons.person,
                  theme,
                ),
                _buildTeamMember(
                  '[Team Member 4]',
                  '[Position/Title]',
                  Icons.person,
                  theme,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Contact Information
            Text(
              'Get In Touch',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.brown500,
              ),
            ),
            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(
                color: AppTheme.sand40,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildContactItem(
                      Icons.email_outlined,
                      'Email',
                      '[company@email.com]',
                      theme,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: AppTheme.beige10),
                    ),
                    _buildContactItem(
                      Icons.phone_outlined,
                      'Phone',
                      '[+1 (555) 123-4567]',
                      theme,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: AppTheme.beige10),
                    ),
                    _buildContactItem(
                      Icons.location_on_outlined,
                      'Address',
                      '[123 Business St, City, State 12345]',
                      theme,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: AppTheme.beige10),
                    ),
                    _buildContactItem(
                      Icons.language,
                      'Website',
                      '[www.yourcompany.com]',
                      theme,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamMember(String name, String position, IconData icon, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.sand40,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.sand50,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.beige10),
              ),
              child: Icon(icon, size: 30, color: AppTheme.brown400),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.brown500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              position,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.brown300,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value, ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryDefault.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryDefault, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.brown500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.brown400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
