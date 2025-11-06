# Contract Status Flow - Contractor & Contractee Views

## Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      PROJECT STATUS: awaiting_contract                  │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │  NO CONTRACT CREATED YET                                         │  │
│  │  ────────────────────────────────────────────────────────────   │  │
│  │  Contractor View: "No Contract"                                  │  │
│  │  Contractee View: "No Contract"                                  │  │
│  └─────────────────────────────────────────────────────────────────┘  │
│                           ↓                                             │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │  CONTRACT CREATED (status: draft) BUT NOT SENT                  │  │
│  │  ────────────────────────────────────────────────────────────   │  │
│  │  Contractor View: "Contract Draft"                               │  │
│  │  Contractee View: "No Contract" (hidden from contractee)       │  │
│  └─────────────────────────────────────────────────────────────────┘  │
│                           ↓                                             │
│                    CONTRACTOR SENDS CONTRACT                            │
│                           ↓                                             │
└─────────────────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                    PROJECT STATUS: awaiting_agreement                    │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │  CONTRACT SENT (status: draft, but effective: sent)              │  │
│  │  ────────────────────────────────────────────────────────────   │  │
│  │  Contractor View: "Contract Waiting for approval"                │  │
│  │  Contractee View: "Contract Waiting for approval"               │  │
│  └─────────────────────────────────────────────────────────────────┘  │
│                           ↓                                             │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │  CONTRACTEE REJECTS CONTRACT                                     │  │
│  │  ────────────────────────────────────────────────────────────   │  │
│  │  • Contract status → 'rejected'                                  │  │
│  │  • Project status → 'awaiting_contract' (GOES BACK)              │  │
│  │  • Contractor View: "No Contract"                                │  │
│  │  • Contractee View: "No Contract"                                │  │
│  └─────────────────────────────────────────────────────────────────┘  │
│                           ↓                                             │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │  CONTRACTOR EDITS REJECTED CONTRACT                               │  │
│  │  ────────────────────────────────────────────────────────────   │  │
│  │  • Contract status → 'draft' (automatically changed)              │  │
│  │  • Project status → 'awaiting_contract' (unchanged)              │  │
│  │  • Contractor View: "Contract Draft"                             │  │
│  │  • Contractee View: "No Contract" (still hidden)                 │  │
│  │                                                                   │  │
│  │  Contractor can now:                                               │  │
│  │  - Continue editing the contract                                  │  │
│  │  - Send the contract (changes project to awaiting_agreement)        │  │
│  └─────────────────────────────────────────────────────────────────┘  │
│                           ↓                                             │
│                    CONTRACTOR RESENDS CONTRACT                          │
│                           ↓                                             │
└─────────────────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                    PROJECT STATUS: awaiting_agreement                    │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │  CONTRACT SENT AGAIN (status: draft, but effective: sent)        │  │
│  │  ────────────────────────────────────────────────────────────   │  │
│  │  Contractor View: "Contract Waiting for approval"                │  │
│  │  Contractee View: "Contract Waiting for approval"               │  │
│  └─────────────────────────────────────────────────────────────────┘  │
│                           ↓                                             │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │  CONTRACTEE APPROVES CONTRACT                                    │  │
│  │  ────────────────────────────────────────────────────────────   │  │
│  │  • Contract status → 'approved'                                  │  │
│  │  • Project status → 'awaiting_signature'                        │  │
│  │  • Contractor View: "Contract Accepted"                          │  │
│  │  • Contractee View: "Contract Accepted"                          │  │
│  └─────────────────────────────────────────────────────────────────┘  │
│                           ↓                                             │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │  BOTH PARTIES SIGN                                               │  │
│  │  ────────────────────────────────────────────────────────────   │  │
│  │  • signed_pdf_url is created (only when BOTH signed)            │  │
│  │  • Project status → 'active'                                    │  │
│  │  • Contractor View: "Contract Accepted" + "Signed Contract"      │  │
│  │  • Contractee View: "Contract Accepted" + "Signed Contract"     │  │
│  └─────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

## Summary of Rules

### Contract Label Display Logic

**When `project.status = 'awaiting_contract'`:**
- If no contract exists → Both see: "No Contract"
- If contract exists with `status = 'draft'`:
  - Contractor sees: "Contract Draft"
  - Contractee sees: "No Contract" (contractee shouldn't see drafts)
- If contract exists with `status = 'rejected'`:
  - Both see: "No Contract" (treated as if no contract exists)
- **When contractor edits a rejected contract:**
  - Contract status automatically changes from `'rejected'` → `'draft'`
  - Contractor sees: "Contract Draft"
  - Contractee sees: "No Contract" (still hidden until sent)

**When `project.status = 'awaiting_agreement'`:**
- Contract must have been sent (even if `status = 'draft'` in DB)
- Both see: "Contract Waiting for approval"
- If contractee rejects → Project goes back to `awaiting_contract`

**When `project.status = 'awaiting_signature'`:**
- Contract has been approved
- Both see: "Contract Accepted"
- If `signed_pdf_url` exists → Both see additional "Signed Contract" label

**When `project.status = 'active'`:**
- Both parties have signed
- Both see: "Contract Accepted"
- If `signed_pdf_url` exists → Both see additional "Signed Contract" label

### Key Points

1. **Contractee never sees drafts** - Only sees contracts when project is `awaiting_agreement` or later
2. **Rejected contracts reset the flow** - Project goes back to `awaiting_contract`, both see "No Contract"
3. **Effective status override** - When project is `awaiting_agreement` and contract is `draft`, display as "sent"
4. **Signed Contract label** - Only shows when `signed_pdf_url` exists (both parties signed)

