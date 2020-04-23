// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';
import 'dart:html';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:js';
import 'package:http/http.dart' as http;

import 'package:time_machine/src/time_machine_internal.dart';

import 'platform_io.dart';

class _WebMachineIO implements PlatformIO {
  static const String dataPrefix = "/tz-data/";

  @override
  Future<ByteData> getBinary(String path, String filename) async {
    if (filename == null) return new ByteData(0);

    var resource =  (await http.get("$dataPrefix$path/$filename")).bodyBytes;

    var binary = new ByteData.view(new Int8List.fromList(await resource).buffer);
    return binary;
  }

  @override
  Future/**<Map<String, dynamic>>*/ getJson(String path, String filename) async {
    var resource =  (await http.get("$dataPrefix$path/$filename")).body;
    return json.decode(resource);
  }
}

Future initialize(Map args) => TimeMachine.initialize();

class TimeMachine {
  // I'm looking to basically use @internal for protection??? <-- what did I mean by this?
  static Future initialize() async {
    Platform.startWeb();

    // Map IO functions
    PlatformIO.local = new _WebMachineIO();

    // Default provider
    var tzdb = await DateTimeZoneProviders.tzdb;
    IDateTimeZoneProviders.defaultProvider = tzdb;

    _readIntlObject();

    // Default TimeZone
    var local = await tzdb[_timeZoneId];
    // todo: cache local more directly? (this is indirect caching)
    TzdbIndex.localId = local.id;

    // Default Culture
    var cultureId = _locale;
    var culture = await Cultures.getCulture(cultureId);
    ICultures.currentCulture = culture;
    // todo: remove Culture.currentCulture

    // todo: set default calendar from [_calendar]
  }

  static String _timeZoneId;
  static String _locale;
  // ignore: unused_field
  static String _numberingSystem;
  // ignore: unused_field
  static String _calendar;
  // ignore: unused_field
  static String _yearFormat;
  // ignore: unused_field
  static String _monthFormat;
  // ignore: unused_field
  static String _dayFormat;

  // {locale: en-US, numberingSystem: latn, calendar: gregory, timeZone: America/New_York, year: numeric, month: numeric, day: numeric}
  static _readIntlObject() {
    try {
      JsObject options = context['Intl']
          .callMethod('DateTimeFormat')
          .callMethod('resolvedOptions');

      _locale = options['locale'];
      _timeZoneId = options['timeZone'];
      _numberingSystem = options['numberingSystem'];
      _calendar = options['calendar'];
      _yearFormat = options['year'];
      _monthFormat = options['month'];
      _dayFormat = options['day'];
    }
    catch (e, s) {
      print('Failed to get platform local information.\n$e\n$s');
    }
  }
}
