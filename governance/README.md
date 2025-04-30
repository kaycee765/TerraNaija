### 📄 **README: TerraNaija - Off-World Soil Renewal Protocol**

---

#### 🌍 Overview

**TerraNaija** is a decentralized Clarity smart contract protocol designed to manage contributions, direct resource allocations, and govern colony participation in **off-world soil rehabilitation initiatives**. The protocol ensures transparent, accountable, and fair distribution of terraforming support to space colonies based on verified status and performance metrics.

---

#### 🚀 Key Features

- **Decentralized Contribution System:** Pioneers can contribute STX tokens to a global terraforming vault supporting interplanetary rehabilitation.
- **Colony Management:** Colonies can be registered, monitored, and funded by a designated director with transparency and traceability.
- **Soil Status Tracking:** Updates on the soil conditions of each colony (e.g., *barren*, *processing*, *fertile*, *sustaining*) ensure dynamic assessment and needs-based support.
- **Program State Control:** The director can pause, resume, or activate quarantine modes in emergency or special conditions.
- **Governance:** The protocol allows for the secure transition of leadership via the `change-director` function.

---

#### 🧑‍💼 Roles

- **Terraforming Director**: The central authority responsible for registering colonies, allocating resources, updating soil statuses, and managing system state.
- **Pioneers**: Contributors who fund the program via STX, tracked in the Pioneer Registry.
- **Rehabilitation Colonies**: Off-world bases eligible for rehabilitation support based on registered status and verified soil status.

---

#### 🛠️ Functions

| Category                | Function                             | Description |
|------------------------|--------------------------------------|-------------|
| Contributions          | `contribute-to-terraforming`         | Contribute STX to the vault |
| Colony Registration     | `register-rehabilitation-colony`     | Director-only colony onboarding |
| Resource Allocation     | `allocate-resources`                 | Transfers STX to colonies |
| Soil Status             | `update-soil-status`                 | Tracks and updates soil conditions |
| Governance              | `change-director`                    | Appoint new terraforming director |
| Admin Controls          | `set-contribution-minimum`           | Set minimum STX contribution |
|                        | `toggle-program-status`              | Pause/resume program |
|                        | `set-quarantine-mode-on/off`         | Emergency isolation mode |
| Read-Only               | `get-colony-info`, `get-pioneer-info`| View data on colonies and pioneers |

---

#### 🧪 Soil Status Codes

| Code         | Meaning |
|--------------|---------|
| `barren`     | No growth, needs full intervention |
| `processing` | Undergoing transformation |
| `fertile`    | Suitable for planting |
| `sustaining` | Self-sufficient status |

---

#### ⚖️ Constants & Limits

- **Minimum Contribution**: `1 STX` (default)
- **Maximum Single Contribution**: `1,000,000 STX` (sanity check)
- **Error Codes**:
  - `u100` – Not authorized
  - `u101` – Colony already registered
  - `u102` – Colony not registered
  - `u103` – Insufficient resources
  - `u104` – Contribution too small
  - `u105` – Program is paused
  - `u106` – Invalid contribution
  - `u107` – Invalid soil status
  - `u108` – Invalid director address

---
