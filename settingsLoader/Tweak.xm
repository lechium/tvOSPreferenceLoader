#import <objc/runtime.h>
#import <notify.h>
#import <dlfcn.h>
#import <substrate.h>
#import <sys/utsname.h>
#import <UIKit/UIKit.h>
#import "TVSettingsTweakViewController.h"
#import <objc/runtime.h>

// static NSInteger PSSpecifierSort(PSSpecifier *a1, PSSpecifier *a2, void *context) {
// 	NSString *string1 = [a1 name];
// 	NSString *string2 = [a2 name];
// 	return [string1 localizedCaseInsensitiveCompare:string2];
// }

%hook NSBundle
+ (NSBundle *)bundleWithPath:(NSString *)path {
	NSString *newPath = nil;
	NSRange sysRange = [path rangeOfString:@"/System/Library/PreferenceBundles" options:0];
	if(sysRange.location != NSNotFound) {
		newPath = [path stringByReplacingCharactersInRange:sysRange withString:@"/Library/PreferenceBundles"];
	}
	if(newPath && [[NSFileManager defaultManager] fileExistsAtPath:newPath]) {
		// /Library/PreferenceBundles will override /System/Library/PreferenceBundles.
		path = newPath;
	}
	return %orig;
}
%end

%hook TVSettingsMainViewController

//loadSettingsGroups is the initial entry point of every group of settings items in TVSettingsApp, this is the root one

- (id)loadSettingGroups {
	
	%log;
	NSArray* groups = %orig;//all the groups (theres only 1)
	TSKSettingGroup *group = groups[0]; //get group 1
	//our tweak loading class, in the future there will be more here, or we might add directly to the avail Apps one
	Class theClass = NSClassFromString(@"TVSettingsTweakViewController");
	TSKSettingItem *tweakMenuItem = [TSKSettingItem childPaneItemWithTitle:@"Tweaks" description:nil representedObject:nil keyPath:nil childControllerClass:theClass];
	//each TSKSettingGroup has an array of TSKSettingItem in "settingsItem" property
	NSArray *settingsItems = [group valueForKey:@"settingItems"];
	NSMutableArray *newItems = [settingsItems mutableCopy];
	[newItems insertObject:tweakMenuItem atIndex:7]; //right underneath /Apps
	//update the group to have our Tweaks item shoehorned in :)
	[group setSettingItems:newItems];
	return @[group];
	
}

%end