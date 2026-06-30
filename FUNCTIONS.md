# Mapa de funciones implementadas

Referencia rápida de la superficie pública real de los módulos en `src/modules/`. Mismo propósito que
[`cad-master/docs/readme-functions.md`](../cad-master/docs/readme-functions.md) y
[`wallet/FLOWS.md`](../wallet/FLOWS.md)#13: documentar funciones ya desarrolladas, no diseño a futuro.
Sólo la clase/función principal de cada módulo está diagramada — las clases secundarias
(`InstantRunoffVoting`, `MultiDeviceRecovery`, `VerificationEconomy`, `SparseMerkleTree`) se mencionan
pero no se expanden, para mantener esto como referencia, no como spec completa.

## Índice
1. ZK Proofs — `modules/zkproof`
2. Merkle — `modules/merkle`
3. Threshold / Shamir — `modules/threshold`
4. Quadratic Voting — `modules/quadratic`
5. Runoff / IRV — `modules/runoff`
6. Delegation — `modules/delegation`
7. Verifier Incentives — `modules/incentives`
8. Analytics — `modules/analytics`
9. Recovery — `modules/recovery`

---

## ZK Proofs — `modules/zkproof`

```mermaid
classDiagram
    class zkproof {
        +compileCircuit(circuitPath, options?) Promise~CompiledCircuit~
        +setup(circuit) Promise~SetupKeys~
        +generateProof(circuit, witness, provingKey) Promise~ZKProof~
        +verifyProof(proof, publicInputs, verificationKey) Promise~boolean~
        +generateVoteProof(vote, voterSecret, merkleProof, provingKey) Promise~ZKProof~
        +verifyVoteProof(proof, publicInputs, verificationKey) Promise~boolean~
        +serializeProof(proof) string
        +deserializeProof(proofString) ZKProof
        +preparePublicInputs(inputs) string[]
        +computeProofHash(proof) string
        +loadProvingKey(filePath) Promise~Uint8Array~
        +saveProvingKey(key, filePath) Promise~void~
        +loadVerificationKey(filePath) Promise~Uint8Array~
        +saveVerificationKey(key, filePath) Promise~void~
        +exportVerificationKey(keys) Promise~object~
    }
```

```mermaid
sequenceDiagram
    participant V as Voter
    participant ZK as zkproof module
    participant M as merkle module
    participant Chain as Verifier (on-chain o servicio)

    V->>M: generateMerkleProof(tree, voterIndex)
    M-->>V: MerkleProof
    V->>ZK: generateVoteProof(vote, voterSecret, merkleProof, provingKey)
    Note over ZK: circuit prueba: "conozco un secreto cuyo\ncommitment está en el árbol" sin revelar cuál
    ZK-->>V: ZKProof
    V->>Chain: submit(proof, publicInputs)
    Chain->>ZK: verifyVoteProof(proof, publicInputs, verificationKey)
    ZK-->>Chain: boolean
```

> El wallet's `BallotAdapter` (`../wallet/src/adapters/ballot-adapter.ts`) valida la *forma* de `zkProof`
> (`circuit`/`proof`/`publicInputs` presentes) pero no ejecuta `verifyProof()` — eso vive aquí, en este repo.

---

## Merkle — `modules/merkle`

```mermaid
classDiagram
    class merkle {
        +buildMerkleTree(voterCommitments) MerkleTree
        +getMerkleRoot(tree) string
        +generateMerkleProof(tree, index) MerkleProof
        +verifyMerkleProof(proof, root) boolean
        +getLeafIndex(tree, commitment) number
        +getLeaves(tree) string[]
        +exportTree(tree) object
        +importTree(leaves) MerkleTree
        +buildVoterTree(voters) object
    }
    class SparseMerkleTree {
        +insert(index, value) void
        +get(index) string|null
        +generateProof(index) MerkleProof
        +getRoot() string
        +export() object
    }
```

> `getMerkleRoot(tree)` es lo que el wallet's `BallotAdapter.create-ballot` espera recibir como
> `payload.merkleRoot` — este módulo es quien lo produce, el wallet solo lo transporta/ancla.

---

## Threshold / Shamir — `modules/threshold`

```mermaid
classDiagram
    class ShamirSecretSharing {
        +split(secret, threshold, totalShares) bigint[]
        +combine(shares) bigint
    }
    class ThresholdVotingSystem {
        +setupKeyShares(masterKey) Map~string,SecretShare~
        +castEncryptedVote(candidateId, encryptedVote) void
        +tallyVotes() TallyResult[]|null
        +canTally() boolean
        +getTallyStatus() object
        +getStats() object
        +toggleAuthorityStatus(authorityId, active) boolean
        +exportAuditLog() object
    }
    class threshold {
        +verifyThresholdSignature(...) boolean
    }
    ThresholdVotingSystem ..> ShamirSecretSharing : usa para repartir masterKey
```

```mermaid
sequenceDiagram
    participant Auth as Authorities (N)
    participant TVS as ThresholdVotingSystem
    participant SSS as ShamirSecretSharing

    TVS->>SSS: split(masterKey, threshold, totalShares)
    SSS-->>TVS: shares[] (uno por authority)
    TVS->>Auth: distribuye 1 share cada uno
    Note over TVS: castEncryptedVote() acumula votos cifrados\nsin que ninguna authority vea un voto individual
    Auth->>TVS: cada authority aporta su share cuando autoriza el tally
    TVS->>TVS: canTally() — ¿llegaron >= threshold shares?
    TVS->>SSS: combine(sharesRecibidos)
    SSS-->>TVS: masterKey reconstruida
    TVS->>TVS: tallyVotes()
```

---

## Quadratic Voting — `modules/quadratic`

```mermaid
classDiagram
    class QuadraticVotingSystem {
        +initializeVoter(voterId, credits?) VoiceCredit
        +removeVotes(voterId, candidateId) boolean
        +getBallot(voterId) QuadraticBallot|null
        +getVoiceCredits(voterId) VoiceCredit|null
        +getResults() Map~number,number~
        +getDetailedResults() object
        +getStats() object
        +exportBallots() Array
    }
    class quadratic {
        +calculateEfficiencyScore(...) number
    }
```

---

## Runoff / IRV — `modules/runoff`

```mermaid
classDiagram
    class RunoffVotingSystem {
        +startElection(electionId) RoundResult
        +runoffRound(electionId) RoundResult|null
        +runCompleteElection(electionId) RoundResult[]
        +getResults(electionId) object
        +getRoundBreakdown(electionId) object
    }
```

> `InstantRunoffVoting` (clase secundaria en el mismo archivo) implementa la variante de una sola
> transferencia de votos en vez de rondas eliminatorias completas — no diagramada aquí.

---

## Delegation — `modules/delegation`

```mermaid
classDiagram
    class DelegationRegistry {
        +revokeDelegation(delegatorId, ballotId) boolean
        +castDirectVote(voterId, ballotId) void
        +resolveDelegationChain(voterId) DelegationChain
        +calculateVoteWeight(voterId) number
        +getActiveDelegations() Delegation[]
        +getDelegation(delegatorId, ballotId) Delegation|null
        +getDelegatorsFor(delegateId) string[]
        +getStats() object
        +exportGraph() object
    }
    class delegation {
        +generateDelegationNullifier(...) string
        +verifyDelegationChain(...) boolean
    }
    note for DelegationRegistry "calculateVoteWeight() sigue la cadena de\ndelegación (resolveDelegationChain) para sumar\nel peso de todo voto delegado transitivamente."
```

---

## Verifier Incentives — `modules/incentives`

```mermaid
classDiagram
    class VerifierIncentiveSystem {
        +registerVerifier(address, publicKey) Verifier
        +assignTask(taskId, verifierId) boolean
        +verifyFraudClaim(bountyId, verifierIds) boolean
        +getAvailableTasks(verifierId) VerificationTask[]
        +getLeaderboard(limit?) Verifier[]
        +getVerifierStats(verifierId) object
        +getSystemStats() object
        +fundTreasury(amount) void
    }
    class incentives {
        +calculateOptimalRewards(...) object
    }
```

> `VerificationEconomy` (clase secundaria) modela el lado económico (treasury/recompensas) por separado
> de la asignación de tareas — no diagramada aquí.

---

## Analytics — `modules/analytics`

```mermaid
classDiagram
    class AnalyticsDashboard {
        +getVoteMetrics() VoteMetrics
        +getParticipationMetrics() ParticipationMetrics
        +getCandidateMetrics() CandidateMetrics[]
        +getGeographicMetrics() GeographicMetrics[]
        +detectAnomalies() AnomalyDetection
        +getPerformanceMetrics() PerformanceMetrics
        +getDashboard() object
    }
    class analytics {
        +exportMetricsToCSV(metrics) string
    }
```

---

## Recovery — `modules/recovery`

```mermaid
classDiagram
    class VoteRecoverySystem {
        +initiateRecovery(voterId) RecoveryRequest
        +executeRecovery(requestId) string|null
        +cancelRecovery(requestId, voterId) boolean
        +getRecoveryStatus(requestId) RecoveryRequest|null
        +getRecoveryConfig(voterId) RecoveryConfig|null
        +testRecovery(voterId) object
        +getStats() object
    }
```

> `MultiDeviceRecovery` (clase secundaria) cubre el caso multi-dispositivo — análogo conceptual al
> sync multi-dispositivo del wallet (`../wallet/FLOWS.md`§3), pero implementado de forma independiente
> aquí; no hay integración entre ambos todavía.
