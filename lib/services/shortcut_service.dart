import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'logger_service.dart';

class ShortcutService {
  static final LoggerService _logger = LoggerService();
  static Map<LogicalKeySet, Intent> get globalShortcuts {
    return {
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN):
          const _AddEquipmentIntent(),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF):
          const _SearchIntent(),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyQ):
          const _ScanQRIntent(),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyE):
          const _ExportIntent(),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS):
          const _SaveIntent(),
    };
  }

  static Map<Type, Action<Intent>> get actions {
    return {
      _AddEquipmentIntent: CallbackAction<_AddEquipmentIntent>(
        onInvoke: (intent) {
          
          _logger.info('Ctrl+N pressed');;
          return null;
        },
      ),
      _SearchIntent: CallbackAction<_SearchIntent>(
        onInvoke: (intent) {
         
          _logger.info('Ctrl+F pressed');;
          return null;
        },
      ),
      _ScanQRIntent: CallbackAction<_ScanQRIntent>(
        onInvoke: (intent) {

          _logger.info('Ctrl+Q pressed');;
          return null;
        },
      ),
      _ExportIntent: CallbackAction<_ExportIntent>(
        onInvoke: (intent) {
          
          _logger.info('Ctrl+E pressed');;
          return null;
        },
      ),
      _SaveIntent: CallbackAction<_SaveIntent>(
        onInvoke: (intent) {
          _logger.info('Ctrl+S pressed');;
          return null;
        },
      ),
    };
  }
}

// Intents для горячих клавиш
class _AddEquipmentIntent extends Intent {
  const _AddEquipmentIntent();
}

class _SearchIntent extends Intent {
  const _SearchIntent();
}

class _ScanQRIntent extends Intent {
  const _ScanQRIntent();
}

class _ExportIntent extends Intent {
  const _ExportIntent();
}

class _SaveIntent extends Intent {
  const _SaveIntent();
}