// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'board_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$storageServiceHash() => r'59688abd0fb16e355f55dd53d8827bcf69375a56';

/// See also [storageService].
@ProviderFor(storageService)
final storageServiceProvider = Provider<StorageService>.internal(
  storageService,
  name: r'storageServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$storageServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef StorageServiceRef = ProviderRef<StorageService>;
String _$appDocumentsDirectoryHash() =>
    r'219ab8ca0195c71ec080c74ecce08563fd910468';

/// See also [appDocumentsDirectory].
@ProviderFor(appDocumentsDirectory)
final appDocumentsDirectoryProvider =
    AutoDisposeFutureProvider<Directory>.internal(
  appDocumentsDirectory,
  name: r'appDocumentsDirectoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appDocumentsDirectoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AppDocumentsDirectoryRef = AutoDisposeFutureProviderRef<Directory>;
String _$initializationHash() => r'0a322986f1116f5a0b9d70bf976bb4bdbda9efcc';

/// See also [initialization].
@ProviderFor(initialization)
final initializationProvider = AutoDisposeFutureProvider<void>.internal(
  initialization,
  name: r'initializationProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$initializationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef InitializationRef = AutoDisposeFutureProviderRef<void>;
String _$boardListHash() => r'183b2b0b982b0073af7894f034e8ebbf2d0b0eb6';

/// See also [BoardList].
@ProviderFor(BoardList)
final boardListProvider = NotifierProvider<BoardList, List<Board>>.internal(
  BoardList.new,
  name: r'boardListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$boardListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BoardList = Notifier<List<Board>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
