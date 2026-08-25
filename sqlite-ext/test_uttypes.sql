-- fileContentType: UTI string derived from file extension
-- Note: /etc/hosts has no extension so returns NULL; use a file with .plist extension
SELECT fileContentType('/System/Library/CoreServices/SystemVersion.plist');
-- expected: com.apple.property-list  (or similar plist UTI)
SELECT fileContentType('/etc/hosts') IS NULL;
-- expected: 1  (no extension → NULL)

-- conformsTo: UTI conformance check
SELECT conformsTo('public.jpeg', 'public.image');
-- expected: 1
SELECT conformsTo('public.jpeg', 'public.audio');
-- expected: 0

-- fileConformsTo: file path + target UTI
SELECT fileConformsTo('/System/Library/CoreServices/SystemVersion.plist', 'public.data');
-- expected: 1
SELECT fileConformsTo('/System/Library/CoreServices/SystemVersion.plist', 'public.audio');
-- expected: 0
