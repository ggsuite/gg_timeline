// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_typedefs/gg_typedefs.dart';

import 'gg_timeline_item.dart';

// #############################################################################
/// The baseclass of timelines with items of type T
abstract class GgTimeline<T> {
  /// Constructor
  GgTimeline() {
    _init();
  }

  // ...........................................................................
  /// Init a timeline with a list of items
  GgTimeline.withItems(Iterable<GgTimelineItem<T>> items) {
    assert(items.isNotEmpty);
    _items.addAll(items);
    _currentItem = items.first;
    _indexOfCurrentItem = 0;
  }

  // ...........................................................................
  /// Returns the initial item. The seed will be initially put on t = 0.
  T get seed;

  // ...........................................................................
  /// Returns true if timeline is an initial timeline
  bool get isInitial => _items.length == 1 && _items.first.data == seed;

  // ...........................................................................
  /// Returns all items
  List<GgTimelineItem<T>> get items => _items;

  // ...........................................................................
  /// Returns the item for a given time
  GgTimelineItem<T> item(GgSeconds timePosition) {
    jumpToOrBefore(timePosition);
    return _currentItem;
  }

  // ...........................................................................
  /// Returns n future items starting after the given time position.
  Iterable<GgTimelineItem<T>> futureItems({
    required GgSeconds timePosition,
    required int count,
    bool Function(GgTimelineItem<T>)? where,
  }) {
    jumpToOrBefore(timePosition);

    // If time is before start of song, also the first item is a future item.
    // Otherwise future items are all items behind the current item
    var index = timePosition >= 0
        ? _indexOfCurrentItem + 1
        : _indexOfCurrentItem;

    final result = <GgTimelineItem<T>>[];

    while (index < _items.length && result.length < count) {
      final item = _items[index];
      if (where == null || where(item)) {
        result.add(item);
      }
      index++;
    }

    return result;
  }

  // ...........................................................................
  /// Returns n past items starting at the given time position.
  Iterable<GgTimelineItem<T>> pastItems({
    required GgSeconds timePosition,
    required int count,
    bool Function(GgTimelineItem<T>)? where,
  }) {
    jumpToOrBefore(timePosition);

    var index = _currentItem.validTo < timePosition
        ? _indexOfCurrentItem
        : _indexOfCurrentItem - 1;

    final result = <GgTimelineItem<T>>[];

    while (index >= 0 && result.length < count) {
      final item = _items[index];
      if (where == null || where(item)) {
        result.add(item);
      }
      index--;
    }

    return result.reversed;
  }

  // ######################
  // Protected
  // ######################

  // ...........................................................................
  /// Jump to the beginning in the timeline
  void jumpToBeginning() {
    _currentItem = items.first;
    _indexOfCurrentItem = 0;
  }

  // ...........................................................................
  /// Makes the item exactly starting on [timePosition] the current item.
  /// If no item exactly starts on [timePosition], the item before time position
  /// will become current item.
  void jumpToOrBefore(GgSeconds timePosition) {
    if (timePosition >= _currentItem.validFrom &&
        (timePosition < _currentItem.validTo || _currentItem.duration == 0.0)) {
      return;
    }

    final startIndex = _indexOfCurrentItem;

    // Find or item in future
    var index = startIndex;
    if (timePosition > _currentItem.validFrom) {
      while (++index < items.length) {
        final snapShot = items[index];
        if (snapShot.validFrom > timePosition) {
          break;
        }
        _indexOfCurrentItem = index;
        _currentItem = snapShot;
      }
    }
    // Find item in past
    else {
      while (--index >= 0) {
        final snapShot = items[index];
        _indexOfCurrentItem = index;
        _currentItem = snapShot;

        if (snapShot.validFrom <= timePosition) {
          break;
        }
      }
    }
  }

  // ...........................................................................
  /// Returns the current item
  GgTimelineItem<T> get currentItem => _currentItem;

  // ...........................................................................
  /// Returns the next item.
  /// Returns the last item when no following item is available
  GgTimelineItem<T> get nextItem => _indexOfCurrentItem == _items.length - 1
      ? _currentItem
      : _items[_indexOfCurrentItem + 1];

  // ...........................................................................
  /// Use this method to replace an existing on given time position.
  /// Return true, if such an item is available or false if not.
  bool tryToReplaceExistingItem({
    required T data,
    required GgSeconds timePosition,
  }) {
    if (timePosition == _currentItem.validFrom) {
      _currentItem = _currentItem.copyWith(data: data);
      _items[_indexOfCurrentItem] = _currentItem;
      return true;
    }

    return false;
  }

  // ...........................................................................
  /// Will update the data of an existing item starting on [timePosition].
  /// If such an item is not existing, a new item will be inserted into the
  /// timeline. The duration of the previous item will change subsequently.
  void addOrReplaceItem({required T data, required GgSeconds timePosition}) {
    jumpToOrBefore(timePosition);

    // Just replace last item when possible
    if (tryToReplaceExistingItem(data: data, timePosition: timePosition)) {
      return;
    }

    // Update validTo at previousItem
    _currentItem = _currentItem.copyWith(validTo: timePosition);
    _items[_indexOfCurrentItem] = _currentItem;

    // Estimate validTo value
    final validTo = _currentItem == _items.last
        ? timePosition
        : _items[_indexOfCurrentItem + 1].validFrom;

    // Insert a new item
    final newItem = createItem(
      data: data,
      validFrom: timePosition,
      validTo: validTo,
    );

    _items.insert(_indexOfCurrentItem + 1, newItem);
  }

  // ...........................................................................
  /// Creates a new item without inserting it into the timeline.
  GgTimelineItem<T> createItem({
    required T data,
    required GgSeconds validFrom,
    required GgSeconds validTo,
  }) => GgTimelineItem<T>(validFrom: validFrom, validTo: validTo, data: data);

  // ######################
  // Private
  // ######################

  // ...........................................................................
  final _items = <GgTimelineItem<T>>[];
  var _indexOfCurrentItem = 0;
  late GgTimelineItem<T> _currentItem;

  // ...........................................................................
  void _init() {
    _initInitialItem();
  }

  // ...........................................................................
  void _initInitialItem() {
    _currentItem = createItem(data: seed, validFrom: 0.0, validTo: 0.0);

    _indexOfCurrentItem = 0;
    _items.add(_currentItem);
  }
}

// #############################################################################
/// A example timeline that can be used for test purposes.
class ExampleTimeline extends GgTimeline<double> {
  /// Creates an example timeline for test purposes
  ExampleTimeline({int numItems = 20}) {
    _addFurtherItems(numItems);
  }

  // ...........................................................................
  /// Create an timeline from a given list of timeline items
  ExampleTimeline.withItems(super.items) : super.withItems();

  // ...........................................................................
  /// The inital value inserted on the timeline
  @override
  double get seed => 0.0;

  // ######################
  // Private
  // ######################

  void _addFurtherItems(int numItems) {
    for (int i = 0; i < numItems; i++) {
      addOrReplaceItem(data: i.toDouble(), timePosition: i.toDouble());
    }
  }
}

/// Create a new [ExampleTimeline] instance.
GgTimeline<double> exampleGgTimeline() => ExampleTimeline();
