#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface SBIconImageView : UIView
@end

static NSString *const kDomain = @"net.adist.chipsglass";
static NSString *const kModeName = @"ChipsMode";
static NSString *const kTintName = @"ChipsTint";
static NSString *const kSpecName = @"ChipsSpec";
static NSString *const kRimName = @"ChipsRim";

static BOOL gEnabled = YES;
static NSString *gMode = @"auto";
static NSString *gTint = @"none";
static CGFloat gIntensity = 0.6;
static NSHashTable *gViews;

static void LoadPrefs(void) {
    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:kDomain];
    [d synchronize];
    id e = [d objectForKey:@"enabled"];
    gEnabled = e ? [e boolValue] : YES;
    gMode = [d stringForKey:@"mode"] ?: @"auto";
    gTint = [d stringForKey:@"tint"] ?: @"none";
    id i = [d objectForKey:@"intensity"];
    gIntensity = i ? [i floatValue] : 0.6;
}

static NSString *ResolveMode(void) {
    if (![gMode isEqualToString:@"auto"]) return gMode;
    NSInteger h = [[NSCalendar currentCalendar] component:NSCalendarUnitHour
                                                 fromDate:[NSDate date]];
    return (h >= 19 || h < 7) ? @"dark" : @"light";
}

static UIColor *TintColor(NSString *name) {
    NSDictionary *m = @{
        @"blue":   [UIColor colorWithRed:0.04 green:0.52 blue:1.00 alpha:1],
        @"pink":   [UIColor colorWithRed:1.00 green:0.30 blue:0.60 alpha:1],
        @"red":    [UIColor colorWithRed:1.00 green:0.23 blue:0.19 alpha:1],
        @"orange": [UIColor colorWithRed:1.00 green:0.58 blue:0.00 alpha:1],
        @"green":  [UIColor colorWithRed:0.20 green:0.78 blue:0.35 alpha:1],
        @"purple": [UIColor colorWithRed:0.69 green:0.32 blue:0.87 alpha:1],
        @"mono":   [UIColor grayColor]
    };
    return m[name];
}

static CALayer *FindSub(CALayer *host, NSString *name) {
    for (CALayer *l in host.sublayers) {
        if ([l.name isEqualToString:name]) return l;
    }
    return nil;
}

static void RemoveAll(CALayer *host) {
    for (NSString *n in @[kModeName, kTintName, kSpecName, kRimName]) {
        [FindSub(host, n) removeFromSuperlayer];
    }
}

static void Apply(UIView *v) {
    CALayer *host = v.layer;
    CGRect b = v.bounds;

    [CATransaction begin];
    [CATransaction setDisableActions:YES];

    if (!gEnabled || b.size.width < 20) {
        RemoveAll(host);
        [CATransaction commit];
        return;
    }

    CGFloat r = b.size.width * 0.2237;
    NSString *mode = ResolveMode();
    BOOL dark = [mode isEqualToString:@"dark"];
    BOOL clear = [mode isEqualToString:@"clear"];

    // Couche de mode (sombre ou clear)
    CALayer *ml = FindSub(host, kModeName);
    if (dark || clear) {
        if (!ml) {
            ml = [CALayer layer];
            ml.name = kModeName;
            [host addSublayer:ml];
        }
        ml.frame = b;
        ml.cornerRadius = r;
        if (dark) {
            ml.compositingFilter = @"multiplyBlendMode";
            ml.backgroundColor = [UIColor colorWithWhite:0.25 alpha:1].CGColor;
        } else {
            ml.compositingFilter = nil;
            ml.backgroundColor = [UIColor colorWithWhite:1 alpha:0.30].CGColor;
        }
    } else {
        [ml removeFromSuperlayer];
    }

    // Teinte (en mode clear sans couleur, on grise l'icone)
    UIColor *tc = TintColor(gTint);
    CGFloat tintOpacity = gIntensity;
    if (clear && !tc) {
        tc = [UIColor whiteColor];
        tintOpacity = 1.0;
    }
    CALayer *tint = FindSub(host, kTintName);
    if (tc) {
        if (!tint) {
            tint = [CALayer layer];
            tint.name = kTintName;
            tint.compositingFilter = @"colorBlendMode";
            [host addSublayer:tint];
        }
        tint.frame = b;
        tint.cornerRadius = r;
        tint.backgroundColor = tc.CGColor;
        tint.opacity = tintOpacity;
    } else {
        [tint removeFromSuperlayer];
    }

    // Reflet "verre"
    CAGradientLayer *spec = (CAGradientLayer *)FindSub(host, kSpecName);
    if (!spec) {
        spec = [CAGradientLayer layer];
        spec.name = kSpecName;
        spec.colors = @[
            (id)[UIColor colorWithWhite:1 alpha:0.55].CGColor,
            (id)[UIColor colorWithWhite:1 alpha:0.10].CGColor,
            (id)[UIColor colorWithWhite:1 alpha:0.00].CGColor,
            (id)[UIColor colorWithWhite:1 alpha:0.28].CGColor
        ];
        spec.locations = @[@0.0, @0.35, @0.70, @1.0];
        spec.startPoint = CGPointMake(0.1, 0.0);
        spec.endPoint = CGPointMake(0.9, 1.0);
        [host addSublayer:spec];
    }
    spec.frame = b;
    spec.cornerRadius = r;
    spec.opacity = dark ? 0.45 : 1.0;

    // Liseré lumineux
    CALayer *rim = FindSub(host, kRimName);
    if (!rim) {
        rim = [CALayer layer];
        rim.name = kRimName;
        rim.borderWidth = 1.0;
        [host addSublayer:rim];
    }
    rim.frame = b;
    rim.cornerRadius = r;
    rim.borderColor = [UIColor colorWithWhite:1 alpha:(dark ? 0.30 : 0.6)].CGColor;

    // Remet les calques dans le bon ordre (mode, teinte, reflet, liseré)
    for (NSString *n in @[kModeName, kTintName, kSpecName, kRimName]) {
        CALayer *l = FindSub(host, n);
        if (l) {
            [l removeFromSuperlayer];
            [host addSublayer:l];
        }
    }

    [CATransaction commit];
}

static void ReloadAll(void) {
    LoadPrefs();
    dispatch_async(dispatch_get_main_queue(), ^{
        for (UIView *v in gViews.allObjects) Apply(v);
    });
}

static void ReloadNotif(CFNotificationCenterRef c, void *o, CFStringRef n,
                        const void *obj, CFDictionaryRef u) {
    ReloadAll();
}

%hook SBIconImageView
- (void)layoutSubviews {
    %orig;
    [gViews addObject:self];
    Apply(self);
}
%end

%ctor {
    gViews = [NSHashTable weakObjectsHashTable];
    LoadPrefs();
    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(), NULL, ReloadNotif,
        CFSTR("net.adist.chipsglass/reload"), NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately);

    // Vérifie le mode auto (jour/nuit) toutes les 10 minutes
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSTimer scheduledTimerWithTimeInterval:600 repeats:YES block:^(NSTimer *t) {
            ReloadAll();
        }];
    });
}
