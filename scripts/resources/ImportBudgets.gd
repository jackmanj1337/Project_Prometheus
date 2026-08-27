class_name ImportBudgets extends RefCounted
# Single configuration owner for player-selected save and campaign artifacts.
# Callers may inject tighter values in tests; platform overrides belong here.

const MIB := 1024 * 1024

const DESKTOP_PORTABLE_SAVE_WARNING_BYTES := 16 * MIB
const DESKTOP_PORTABLE_SAVE_MAXIMUM_BYTES := 64 * MIB

const CAMPAIGN_ARCHIVE_MAX_ENTRIES := 4096
const CAMPAIGN_ARCHIVE_MAX_ENTRY_COMPRESSED_BYTES := 64 * MIB
const CAMPAIGN_ARCHIVE_MAX_ENTRY_UNCOMPRESSED_BYTES := 64 * MIB
const CAMPAIGN_ARCHIVE_MAX_TOTAL_COMPRESSED_BYTES := 512 * MIB
const CAMPAIGN_ARCHIVE_MAX_TOTAL_UNCOMPRESSED_BYTES := 512 * MIB

# A full backup holds whole pack archives as single entries, so its per-entry
# ceiling is a pack's total rather than a pack file's, and its total is larger than
# any one pack. Development ceilings, like the values above.
const BACKUP_ARCHIVE_MAX_ENTRIES := 8192
const BACKUP_ARCHIVE_MAX_ENTRY_UNCOMPRESSED_BYTES := 512 * MIB
const BACKUP_ARCHIVE_MAX_TOTAL_UNCOMPRESSED_BYTES := 2048 * MIB
const BACKUP_ARCHIVE_WARNING_BYTES := 256 * MIB


static func portable_save_warning_bytes() -> int:
	# Web may return a tighter value here once browser measurements exist.
	return DESKTOP_PORTABLE_SAVE_WARNING_BYTES


static func portable_save_maximum_bytes() -> int:
	# Keep the desktop development ceiling until measurements justify a change.
	return DESKTOP_PORTABLE_SAVE_MAXIMUM_BYTES
