#[test_only]
module nexuswars::test {
    use sui::test_scenario::{Self as ts, next_tx};
    use sui::coin::{mint_for_testing};
    use sui::sui::{SUI};

    use std::string::{Self, String};
    use std::debug::print;

    use nexuswars::helpers::init_test_helper;
    use nexuswars::core::{Self as core};

    const ADMIN: address = @0xe;
    const TEST_ADDRESS1: address = @0xee;
    const TEST_ADDRESS2: address = @0xbb;

   #[test]
    public fun test1() {
        let mut scenario_test = init_test_helper();
        let scenario = &mut scenario_test;

        // set platfrom shared object  
        next_tx(scenario, TEST_ADDRESS1);
        {
   
        };

    

        ts::end(scenario_test);
    }


}