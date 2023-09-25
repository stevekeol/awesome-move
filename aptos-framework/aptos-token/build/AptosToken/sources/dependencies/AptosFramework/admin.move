///
module aptos_framework::admin {
	const INIT_FEE_POINT: u8 = 250; //2.5%

	const EPROJECT_HAS_PUBLISHED: u64 = 1;

	const SALT: vector<u8> = b"Aptos::protocol";

	struct StreamEvent has drop, store {
		id: u64,
		
	}
}