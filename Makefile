.PHONY: build run clean release

build:
	xcodebuild -project PDFScribe.xcodeproj -scheme PDFScribe -configuration Debug build

run:
	xcodebuild -project PDFScribe.xcodeproj -scheme PDFScribe -configuration Debug build
	open $$(find ~/Library/Developer/Xcode/DerivedData/PDFScribe-*/Build/Products/Debug/PDFScribe.app | head -1)

clean:
	xcodebuild -project PDFScribe.xcodeproj -scheme PDFScribe clean
	rm -rf ~/Library/Developer/Xcode/DerivedData/PDFScribe-*

release:
	xcodebuild -project PDFScribe.xcodeproj -scheme PDFScribe -configuration Release build
	@echo "✅ Release build created at ~/Library/Developer/Xcode/DerivedData/PDFScribe-.../Build/Products/Release/PDFScribe.app"
