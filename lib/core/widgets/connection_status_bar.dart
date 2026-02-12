import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:convex_flutter/convex_flutter.dart';

class ConnectionStatusBar extends StatelessWidget {
  const ConnectionStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final convex = context.read<ConvexClient?>();
    if (convex == null) return const SizedBox.shrink();

    return StreamBuilder<WebSocketConnectionState>(
      stream: convex.connectionState,
      initialData: convex.currentConnectionState,
      builder: (context, snapshot) {
        final state =
            snapshot.data ?? WebSocketConnectionState.connecting;
        final isConnected = state == WebSocketConnectionState.connected;

        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: isConnected
              ? const SizedBox.shrink()
              : Material(
                  color: Colors.orange.shade700,
                  child: SafeArea(
                    bottom: false,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 16),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Reconnecting...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
