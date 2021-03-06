// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';

import 'package:test/test.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';

import '../time_machine_testing.dart';

DateTimeZone Paris;
DateTimeZoneProvider Tzdb;

// Until 1911, Paris was 9 minutes and 21 seconds off UTC.
Offset InitialOffset = TestObjects.CreatePositiveOffset(0, 9, 21);

/// Tests for the Paris time zone. This exercises functionality within various classes.
/// Paris varies between +1 (standard) and +2 (DST); transitions occur at 2am or 3am wall time,
/// which is always 1am UTC.
/// 2009 fall transition: October 25th
/// 2010 spring transition: March 28th
/// 2010 fall transition: October 31st
/// 2011 spring transition: March 27th
Future main() async {
  await TimeMachine.initialize();
  await setup();

  await runTests();
}

Future setup() async {
  Tzdb = await DateTimeZoneProviders.tzdb;
  // Make sure we deal with the uncached time zone
  Paris = Uncached(await Tzdb["Europe/Paris"]);
}

@Test()
void FirstTransitions()
{
  // Paris had a name change in 1891, and then moved from +0:09:21 to UTC in 1911
  var nameChangeInstant = new Instant.utc(1891, 3, 14, 23, 51, 39);
  var utcChangeInstant = new Instant.utc(1911, 3, 10, 23, 51, 39);

  var beforeNameChange = Paris.getZoneInterval(nameChangeInstant - Time.epsilon);
  var afterNameChange = Paris.getZoneInterval(nameChangeInstant);
  var afterSmallChange = Paris.getZoneInterval(utcChangeInstant);

  expect("LMT", beforeNameChange.name);
  expect(InitialOffset, beforeNameChange.wallOffset);

  expect("PMT", afterNameChange.name);
  expect(InitialOffset, afterNameChange.wallOffset);

  expect("WET", afterSmallChange.name);
  expect(Offset.zero, afterSmallChange.wallOffset);
}

