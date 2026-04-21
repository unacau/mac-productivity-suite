# Work Item 004: Generate Karabiner-Elements Hyper Key Mapping

## Description
Create the complex modification JSON for Karabiner-Elements to map `Caps Lock` held to the Hyper Key (`Cmd + Opt + Ctrl + Shift`) and `Caps Lock` tapped to `Escape`. This will serve as the foundation for the global app switcher and other advanced shortcuts in the Mac Productivity Suite.

## Acceptance Criteria
- [ ] A valid Karabiner-Elements complex modification JSON file is created.
- [ ] Pressing and holding `Caps Lock` registers as `Cmd + Opt + Ctrl + Shift` simultaneously.
- [ ] Tapping `Caps Lock` quickly registers as the `Escape` key.
- [ ] The modification can be successfully imported and activated in the Karabiner-Elements application.

## Implementation Steps
1. Create a new JSON file (e.g., `hyper-key-mapping.json`) in the project directory (or within a `karabiner` subfolder).
2. Define the `title` and `rules` array in the JSON structure.
3. Within `rules`, define a manipulator that targets the `caps_lock` key.
4. Set the `to` action to send `left_command`, `left_control`, `left_option`, and `left_shift` simultaneously when `caps_lock` is held.
5. Set the `to_if_alone` action to send `escape` when `caps_lock` is tapped quickly.
6. Copy the JSON structure or file into `~/.config/karabiner/assets/complex_modifications/`.

## Testing Strategy
- **Validation**: Open Karabiner-Elements, navigate to Complex Modifications, and add the new rule.
- **Verification Tool**: Use a keyboard event viewer (like the Karabiner-EventViewer or a web-based key tester) to verify that holding `Caps Lock` outputs the four modifier keys and tapping it outputs `Escape`.

## Dependencies
- Karabiner-Elements must be installed and running on the target macOS system.
- Basic understanding of Karabiner-Elements complex modification JSON schema.

## Decisions & Trade-offs
To be updated during implementation.

## Completion Reminder
Note: `docs/aide/progress.md` MUST be updated (📋 → 🚧 → ✅) when this item is completed.

## Testing Prerequisites

### Required Services
- Karabiner-Elements (macOS application)

### Environment Configuration
- No special environment variables required.
- Karabiner-Elements must be granted Input Monitoring permissions in macOS System Settings.

### Manual Validation Checklist
- [ ] **Services started**: Open Karabiner-Elements.
- [ ] **Configuration loaded**: Place the JSON file in `~/.config/karabiner/assets/complex_modifications/` and add the rule in the Karabiner-Elements UI.
- [ ] **Feature verified (Hold)**: Press and hold `Caps Lock`. Verify in Karabiner-EventViewer that `Cmd`, `Ctrl`, `Opt`, and `Shift` are registered.
- [ ] **Feature verified (Tap)**: Tap `Caps Lock`. Verify in Karabiner-EventViewer that `Escape` is registered.

### Expected Outcomes
- A single JSON file containing the exact complex modification configuration.
- The configuration successfully maps the keys without errors in Karabiner-Elements.

### Validation Documentation Template

```markdown
## Validation Results
- [ ] Service started: Karabiner-Elements
- [ ] Application started successfully: N/A
- [ ] Database tables verified: N/A
- [ ] Seed data verified: N/A
- [ ] API endpoints verified: N/A
- [ ] JSON configuration imported successfully
- [ ] Keystrokes verified in EventViewer (Hold -> Hyper, Tap -> Escape)
```
