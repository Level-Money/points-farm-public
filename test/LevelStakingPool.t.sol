// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../contracts/LevelStakingPool.sol";
import "../contracts/interface/IWETH.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor() ERC20("Mock Token", "MTK") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract MockWETH is ERC20 {
    constructor() ERC20("Wrapped ETH", "WETH") {}

    function deposit() external payable {
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        _burn(msg.sender, amount);
        payable(msg.sender).transfer(amount);
    }
}

contract MockMigrator {
    function migrate(address user, address[] calldata tokens, address destination, uint256[] calldata amounts)
        external
    {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20(tokens[i]).transferFrom(msg.sender, destination, amounts[i]);
        }
    }
}

contract LevelStakingPoolTest is Test {
    LevelStakingPool public pool;
    MockToken public token1;
    MockToken public token2;
    MockWETH public weth;
    MockMigrator public migrator;

    address public signer;
    address public user1;
    address public user2;
    uint256 public signerPrivateKey;
    uint256 public user1PrivateKey;

    event Deposit(uint256 indexed eventId, address indexed user, address indexed token, uint256 amount);
    event Withdraw(uint256 indexed eventId, address indexed user, address indexed token, uint256 amount);
    event Migrate(
        uint256 indexed eventId,
        address indexed user,
        address[] tokens,
        address destination,
        address migrator,
        uint256[] amounts
    );

    bytes32 constant DOMAIN_TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 constant MIGRATE_TYPEHASH = keccak256(
        "Migrate(address user,address migratorContract,address destination,address[] tokens,uint256 signatureExpiry,uint256 nonce)"
    );

    function setUp() public {
        signerPrivateKey = 1;
        user1PrivateKey = 2;
        signer = vm.addr(signerPrivateKey);
        user1 = vm.addr(user1PrivateKey);
        user2 = makeAddr("user2");

        token1 = new MockToken();
        token2 = new MockToken();
        weth = new MockWETH();
        migrator = new MockMigrator();

        address[] memory tokens = new address[](3);
        tokens[0] = address(token1);
        tokens[1] = address(token2);
        tokens[2] = address(weth);

        uint256[] memory limits = new uint256[](3);
        limits[0] = 1000e18;
        limits[1] = 1000e18;
        limits[2] = 1000e18;

        pool = new LevelStakingPool(signer, tokens, limits, address(weth));

        // Setup initial token balances
        token1.mint(user1, 100e18);
        token2.mint(user1, 100e18);
        token1.mint(user2, 100e18);
        token2.mint(user2, 100e18);

        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
    }

    function getDomainSeparator() internal view returns (bytes32) {
        return keccak256(
            abi.encode(DOMAIN_TYPE_HASH, keccak256("LevelStakingPool"), keccak256("1"), block.chainid, address(pool))
        );
    }

    function getDigest(
        address user,
        address migratorContract,
        address destination,
        address[] memory tokens,
        uint256 signatureExpiry,
        uint256 nonce
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                MIGRATE_TYPEHASH,
                user,
                migratorContract,
                destination,
                keccak256(abi.encodePacked(tokens)),
                signatureExpiry,
                nonce
            )
        );

        return keccak256(abi.encodePacked("\x19\x01", getDomainSeparator(), structHash));
    }

    function testFuzz_DepositFor(uint256 amount) public {
        vm.assume(amount > 0 && amount <= 100e18);

        vm.startPrank(user1);
        token1.approve(address(pool), amount);

        vm.expectEmit(true, true, true, true);
        emit Deposit(1, user1, address(token1), amount);

        pool.depositFor(address(token1), user1, amount);
        assertEq(pool.balance(address(token1), user1), amount);
        vm.stopPrank();
    }

    function testFuzz_DepositETHFor(uint256 amount) public {
        vm.assume(amount > 0 && amount <= 100 ether);

        vm.startPrank(user1);
        vm.expectEmit(true, true, true, true);
        emit Deposit(1, user1, address(weth), amount);

        pool.depositETHFor{value: amount}(user1);
        assertEq(pool.balance(address(weth), user1), amount);
        vm.stopPrank();
    }

    function testFuzz_Withdraw(uint256 depositAmount, uint256 withdrawAmount) public {
        vm.assume(depositAmount > 0 && depositAmount <= 100e18);
        vm.assume(withdrawAmount > 0 && withdrawAmount <= depositAmount);

        // Setup deposit
        vm.startPrank(user1);
        token1.approve(address(pool), depositAmount);
        pool.depositFor(address(token1), user1, depositAmount);

        vm.expectEmit(true, true, true, true);
        emit Withdraw(2, user1, address(token1), withdrawAmount);

        pool.withdraw(address(token1), withdrawAmount);
        assertEq(pool.balance(address(token1), user1), depositAmount - withdrawAmount);
        vm.stopPrank();
    }

    function test_MigrateWithSig() public {
        // Setup initial deposit
        vm.startPrank(user1);
        uint256 amount = 50e18;
        token1.approve(address(pool), amount);
        pool.depositFor(address(token1), user1, amount);
        vm.stopPrank();

        address[] memory tokens = new address[](1);
        tokens[0] = address(token1);

        uint256 signatureExpiry = block.timestamp + 1 hours;

        bytes32 digest = getDigest(
            user1,
            address(migrator),
            user2,
            tokens,
            signatureExpiry,
            0 // nonce
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(user1PrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        uint256 user2BalanceBeforeMigration = token1.balanceOf(user2);
        vm.prank(pool.owner());
        pool.migrateWithSig(user1, tokens, address(migrator), user2, signatureExpiry, signature);

        assertEq(pool.balance(address(token1), user1), 0);
        assertEq(token1.balanceOf(user2), amount + user2BalanceBeforeMigration);
    }

    function test_Migrate() public {
        // Setup initial deposit
        vm.startPrank(user1);
        uint256 amount = 50e18;
        token1.approve(address(pool), amount);
        pool.depositFor(address(token1), user1, amount);

        address[] memory tokens = new address[](1);
        tokens[0] = address(token1);

        uint256 signatureExpiry = block.timestamp + 1 hours;

        bytes32 message = keccak256(abi.encodePacked(address(migrator), signatureExpiry, address(pool), block.chainid));

        bytes32 digest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        uint256 user2BalanceBeforeMigration = token1.balanceOf(user2);

        pool.migrate(tokens, address(migrator), user2, signatureExpiry, signature);
        vm.stopPrank();

        assertEq(pool.balance(address(token1), user1), 0);
        assertEq(token1.balanceOf(user2), amount + user2BalanceBeforeMigration);
    }

    function testFuzz_SetStakableAmount(uint256 amount) public {
        vm.prank(pool.owner());
        pool.setStakableAmount(address(token1), amount);
        assertEq(pool.tokenBalanceAllowList(address(token1)), amount);
    }

    // Error cases
    function test_RevertWhen_DepositAmountZero() public {
        vm.expectRevert(ILevelStakingPool.DepositAmountCannotBeZero.selector);
        pool.depositFor(address(token1), user1, 0);
    }

    function test_RevertWhen_DepositForZeroAddress() public {
        vm.expectRevert(ILevelStakingPool.CannotDepositForZeroAddress.selector);
        pool.depositFor(address(token1), address(0), 1e18);
    }

    function test_RevertWhen_WithdrawAmountZero() public {
        vm.expectRevert(ILevelStakingPool.WithdrawAmountCannotBeZero.selector);
        pool.withdraw(address(token1), 0);
    }

    function test_RevertWhen_InsufficientBalance() public {
        vm.startPrank(user1);
        vm.expectRevert();
        pool.withdraw(address(token1), 1e18);
        vm.stopPrank();
    }

    function test_RevertWhen_StakingLimitExceeded() public {
        uint256 limit = pool.tokenBalanceAllowList(address(token1));
        vm.startPrank(user1);
        token1.mint(user1, limit + 1);
        token1.approve(address(pool), limit + 1);

        vm.expectRevert(ILevelStakingPool.StakingLimitExceeded.selector);
        pool.depositFor(address(token1), user1, limit + 1);
        vm.stopPrank();
    }

    function test_RevertWhen_MigratorBlocked() public {
        // Block migrator
        vm.prank(pool.owner());
        pool.blockMigrator(address(migrator), true);

        address[] memory tokens = new address[](1);
        tokens[0] = address(token1);

        vm.startPrank(user2);
        token1.approve(address(pool), 1);
        pool.depositFor(address(token1), user2, 1);

        vm.expectRevert(ILevelStakingPool.MigratorBlocked.selector);
        pool.migrate(tokens, address(migrator), user2, block.timestamp + 1 hours, new bytes(65));
        vm.stopPrank();
    }

    function test_PauseUnpause() public {
        vm.startPrank(pool.owner());

        pool.pause();
        assertTrue(pool.paused());

        vm.expectRevert();
        pool.depositFor(address(token1), user1, 0);

        pool.unpause();
        assertFalse(pool.paused());
        vm.stopPrank();
    }

    function test_RevertWhen_RenounceOwnership() public {
        vm.prank(pool.owner());
        vm.expectRevert(ILevelStakingPool.CannotRenounceOwnership.selector);
        pool.renounceOwnership();
    }

    receive() external payable {}
}
