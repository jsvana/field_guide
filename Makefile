.PHONY: build test clean download-pdfs extract-content generate-manifest

PROJECT := FieldGuide.xcodeproj
SCHEME := FieldGuide
SIMULATOR := iPhone 16 Pro

# Build for simulator (default)
build:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-destination 'platform=iOS Simulator,name=$(SIMULATOR)' build

# Run tests
test:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-destination 'platform=iOS Simulator,name=$(SIMULATOR)' test

# Clean build artifacts
clean:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean
	rm -rf ~/Library/Developer/Xcode/DerivedData/FieldGuide-*

# Python tooling commands
download-pdfs:
	cd tools && source venv/bin/activate && python download_pdfs.py

extract-content:
	cd tools && source venv/bin/activate && python extract_content.py --all elecraft-k1

generate-manifest:
	cd tools && source venv/bin/activate && python generate_manifest.py
