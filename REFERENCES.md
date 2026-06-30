# External References

This repo is the domain implementation for ZK ballot voting. Blockchain anchoring and
cross-device sync are delegated to a separate, generic wallet — not duplicated here.

| Repo | What it's for | This repo's integration point |
|---|---|---|
| [`../wallet`](../wallet) | Generic offline/online BSV wallet with a protocol-adapter layer | Integrate via [`PROTOCOL_ADAPTER_SPEC.md`](../wallet/PROTOCOL_ADAPTER_SPEC.md) — implement `ProtocolAdapter` and self-register by `id`/`tags`/`discoveryMetadata`, no naming coupling required. The wallet's own `BallotAdapter` (`../wallet/src/adapters/ballot-adapter.ts`) mirrors this domain's ballot lifecycle (create-ballot → cast-vote → tally-votes → register-nullifier → update-ballot-phase) as a worked example, not a dependency. |

See [`../wallet/REFERENCES.md`](../wallet/REFERENCES.md) for the wallet's own external-reference catalog (BSV SDKs, sCrypt examples, BRC-100/Paymail research).

## This repo's own functions

[`FUNCTIONS.md`](FUNCTIONS.md) maps the public API of every implemented module under `src/modules/`
(zkproof, merkle, threshold/Shamir, quadratic, runoff/IRV, delegation, incentives, analytics, recovery)
as mermaid class/sequence diagrams — same documentation pattern as
[`cad-master/docs/readme-functions.md`](../cad-master/docs/readme-functions.md) and
[`wallet/FLOWS.md`](../wallet/FLOWS.md)§13.
