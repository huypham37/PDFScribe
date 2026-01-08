.PHONY: build run clean release

build:
	swift build

run:
	swift run

clean:
	swift package clean

release:
	swift build -c release
	@echo "Creating app bundle..."
	@mkdir -p PDFScribe.app/Contents/MacOS
	@mkdir -p PDFScribe.app/Contents/Resources
	@cp .build/release/PDFScribe PDFScribe.app/Contents/MacOS/
	@echo '<?xml version="1.0" encoding="UTF-8"?>' > PDFScribe.app/Contents/Info.plist
	@echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> PDFScribe.app/Contents/Info.plist
	@echo '<plist version="1.0">' >> PDFScribe.app/Contents/Info.plist
	@echo '<dict>' >> PDFScribe.app/Contents/Info.plist
	@echo '  <key>CFBundleExecutable</key>' >> PDFScribe.app/Contents/Info.plist
	@echo '  <string>PDFScribe</string>' >> PDFScribe.app/Contents/Info.plist
	@echo '  <key>CFBundleIdentifier</key>' >> PDFScribe.app/Contents/Info.plist
	@echo '  <string>com.pdfscribe.app</string>' >> PDFScribe.app/Contents/Info.plist
	@echo '  <key>CFBundleName</key>' >> PDFScribe.app/Contents/Info.plist
	@echo '  <string>PDFScribe</string>' >> PDFScribe.app/Contents/Info.plist
	@echo '  <key>CFBundlePackageType</key>' >> PDFScribe.app/Contents/Info.plist
	@echo '  <string>APPL</string>' >> PDFScribe.app/Contents/Info.plist
	@echo '  <key>CFBundleShortVersionString</key>' >> PDFScribe.app/Contents/Info.plist
	@echo '  <string>1.0</string>' >> PDFScribe.app/Contents/Info.plist
	@echo '  <key>NSHighResolutionCapable</key>' >> PDFScribe.app/Contents/Info.plist
	@echo '  <true/>' >> PDFScribe.app/Contents/Info.plist
	@echo '</dict>' >> PDFScribe.app/Contents/Info.plist
	@echo '</plist>' >> PDFScribe.app/Contents/Info.plist
	@echo "✅ App bundle created at PDFScribe.app"
