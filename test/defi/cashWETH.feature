Feature: Cash-secured Wrapped Ether

    As an Option Market Maker,
    I want to use USDC to collateralize my ETH puts,
    so that I can achieve higher capital efficiency and simplify my PNL accounting.

    Scenario: Deposit USDC into vault
        Given I have 1,000,000 USDC in my wallet
        And The current price of ETH is 1,800 USDC
        And The cashWETH vault total assets is 0 USDC
        When I deposit 1,800 USDC into the cashWETH vault
        Then I should have 998,200 USDC in my wallet
        And I should have 1 cashWETH share in my wallet (balanceOf)
        And I should be able to withdraw 1,800 USDC assets for my 1 cashWETH share (previewWithdraw)
        And The cashWETH vault total assets is 1,800 USDC

    Scenario: Withdraw USDC from vault
        Given I have 1 cashWETH share in my wallet
        And The current price of ETH is 1,800 USDC
        And The cashWETH vault total assets is 1,800 USDC
        When I withdraw 1,800 USDC from the cashWETH vault
        Then I should have 1,000,000 USDC in my wallet
        And I should have 0 cashWETH shares in my wallet
        And The cashWETH vault total assets should be 0 USDC

    Scenario: Withdraw WETH from vault
        Given TODO

    Scenario: Transfer to another address and withdraw USDC from vault
        Given TODO

    Scenario: Transfer to another address and withdraw WETH from vault
        Given TODO

    Scenario: Rebalance vault when ETH price increases
        Given I have 998,200 USDC in my wallet
        And I have 1 cashWETH share in my wallet
        And The cashWETH vault total assets is 1,800 USDC
        When The price of ETH increases to 2,000 USDC
        Then I should have 998,000 USDC in my wallet
        And I should be able to withdraw 2,000 USDC assets for my 1 cashWETH share (previewWithdraw)
        And The cashWETH vault total assets should be 2,000 USDC

    Scenario: Rebalance vault when ETH price decreases
        Given I have 998,200 USDC in my wallet
        And I have 1 cashWETH share in my wallet
        And The cashWETH vault total assets is 1,800 USDC
        When The price of ETH decreases to 1,600 USDC
        Then I should have 998,400 USDC in my wallet
        And I should be able to withdraw 1,600 USDC assets for my 1 cashWETH share (previewWithdraw)
        And The cashWETH vault total assets should be 1,600 USDC

    @Revert
    Scenario: Rebalance vault when ETH price decreases, insufficient balance
        Given TODO

    @Revert
    Scenario: Rebalance vault when ETH price decreases, insufficient allowance
        Given TODO
