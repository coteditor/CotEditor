# Test Wiki Link Integration

This file tests the new WikiLinkDetector integration with CotEditor's URLDetector system.

## Test Links

Here are some wiki links to test:

- [[Basic Link]] - Simple link
- [[Link with Spaces]] - Link with spaces  
- [[link-with-dashes]] - Link with dashes
- [[Link_with_underscores]] - Link with underscores
- [[Link123]] - Link with numbers
- [[📝 Note with Emoji]] - Link with emoji

## Expected Behavior

1. **Auto Link Detection Setting**: Wiki links should appear/disappear when toggling "Link URLs in document" in Edit Settings
2. **Visual Highlighting**: Wiki links should have .link attribute styling (like URLs)
3. **Click Handling**: Clicking wiki links should attempt to open/create note files
4. **Consistency**: Wiki links should behave similarly to regular URLs

## Test Results

- [ ] Links appear when autoLinkDetection is enabled
- [ ] Links disappear when autoLinkDetection is disabled  
- [ ] Visual styling matches other links
- [ ] Click navigation works
- [ ] No console errors or crashes