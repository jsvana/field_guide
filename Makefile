.PHONY: build test clean download-pdfs extract-content generate-manifest

PROJECT := FieldGuide.xcodeproj
TARGET := FieldGuide
TEST_TARGET := FieldGuideTests
SIMULATOR := iPhone 16 Pro

# Build for simulator (default)
build:
	xcodebuild -project $(PROJECT) -target $(TARGET) \
		-configuration Debug build

# Run tests
test:
	xcodebuild -project $(PROJECT) -target $(TEST_TARGET) \
		-destination 'platform=iOS Simulator,name=$(SIMULATOR)' test

# Clean build artifacts
clean:
	xcodebuild -project $(PROJECT) -target $(TARGET) clean
	rm -rf ~/Library/Developer/Xcode/DerivedData/FieldGuide-*
	rm -rf build

# Python tooling commands
download-pdfs:
	cd tools && source venv/bin/activate && python download_pdfs.py

extract-content:
	cd tools && source venv/bin/activate && python extract_content.py --all elecraft-k1

generate-manifest:
	cd tools && source venv/bin/activate && python generate_manifest.py
