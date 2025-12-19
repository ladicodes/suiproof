# SuiProof Deployment

## Package ID
```
0xde8566572a488eb1cb87145ef1333e99981b711192d92cf9e84e85626bbcee47
```

## Network
- **Network**: Sui Devnet
- **Transaction Digest**: `HuC2M1cHiJ1foC3CCREKtteVpm7qPDmWahm9dgtDbfkS`
- **Published**: December 19, 2025

## Module
`suiproof::document_proof`

## Entry Functions
- `create_proof(doc_hash: vector<u8>, expires_at_ms: u64, clock: &Clock, ctx: &mut TxContext)`
- `verify_proof(proof: &DocumentProof, provided_hash: vector<u8>, clock: &Clock)`
- `revoke_proof(proof: &mut DocumentProof, ctx: &TxContext)`
- `extend_expiry(proof: &mut DocumentProof, new_expires_at_ms: u64, clock: &Clock, ctx: &TxContext)`
- `burn_expired(proof: DocumentProof, clock: &Clock)`

## Explorer
https://testnet.suivision.xyz/package/0xde8566572a488eb1cb87145ef1333e99981b711192d92cf9e84e85626bbcee47
