// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_typedefs/gg_typedefs.dart';

/// Defines a item of music xml data for a given time position
class GgTimelineItem<T> {
  const GgTimelineItem({
    required this.validFrom,
    required this.validTo,
    required this.data,
  });

  final GgSeconds validFrom;
  final GgSeconds validTo;
  final T data;

  GgSeconds get duration => validTo - validFrom;

  // ...........................................................................
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
  @override
  int get hashCode => validFrom.hashCode ^ validTo.hashCode ^ data.hashCode;
}

// #############################################################################
const exampleGgTimelineItem = GgTimelineItem<int>(
  validFrom: 0.0,
  validTo: 0.0,
  data: 0,
);
