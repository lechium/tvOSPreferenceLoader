/*
 
 This is where a lot of the 'magic' happens specifiersFromEntry:sourcePreferenceLoaderBundlePath:title is pulled straight 
 from the iOS version of preferenceloader with some things trimmed out or commented out that cant or wont be reused.
 
 preferenceBundleGroups is called by loadSettingGroups which is the initial entry point for everything.
 
 */

#import "prefs.h"
#import "NSTask.h"
#import <UIKit/UITextInputTraits.h>
#import "TVSPreferences.h"
#import "Log.h"

@implementation NSArray (reverse)

- (NSArray *)reverseArray {
    return [[self reverseObjectEnumerator] allObjects];
}
@end

@implementation UIView (RecursiveFind)

- (NSArray *)siblingsInclusive:(BOOL)include {
    UIView *superview = [self superview];
    if (!superview) return nil;
    __block NSMutableArray *sibs = [[superview subviews] mutableCopy];
    [[superview subviews] enumerateObjectsUsingBlock:^(UIView  *_Nonnull subview, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![subview isMemberOfClass:[self class]]){
            [sibs removeObject:subview];
            NSLog(@"removing object: %@", subview);
        }
    }];
    if (!include){
        [sibs removeObject:self];
    }
    return [sibs reverseArray];
}

- (BOOL)darkMode {
    
    if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark){
        return TRUE;
    }
    return FALSE;
}

- (UIView *)findFirstSubviewWithClass:(Class)theClass {
    if ([self isKindOfClass:theClass]) {
            return self;
        }
    for (UIView *v in self.subviews) {
        UIView *theView = [v findFirstSubviewWithClass:theClass];
        if (theView != nil){
            return theView;
        }
    }
    return nil;
}

- (void)removeAllSubviews {
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
}

@end

@implementation TSKTableViewController (preferenceLoader)

-(UITableViewCell *)cellFromSettingsItem:(TSKSettingItem *)settingsItem {
    NSArray *cells = [self tableViewCells];
    __block id object = nil;
    [cells enumerateObjectsUsingBlock:^(TSKTableViewTextCell  *_Nonnull cell, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([cell item] == settingsItem){
            object = cell;
            *stop = true;
        }
    }];
    return object;
}

- (NSArray *)tableViewCells {
    UITableView *tv = [self tableView];
    UITableViewCell *firstCell = (UITableViewCell*)[tv findFirstSubviewWithClass:[UITableViewCell class]];
    if (firstCell){
        return [firstCell siblingsInclusive:true];
    }
    return nil;
}
@end

@implementation TSKSettingItem (preferenceLoader)

+ (BOOL)environmentPassesPreferenceLoaderFilter:(NSDictionary *)filter {
    
    if(!filter) return YES;
    bool valid = YES;
    NSLog(@"Checking filter %@", filter);
    NSArray *coreFoundationVersion = [filter objectForKey:@"CoreFoundationVersion"];
    if(coreFoundationVersion && coreFoundationVersion.count > 0) {
        NSNumber *lowerBound = [coreFoundationVersion objectAtIndex:0];
        NSNumber *upperBound = coreFoundationVersion.count > 1 ? [coreFoundationVersion objectAtIndex:1] : nil;
        NSLog(@"%@ <= CF Version (%f) < %@", lowerBound, kCFCoreFoundationVersionNumber, upperBound);
        valid = valid && (kCFCoreFoundationVersionNumber >= lowerBound.floatValue);
        
        if(upperBound)
            valid = valid && (kCFCoreFoundationVersionNumber < upperBound.floatValue);
    }
    NSLog(valid ? @"Filter matched" : @"Filter did not match");
    return valid;
}

//- (NSBundle *)preferenceLoaderBundle {
//    return [self propertyForKey:PLBundleKey];
//}

-(NSDictionary *)specifier {
    NSDictionary *specifier = objc_getAssociatedObject(self, @selector(specifier));
    //NSLog(@" %@ specifier: %@", self, specifier);
    return specifier;
}

- (void)setSpecifier:(NSDictionary*)specifier {
    //NSLog(@"%@ setSpecifier: %@", self, specifier);
    objc_setAssociatedObject(self, @selector(specifier), specifier, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(PLCustomListViewController *)controller {
    PLCustomListViewController *controller = objc_getAssociatedObject(self, @selector(controller));
    return controller;
}

- (void)setController:(PLCustomListViewController*)controller {
    objc_setAssociatedObject(self, @selector(controller), controller, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (TSKPreviewViewController *)previewViewController
{
    TSKPreviewViewController *previewViewController = objc_getAssociatedObject(self, @selector(previewViewController));
    return previewViewController;
}

- (void)setPreviewViewController:(TSKPreviewViewController *)previewViewController {
    objc_setAssociatedObject(self, @selector(previewViewController), previewViewController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end

@implementation UINavigationController (convenience)

- (TSKTableViewController *)previousViewController {
    NSInteger vcCount = [[self viewControllers] count];
    if (vcCount == 1){
        return (TSKTableViewController*)[self visibleViewController];
    }
    NSInteger desiredIndex = vcCount - 2;
    return (TSKTableViewController*)[self viewControllers][desiredIndex];
}

@end

/* {{{ Constants */
static NSString *const PLBundleKey = @"pl_bundle";
NSString *const PLFilterKey = @"pl_filter";
static NSString *const PLAlternatePlistNameKey = @"pl_alt_plist_name";
/* }}} */

/*
 
 This is where it converts our plist entries into TSKSettingGroups/Items that can actually be displayed in TVSettings. If applicable.
 
 
 */

@implementation TSKViewController (science)

- (NSArray *)menuItemsFromItems:(NSArray *)items {
    /* these plists are kind of dumb imo, you need to loop through the items but the way you dilineate groups is they start and stop when the next group is found.
     
     ie Group 1 | Item 1 | Item 2 | Group 2 | Item 3 | Item 4 | Group 3 ... so item 1&2 would be in group 1, 3 & 4 in Group 2 etc..
     */
    
    __block NSMutableArray *groups = [NSMutableArray new];
    __block NSString *currentGroupName = nil;
    __block NSMutableArray *currentGroupItems = [NSMutableArray new];
    __block BOOL haveGroups = FALSE;
    [items enumerateObjectsUsingBlock:^(NSDictionary  *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSString *cell = obj[@"cell"];
        NSString *label = obj[@"label"];
        
        if ([cell isEqualToString:@"PSGroupCell"]){
            
            if (currentGroupItems.count < 1){ //we might not have any group items yet!
                currentGroupName = label;
                //NSLog(@"no groups yet, starting with group name: %@", label);
                haveGroups = TRUE;
                
            } else {
                
                //NSLog(@"we already have a group: %@ adding items %@", currentGroupName, currentGroupItems);
                TSKSettingGroup *groupItem = [TSKSettingGroup groupWithTitle:currentGroupName settingItems:currentGroupItems];
                [groups addObject:groupItem];
                currentGroupName = label;
                //NSLog(@"starting a new group: %@", currentGroupName);
                [currentGroupItems removeAllObjects];
            }
            
        } else if ([cell isEqualToString:@"PSSwitchCell"]){
            
            NSString *key = obj[@"key"];
            NSString *label = obj[@"label"];
            NSString *description = obj[@"description"];
            BOOL defaultOn = [obj[@"default"] boolValue];
            id facade = nil;
            NSString *domain = obj[@"defaults"];
            //NSString *postNotification = obj[@"PostNotification"];
            facade = [[NSClassFromString(@"TVSettingsPreferenceFacade") alloc] initWithDomain:domain notifyChanges:TRUE];
            TSKSettingItem *settingsItem = [TSKSettingItem toggleItemWithTitle:label description:description representedObject:facade keyPath:key onTitle:nil offTitle:nil];
            if (defaultOn){
                [settingsItem setDefaultValue:@1];
            } else {
                [settingsItem setDefaultValue:@0];
            }
            //NSLog(@"created settings item: %@", settingsItem);
            
            [currentGroupItems addObject:settingsItem];
            //NSLog(@"currentGroupItems: %@", currentGroupItems);
            
        } else if ([cell isEqualToString:@"PSEditTextCell"] || [cell isEqualToString:@"PSSecureEditTextCell"]) {
            
            BOOL secure = [cell containsString:@"Secure"];
            NSString *key = obj[@"key"];
            NSString *label = obj[@"label"];
            if (!label){
                label = obj[@"prompt"];
            }
            NSString *description = obj[@"description"];
            NSString *domain = obj[@"defaults"];
            NSString *keyboardType = obj[@"keyboard"]; //numbers or phone
            NSString *autoCaps = obj[@"autoCaps"]; //sentences, words, all
            BOOL isIP = [obj[@"isIP"] boolValue]; //use numbers keyboard
            BOOL isURL = [obj[@"isURL"] boolValue]; //use URL keyboard
            BOOL isNumeric = [obj[@"isNumeric"] boolValue]; //use numeric keyboard
            BOOL isEmail = [obj[@"isEmail"] boolValue]; //use email keyboard
            BOOL noAutoCorrect = [obj[@"noAutoCorrect"] boolValue]; //turn off auto-correct
            
            id facade = [[NSClassFromString(@"TVSettingsPreferenceFacade") alloc] initWithDomain:domain notifyChanges:TRUE];
            
            TSKTextInputSettingItem *textEntryItem =  [TSKTextInputSettingItem textInputItemWithTitle:label description:description representedObject:facade keyPath:key];
            if(secure) {
                textEntryItem.secure = TRUE;
            }
            if (keyboardType){
                if ([keyboardType isEqualToString:@"numbers"]){
                    [textEntryItem setKeyboardType:UIKeyboardTypeNumbersAndPunctuation];
                } else if ([keyboardType isEqualToString:@"phone"]){
                    [textEntryItem setKeyboardType:UIKeyboardTypePhonePad];
                } else {
                    [textEntryItem setKeyboardType:UIKeyboardTypeDefault];
                }
            }
            if (autoCaps){
                if ([autoCaps isEqualToString:@"sentences"]){
                    [textEntryItem setAutocapitalizationType:UITextAutocapitalizationTypeSentences];
                } else if ([autoCaps isEqualToString:@"words"]){
                    [textEntryItem setAutocapitalizationType:UITextAutocapitalizationTypeWords];
                } else if([autoCaps isEqualToString:@"all"]){
                    [textEntryItem setAutocapitalizationType:UITextAutocapitalizationTypeAllCharacters];
                }
            }
            if (isIP){
                [textEntryItem setKeyboardType:UIKeyboardTypeNumbersAndPunctuation];
            }
            if (isURL){
                [textEntryItem setKeyboardType:UIKeyboardTypeURL];
            }
            if (isNumeric){
                [textEntryItem setKeyboardType:UIKeyboardTypeNumbersAndPunctuation];
            }
            if (isEmail){
                [textEntryItem setKeyboardType:UIKeyboardTypeEmailAddress];
            }
            if (noAutoCorrect){
                [textEntryItem setAutocorrectionType:UITextAutocorrectionTypeNo];
            }
            [textEntryItem setKeyboardDetails:obj];
            [currentGroupItems addObject:textEntryItem];
            
        } else if ([cell isEqualToString:@"PSMultiItemCell"] || [cell isEqualToString:@"PSLinkListCell"]) { //new tvOS only special addition :D
            
            NSString *key = obj[@"key"];
            NSString *label = obj[@"label"];
            NSString *description = obj[@"description"];
            NSString *domain = obj[@"defaults"];
            NSString *defaultValue = obj[@"default"];
            NSArray *availableValues = obj[@"availableValues"];
            if (!availableValues){
                availableValues = obj[@"validValues"];
            }
            id facade = [[NSClassFromString(@"TVSettingsPreferenceFacade") alloc] initWithDomain:domain notifyChanges:TRUE];
            TSKSettingItem *multiItem = [TSKSettingItem multiValueItemWithTitle:label description:description representedObject:facade keyPath:key availableValues:availableValues];
            if (defaultValue){
                [multiItem setDefaultValue:defaultValue];
            }
            [currentGroupItems addObject:multiItem];
            
        } else if ([cell isEqualToString:@"PSButtonCell"]) {
            NSString *action = obj[@"action"];
            NSString *label = obj[@"label"];
            NSString *description = obj[@"description"];
            SEL ourAction = NSSelectorFromString(action);
            if (![self respondsToSelector:ourAction]){
                ourAction = NSSelectorFromString(@"showMissingActionAlert");
            }
            TSKSettingItem *actionItem = [TSKSettingItem actionItemWithTitle:label description:description representedObject:nil keyPath:nil target:self action:ourAction];
            
            [currentGroupItems addObject:actionItem];
        } else if ([cell isEqualToString:@"PSLinkCell"]){
            if([[obj objectForKey:@"isController"] boolValue]) {
                
                //NSLog(@"creating TSKSettingItems!");
                
                NSString *iconKey = obj[@"icon"];
                NSString *labelKey = obj[@"label"];
                NSString *bundle = obj[@"bundle"];
                NSString *descriptionKey = obj[@"description"]; //not part of original spec, custom addition.
                //load the bundle so we can get access to the class
                NSBundle *prefBundle = [NSBundle bundleWithName:bundle];
                [prefBundle load];
                NSString *className = prefBundle.infoDictionary[@"NSPrincipalClass"];
                //NSLog(@"class name: %@", className);
                //all items are going to be child panel items for now which allow use to load another class that gives us our groups from said tweak
                //TSKSettingItem *item = [TSKSettingItem childPaneItemWithTitle:labelKey description:descriptionKey representedObject:nil keyPath:nil childControllerClass:NSClassFromString(className)];
                
                TSKSettingItem *item = [TSKSettingItem childPaneItemWithTitle:labelKey description:descriptionKey representedObject:nil keyPath:nil childControllerBlock:^(TSKSettingItem *object) {
                    id controller = [[NSClassFromString(className) alloc] init];
                    NSLog(@"controller: %@", controller);
                    [controller setSpecifier:obj];
                    return controller;
                }];
                
                //this does the magic of loading the class from the bundle
                TSKBundleLoader *bundleLoader = [[TSKBundleLoader alloc] initWithBundle:prefBundle];
                [item setBundleLoader:bundleLoader];
                
                //NSLog(@"iconKey: %@", iconKey);
                
                NSString *iconPath = [prefBundle.bundlePath stringByAppendingPathComponent:iconKey];
                //NSString *iconPath =[[NSBundle mainBundle] pathForResource:[iconKey stringByDeletingPathExtension] ofType:[iconKey pathExtension]];
                
                //NSLog(@"iconPath: %@", iconPath);
                UIImage *image = [UIImage imageWithContentsOfFile:iconPath];
                //NSLog(@"image: %@", image);
                [item setItemIcon:image];
                //NSLog(@"item: %@ icon: %@", item, [item itemIcon]);
                
                TSKPreviewViewController *previewVC = nil;
                if (className) {
                    Class principalClass = NSClassFromString(className);
                    if (principalClass && [principalClass respondsToSelector:@selector(defaultPreviewViewController)]) {
                        previewVC = (TSKPreviewViewController*)[principalClass defaultPreviewViewController];
                    }
                }
                if (previewVC == nil) {
                    previewVC = [[TSKPreviewViewController alloc] init];
                }
                if (image != nil && [item previewViewController] == nil) {
                    TSKVibrantImageView *imageView = [[TSKVibrantImageView alloc] initWithImage:image];
                    [previewVC setContentView:imageView];
                }
                [previewVC setDescriptionText:[item localizedDescription]];
                [item setPreviewViewController:previewVC];
                [currentGroupItems addObject:item];
            }
        }
        //Since the groups are created when we find the next one, if we are at the last (or only) group we need to create one for the remaining items
        //NSLog(@"idx: %lu count: %lu", idx, items.count);
        if (idx == items.count-1){
            
            //NSLog(@"creating final group: %@ with items: %@", currentGroupName, currentGroupItems);
            TSKSettingGroup *groupItem = [TSKSettingGroup groupWithTitle:currentGroupName settingItems:currentGroupItems];
            [groups addObject:groupItem];
        }
        
    }];
    
    return groups;
}



@end

@implementation TSKSettingGroup (lazyItems)

- (void)addSettingItem:(TSKSettingItem *)item {
    
    NSMutableArray *currentSettingsItems = [[self settingItems] mutableCopy];
    [currentSettingsItems addObject:item];
    [self setSettingItems:currentSettingsItems];
}

@end

/**
 
 Add an itemIcon for TSKSettingItem, this is a lazy convenience to make it easier to set icons per item
 There is a likely a more elegant and proper way to do this, but it works for now and wont hurt anything.
 
 */

@implementation TSKSettingItem (lazyIcons) 

- (NSDictionary *)keyboardDetails {
    
    return objc_getAssociatedObject(self, @selector(keyboardDetails));
}

- (void)setKeyboardDetails:(NSDictionary *)keyboardDetails {
    objc_setAssociatedObject(self, @selector(keyboardDetails), keyboardDetails, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (UIImage *)itemIcon
{
    return objc_getAssociatedObject(self, @selector(itemIcon));
}

- (void)setItemIcon:(UIImage *)itemIcon {
    objc_setAssociatedObject(self, @selector(itemIcon), itemIcon, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation PLCustomListViewController

- (void)showMissingActionAlert {
    
    UIAlertController *notFoundAlert = [UIAlertController alertControllerWithTitle:@"Action not found" message:@"Your setting's bundle attempted to call an action that doesn't exist" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    [notFoundAlert addAction:cancel];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self presentViewController:notFoundAlert animated:TRUE completion:nil];
        
    });
}

- (void)relaunchBackboardd {
    
    [NSTask launchedTaskWithLaunchPath:@"/usr/bin/killall" arguments:@[@"-9", @"backboardd"]];
    
}

- (id)ourPreferences {
    
    return [objc_getClass("TVSPreferences") preferencesWithDomain:self.ourDomain];
}

- (id)loadSettingGroups
{
    NSMutableArray *_backingArray = [NSMutableArray new];
    NSArray *items = [self menuItemsFromItems:self.menuItems];
    [_backingArray addObjectsFromArray:items];
    [self setValue:_backingArray forKey:@"_settingGroups"];
    return _backingArray;
    
}

-(TSKPreviewViewController*)previewViewController {
    @synchronized (self) {
        if ([super previewViewController] == nil) {
            //NSLog(@"%@: generating a previewViewController :(", self);
            id preview = [[[self navigationController] previousViewController] defaultPreviewViewController];
            [self setPreviewViewController:preview];
        }
    }
    return (TSKPreviewViewController*)[super previewViewController];
}

-(id)previewForItemAtIndexPath:(NSIndexPath*)indexPath {
    TSKSettingGroup *currentGroup = self.settingGroups[indexPath.section];
    TSKSettingItem *currentItem = currentGroup.settingItems[indexPath.row];
    NSString *desc = [currentItem localizedDescription];
    UIImage *icon = [self ourIcon];
    TSKPreviewViewController *item = (TSKPreviewViewController*)[self previewViewController];
    //NSLog(@"%@ previewForItemAtIndexPath: %@", self, item);
    if (icon != nil) {
        TSKVibrantImageView *imageView = [[TSKVibrantImageView alloc] initWithImage:icon];
        [item setContentView:imageView];
    }
    [item setDescriptionText:desc];
    return item;
}



@end

@interface TVSettingsTweakViewController() {
    
    //in case we ever want / need any private vars;
    
}

@end

@implementation TVSettingsTweakViewController

-(TSKPreviewViewController*)previewViewController {
    TSKPreviewViewController *vc = (TSKPreviewViewController*)[super previewViewController];
    if (vc == nil) {
        vc = [[TSKPreviewViewController alloc] init];
        [super setPreviewViewController:vc];
    }
    return vc;
}

//initial entry point for any type of TSKViewController (which we inherit from)

- (id)loadSettingGroups {
    
    NSMutableArray *_backingArray = [NSMutableArray new];
    NSArray *prefBundleGroups = [self preferenceBundleGroups];
    //NSLog(@"prefBundleGroups: %@", prefBundleGroups);
    if (prefBundleGroups.count > 0) {
        TSKSettingGroup *group = [TSKSettingGroup groupWithTitle:nil settingItems:prefBundleGroups];
        [_backingArray addObject:group];
        //property is read only, so maybe we really should be overriding settingsGroup property instead... more thought needed.
        [self setValue:_backingArray forKey:@"_settingGroups"];
    }
    
    
    return _backingArray;
    
}

//search through /Library/PreferenceLoader/Preferences for entries to add, currently is only supporting adding to Tweaks menu item

- (NSArray *)preferenceBundleGroups {
    
    NSMutableArray *allTheSpecs = [NSMutableArray new];
    
    NSString *preferencesPath = @"/Library/PreferenceLoader/Preferences";
    
    NSArray *subpaths = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:preferencesPath error:NULL];
    for(NSString *item in subpaths) {
        if(![[item pathExtension] isEqualToString:@"plist"]) continue;
        NSLog(@"processing %@", item);
        NSString *fullPath = [NSString stringWithFormat:@"/Library/PreferenceLoader/Preferences/%@", item];
        NSDictionary *plPlist = [NSDictionary dictionaryWithContentsOfFile:fullPath];
        if(![TSKSettingGroup environmentPassesPreferenceLoaderFilter:[plPlist objectForKey:@"filter"] ?: [plPlist objectForKey:PLFilterKey]]) continue;
        
        NSDictionary *entry = [plPlist objectForKey:@"entry"];
        if(!entry) continue;
        NSLog(@"found an entry key for %@!", item);
        
        if(![TSKSettingGroup environmentPassesPreferenceLoaderFilter:[entry objectForKey:PLFilterKey]]) continue;
        
        NSArray *specs = [self specifiersFromEntry:entry sourcePreferenceLoaderBundlePath:[fullPath stringByDeletingLastPathComponent] title:[[item lastPathComponent] stringByDeletingPathExtension]];
        if(specs.count > 0) {
            
            NSLog(@"appending to the array!");
            
            [allTheSpecs addObjectsFromArray:specs];
        } else { //there isnt a bundle
            NSString *label = entry[@"label"];
            NSArray *items = plPlist[@"items"];
            NSString *iconPath = entry[@"icon"];
            NSString *description = entry[@"description"];
            //NSLog(@"items: %@", items);
            
            //NSLog(@"creating menu items!!");
            NSString *fullIconPath = [preferencesPath stringByAppendingPathComponent:iconPath];
            if ([[NSFileManager defaultManager] fileExistsAtPath:iconPath]){
                fullIconPath = iconPath;
            }
            UIImage *image = [UIImage imageWithContentsOfFile:fullIconPath];
            //NSLog(@"fullIconPath: %@", fullIconPath);
            //NSLog(@"image: %@", image);
            
            //we need to configure this settings item later, so we use the childBlocks based init
            
            TSKSettingItem *settingsItem = [TSKSettingItem childPaneItemWithTitle:label description:description representedObject:nil keyPath:nil childControllerBlock:^(TSKSettingItem *object) {
                PLCustomListViewController* controller = [object controller];
                if (controller)
                    return controller;
                
                NSLog(@"self: %@ object: %@", self, object);
                
                controller = [PLCustomListViewController new];
                if (image){
                    [controller setOurIcon:image];
                    [controller setPreviewViewController:[object previewViewController]];
                }
                [controller setTitle:label];
                [controller setMenuItems:items]; //these are just dictionary menu items loaded from our plist, will be converted later
                [object setController:controller];
                return controller;
            }];
            [settingsItem setPreviewViewController:[[TSKPreviewViewController alloc] init]];
            [settingsItem setItemIcon:image];
            [allTheSpecs addObject:settingsItem];
            //NSLog(@"made item: %@", settingsItem);
            //description:(id)arg2 representedObject:(id)arg3 keyPath:(id)arg4 childControllerBlock:((void(^childControllerBlock)(id object))completionBlock
        }
    }
    return allTheSpecs;
}


/*
 
 plucked straight from iOS version in prefs.xm, this will return the TSKSettingItem that will get added to our list
 
 */

- (NSArray *)specifiersFromEntry:(NSDictionary *)entry sourcePreferenceLoaderBundlePath:(NSString *)sourceBundlePath title:(NSString *)title {
    
    //NSDictionary *specifierPlist = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:entry, nil], @"items", nil];
    
    BOOL isBundle = [entry objectForKey:@"bundle"] != nil;
    //BOOL isLocalizedBundle = ![[sourceBundlePath lastPathComponent] isEqualToString:@"Preferences"];
    
    NSBundle *prefBundle;
    NSString *bundleName = entry[@"bundle"];
    NSString *bundlePath = entry[@"bundlePath"];
    
    if(isBundle) {
        // Second Try (bundlePath key failed)
        if(![[NSFileManager defaultManager] fileExistsAtPath:bundlePath])
            bundlePath = [NSString stringWithFormat:@"/Library/PreferenceBundles/%@.bundle", bundleName];
        
        // Third Try (/Library failed)
        if(![[NSFileManager defaultManager] fileExistsAtPath:bundlePath])
            bundlePath = [NSString stringWithFormat:@"/System/Library/PreferenceBundles/%@.bundle", bundleName];
        
        // Really? (/System/Library failed...)
        if(![[NSFileManager defaultManager] fileExistsAtPath:bundlePath]) {
            NSLog(@"Discarding specifier for missing isBundle bundle %@.", bundleName);
            return nil;
        }
        prefBundle = [NSBundle bundleWithPath:bundlePath];
        NSLog(@"is a bundle: %@!", prefBundle);
    } else {
        prefBundle = [NSBundle bundleWithPath:sourceBundlePath];
        NSLog(@"is NOT a bundle, so we're giving it %@!", prefBundle);
    }
    
    /*
     
     entry.plist looks something like this
     
     <key>bundle</key>
     <string>DDBSettings</string>
     <key>cell</key>
     <string>PSLinkCell</string>
     <key>detail</key>
     <string>DDBSettingsController</string>
     <key>icon</key>
     <string>icon.png</string>
     <key>isController</key>
     <true/>
     <key>label</key>
     <string>Dales Dead Bug</string>
     <key>description</key>
     <string>Dales Dead Bug</string>
     
     */
    
    
    NSMutableArray *items = [NSMutableArray  new];
    
    if(isBundle) {
        
        NSLog(@"we got a bundle!");
        
        if([[entry objectForKey:@"isController"] boolValue]) {
            
            NSLog(@"creating TSKSettingItems!");
            
            NSString *principalClassKey = entry[@"detail"];
            NSString *iconKey = entry[@"icon"]; 
            NSString *labelKey = entry[@"label"];
            NSString *descriptionKey = entry[@"description"]; //not part of original spec, custom addition.
            //load the bundle so we can get access to the class
            [prefBundle load];
            
            //all items are going to be child panel items for now which allow use to load another class that gives us our groups from said tweak
            TSKSettingItem *item = [TSKSettingItem childPaneItemWithTitle:labelKey description:descriptionKey representedObject:nil keyPath:nil childControllerClass:NSClassFromString(principalClassKey)];
            
            //this does the magic of loading the class from the bundle
            TSKBundleLoader *bundleLoader = [[TSKBundleLoader alloc] initWithBundle:prefBundle];
            [item setBundleLoader:bundleLoader];
            
            //NSLog(@"iconKey: %@", iconKey);
            
            NSString *iconPath = [bundlePath stringByAppendingPathComponent:iconKey];
            //NSString *iconPath =[[NSBundle mainBundle] pathForResource:[iconKey stringByDeletingPathExtension] ofType:[iconKey pathExtension]];
            
            //NSLog(@"iconPath: %@", iconPath);
            UIImage *image = [UIImage imageWithContentsOfFile:iconPath];
            //NSLog(@"image: %@", image);
            [item setItemIcon:image];
            //NSLog(@"item: %@ icon: %@", item, [item itemIcon]);
            NSString *className = prefBundle.infoDictionary[@"NSPrincipalClass"];
            TSKPreviewViewController *previewVC = nil;
            if (className) {
                Class principalClass = NSClassFromString(className);
                if (principalClass && [principalClass respondsToSelector:@selector(defaultPreviewViewController)]) {
                    previewVC = (TSKPreviewViewController*)[principalClass defaultPreviewViewController];
                }
            }
            if (previewVC == nil) {
                previewVC = [[TSKPreviewViewController alloc] init];
            }
            if (image != nil && [item previewViewController] == nil) {
                TSKVibrantImageView *imageView = [[TSKVibrantImageView alloc] initWithImage:image];
                [previewVC setContentView:imageView];
            }
            [previewVC setDescriptionText:[item localizedDescription]];
            [item setPreviewViewController:previewVC];
            [items addObject:item];
        }
    } else {
        
        //NSLog(@"not a bundle! this feature is currently unsupported entry: %@ path: %@", entry, prefBundle);
        
    }
    return items;
}


-(id)previewForItemAtIndexPath:(NSIndexPath *)indexPath {
    TSKSettingGroup *currentGroup = self.settingGroups[indexPath.section];
    TSKSettingItem *currentItem = currentGroup.settingItems[indexPath.row];
    NSString *desc = [currentItem localizedDescription];
    UIImage *icon = [currentItem itemIcon];
    //added a category to make item icons easier to get and set per item.
    TSKPreviewViewController *previewItem = [currentItem previewViewController];
    //NSLog(@"preview item :%@ icon; %@ for item %@", previewItem, icon, currentItem);
    if (!previewItem || !icon) {
        if (icon == nil) {
            //take the previous view controller on the navigation stack and use the default controller from that
            previewItem = [[[self navigationController] previousViewController] defaultPreviewViewController];
            NSLog(@"we got no icon, preview item: %@", previewItem);
            return previewItem;
        } else {
            previewItem = [[TSKPreviewViewController alloc] init];
        }
        [currentItem setPreviewViewController:previewItem];
    }
    [previewItem setDescriptionText:desc];
    TSKVibrantImageView *imageView = (TSKVibrantImageView*)[previewItem contentView];
    if (imageView == nil) {
        imageView = [[TSKVibrantImageView alloc] initWithImage:icon];
        [previewItem setContentView:imageView];
    }
    if ([imageView image] != icon) {
        [imageView setImage:icon];
    }
    //NSLog(@"previewForItemAtIndexPath: %@", previewItem);
    return previewItem;
}


@end
