# Squad Decisions

## Active Decisions

### 2026-04-20: User directive
**By:** Patrick Boyle (via Copilot)
**What:** All diagrams for this project will be maintained in Mermaid format — text-based, embedded in markdown, renders natively in GitHub.
**Why:** User request — captured for team memory

### ADR-001: Player Form State Machine

*   **Status:** Proposed
*   **Owner:** Mal (Lead)
*   **Collaborators:** Kaylee (Game Dev)
*   **Date:** 2026-04-19

#### Context
To support the core "shapeshifting" mechanic, the player needs a robust way to switch between different forms (Human, Bird, Wolf, etc.). Each form will have unique physics, animations, and abilities.

#### Decision
We will implement a **Node-based State Machine** for player forms, adhering to the `GEMINI.md` mandate for "node-based composition."

#### Architecture
1.  **FormManager (Node):** A child of the `Player` root node that manages the active form.
2.  **BaseForm (Resource or Node):** A base class defining the interface for all forms (e.g., `_apply_movement`, `_handle_input`).
3.  **HumanForm (Node):** The default form using the current movement logic.
4.  **Morphomon Form(s):** Specialized nodes that override movement constants (speed, gravity) and animation sets.

#### Signal-Driven Transitions
The `FormManager` will listen for `transformation_requested` signals from the Morphomon Scanner.

#### Consequences
- **Pros:** Clean separation of logic; adding new creatures just requires adding a new node; easy to debug individual states.
- **Cons:** Slightly more initial setup than a simple switch statement.

#### Implementation Plan (Kaylee)
1.  Create `scripts/form_manager.gd`.
2.  Refactor `player.gd` to delegate physics and animation updates to the active child of `FormManager`.
3.  Implement the first state: `HumanForm`.

### ADR-002: Morphomon Scanner System

*   **Status:** Proposed
*   **Owner:** Mal (Lead)
*   **Collaborators:** Kaylee (Game Dev), Wash (Level & Art)
*   **Date:** 2026-04-19

#### Context
The core gameplay loop requires a way for the player to "acquire" new forms. The "Morphomon Scanner" is a handheld tool used to identify and record the DNA of magical creatures.

#### Decision
We will implement the scanner as a **RayCast2D or Area2D-based detection system** attached to the player.

#### Components
1.  **Scanner (Node2D):** Attached to the Player. Handles the logic of "scanning" a target.
2.  **Scannable (Area2D/Component):** A component attached to NPC creatures that contains their `Form` data.
3.  **DNA Bank (Resource):** A global or player-owned resource that tracks which forms have been unlocked.

#### Interaction Flow
1.  Player holds a "Scanner" button (e.g., Right Click or Shift).
2.  The Scanner projects a beam/cone.
3.  If it hits a `Scannable` target for X seconds:
    - Target provides a `BaseForm` script/type.
    - `DNA Bank` adds the new form.
    - `FormManager` is notified that a new form is available.

#### Consequences
- **Pros:** Encourages exploration; provides a clear "catch 'em all" progression; modular design makes adding scannable objects easy.
- **Cons:** Requires clear visual feedback (Wash) so players know what is scannable.

#### Implementation Plan
1.  **Kaylee:** Create `scripts/scannable.gd` component.
2.  **Kaylee:** Implement `scripts/scanner.gd` logic.
3.  **Wash:** Create visual feedback (beam/progress bar) for the scanning process.

### ADR-003: Morphomon DNA Bank UI

*   **Status:** Proposed
*   **Owner:** Mal (Lead)
*   **Collaborators:** Wash (Level & Art), Kaylee (Game Dev)
*   **Date:** 2026-04-19

#### Context
As the player scans more creatures, cycling through forms with a single key ('T') becomes inefficient. The player needs a visual "Bank" to see all unlocked forms and select them.

#### Decision
We will implement a **Grid-based DNA Bank UI** that overlays the game.

#### Features
1.  **Toggleable Menu:** Opened with the `TAB` key.
2.  **Dynamic Grid:** Automatically populates based on the forms available in the `FormManager`.
3.  **Visual Feedback:** Shows the currently active form with a highlight.
4.  **Selection:** Clicking a form icon (or using keys) switches the player instantly.

#### Technical Approach
- **DNA_Bank (Control):** A new UI component inside `HUD.tscn`.
- **Signals:** `FormManager` will emit a `form_unlocked` signal when a new form is added so the UI can refresh.

#### Implementation Plan
1.  **Kaylee:** Add `inventory` input action (TAB) to `project.godot`.
2.  **Kaylee:** Update `FormManager` to emit `form_unlocked`.
3.  **Wash:** Design the Grid UI in `scenes/hud.tscn`.
4.  **Kaylee:** Implement the logic to populate the grid and handle form selection.

## Governance

- All meaningful changes require team consensus
- Document architectural decisions here
- Keep history focused on work, decisions focused on direction
