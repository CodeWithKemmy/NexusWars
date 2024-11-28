module nexuswars::core;

    use std::string::{Self, String};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::event;
    use sui::sui::SUI;
    use sui::table::{Self, Table};

    // ======== Error Constants ========
    const EInvalidAgentType: u64 = 0;
    const EInvalidRiskProfile: u64 = 1;
    const EInvalidEvolutionStage: u64 = 2;
    // const EInsufficientBalance: u64 = 3;
    const EInvalidStrategyRequirements: u64 = 4;

    // ======== Core Structs ========
    public struct TradingAgent has key, store {
        id: UID,
        genome: vector<u8>,
        performance_history: vector<TradeResult>,
        specialization: AgentType,
        experience: u64,
        evolution_stage: u8,
        mutation_rate: u64,
        training_data: vector<MarketData>,
        metadata: Table<String, String>,
    }

    public struct AgentType has copy, drop, store {
        primary_strategy: u8,
        risk_profile: u8,
        market_focus: vector<u8>,
        time_horizon: u64,
    }

    public struct TradeResult has store, drop {
        timestamp: u64,
        profit_loss: u64,
        strategy_used: u8,
        market_conditions: MarketState,
    }

    public struct MarketData has store, drop {
        timestamp: u64,
        price: u64,
        volume: u64,
        market_type: u8,
        additional_metrics: vector<u64>,
    }

    public struct MarketState has store, drop {
        volatility: u64,
        trend: u64,
        liquidity: u64,
        timestamp: u64,
    }

    public struct Legion has key {
        id: UID,
        owner: address,
        agents: vector<TradingAgent>,
        treasury: Balance<SUI>,
        reputation: u64,
        achievements: vector<Achievement>,
        alliance_memberships: vector<ID>,
        deployment_history: vector<DeploymentRecord>,
    }

    public struct Achievement has store, drop {
        id: u64,
        name: String,
        timestamp: u64,
        score: u64,
    }

    public struct DeploymentRecord has store, drop {
        timestamp: u64,
        strategy_id: ID,
        performance: u64,
        duration: u64,
    }

    public struct Strategy has key {
        id: UID,
        creator: address,
        agent_requirements: vector<AgentType>,
        risk_level: u8,
        expected_returns: u64,
        execution_logic: vector<u8>,
        performance_history: vector<PerformanceRecord>,
    }

    public struct PerformanceRecord has store, drop {
        timestamp: u64,
        returns: u64,
        risk_metrics: vector<u64>,
        market_conditions: MarketState,
    }

    // ======== Events ========
    // Updated event structs to follow Sui's event pattern
    public struct AgentCreated has copy, drop {
        agent_id: address,
        creator: address,
        specialization: AgentType,
        timestamp: u64,
    }

    public struct LegionFormed has copy, drop {
        legion_id: address,
        owner: address,
        initial_agent_count: u64,
        timestamp: u64,
    }

    public struct StrategyDeployed has copy, drop {
        strategy_id: address,
        legion_id: address,
        timestamp: u64,
    }

    public struct AgentEvolved has copy, drop {
        agent_id: address,
        new_evolution_stage: u8,
        timestamp: u64,
    }

    // ======== Core Functions ========
   
    public fun create_agent(
        genome: vector<u8>,
        primary_strategy: u8,
        risk_profile: u8,
        market_focus: vector<u8>,
        time_horizon: u64,
        ctx: &mut TxContext,
    ): TradingAgent {

        let specialization = AgentType {
            primary_strategy,
            risk_profile,
            market_focus,
            time_horizon
        };

        assert!(specialization.risk_profile <= 100, EInvalidRiskProfile);
        assert!(specialization.primary_strategy < 255, EInvalidAgentType);

        let mut metadata = table::new<String, String>(ctx);

        // Convert epoch number to string representation
        let epoch_bytes = number_to_string(tx_context::epoch(ctx));
        table::add(&mut metadata, string::utf8(b"creation_time"), string::utf8(epoch_bytes));

        let agent = TradingAgent {
            id: object::new(ctx),
            genome,
            performance_history: vector::empty(),
            specialization,
            experience: 0,
            evolution_stage: 0,
            mutation_rate: 5,
            training_data: vector::empty(),
            metadata,
        };

        // Emit agent creation event
        event::emit(AgentCreated {
            agent_id: object::uid_to_address(&agent.id),
            creator: tx_context::sender(ctx),
            specialization: agent.specialization,
            timestamp: tx_context::epoch(ctx),
        });

        agent
    }

    // Helper function to convert a number to its string representation as bytes
    fun number_to_string(num: u64): vector<u8> {
        if (num == 0) {
            return vector[48] // ASCII '0'
        };

        let mut bytes = vector::empty<u8>();
        let mut n = num;

        while (n > 0) {
            let digit = ((n % 10) as u8) + 48; // Convert to ASCII
            vector::push_back(&mut bytes, digit);
            n = n / 10;
        };

        // Reverse the bytes since we added digits from right to left
        let len = vector::length(&bytes);
        let mut i = 0;
        while (i < len / 2) {
            let j = len - i - 1;
            let temp = *vector::borrow(&bytes, i);
            *vector::borrow_mut(&mut bytes, i) = *vector::borrow(&bytes, j);
            *vector::borrow_mut(&mut bytes, j) = temp;
            i = i + 1;
        };

        bytes
    }

    public fun create_legion(
        initial_agents: vector<TradingAgent>,
        initial_deposit: Coin<SUI>,
        ctx: &mut TxContext,
    ): Legion {
        let treasury = coin::into_balance(initial_deposit);
        let initial_agent_count = vector::length(&initial_agents);

        let legion = Legion {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            agents: initial_agents,
            treasury,
            reputation: 0,
            achievements: vector::empty(),
            alliance_memberships: vector::empty(),
            deployment_history: vector::empty(),
        };

        // Emit legion creation event with updated event structure
        event::emit(LegionFormed {
            legion_id: object::uid_to_address(&legion.id),
            owner: tx_context::sender(ctx),
            initial_agent_count,
            timestamp: tx_context::epoch(ctx),
        });

        legion
    }

    public fun share_legion(self: Legion) {
        transfer::share_object(self);
    }

    public fun deploy_strategy(legion: &mut Legion, strategy: &Strategy, ctx: &mut TxContext) {
        // Check if legion has sufficient balance to deploy strategy

        // Verify strategy requirements are met
        verify_strategy_requirements(&legion.agents, &strategy.agent_requirements);

        // Record deployment
        let deployment = DeploymentRecord {
            timestamp: tx_context::epoch(ctx),
            strategy_id: object::uid_to_inner(&strategy.id),
            performance: 0,
            duration: 0,
        };
        vector::push_back(&mut legion.deployment_history, deployment);

        // Emit strategy deployment event with updated event structure
        event::emit(StrategyDeployed {
            strategy_id: object::uid_to_address(&strategy.id),
            legion_id: object::uid_to_address(&legion.id),
            timestamp: tx_context::epoch(ctx),
        });
    }

    public fun evolve_agent(agent: &mut TradingAgent, new_genome: vector<u8>, ctx: &mut TxContext) {
        assert!(agent.evolution_stage < 255, EInvalidEvolutionStage);

        agent.genome = new_genome;
        agent.evolution_stage = agent.evolution_stage + 1;

        // Convert epoch number to string representation for metadata
        let epoch_bytes = number_to_string(tx_context::epoch(ctx));
        table::add(&mut agent.metadata, string::utf8(b"last_evolution"), string::utf8(epoch_bytes));

        // Emit agent evolution event
        event::emit(AgentEvolved {
            agent_id: object::uid_to_address(&agent.id),
            new_evolution_stage: agent.evolution_stage,
            timestamp: tx_context::epoch(ctx),
        });
    }

    // ======== Helper Functions ========

    fun verify_strategy_requirements(agents: &vector<TradingAgent>, requirements: &vector<AgentType>) {
        let mut i = 0;
        while (i < vector::length(requirements)) {
            let req = vector::borrow(requirements, i);
            assert!(has_compatible_agent(agents, req), EInvalidStrategyRequirements);
            i = i + 1;
        }
    }

    fun has_compatible_agent(agents: &vector<TradingAgent>, requirement: &AgentType): bool {
        let mut i = 0;
        while (i < vector::length(agents)) {
            let agent = vector::borrow(agents, i);
            if (is_agent_compatible(&agent.specialization, requirement)) {
                return true
            };
            i = i + 1;
        };
        false
    }

    fun is_agent_compatible(agent_type: &AgentType, requirement: &AgentType): bool {
        if (agent_type.primary_strategy != requirement.primary_strategy) {
            return false
        };
        if (agent_type.risk_profile < requirement.risk_profile) {
            return false
        };
        // Add more compatibility checks as needed
        true
    }

    // // ======== Test Functions ========
    // #[test]
    // fun test_create_agent() {
    //     let mut ctx = tx_context::dummy();

    //     let agent_type = AgentType {
    //         primary_strategy: 0,
    //         risk_profile: 50,
    //         market_focus: vector::empty(),
    //         time_horizon: 86400
    //     };

    //     let agent = create_agent(
    //         vector::empty(),
    //         agent_type,
    //         &mut ctx
    //     );

    //     assert!(agent.evolution_stage == 0, 0);
    //     assert!(agent.experience == 0, 1);
    // }
