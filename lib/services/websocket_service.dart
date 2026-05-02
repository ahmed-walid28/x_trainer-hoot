import 'package:socket_io_client/socket_io_client.dart' as IO;

class WebSocketService {
  IO.Socket? socket;
  final String serverUrl;

  // Callbacks
  Function(Map<String, dynamic>)? onPoseResult;
  Function(String)? onError;
  Function()? onConnected;
  Function()? onDisconnected;

  WebSocketService({required this.serverUrl});

  void connect() {
    socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket!.connect();

    socket!.onConnect((_) {
      print('Connected to server');
      onConnected?.call();
    });

    socket!.onDisconnect((_) {
      print('Disconnected from server');
      onDisconnected?.call();
    });

    socket!.on('connection_response', (data) {
      print('Connection response: $data');
    });

    socket!.on('pose_result', (data) {
      print('Pose result received: $data');
      onPoseResult?.call(data);
    });

    socket!.on('error', (data) {
      print('Error: $data');
      onError?.call(data['message'] ?? 'Unknown error');
    });

    socket!.on('exercise_started', (data) {
      print('Exercise started: $data');
    });

    socket!.on('exercise_stopped', (data) {
      print('Exercise stopped: $data');
    });
  }

  void startExercise(String exerciseType) {
    socket?.emit('start_exercise', {'exercise_type': exerciseType});
  }

  void sendFrame(String base64Image) {
    socket?.emit('process_frame', {'frame': base64Image});
  }

  void stopExercise() {
    socket?.emit('stop_exercise', {});
  }

  void disconnect() {
    socket?.disconnect();
    socket?.dispose();
  }
}