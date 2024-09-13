// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../contracts/LevelUsdPointsFarm.sol";
import "../contracts/mock/MockERC20.sol";

contract LevelUsdPointsFarmTest is Test {
    LevelUsdPointsFarm farm;
    MockERC20 lpToken;
    address owner = address(1);
    address user1 = address(2);
    address user2 = address(3);

    function setUp() public {
        vm.startPrank(owner);
        farm = new LevelUsdPointsFarm(owner);
        lpToken = new MockERC20("LP Token", "LPT");
        vm.stopPrank();

        lpToken.mint(user1, 1000 ether);
        lpToken.mint(user2, 1000 ether);
    }

    function testConstructorSetsOwner() public {
        assertEq(farm.owner(), owner);
    }

    function testConstructorRevertsOnZeroAddress() public {
        vm.expectRevert(abi.encodeWithSignature("ZeroAddressException()"));
        new LevelUsdPointsFarm(address(0));
    }

    function testOwnerCanSetEpoch() public {
        vm.prank(owner);
        farm.setEpoch(1);
        assertEq(farm.currentEpoch(), 1);
    }

    function testNonOwnerCannotSetEpoch() public {
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        farm.setEpoch(1);
    }

    function testCannotSetSameEpoch() public {
        vm.startPrank(owner);
        farm.setEpoch(1);
        vm.expectRevert(abi.encodeWithSignature("InvalidEpoch()"));
        farm.setEpoch(1);
        vm.stopPrank();
    }

    function testOwnerCanUpdateStakeParameters() public {
        vm.prank(owner);
        farm.updateStakeParameters(address(lpToken), 1, 1000 ether, 1 days);

        (uint8 epoch, uint248 stakeLimit, , , uint48 cooldown) = farm
            .stakeParametersByToken(address(lpToken));
        assertEq(epoch, 1);
        assertEq(stakeLimit, 1000 ether);
        assertEq(cooldown, 1 days);
    }

    function testNonOwnerCannotUpdateStakeParameters() public {
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        farm.updateStakeParameters(address(lpToken), 1, 1000 ether, 1 days);
    }

    function testCannotSetCooldownBeyondMaximum() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("MaxCooldownExceeded()"));
        farm.updateStakeParameters(address(lpToken), 1, 1000 ether, 91 days);
    }

    function testUserCanStake() public {
        vm.startPrank(owner);
        farm.setEpoch(1);
        farm.updateStakeParameters(address(lpToken), 1, 1000 ether, 1 days);
        vm.stopPrank();

        vm.startPrank(user1);
        lpToken.approve(address(farm), 100 ether);
        farm.stake(address(lpToken), 100 ether);

        (uint256 stakedAmount, , ) = farm.stakes(user1, address(lpToken));
        assertEq(stakedAmount, 100 ether);
        vm.stopPrank();
    }

    function testCannotStakeZeroAmount() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSignature("InvalidAmount()"));
        farm.stake(address(lpToken), 0);
    }

    function testCannotStakeBeyondLimit() public {
        vm.startPrank(owner);
        farm.setEpoch(1);
        farm.updateStakeParameters(address(lpToken), 1, 1000 ether, 1 days);
        vm.stopPrank();

        vm.startPrank(user1);
        lpToken.approve(address(farm), 1001 ether);
        vm.expectRevert(abi.encodeWithSignature("StakeLimitExceeded()"));
        farm.stake(address(lpToken), 1001 ether);
        vm.stopPrank();
    }

    function testCannotStakeInWrongEpoch() public {
        vm.startPrank(owner);
        farm.setEpoch(1);
        farm.updateStakeParameters(address(lpToken), 2, 1000 ether, 1 days);
        vm.stopPrank();

        vm.startPrank(user1);
        lpToken.approve(address(farm), 100 ether);
        vm.expectRevert(abi.encodeWithSignature("InvalidEpoch()"));
        farm.stake(address(lpToken), 100 ether);
        vm.stopPrank();
    }

    function testUserCanUnstake() public {
        vm.startPrank(owner);
        farm.setEpoch(1);
        farm.updateStakeParameters(address(lpToken), 1, 1000 ether, 1 days);
        vm.stopPrank();

        vm.startPrank(user1);
        lpToken.approve(address(farm), 100 ether);
        farm.stake(address(lpToken), 100 ether);

        farm.unstake(address(lpToken), 50 ether);

        (
            uint256 stakedAmount,
            uint152 coolingDownAmount,
            uint104 cooldownStartTimestamp
        ) = farm.stakes(user1, address(lpToken));
        assertEq(stakedAmount, 50 ether);
        assertEq(coolingDownAmount, 50 ether);
        assertEq(cooldownStartTimestamp, block.timestamp);
        vm.stopPrank();
    }

    function testCannotUnstakeZeroAmount() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSignature("InvalidAmount()"));
        farm.unstake(address(lpToken), 0);
    }

    function testCannotUnstakeMoreThanStaked() public {
        vm.startPrank(owner);
        farm.setEpoch(1);
        farm.updateStakeParameters(address(lpToken), 1, 1000 ether, 1 days);
        vm.stopPrank();

        vm.startPrank(user1);
        lpToken.approve(address(farm), 100 ether);
        farm.stake(address(lpToken), 100 ether);

        vm.expectRevert(abi.encodeWithSignature("InvalidAmount()"));
        farm.unstake(address(lpToken), 101 ether);
        vm.stopPrank();
    }

    function testUserCanWithdrawAfterCooldown() public {
        vm.startPrank(owner);
        farm.setEpoch(1);
        farm.updateStakeParameters(address(lpToken), 1, 1000 ether, 1 days);
        vm.stopPrank();

        vm.startPrank(user1);
        lpToken.approve(address(farm), 100 ether);
        farm.stake(address(lpToken), 100 ether);
        farm.unstake(address(lpToken), 50 ether);

        vm.warp(block.timestamp + 1 days + 1);

        farm.withdraw(address(lpToken), 50 ether);

        (uint256 stakedAmount, uint152 coolingDownAmount, ) = farm.stakes(
            user1,
            address(lpToken)
        );
        assertEq(stakedAmount, 50 ether);
        assertEq(coolingDownAmount, 0);
        vm.stopPrank();
    }

    function testCannotWithdrawBeforeCooldown() public {
        vm.startPrank(owner);
        farm.setEpoch(1);
        farm.updateStakeParameters(address(lpToken), 1, 1000 ether, 1 days);
        vm.stopPrank();

        vm.startPrank(user1);
        lpToken.approve(address(farm), 100 ether);
        farm.stake(address(lpToken), 100 ether);
        farm.unstake(address(lpToken), 50 ether);

        vm.expectRevert(abi.encodeWithSignature("CooldownNotOver()"));
        farm.withdraw(address(lpToken), 50 ether);
        vm.stopPrank();
    }

    function testCannotWithdrawZeroAmount() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSignature("InvalidAmount()"));
        farm.withdraw(address(lpToken), 0);
    }

    function testCannotWithdrawMoreThanCoolingDown() public {
        vm.startPrank(owner);
        farm.setEpoch(1);
        farm.updateStakeParameters(address(lpToken), 1, 1000 ether, 1 days);
        vm.stopPrank();

        vm.startPrank(user1);
        lpToken.approve(address(farm), 100 ether);
        farm.stake(address(lpToken), 100 ether);
        farm.unstake(address(lpToken), 50 ether);

        vm.warp(block.timestamp + 1 days + 1);

        vm.expectRevert(abi.encodeWithSignature("InvalidAmount()"));
        farm.withdraw(address(lpToken), 51 ether);
        vm.stopPrank();
    }

    function testOwnerCanRescueTokens() public {
        lpToken.mint(address(farm), 100 ether);

        vm.prank(owner);
        farm.rescueTokens(address(lpToken), user2, 100 ether);
        assertEq(lpToken.balanceOf(user2), 1100 ether);
    }

    function testOwnerCanRescueEth() public {
        vm.deal(address(farm), 1 ether);

        vm.prank(owner);
        farm.rescueTokens(
            address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
            user2,
            1 ether
        );
        assertEq(user2.balance, 1 ether);
    }

    function testNonOwnerCannotRescueTokens() public {
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        farm.rescueTokens(address(lpToken), user2, 100 ether);
    }

    function testCannotRescueZeroAmount() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("InvalidAmount()"));
        farm.rescueTokens(address(lpToken), user2, 0);
    }

    function testCannotRescueToZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("ZeroAddressException()"));
        farm.rescueTokens(address(lpToken), address(0), 100 ether);
    }

    function testOwnerCannotRenounceOwnership() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("CantRenounceOwnership()"));
        farm.renounceOwnership();
    }

    function testInvariantIsEnforced() public {
        vm.startPrank(owner);
        farm.setEpoch(1);
        farm.updateStakeParameters(address(lpToken), 1, 1000 ether, 1 days);
        vm.stopPrank();

        vm.startPrank(user1);
        lpToken.approve(address(farm), 100 ether);
        farm.stake(address(lpToken), 100 ether);

        // Simulate a situation where the contract balance is less than total staked
        lpToken.transfer(user2, 1 ether);

        vm.expectRevert(abi.encodeWithSignature("InvariantBroken()"));
        farm.unstake(address(lpToken), 50 ether);
        vm.stopPrank();
    }

    function testFuzzStake(uint104 amount) public {
        vm.assume(amount > 0 && amount <= 1000 ether);

        vm.startPrank(owner);
        farm.setEpoch(1);
        farm.updateStakeParameters(address(lpToken), 1, 1000 ether, 1 days);
        vm.stopPrank();

        vm.startPrank(user1);
        lpToken.approve(address(farm), amount);
        farm.stake(address(lpToken), amount);

        (uint256 stakedAmount, , ) = farm.stakes(user1, address(lpToken));
        assertEq(stakedAmount, amount);
        vm.stopPrank();
    }

    function testFuzzUnstakeWithdraw(
        uint104 stakeAmount,
        uint104 unstakeAmount,
        uint48 cooldownTime
    ) public {
        vm.assume(stakeAmount > 0 && stakeAmount <= 1000 ether);
        vm.assume(unstakeAmount > 0 && unstakeAmount <= stakeAmount);
        vm.assume(cooldownTime > 0 && cooldownTime <= 90 days);

        vm.startPrank(owner);
        farm.setEpoch(1);
        farm.updateStakeParameters(
            address(lpToken),
            1,
            1000 ether,
            cooldownTime
        );
        vm.stopPrank();

        vm.startPrank(user1);
        lpToken.approve(address(farm), stakeAmount);
        farm.stake(address(lpToken), stakeAmount);
        farm.unstake(address(lpToken), unstakeAmount);

        vm.warp(block.timestamp + cooldownTime + 1);

        farm.withdraw(address(lpToken), unstakeAmount);

        (uint256 stakedAmount, uint152 coolingDownAmount, ) = farm.stakes(
            user1,
            address(lpToken)
        );
        assertEq(stakedAmount, stakeAmount - unstakeAmount);
        assertEq(coolingDownAmount, 0);
        vm.stopPrank();
    }
}
