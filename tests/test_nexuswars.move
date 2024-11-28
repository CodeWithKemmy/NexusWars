#[test_only]
module nexuswars::test {
    use sui::test_scenario::{Self as ts, next_tx};
    use sui::coin::{mint_for_testing};
    use sui::sui::{SUI};

    use std::string::{Self, String};
    use std::debug::print;

    use nexuswars::helpers::init_test_helper;
    use nexuswars::core::{Self as core, TradingAgent, Legion};

    const ADMIN: address = @0xe;
    const TEST_ADDRESS1: address = @0xee;
    const TEST_ADDRESS2: address = @0xbb;

   #[test]
    public fun test1() {
        let mut scenario_test = init_test_helper();
        let scenario = &mut scenario_test;

        // create agent
        next_tx(scenario, TEST_ADDRESS1);
        {
            let genome = b"type";
            let primary_strategy: u8 = 1;
            let risk_profile: u8 = 2;
            let market_focus = b"market";
            let time_horizon: u64 = 50;

            let agent = core::create_agent(genome, primary_strategy, risk_profile, market_focus, time_horizon, ts::ctx(scenario));
            transfer::public_transfer(agent, TEST_ADDRESS1);
        };
        // create legion
        next_tx(scenario, TEST_ADDRESS1);
        {
            let agent = ts::take_from_sender<TradingAgent>(scenario);
            let mut initial_agents = vector::empty<TradingAgent>();
            initial_agents.push_back(agent);

            let initial_deposit = mint_for_testing<SUI>(1_000_000_000, ts::ctx(scenario));

            let legion = core::create_legion(initial_agents, initial_deposit, ts::ctx(scenario));

            core::share_legion(legion);
        };





        ts::end(scenario_test);
    }


}