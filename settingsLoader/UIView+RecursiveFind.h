#import <UIKit/UIKit.h>


@interface UIView (RecursiveFind)
- (NSArray *)siblingsInclusive:(BOOL)include;// inclusive means we include ourselves as well
- (BOOL)darkMode;
- (id) clone;
- (UIImage *)snapshotViewWithSize:(CGSize)size;
- (UIImage *) snapshotView;
- (UIView *)findFirstSubviewWithClass:(Class)theClass;
- (void)printRecursiveDescription;
- (void)removeAllSubviews;
- (void)printAutolayoutTrace;
//- (NSString *)recursiveDescription;
//- (id)_recursiveAutolayoutTraceAtLevel:(long long)arg1;
@end

