# Changelog

All notable changes to CW Field Guide will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.4.0] - 2026-02-15

### Added
- Outing checklists — five-phase workflow (Pre-Outing, During Outing, Debugging, Cleanup, Post-Outing) with resettable check state
- Checklists tab in main navigation
- Radio-specific checklist items appear automatically for downloaded radios (KX2, KX3, G90, IC-705, FT-891)
- Deep linking support for checklists (`cwfieldguide://checklist/{phase}`)

## [1.3.0] - 2026-02-10

### Added
- Add deep link support — `cwfieldguide://radio/{id}` opens directly to a radio's manual from Carrier Wave

## [1.2.1] - 2026-02-04

### Fixed
- Crash on launch for users upgrading from v1.0 (SwiftData migration failure due to missing default value on isFavorite property)

## [1.2] - 2026-02-04

### Added
- 2 NorCal QRP Club radios: NorCal 20, NorCal 40A

## [1.1] - 2026-02-03

### Added
- 6 Xiegu radios: G1M, G90, G106, X5105, X6100, X6200
- Documentation for adding new radios to the app

### Changed
- Library tab now sorts radios by manufacturer, then by model

## [1.0] - 2026-02-02

### Added
- Initial release with 23 radios from 9 manufacturers:
  - BG2FX: FX-4CR
  - Elecraft: K1, K2, KH1, KX1, KX2, KX3
  - HamGadgets: CFT1
  - ICOM: IC-705, IC-7100, IC-7300, IC-7300MK2
  - LNR Precision: LD-5, MTR-3B-V4, MTR-4B-V2, MTR-5B
  - PennTek: TR-25, TR-35, TR-45L
  - Venus: SW-3B, SW-6B
  - Yaesu: FT-710, FT-891, FT-991A, FTDX101MP, FTX1
- Library tab with radio grid and favorites
- Full-text search across all manuals
- Settings tab with download management
- Offline-first design - all content works without network
