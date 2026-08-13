// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_typedefs/gg_typedefs.dart';

/// An item on an GgTimelin
class GgTimelineItem<T> {
  /// - [validFrom] the start time position of the item
  /// - [validTo] the excluded end time position of the item
  /// - [data] the data of the timeline item
  const GgTimelineItem({
    required this.validFrom,
    required this.validTo,
    required this.data,
  });

  /// The start position of the item on the timeline
  final GgSeconds validFrom;

  /// The excluded end position of the item on the timeline
  final GgSeconds validTo;

  /// The data of the timeline item
  final T data;

  /// The duration of the timeline item
  GgSeconds get duration => validTo - validFrom;

  // ...........................................................................
  /// Create a copy of the item with different position, duration or data
  GgTimelineItem<T> copyWith({
    GgSeconds? validFrom,
    GgSeconds? validTo,
    T? data,
  }) {
    return GgTimelineItem(
      validFrom: validFrom ?? this.validFrom,
      validTo: validTo ?? this.validTo,
      data: data ?? this.data,
    );
  }

  // ...........................................................................
  /// Compare two timeline items
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (runtimeType == other.runtimeType &&
            (other is GgTimelineItem) &&
            (other.validFrom == validFrom) &&
            (other.validTo == validTo) &&
            (other.data == data));
  }

  // ...........................................................................
  /// The hashcode of the timeline item
  @override
  int get hashCode => validFrom.hashCode ^ validTo.hashCode ^ data.hashCode;
}

// #############################################################################
/// An example timeline item used for tests
const exampleGgTimelineItem = GgTimelineItem<int>(
  validFrom: 0.0,
  validTo: 0.0,
  data: 0,
);
