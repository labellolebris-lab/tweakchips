#import <UIKit/UIKit.h>

@interface SBDockView : UIView
@end

static const NSInteger kGlassTag = 0xC41B;

%hook SBDockView
- (void)layoutSubviews {
    %orig;
    UIVisualEffectView *glass = (UIVisualEffectView *)[self viewWithTag:kGlassTag];
    if (!glass) {
        glass = [[UIVisualEffectView alloc] initWithEffect:
            [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterial]];
        glass.tag = kGlassTag;
        glass.userInteractionEnabled = NO;
        glass.clipsToBounds = YES;
        glass.layer.cornerRadius = 30;
        glass.layer.borderWidth = 0.5;
        glass.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.35].CGColor;
        [self insertSubview:glass atIndex:0];
    }
    glass.frame = CGRectInset(self.bounds, 8, 4);
}
%end
