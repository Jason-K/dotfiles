# Directory Status Review Checklist

Review status of unclear directories. Update as decisions are made.

## Directories Requiring Clarification

### [x] km/
**Current:** Placeholder
**Decision:** Will hold Keyboard Maestro settings (pending migration)
**Date:** 2026-01-12

### [x] hazel/
**Current:** Placeholder
**Decision:** Will hold Hazel automation rules (pending migration)
**Date:** 2026-01-12

### [x] typinator/
**Current:** Placeholder
**Decision:** Will hold Typinator text expansion rulesets (pending migration)
**Date:** 2026-01-12

### [x] settings/supercharge/
**Current:** Vestigial (to be removed)
**Decision:** Remove - contents already in ~/dotfiles/settings/supercharge (the app's backup location)
**Date:** 2026-01-12

---

## Decision Framework

### If Active
- [ ] Add to maintenance schedule
- [ ] Document setup/usage
- [ ] Ensure backups configured

### If Reference/Archived
- [ ] Mark as such in DIRECTORY_STRUCTURE.md
- [ ] Note reason and date
- [ ] Link to historical docs if applicable

### If Should Delete
- [ ] Ensure no dependencies
- [ ] Archive history if needed
- [ ] Remove via `git rm -r dirname/`
