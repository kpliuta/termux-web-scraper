# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [Unreleased]

### Added
- OpenVPN integration for Termux. Added `-r` and `--open-vpn <profile>` parameters. (Note: This change will never be released, because the solution of calling OpenVPN activity to startup and shutdown VPN connection works only if a phone is not locked).

### Changed
- Removed `-i` parameter.

### Fixed
- Variable names in validation logic in `run.sh` and `run_distro.sh`.


## [0.1.1]

### Added
- Helper methods: `get_optional_element`, `select_option_by_text`.

### Changed
- Make termux/container dependencies install without manual intervention.
- Enable termux package upgrades for F-Droid version and disable for Google Play version to avoid breakage.

### Fixed
- `gtk-update-icon-cache` related hang.


## [0.1.0]

### Added
- Web scraper framework.
- Python framework.
