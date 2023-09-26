// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

interface ERC20Token {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(
        address _to,
        uint256 _value
    ) external returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(
        address _spender,
        uint256 _value
    ) external returns (bool success);

    function allowance(
        address _owner,
        address _spender
    ) external view returns (uint256 remaining);
}

contract DeployBytecode {
    Vm public constant vm =
        Vm(address(bytes20(uint160(uint256(keccak256("hevm cheat code"))))));

    function deployFromBytecode(
        bytes memory bytecode,
        address deployer
    ) public returns (address) {
        vm.prank(deployer);
        address deployedAddress;
        assembly {
            mstore(0x0, bytecode)
            deployedAddress := create(0, add(bytecode, 0x20), mload(bytecode))
        }

        require(
            deployedAddress != address(0),
            "DeployBytecode could not deploy contract"
        );
        return deployedAddress;
    }
}

contract ContractTest is Test {
    ERC20Token token;
    address user1;
    address user2;

    function _compileCode() internal returns (bytes memory) {
        string[] memory inputs = new string[](2);
        /**
         * windows: script/compile.bat
         * linux  : script/compile.sh
         */
        inputs[0] = "script/compile.sh";
        inputs[1] = "src/Contract.etk";

        bytes memory bytecode = vm.ffi(inputs);

        return bytecode;
    }

    function _compileCodeWithArgs(
        bytes memory args
    ) internal returns (bytes memory) {
        string[] memory inputs = new string[](2);

        inputs[0] = "script/compile.sh";
        inputs[1] = "src/Contract.etk";

        bytes memory bytecode = vm.ffi(inputs);
        bytecode = bytes.concat(bytecode, args);

        return bytecode;
    }

    function setUp() public {
        user1 = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        vm.prank(user1);

        user2 = address(0x900e);

        vm.label(user1, "User1");
        vm.label(user2, "User2");

        bytes memory bytecode = _compileCode();

        DeployBytecode deploy = new DeployBytecode();
        address addr = deploy.deployFromBytecode(bytecode, user1);

        vm.label(addr, "Token");

        token = ERC20Token(addr);
    }

    /* 
    function testTokenName() public view {
        string memory name = token.name();
        // TODO Hardcoded value
    }

    function testTokenSymbol() public view {
        string memory symbol = token.symbol();
        // TODO Hardcoded value
    }
    */

    function testInitialBalance() public {
        assertEq(token.balanceOf(user1), 21000000e18);
        assertEq(token.balanceOf(user2), 0);
        assertEq(token.totalSupply(), 21000000e18);
    }

    function testTransfer() public {
        assertEq(token.balanceOf(user1), 21000000e18);

        assertEq(token.balanceOf(user2), 0);

        vm.prank(user1);
        token.transfer(user2, 1e18);

        assertEq(token.balanceOf(user1), 20999999e18);

        assertEq(token.balanceOf(user2), 1e18);
    }

    function testAllowance() public {
        assertEq(token.allowance(user1, user2), 0);

        vm.prank(user1);
        token.approve(user2, 1e18);

        assertEq(token.allowance(user1, user2), 1e18);
    }

    function testTransferFrom() public {
        assertEq(token.allowance(user1, user2), 0);

        vm.prank(user1);
        token.approve(user2, 1e18);

        assertEq(token.allowance(user1, user2), 1e18);

        vm.prank(user2);
        token.transferFrom(user1, user2, 1e18);

        assertEq(token.allowance(user1, user2), 0);
        assertEq(token.balanceOf(user1), 20999999e18);
        assertEq(token.balanceOf(user2), 1e18);
    }
}
