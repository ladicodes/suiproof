# SuiProof

Move package for self-destructing, hash-only document verification on Sui.

## Module
- `suiproof::document_proof` manages `DocumentProof` objects with create, verify, revoke, extend, and burn-on-expiry flows.

## Tests
- Run `sui move test` from the package root.

## Entry points
- `create_proof(owner, doc_hash, expires_at_ms, clock, ctx)`
- `verify_proof(proof, provided_hash, clock)`
- `revoke_proof(owner, proof)`
- `extend_expiry(owner, proof, new_expires_at_ms, clock)`
- `burn_expired(proof, clock)`

## Notes
- Only hashes are stored on-chain.
- Expiry is enforced with `Clock`; anyone can burn expired proofs to reclaim storage.
