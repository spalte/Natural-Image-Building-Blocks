//  Created by Joël Spaltenstein on 10/15/15.
//  Copyright (c) 2017 Spaltenstein Natural Image
//  Copyright (c) 2017 Michael Hilker and Andreas Holzamer
//  Copyright (c) 2017 volz io
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "NIAgeFormatter.h"

@implementation NIAgeFormatter

@synthesize ageStyle = _ageStyle;
@synthesize referenceDate = _referenceDate;

- (void)dealloc
{
    [_referenceDate release];
    _referenceDate = nil;

    [super dealloc];
}

- (NSString *)stringFromDate:(NSDate *)date
{
    return [self stringForObjectValue:date];
}

- (NSString *)stringForObjectValue:(id)anObject
{
    if ([anObject isKindOfClass:[NSDate class]]) {
        NSDate *birthdate = (NSDate *)anObject;

        NSDate *referenceDate = self.referenceDate;
        if (referenceDate == nil) {
            referenceDate = [NSDate date];
        }
        NSDateComponents* ageComponents = [[NSCalendar calendarWithIdentifier:NSCalendarIdentifierISO8601]
                                           components:NSCalendarUnitYear
                                           fromDate:birthdate
                                           toDate:referenceDate
                                           options:0];
        NSInteger age = [ageComponents year];

        NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
        [dateFormatter setCalendar:[NSCalendar calendarWithIdentifier:NSCalendarIdentifierISO8601]];
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];

        NSString *birthDateString = [dateFormatter stringFromDate:birthdate];

        return [NSString stringWithFormat:@"%@ (%lld)", birthDateString, (long long)age];
    } else {
        return nil;
    }
}

- (BOOL)getObjectValue:(id*)anObject forString:(NSString *)string errorDescription:(NSString **)error
{
    return NO;
}


@end
