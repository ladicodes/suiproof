module suiproof::document_proof {
    use sui::clock::{Self, Clock};
    use sui::event;
    use sui::object;
    use sui::transfer;
    use sui::tx_context::TxContext;
    use std::vector;

    const ERR_ALREADY_EXPIRED: u64 = 0;
    const ERR_NOT_OWNER: u64 = 1;
    const ERR_INACTIVE: u64 = 2;
    const ERR_EXPIRED: u64 = 3;
    const ERR_HASH_MISMATCH: u64 = 4;
    const ERR_NEW_EXPIRY_NOT_LATER: u64 = 5;
    const ERR_EMPTY_HASH: u64 = 6;
    const ERR_NOT_EXPIRED_FOR_BURN: u64 = 7;

    public struct DocumentProof has key {
        id: object::UID,
        doc_hash: vector<u8>,
        owner: address,
        expires_at_ms: u64,
        active: bool,
    }
    public struct ProofCreated has copy, drop, store {
        owner: address,
        expires_at_ms: u64,
    }
    public struct ProofRevoked has copy, drop, store {
        owner: address,
        proof_id: object::ID,
    }
    public struct ProofExtended has copy, drop, store {
        owner: address,
        proof_id: object::ID,
        new_expires_at_ms: u64,
    }
    public entry fun create_proof(
        doc_hash: vector<u8>,
        expires_at_ms: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        let owner = tx_context::sender(ctx);
        let proof = build_proof(owner, doc_hash, expires_at_ms, clock, ctx);
        event::emit(ProofCreated { owner, expires_at_ms });
        transfer::transfer(proof, owner);
    }
    public fun verify_proof(proof: &DocumentProof, provided_hash: vector<u8>, clock: &Clock) {
        assert_valid(proof, &provided_hash, clock);
    }
    public fun is_expired(proof: &DocumentProof, clock: &Clock): bool {
        let now = clock::timestamp_ms(clock);
        now >= proof.expires_at_ms
    }
    public entry fun revoke_proof(proof: &mut DocumentProof, ctx: &TxContext) {
        let sender = tx_context::sender(ctx);
        assert_owner(sender, proof);
        if (!proof.active) {
            return
        };
        proof.active = false;
        event::emit(ProofRevoked { owner: sender, proof_id: object::uid_to_inner(&proof.id) });
    }
    public entry fun extend_expiry(
        proof: &mut DocumentProof,
        new_expires_at_ms: u64,
        clock: &Clock,
        ctx: &TxContext,
    ) {
        let sender = tx_context::sender(ctx);
        assert_owner(sender, proof);
        let now = clock::timestamp_ms(clock);
        assert!(new_expires_at_ms > proof.expires_at_ms, ERR_NEW_EXPIRY_NOT_LATER);
        assert!(new_expires_at_ms > now, ERR_ALREADY_EXPIRED);
        proof.expires_at_ms = new_expires_at_ms;
        proof.active = true;
        event::emit(ProofExtended {
            owner: sender,
            proof_id: object::uid_to_inner(&proof.id),
            new_expires_at_ms,
        });
    }
    public fun burn_expired(proof: DocumentProof, clock: &Clock) {
        assert!(is_expired(&proof, clock), ERR_NOT_EXPIRED_FOR_BURN);
        let DocumentProof { id, doc_hash: _, owner: _, expires_at_ms: _, active: _ } = proof;
        object::delete(id);
    }
    public fun get_details(proof: &DocumentProof): (vector<u8>, address, u64, bool) {
        (copy proof.doc_hash, proof.owner, proof.expires_at_ms, proof.active)
    }
    public fun assert_valid(proof: &DocumentProof, provided_hash: &vector<u8>, clock: &Clock) {
        assert!(proof.active, ERR_INACTIVE);
        assert!(!is_expired(proof, clock), ERR_EXPIRED);
        assert!(hash_equals(&proof.doc_hash, provided_hash), ERR_HASH_MISMATCH);
    }

    fun hash_equals(a: &vector<u8>, b: &vector<u8>): bool {
        let len_a = vector::length(a);
        let len_b = vector::length(b);
        if (len_a != len_b) {
            return false
        };
        let mut i = 0;
        while (i < len_a) {
            if (*vector::borrow(a, i) != *vector::borrow(b, i)) {
                return false
            };
            i = i + 1;
        };
        true
    }

    fun assert_owner(caller: address, proof: &DocumentProof) {
        assert!(caller == proof.owner, ERR_NOT_OWNER);
    }

    fun build_proof(owner: address, doc_hash: vector<u8>, expires_at_ms: u64, clock: &Clock, ctx: &mut TxContext): DocumentProof {
        assert!(vector::length(&doc_hash) > 0, ERR_EMPTY_HASH);
        let now = clock::timestamp_ms(clock);
        assert!(expires_at_ms > now, ERR_ALREADY_EXPIRED);
        DocumentProof { id: object::new(ctx), doc_hash, owner, expires_at_ms, active: true }
    }

    #[test_only]
    public fun create_proof_for_tests(owner: address, doc_hash: vector<u8>, expires_at_ms: u64, clock: &Clock, ctx: &mut TxContext): DocumentProof {
        build_proof(owner, doc_hash, expires_at_ms, clock, ctx)
    }

    #[test_only]
    public fun create_expired_proof_for_tests(owner: address, doc_hash: vector<u8>, expires_at_ms: u64, ctx: &mut TxContext): DocumentProof {
        assert!(vector::length(&doc_hash) > 0, ERR_EMPTY_HASH);
        DocumentProof { id: object::new(ctx), doc_hash, owner, expires_at_ms, active: true }
    }

    #[test_only]
    public fun revoke_with_address(owner: address, proof: &mut DocumentProof) {
        assert!(owner == proof.owner, ERR_NOT_OWNER);
        if (!proof.active) {
            return
        };
        proof.active = false;
    }

    #[test_only]
    public fun extend_with_address(owner: address, proof: &mut DocumentProof, new_expires_at_ms: u64, clock: &Clock) {
        assert!(owner == proof.owner, ERR_NOT_OWNER);
        let now = clock::timestamp_ms(clock);
        assert!(new_expires_at_ms > proof.expires_at_ms, ERR_NEW_EXPIRY_NOT_LATER);
        assert!(new_expires_at_ms > now, ERR_ALREADY_EXPIRED);
        proof.expires_at_ms = new_expires_at_ms;
        proof.active = true;
    }

    #[test_only]
    public fun destroy_for_tests(proof: DocumentProof) {
        let DocumentProof { id, doc_hash: _, owner: _, expires_at_ms: _, active: _ } = proof;
        object::delete(id);
    }
}
