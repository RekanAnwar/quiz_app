import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _walletAddressController =
      TextEditingController();
  final TextEditingController _guessController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _walletAddressController.dispose();
    _guessController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Web3 Guessing Game'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsModal(context),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, _) {
          return Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Show error message if any
                if (appProvider.error != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(
                        AppConstants.defaultRadius,
                      ),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Text(
                      appProvider.error!,
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                  ),

                // Main content based on wallet connection status
                if (!appProvider.isWalletConnected)
                  _buildWalletConnectSection(appProvider)
                else
                  Expanded(child: _buildConnectedSection(appProvider)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWalletConnectSection(AppProvider appProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Connect Your Wallet',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _walletAddressController,
              decoration: const InputDecoration(
                labelText: 'Wallet Address',
                hintText: 'Enter your Ethereum wallet address',
                prefixIcon: Icon(Icons.account_balance_wallet),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed:
                  appProvider.isWalletConnecting
                      ? null
                      : () async {
                        if (_walletAddressController.text.isNotEmpty) {
                          await appProvider.connectWallet(
                            _walletAddressController.text,
                          );
                        }
                      },
              icon:
                  appProvider.isWalletConnecting
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.link),
              label: Text(
                appProvider.isWalletConnecting
                    ? 'Connecting...'
                    : 'Connect Wallet',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedSection(AppProvider appProvider) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Wallet info card
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          appProvider.formattedWalletAddress ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: () => appProvider.disconnectWallet(),
                        tooltip: 'Disconnect wallet',
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _balanceItem(
                        'ETH',
                        appProvider.ethBalance.toStringAsFixed(4),
                      ),
                      _balanceItem(
                        'TOKEN',
                        appProvider.tokenBalance.toStringAsFixed(2),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Game section
          if (appProvider.isGameInProgress)
            _buildGameInputSection(appProvider)
          else if (appProvider.lastGameResult != null)
            _buildGameResultSection(appProvider)
          else
            _buildStartGameSection(appProvider),
        ],
      ),
    );
  }

  Widget _balanceItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildStartGameSection(AppProvider appProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            const Text(
              'Number Guessing Game',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Guess a number between 0 and 100. The closer your guess is to the target number, the more tokens you win!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => appProvider.startGame(),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start New Game'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameInputSection(AppProvider appProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                'Make Your Guess!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Enter a number between 0 and 100:',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _guessController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Your Guess',
                  hintText: 'Enter a number (0-100)',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a number';
                  }
                  final number = int.tryParse(value);
                  if (number == null) {
                    return 'Please enter a valid number';
                  }
                  if (number < 0 || number > 100) {
                    return 'Number must be between 0 and 100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () => appProvider.endGame(),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
                  ),
                  ElevatedButton.icon(
                    onPressed:
                        appProvider.isLoading
                            ? null
                            : () async {
                              if (_formKey.currentState!.validate()) {
                                final guess = int.parse(_guessController.text);

                                await appProvider.playGame(guess);

                                _guessController.clear();
                              }
                            },
                    icon:
                        appProvider.isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.check_circle),
                    label: Text(
                      appProvider.isLoading ? 'Submitting...' : 'Submit Guess',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameResultSection(AppProvider appProvider) {
    final result = appProvider.lastGameResult!;
    final difference = result.difference;

    String resultMessage;
    if (difference == 0) {
      resultMessage = 'Perfect! Exact match!';
    } else if (difference <= 5) {
      resultMessage = 'Amazing! Very close!';
    } else if (difference <= 10) {
      resultMessage = 'Great! Close guess!';
    } else if (difference <= 20) {
      resultMessage = 'Good! Not too far off!';
    } else if (difference <= 30) {
      resultMessage = 'Not bad! Keep trying!';
    } else {
      resultMessage = 'Try again for a better score!';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            const Text(
              'Game Result',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 48,
              backgroundColor: _getResultColor(result),
              child: Text(
                difference.toString(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              resultMessage,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Your guess: ${result.userGuess}',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'Target number: ${result.targetNumber}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Text(
              'Reward: ${result.rewardAmount} TOKEN',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                appProvider.clearLastGameResult();
              },
              icon: const Icon(Icons.replay),
              label: const Text('Play Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Consumer<AppProvider>(
          builder: (context, appProvider, _) {
            return Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Settings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('App Theme'),
                    leading: const Icon(Icons.brightness_6),
                    trailing: DropdownButton<String>(
                      value: appProvider.themeMode,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          appProvider.updateThemeMode(newValue);
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: 'system',
                          child: Text('System'),
                        ),
                        DropdownMenuItem(value: 'light', child: Text('Light')),
                        DropdownMenuItem(value: 'dark', child: Text('Dark')),
                      ],
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Notifications'),
                    subtitle: const Text('Enable push notifications'),
                    value: appProvider.notificationsEnabled,
                    onChanged: (bool value) {
                      appProvider.updateNotificationsEnabled(value);
                    },
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _getResultColor(GameResult result) {
    final difference = result.difference;
    if (difference == 0) {
      return Colors.purple;
    } else if (difference <= 5) {
      return Colors.blue;
    } else if (difference <= 10) {
      return Colors.green;
    } else if (difference <= 20) {
      return Colors.amber;
    } else if (difference <= 30) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
