#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface SBDockView : UIView
@end

@interface MTMaterialView : UIView
@end

static NSString *const kGlassLayerName = @"ChipsGlassLayer";

static void ChipsApplyGlass(UIView *view, CALayer *host) {
    CGRect b = view.bounds;
    CGSize s = UIScreen.mainScreen.bounds.size;
    if (b.size.width < 24 || b.size.height < 24) return;
    if (b.size.width >= s.width && b.size.height >= s.height) return;

    CAGradientLayer *g = nil;
    for (CALayer *l in host.sublayers) {
        if ([l.name isEqualToString:kGlassLayerName]) { g = (CAGradientLayer *)l; break; }
    }

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    if (!g) {
        g = [CAGradientLayer layer];
        g.name = kGlassLayerName;
        g.colors = @[
            (id)[UIColor colorWithWhite:1.0 alpha:0.38].CGColor,
            (id)[UIColor colorWithWhite:1.0 alpha:0.04].CGColor,
            (id)[UIColor colorWithWhite:1.0 alpha:0.16].CGColor
        ];
        g.locations = @[@0.0, @0.5, @1.0];
        g.startPoint = CGPointMake(0.0, 0.0);
        g.endPoint = CGPointMake(1.0, 1.0);
        g.borderWidth = 0.6;
        g.borderColor = [UIColor colorWithWhite:1.0 alpha:0.45].CGColor;
        [host addSublayer:g];
    }
    g.frame = host.bounds;
    g.cornerRadius = view.layer.cornerRadius;
    [CATransaction commit];
}

%hook UIVisualEffectView
- (void)layoutSubviews {
    %orig;
    ChipsApplyGlass(self, self.contentView.layer);
}
%end

%hook MTMaterialView
- (void)layoutSubviews {
    %orig;
    ChipsApplyGlass(self, self.layer);
}
%end

%hook SBDockView
- (void)layoutSubviews {
    %orig;
    static const NSInteger kGlassTag = 0xC41B;
    UIVisualEffectView *glass = (UIVisualEffectView *)[self viewWithTag:kGlassTag];
    if (!glass) {
        glass = [[UIVisualEffectView alloc] initWithEffect:
            [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
        glass.tag = kGlassTag;
        glass.userInteractionEnabled = NO;
        glass.clipsToBounds = YES;
        glass.layer.cornerRadius = 30;
        [self insertSubview:glass atIndex:0];
    }
    glass.frame = CGRectInset(self.bounds, 8, 4);
}
%end
