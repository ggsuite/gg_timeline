// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_timeline/gg_timeline.dart';
import 'package:test/test.dart';

void main() {
  late GgTimeline<double> timeline;
  late GgTimelineItem<double> firstItem;
  late GgTimelineItem<double> secondItem;
  late GgTimelineItem<double> lastItem;
  late GgTimelineItem<double> secondLastItem;

  setUp(() {
    timeline = exampleGgTimeline();
    timeline.jumpToBeginning();

    firstItem = timeline.items[0];
    secondItem = timeline.items[1];
    lastItem = timeline.items[timeline.items.length - 1];
    secondLastItem = timeline.items[timeline.items.length - 2];
  });

  group('GgTimeline', () {
    // #########################################################################
    group('initialization', () {
      test('should work fine', () {
        expect(timeline, isNotNull);
        expect(timeline.items.length, 20);

        final item0a = timeline.item(0.0);
        final item0b = timeline.item(0.0);
        expect(item0a, same(item0b));
        expect(item0a, firstItem);
        expect(item0a.validFrom, 0.0);
        expect(item0a.validTo, 1.0);

        expect(timeline.item(1.0).validFrom, 1.0);
        expect(timeline.item(1.0).validTo, 2.0);
        expect(timeline.seed, 0);
      });
    });

    // #########################################################################
    group('withItems(items)', () {
      test('asserts that items are not empty', () {
        expect(
          () => ExampleTimeline.withItems([]),
          throwsA(const TypeMatcher<AssertionError>()),
        );
      });

      test('creates a timeline with predefined set of items', () {
        final timelineA = exampleGgTimeline();
        final timelineB = ExampleTimeline.withItems(timelineA.items);
        expect(timelineB.item(11.5), timelineA.item(11.5));
      });
    });

    group('currentItem, nextItem, jumpToOrBefore, jumpToBeginning', () {
      test('should set current item to the right one', () {
        expect(timeline.currentItem, firstItem);
        expect(timeline.nextItem, timeline.items[1]);
        timeline.jumpToOrBefore(100);
        expect(timeline.currentItem, lastItem);
        expect(timeline.nextItem, lastItem);
        timeline.jumpToOrBefore(0.0);
        expect(timeline.currentItem, firstItem);
        expect(timeline.nextItem, timeline.items[1]);
      });
    });

    group('tryToReplaceLastItem', () {
      test('should replace last item if time matches, otherwise not', () {
        expect(timeline.currentItem, firstItem);
        timeline.jumpToOrBefore(100);

        const replacedData = 50.0;

        // Time does not match -> dont' replace
        var didReplace = timeline.tryToReplaceExistingItem(
          data: replacedData,
          timePosition: 123890,
        );

        expect(didReplace, isFalse);

        // Time does match -> replace
        didReplace = timeline.tryToReplaceExistingItem(
          data: 50,
          timePosition: lastItem.validFrom,
        );

        expect(didReplace, isTrue);
        expect(timeline.items.last.data, replacedData);
      });
    });

    group('addOrReplaceItem', () {
      const data = 123.0;

      test('should replace an existing item with the same timePosition', () {
        final existingItem = timeline.currentItem;
        expect(existingItem, timeline.items.first);
        timeline.addOrReplaceItem(
          data: data,
          timePosition: existingItem.validFrom,
        );
        expect(timeline.items.first.data, data);
      });

      test('should add an item if no item with same time position exists.', () {
        final validFrom = lastItem.validFrom + 1;
        timeline.addOrReplaceItem(data: data, timePosition: validFrom);

        expect(timeline.items.last.data, data);
        expect(timeline.items.last.validFrom, validFrom);
      });

      test(
        'should insert an item if no item with same time position exists.',
        () {
          // Check item count before
          final itemCountBefore = timeline.items.length;

          // Insert item in the middle between first and second item
          timeline.addOrReplaceItem(data: 0.5, timePosition: 0.5);
          expect(timeline.items.length, itemCountBefore + 1);

          final addedItem = timeline.item(0.5);
          expect(addedItem, timeline.items[1]);

          // Now the previous item should only endure to the inserted one
          expect(timeline.items.first.validTo, 0.5);
          expect(timeline.items.first.duration, 0.5);

          // The new item should last to the next one
          expect(addedItem.validFrom, 0.5);
          expect(addedItem.validTo, 1.0);
        },
      );

      test('should update previous item\'s validTo value.', () {
        // Check the last item's validTo value
        final lastItemValidFrom = timeline.items.last.validFrom;
        final lastItemDuration = timeline.items.last.duration;
        expect(lastItemValidFrom, 19.0);
        expect(lastItemDuration, 0.0);

        // Add another item one second after last item
        const timeDifference = 1.0;
        final addedItemValidFrom = lastItemValidFrom + timeDifference;
        timeline.addOrReplaceItem(data: data, timePosition: addedItemValidFrom);
        final addedItem = timeline.items.last;

        // Did previously last items duration as well validTo increase?
        final secondLastItem = timeline.items[timeline.items.length - 2];
        expect(secondLastItem.validFrom, 19.0);
        expect(secondLastItem.duration, timeDifference);
        expect(secondLastItem.validTo, addedItem.validFrom);
      });
    });

    // #########################################################################
    group('futureItems(timePosition, n, where)', () {
      test('should return the n first items when timePosition is '
          'before beginning', () {
        const count = 2;
        final futureItems = timeline.futureItems(
          timePosition: -0.001,
          count: count,
        );

        expect(futureItems.first, firstItem);
        expect(futureItems.length, count);
      });

      test('should return n items behind timePosition', () {
        const count = 2;
        final futureItems = timeline.futureItems(timePosition: 0, count: count);

        final secondItem = timeline.items[1];
        expect(futureItems.first, secondItem);
        expect(futureItems.length, count);
      });

      test('should return available items if count is too big', () {
        const count = 10000;
        final futureItems = timeline.futureItems(
          timePosition: -0.001,
          count: count,
        );

        expect(futureItems.first, firstItem);
        expect(futureItems.length, timeline.items.length);
      });

      test('should return available items if not enough items are available '
          'anymore', () {
        const count = 5;

        final secondLastItem = timeline.items[timeline.items.length - 2];

        final futureItems = timeline.futureItems(
          timePosition: secondLastItem.validFrom,
          count: count,
        );

        expect(futureItems.first, lastItem);
        expect(futureItems.length, 1);
      });

      test('should filter items using "where" filter', () {
        final futureItems = timeline
            .futureItems(
              count: 2,
              timePosition: 0.0,
              where: (p0) => p0.data >= 10,
            )
            .map((e) => e.data)
            .toList();

        expect(futureItems, [10.0, 11.0]);
      });
    });

    // #########################################################################
    group('pastItems(timePosition, n, where)', () {
      group('should return right past items', () {
        test('when timePosition is before start of the timeline', () {
          final pastItems = timeline.pastItems(timePosition: -0.5, count: 2);

          expect(pastItems, <GgTimelineItem<double>>[]);
        });

        test('when timePosition is at the beginning of the timeline', () {
          final pastItems = timeline.pastItems(timePosition: 0, count: 2);

          expect(pastItems, <GgTimelineItem<double>>[]);
        });

        test(
          'when timePosition is shortly after beginning of the timeline',
          () {
            final pastItems = timeline.pastItems(timePosition: 0.5, count: 2);

            expect(pastItems, <GgTimelineItem<double>>[]);
          },
        );

        test('when timePosition is shortly before the end of the first item on '
            'the timeline', () {
          final pastItems = timeline.pastItems(
            timePosition: firstItem.validTo - 0.1,
            count: 2,
          );

          expect(pastItems, <GgTimelineItem<double>>[]);
        });

        test(
          'when timePosition is at the end of the first item on the timeline',
          () {
            final pastItems = timeline.pastItems(
              timePosition: firstItem.validTo,
              count: 2,
            );

            expect(pastItems, [firstItem]);
          },
        );

        test('when timePosition is shortly after the end of the first item on '
            'the timeline', () {
          final pastItems = timeline.pastItems(
            timePosition: firstItem.validTo + 0.1,
            count: 2,
          );

          expect(pastItems, [firstItem]);
        });

        test('when timePosition is after the second item on the timeline', () {
          final pastItems = timeline.pastItems(
            timePosition: secondItem.validTo + 0.1,
            count: 2,
          );

          expect(pastItems, [firstItem, secondItem]);
        });

        test('when timePosition is after the last item on the timeline', () {
          final pastItems = timeline.pastItems(
            timePosition: lastItem.validTo + 0.1,
            count: 2,
          );

          expect(pastItems, [secondLastItem, lastItem]);
        });

        test(
          'when timePosition is far after the last item on the timeline',
          () {
            final pastItems = timeline.pastItems(
              timePosition: lastItem.validTo + 1000,
              count: 2,
            );

            expect(pastItems, [secondLastItem, lastItem]);
          },
        );

        test('when filter is given', () {
          final pastItems = timeline
              .pastItems(
                timePosition: lastItem.validTo,
                count: 2,
                where: (p0) => p0.data <= 5.0,
              )
              .map((e) => e.data);

          expect(pastItems, [4.0, 5.0]);
        });
      });
    });

    // #########################################################################
    group('isInitial)', () {
      test('should return true if timeline contains only the seed item', () {
        final timeline = ExampleTimeline(numItems: 0);
        expect(timeline.isInitial, true);
      });
    });
  });
}
