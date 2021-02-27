// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.


//import 'dart:io';
import 'dart:typed_data';
import 'dart:async';

import 'package:meta/meta.dart';
import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';
import 'package:time_machine/src/platforms/platform_io.dart';

@internal
class TzdbIndex {
  static Future<TzdbIndex> load() async {
    var _jsonMap = await _loadIdMapping();

    // todo: Dart2.0: seek a more elegant mapping of <String, dynamic> to <String, String>
    var map = <String, String>{IDateTimeZone.utcId: ''};
    _jsonMap.forEach((key, value){
      map[key] = value;
    });

    return new TzdbIndex._(map);
  }

  // todo: if we swap to something supporting offset skipping around 'tzdb.bin' file, just fill the _binaryCache instead.
  static Future<TzdbIndex> loadAll() async {
    // This won't have any filenames in it.
    // It's just a dummy object that will also give [zoneIds] and [zoneIdExists] functionality
    var jsonMap = <String, String>{IDateTimeZone.utcId: ''};
    var cache = <String, DateTimeZone>{};

    var binary = await PlatformIO.local.getBinary('tzdb', 'tzdb.bin');
    var reader = new DateTimeZoneReader(binary);

    while (reader.isMore) {
      var id = reader.readString();
      var zone = PrecalculatedDateTimeZone.read(reader, id);
      cache[id] = zone;
      jsonMap[id] = '';
    }

    // todo: this is a good thing to log? (todo: research whether it's ok for libraries in Dart to log)
    // print('Total ${cache.length} zones loaded');

    // todo: we might be able to just foward the _cache.keys instead?
    var index = new TzdbIndex._(jsonMap);
    cache.forEach((id, zone) => index._cache[id] = zone);
    return index;
  }

  TzdbIndex._(this._zoneFilenames);

  static Future<Map<String, dynamic>> _loadIdMapping() async {
    var json = await PlatformIO.local.getJson('tzdb', 'tzdb.json');
    return json;
  }

  final Map<String, String> _zoneFilenames;
  final Map<String, DateTimeZone> _cache = { IDateTimeZone.utcId: DateTimeZone.utc };
  /// Holding place for binary, if it's loaded but not yet transformed into a [DateTimeZone]
  final Map<String, ByteData> _binaryCache = { };

  Iterable<String> get zoneIds => _zoneFilenames.keys;
  bool zoneIdExists(String zoneId) => _zoneFilenames.containsKey(zoneId);

  DateTimeZone _zoneFromBinary(ByteData binary) {
    var reader = new DateTimeZoneReader(binary);
    // this should be the same as the index id
    var id = reader.readString();
    var zone = PrecalculatedDateTimeZone.read(reader, id);
    return zone;
  }

  Future<DateTimeZone> getTimeZone(String zoneId) async {
    var zone = getTimeZoneSync(zoneId);
    if (zone != null) return zone;

    var filename = _zoneFilenames[zoneId];
    if (filename == null) throw new DateTimeZoneNotFoundError('$zoneId had no associated filename.');

    return _cache[zoneId] = _zoneFromBinary(await PlatformIO.local.getBinary('tzdb', '$filename.bin'));
  }

  DateTimeZone getTimeZoneSync(String zoneId) {
    var zone = _cache[zoneId];
    if (zone != null) return zone;

    var binaryData = _binaryCache.remove(zoneId);
    if (binaryData == null) return null;

    return _cache[zoneId] = _zoneFromBinary(binaryData);
  }

  // Default to UTC if we fail to set a local [DateTimeZone]
  static String localId = IDateTimeZone.utcId; // => Platform.localeName;
}

// todo: if we get extension methods, that'll work pretty well with these two classes
// https://github.com/dart-lang/language/issues/41
// todo: normalize behavior so these classes look more alike

@internal
class DateTimeZoneReader extends BinaryReader {
  DateTimeZoneReader(ByteData binary, [int offset = 0]) : super(binary, offset);

  ZoneInterval readZoneInterval() {
    var name = /*stream.*/readString();
    var flag = /*stream.*/readUint8();
    bool startIsLong = (flag & (1 << 2)) != 0;
    bool endIsLong = (flag & (1 << 3)) != 0;
    bool hasStart = (flag & 1) == 1;
    bool hasEnd = (flag & 2) == 2;
    int startSeconds = null;
    int endSeconds = null;

    if (hasStart) {
      if (startIsLong) startSeconds = readInt64();
      else startSeconds = /*stream.*/readInt32();
    }
    if (hasEnd) {
      if (endIsLong) endSeconds = readInt64();
      else endSeconds = /*stream.*/readInt32();
    }

    Instant start = startSeconds == null ? IInstant.beforeMinValue : Instant.fromEpochSeconds(startSeconds);
    Instant end = endSeconds == null ? IInstant.afterMaxValue : Instant.fromEpochSeconds(endSeconds);

    var wallOffset = /*stream.*/readOffsetSeconds2(); // Offset.fromSeconds(stream.readInt32());
    var savings = /*stream.*/readOffsetSeconds2(); // Offset.fromSeconds(stream.readInt32());
    return IZoneInterval.newZoneInterval(name, start, end, wallOffset, savings);
  }
}

abstract class DateTimeZoneType
{
  static const int fixed = 1;
  static const int precalculated = 2;
}

@internal
class DateTimeZoneWriter implements BinaryWriter {
  BinaryWriter _writer;
  final List<String> _stringPool;

  DateTimeZoneWriter(this._writer, [this._stringPool = null]);

  void writeZoneInterval(ZoneInterval zoneInterval) {
    int flag = 0;
    bool longStartRequired = false;
    bool longEndRequired = false;

    if (zoneInterval.hasStart)
    {
      var longStart = zoneInterval.start.epochSeconds;
      longStartRequired = longStart < Platform.int32MinValue || longStart > Platform.int32MaxValue;

      flag |= 1;
      if (longStartRequired) flag |= 1 << 2;
    }

    if (zoneInterval.hasEnd)
    {
      var longEnd = zoneInterval.end.epochSeconds;
      longEndRequired = longEnd < Platform.int32MinValue || longEnd > Platform.int32MaxValue;

      flag |= 2;
      if (longEndRequired) flag |= 1 << 3;
    }
    _writer.writeUint8(flag);

    if (zoneInterval.hasStart) {
      if (zoneInterval.start.epochNanoseconds % TimeConstants.nanosecondsPerSecond != 0) throw new Exception("zoneInterval.Start not seconds.");
      if (longStartRequired) _writer.writeInt64(zoneInterval.start.epochSeconds);
      else _writer.writeInt32(zoneInterval.start.epochSeconds); // .ToUnixTimeMilliseconds());
    }

    if (zoneInterval.hasEnd) {
      if (zoneInterval.end.epochNanoseconds % TimeConstants.nanosecondsPerSecond != 0) throw new Exception("zoneInterval.End not seconds.");
      if (longEndRequired) _writer.writeInt64(zoneInterval.end.epochSeconds);
      else _writer.writeInt32(zoneInterval.end.epochSeconds); // .ToUnixTimeMilliseconds());
    }

    _writer.writeInt32(zoneInterval.wallOffset.inSeconds);
    _writer.writeInt32(zoneInterval.savings.inSeconds);
  }

  // todo: this is a bit ugly

  @override
  Future close() => _writer.close();

  @override
  void write7BitEncodedInt(int value) => _writer.write7BitEncodedInt(value);

  @override
  void writeBool(bool value) => _writer.writeBool(value);

  @override
  void writeInt32(int value) => _writer.writeInt32(value);

  @override
  void writeInt64(int value) => _writer.writeInt64(value);

  @override
  void writeOffsetSeconds(Offset value) => _writer.writeOffsetSeconds(value);

  @override
  void writeOffsetSeconds2(Offset value) => _writer.writeOffsetSeconds2(value);

  @override
  void writeString(String value) => _writer.writeString(value);

  @override
  void writeStringList(List<String> list) => _writer.writeStringList(list);

  @override
  void writeUint8(int value) => _writer.writeUint8(value);

  /// Writes the given dictionary of string to string to the stream.
  /// </summary>
  /// <param name="dictionary">The <see cref="IDictionary{TKey,TValue}" /> to write.</param>
  void writeDictionary(Map<String, String> map) {
    Preconditions.checkNotNull(map, 'map');

    _writer.write7BitEncodedInt(map.length);
    for (var entry in map.entries) {
      _writer.writeString(entry.key);
      _writer.writeString(entry.value);
    }
  }
}


