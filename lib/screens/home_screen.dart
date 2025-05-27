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
      appBar: AppBar(title: const Text('Web3 Guessing Game')),
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
              'Guess a number between 0 and 100!\n🎯 Win: Within 20 points = receive 12.5-50 tokens\n💸 Lose: More than 20 points = pay 5 tokens entry fee\n\nTokens come from/go to the game owner!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
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
                'Enter a number between 0 and 100:\n\n💸 Entry Fee: 5 GUESS tokens (paid if you lose)\n🎯 Potential Reward: 12.5-50 GUESS tokens (received if you win)',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w500),
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

    bool playerWon = difference <= 20;
    String resultMessage;
    if (playerWon) {
      if (difference == 0) {
        resultMessage = '🎉 YOU WON! Perfect match!';
      } else if (difference <= 5) {
        resultMessage = '🎉 YOU WON! Amazing! Very close!';
      } else if (difference <= 10) {
        resultMessage = '🎉 YOU WON! Great! Close guess!';
      } else {
        resultMessage = '🎉 YOU WON! Good! Not too far off!';
      }
    } else {
      resultMessage = '💔 YOU LOST! Try again for a better score!';
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
            if (playerWon)
              Text(
                'Reward: +${result.rewardAmount} TOKEN',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              )
            else
              const Text(
                'Entry Fee: -5 TOKEN',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
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

  Color _getResultColor(GameResult result) {
    final difference = result.difference;
    bool playerWon = difference <= 20;

    if (playerWon) {
      if (difference == 0) {
        return Colors.purple; // Perfect
      } else if (difference <= 5) {
        return Colors.blue; // Excellent
      } else if (difference <= 10) {
        return Colors.green; // Great
      } else {
        return Colors.amber; // Good
      }
    } else {
      return Colors.red; // Lost
    }
  }
}
