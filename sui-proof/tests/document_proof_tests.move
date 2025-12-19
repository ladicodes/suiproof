#[test_only]
module suiproof::document_proof_tests {
    use sui::clock;
    use sui::tx_context;
    use std::vector;
    use suiproof::document_proof;

    #[test]
    fun create_and_verify_ok() {
        let owner = @0x1;
        let mut ctx = tx_context::dummy();
        let clock_obj = clock::create_for_testing(&mut ctx);
        let now = clock::timestamp_ms(&clock_obj);
        let expires = now + 1000;
        let hash = vector[1u8, 2u8, 3u8];
        let proof = document_proof::create_proof_for_tests(owner, copy hash, expires, &clock_obj, &mut ctx);
        document_proof::verify_proof(&proof, copy hash, &clock_obj);
        let (stored_hash, stored_owner, _, active) = document_proof::get_details(&proof);
        assert!(stored_owner == owner, 0);
        assert!(vector::length(&stored_hash) == vector::length(&hash), 0);
        assert!(active, 0);
        document_proof::destroy_for_tests(proof);
        clock::destroy_for_testing(clock_obj);
    }

    #[test, expected_failure(abort_code = 2, location = suiproof::document_proof)]
    fun revoked_fails_verify() {
        let owner = @0x2;
        let mut ctx = tx_context::dummy();
        let clock_obj = clock::create_for_testing(&mut ctx);
        let expires = clock::timestamp_ms(&clock_obj) + 1000;
        let mut proof = document_proof::create_proof_for_tests(owner, vector[7u8], expires, &clock_obj, &mut ctx);
        document_proof::revoke_with_address(owner, &mut proof);
        document_proof::verify_proof(&proof, vector[7u8], &clock_obj);
        document_proof::destroy_for_tests(proof);
        clock::destroy_for_testing(clock_obj);
    }

    #[test]
    fun extend_allows_verify() {
        let owner = @0x3;
        let mut ctx = tx_context::dummy();
        let clock_obj = clock::create_for_testing(&mut ctx);
        let now = clock::timestamp_ms(&clock_obj);
        let mut proof = document_proof::create_proof_for_tests(owner, vector[9u8], now + 50, &clock_obj, &mut ctx);
        document_proof::extend_with_address(owner, &mut proof, now + 5000, &clock_obj);
        document_proof::verify_proof(&proof, vector[9u8], &clock_obj);
        document_proof::destroy_for_tests(proof);
        clock::destroy_for_testing(clock_obj);
    }

    #[test]
    fun burn_expired_succeeds() {
        let owner = @0x4;
        let mut ctx = tx_context::dummy();
        let clock_obj = clock::create_for_testing(&mut ctx);
        let proof = document_proof::create_expired_proof_for_tests(owner, vector[5u8], 0, &mut ctx);
        document_proof::burn_expired(proof, &clock_obj);
        clock::destroy_for_testing(clock_obj);
    }
}
