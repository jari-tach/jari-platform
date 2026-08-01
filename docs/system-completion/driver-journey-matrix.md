# Driver Journey Matrix

> **Audit date:** 2026-08-02  
> **Statuses:** `wired` | `partial` | `fake` | `blocked`  
> **Mode:** Remote backend assumed for “wired”; Fake mode still available for local/dev.

| Stage | Path / entry | Status | Evidence / notes |
|-------|--------------|--------|------------------|
| OTP | Login → OTP → session | **wired** | Remote auth + I-key verify; device UUID; busy guards |
| Profile | Home / Profile tab → load / edit | **wired** | Remote GET/PATCH profile + compliance (non-blocking) |
| Availability | Home toggle available/unavailable | **blocked** → **partial** on WIP | HEAD: #32 wire bug + deny-safe eligibility. WIP branch: wire+eligibility fixed but unmerged; remote repo still may treat `unavailable→available` as suspended (**P0**) |
| Offer accept | Incoming offer / home banner → accept | **wired** | Remote accept + busy bind; PR #31/#33 unblocked Device QA path |
| Offer reject | Offer reject CTA | **wired** | Remote reject + I-key |
| Pickup | Active delivery → Confirm pickup | **wired** | Remote confirm pickup; PR #35 revision scope |
| Navigate | Active delivery Maps CTA | **partial** / **fake** | Clipboard Maps URL only; no launcher on this CTA |
| Arrival | Auto geofence (no button) | **wired** (device) / **fake** (fake location) | Automatic only; remote arrival POST + evidence |
| Delivery | Verify → confirm delivery | **wired** | Remote confirm (code ignored); Fake still uses verify code |
| Cancel | Verify / issue cancel | **wired** | Remote cancel or Fake local record |
| Issue | Report issue page | **wired** | Remote issues POST or Fake workflow |
| Logout | Settings → confirm | **wired** | Availability prep + auth logout + realtime teardown |

---

## End-to-end path (remote)

```text
OTP (Remote)
  → Profile (Remote)
  → Availability (Remote) ⚠ #32 / suspend-gate
  → Offer Accept|Reject (Remote + Realtime resync)
  → Confirm Pickup (Remote)
  → Navigate (Clipboard placeholder)
  → Arrival (Geofence → Remote)
  → Confirm Delivery (Remote)
  → Cancel | Report Issue (Remote)
  → Logout (Remote best-effort + local clear)
```

---

## Adjacent journeys (not full product wire)

| Journey | Status | Notes |
|---------|--------|-------|
| Batch offer → multi-stop | **fake** | `FakeBatchService` UI; remote GET active batch unused by batch screens |
| Earnings / history / notifications | **fake** | Fixture repos; null in production |
| Vehicle / documents KYC | **fake** | In-memory STEP 2A |
| Home metrics strip | **fake** | `FakeHomeSummary`; hidden in production |
| Support contact | **fake** / unavailable | Intentional |

---

## Blockers for full remote journey (code)

1. **Merge + complete Issue #32** (wire + eligibility + remove/narrow suspended gate on unavailable).  
2. **Navigate CTA** should use external navigation gateway if product requires real Maps handoff.  
3. **Batch UI** remains Fake until accept/reject/stop flow binds to lifecycle remote.
