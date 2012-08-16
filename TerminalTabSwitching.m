#import "JRSwizzle.h"

@implementation NSWindowController(TerminalTabSwitching)
- (void)selectRepresentedTabViewItem:(NSMenuItem*)item
{
	NSTabViewItem* tabViewItem = [item representedObject];
	[[tabViewItem tabView] selectTabViewItem:tabViewItem];
}

- (void)updateTabListMenu
{
	NSMenu* windowsMenu = [[NSApplication sharedApplication] windowsMenu];

	for(NSMenuItem* menuItem in [windowsMenu itemArray])
	{
//		NSString* key = [menuItem keyEquivalent];
//		if(([key length] == 1 && 0x30 <= [key characterAtIndex:0] && [key characterAtIndex:0] <= 0x39)
//		 || [menuItem action] == @selector(selectRepresentedTabViewItem:))
		if([menuItem action] == @selector(selectRepresentedTabViewItem:))
			[windowsMenu removeItem:menuItem];
	}
	NSArray* tabViewItems = [[self valueForKey:@"tabView"] tabViewItems];
	for(size_t tabIndex = 0; tabIndex < [tabViewItems count]; ++tabIndex)
	{
		NSString* keyEquivalent = (tabIndex < 10) ? [NSString stringWithFormat:@"%ld", (tabIndex+1)%10] : @"";
		NSTabViewItem* tabViewItem = [tabViewItems objectAtIndex:tabIndex];
		NSMenuItem* menuItem = [[NSMenuItem alloc] initWithTitle:[tabViewItem label]
														  action:@selector(selectRepresentedTabViewItem:)
												   keyEquivalent:keyEquivalent];
		[menuItem setRepresentedObject:tabViewItem];
		[windowsMenu addItem:menuItem];
		[menuItem release];
	}
}

- (void)TerminalTabSwitching_windowDidLoad
{
	// This method is not called at first time for the first main window.
	[self TerminalTabSwitching_windowDidLoad];
	[[NSApplication sharedApplication] removeWindowsItem:[self window]];
	[[self window] setExcludedFromWindowsMenu:YES];
	[self updateTabListMenu];
}

- (void)TerminalTabSwitching_windowDidBecomeMain:(id)fp8
{
	[self TerminalTabSwitching_windowDidBecomeMain:fp8];
	[self updateTabListMenu];
}

- (void)TerminalTabSwitching_newTab:(id)fp8
{
	[self TerminalTabSwitching_newTab:fp8];
	[self updateTabListMenu];
}

- (void)TerminalTabSwitching_tabView:(id)arg1 didCloseTabViewItem:(id)arg2
{
	[self TerminalTabSwitching_tabView:arg1 didCloseTabViewItem:arg2];
	[self updateTabListMenu];
}

- (void)TerminalTabSwitching_mergeAllWindows:(id)fp8
{
	[self TerminalTabSwitching_mergeAllWindows:fp8];
	[self updateTabListMenu];
}
@end

#pragma mark -

@implementation NSTabViewItem(TerminalTabSwitching)
- (void)TerminalTabSwitching_setReorderState:(int)arg1
{
	[self TerminalTabSwitching_setReorderState:arg1];
	if(arg1 == 0) {
		// FIXME what is the best way to grab current NSWindowController from self
		[[[[NSApplication sharedApplication] mainWindow] windowController]updateTabListMenu];
	}
}
@end

#pragma mark -

@interface TerminalTabSwitching : NSObject
@end

@implementation TerminalTabSwitching
+ (void)load
{
	[NSClassFromString(@"TTWindowController") jr_swizzleMethod:@selector(windowDidLoad) withMethod:@selector(TerminalTabSwitching_windowDidLoad) error:NULL];

	[NSClassFromString(@"TTWindowController") jr_swizzleMethod:@selector(windowDidBecomeMain:) withMethod:@selector(TerminalTabSwitching_windowDidBecomeMain:) error:NULL];
	[NSClassFromString(@"TTWindowController") jr_swizzleMethod:@selector(newTab:) withMethod:@selector(TerminalTabSwitching_newTab:) error:NULL];
	[NSClassFromString(@"TTWindowController") jr_swizzleMethod:@selector(tabView:didCloseTabViewItem:) withMethod:@selector(TerminalTabSwitching_tabView:didCloseTabViewItem:) error:NULL];
	[NSClassFromString(@"TTWindowController") jr_swizzleMethod:@selector(mergeAllWindows:) withMethod:@selector(TerminalTabSwitching_mergeAllWindows:) error:NULL];

	[NSClassFromString(@"TTTabViewItem") jr_swizzleMethod:@selector(setReorderState:) withMethod:@selector(TerminalTabSwitching_setReorderState:) error:NULL];

	NSApplication *app = [NSApplication sharedApplication];
	NSWindow *mainWindow = [app mainWindow];

	// NOTE The issue of timing to install SIMBL hook, we need to exclude the window already laoded here.
	// After loaded, we can exclude new windows inside windowDidLoad callback method.
	BOOL shouldExcludeMainWindow = ![mainWindow isExcludedFromWindowsMenu];

	if(shouldExcludeMainWindow) {
		[app removeWindowsItem:mainWindow];
		[mainWindow setExcludedFromWindowsMenu:YES];
	}

	[[app windowsMenu] addItem:[NSMenuItem separatorItem]];

	if(shouldExcludeMainWindow) {
		[[mainWindow windowController] updateTabListMenu];
	}

	NSLog(@"TerminalTabSwitching installed");
}
@end