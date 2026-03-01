import 'package:flutter/material.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(Icons.support_agent_rounded, size: 80, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text('How can we help you?', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Need assistance with your trades or account?', textAlign: TextAlign.center),
                ],
              ),
            ),
            
            _buildSectionHeader(context, 'Common Questions'),
            _buildFAQTile('How does trading work?', 'Trading on Baterpoint is simple. You can either swap items directly or use Baterpoints to pay for items.'),
            _buildFAQTile('What are Baterpoints?', 'Baterpoints are our community currency. Earn them by completing quests or selling items.'),
            _buildFAQTile('My trade didn\'t go through.', 'If you encounter any issues with a trade, contact our support team immediately with the trade ID.'),
            
            const SizedBox(height: 16),
            _buildSectionHeader(context, 'Contact Us'),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email Support'),
              subtitle: const Text('support@baterpoint.com'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.chat_outlined),
              title: const Text('Live Chat'),
              subtitle: const Text('Wait time: ~5 mins'),
              onTap: () {},
            ),
             ListTile(
              leading: const Icon(Icons.help_center_outlined),
              title: const Text('Help Center'),
              subtitle: const Text('support.baterpoint.com'),
              onTap: () {},
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildFAQTile(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(answer),
        ),
      ],
    );
  }
}
