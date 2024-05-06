// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract RestaurantdApp is ERC721 {
    uint256 private tokenId;
    constructor() ERC721("RestaurantCoupon", "RCT") {
        tokenId = 1;
    }

    struct MenuItem {
        string itemName;
        uint256 itemPrice;
    }

    struct Coupon {
        uint256 amount;
        uint256 securityCode;
        uint256 expiry;
        string coupon_type;
    }

    struct CustomerData {
        string custName;
        bytes32 password;
        address custwallet;
    }

    struct RestaurantOwner {
        string ownerName;
        bytes32 password;
        address ownerWallet;
        string[] restaurants;
    }

    struct Couponset {
        uint256 amount;
        uint256 expiry;
    }

    address[] private restowner;
    address[] private cust;
    mapping(string => Couponset) Cashset;
    mapping(string => Couponset) Percentset;
    mapping(uint256 => Coupon) private CashCoupons;
    mapping(uint256 => Coupon) private PercentCoupons;
    mapping(address => RestaurantOwner) private RestaurantOwners;
    mapping(string => MenuItem[]) private Menus;
    mapping(string => uint256[]) private ResCashCoupons;
    mapping(string => uint256[]) private ResPercentCoupons;
    mapping(string => mapping(address => uint256)) private CustOrder;
    mapping(string => mapping(address => uint256)) private CustPrice;


    mapping(address => CustomerData) private Customers;
    mapping(uint256 => address) private CusCashCoupon;
    mapping(uint256 => address) private CusPercentCoupon;

    modifier onlyOwner() {
        bool check = false;
        for (uint i = 0; i < restowner.length; i++) {
            if (msg.sender == restowner[i]) {
                check = true;
            }
        }
        require(check, "You are not a restaurant owner");
        _;
    }

    modifier onlyCustomer() {
        bool check = false;
        for (uint i = 0; i < cust.length; i++) {
            if (msg.sender == cust[i]) {
                check = true;
            }
        }
        require(check, "You are not a customer");
        _;
    }

    function checkaddressExist(address addresstocheck, address[] memory addressarray) private pure returns (bool) {
        for (uint i = 0; i < addressarray.length; i++) {
            if (addressarray[i] == addresstocheck) {
                return true; //the address exists
            }
        }
        return false; //the address does not exists
    }

    function getuser() public view returns(address[] memory) {
        address[] memory list = cust;
        return list;
    }

    function getowner() public view returns(address[] memory) {
        address[] memory list = restowner;
        return list;
    }


    function ownerRegister (string memory _ownerName, string memory _password, string memory _password2) public{
        require(!checkaddressExist(msg.sender, restowner), "Address had been Registered");
        require(bytes(_ownerName).length > 0, "Owner name can not be empty");
        require(bytes(_password).length > 0, "Password can not be empty");
        require(keccak256(abi.encodePacked(_password)) == keccak256(abi.encodePacked(_password2)), "types in passwords are not match");

        RestaurantOwners[msg.sender] = RestaurantOwner({
            ownerName: _ownerName,
            password: keccak256(abi.encodePacked(_password)),
            ownerWallet: msg.sender,
            restaurants: new string[](0)
        });

        restowner.push(msg.sender);
    }

    function ownerLogin (string memory _ownerName, string memory _password) public view returns (bool){
        require(bytes(_ownerName).length > 0, "Owner name can not be empty");
        require(bytes(_password).length > 0, "Password can not be empty");
        require(checkaddressExist(msg.sender, restowner), "Address had not Registered");
        require(keccak256(abi.encodePacked(RestaurantOwners[msg.sender].ownerName)) == keccak256(abi.encodePacked(_ownerName)), "Username or Password is Wrong");
        require(RestaurantOwners[msg.sender].password == keccak256(abi.encodePacked(_password)), "Username or Password is Wrong");

        return true;

    }

    function checkResExist (address _address, string memory _restName) private view returns (bool) {
        string[] memory restlist = RestaurantOwners[_address].restaurants;
        for (uint i = 0; i < restlist.length; i++) {
            if (keccak256((bytes(restlist[i]))) == keccak256((bytes(_restName)))) {
                return false;
            }
        }
        return true;
    }

    function addRest (string memory _restName) onlyOwner public {
        require(bytes(_restName).length > 0, "Restaurant name can not be empty");
        bool check = true;
        for (uint i = 0; i < restowner.length; i++) {
            if (!checkResExist(restowner[i], _restName)) {
                check = false;
            } 
        }
        require(check, "Restaurant already exist"); 
        RestaurantOwners[msg.sender].restaurants.push(_restName);
    }

    function getrest () public view returns(string[] memory) {
        string[] memory list = RestaurantOwners[msg.sender].restaurants;
        return list;
    }

    function checkItem (string memory _restname, string memory _itemname) onlyOwner private view returns (bool){
        for (uint i = 0; i < Menus[_restname].length; i++) {
            if (keccak256(abi.encodePacked(_itemname)) == keccak256(abi.encodePacked(Menus[_restname][i].itemName))) {
                return false;
            }
        }
        return true;
    }

    function addItem (string memory _restname, string memory _itemname, uint256 _itemprice) onlyOwner public {
        require(!checkResExist(msg.sender, _restname), "Your are not the owner of the restaurant");
        require(bytes(_itemname).length > 0, "Item name can not be empty");
        require(checkItem(_restname, _itemname), "Item already exists");

        Menus[_restname].push(
            MenuItem({
                itemName: _itemname,
                itemPrice: _itemprice
            })
        );
    }

    function getMenu (string memory _restname) public view returns(MenuItem[] memory) {
        return Menus[_restname];
    }

    function setCash(uint256 amount, uint256 expire, string memory _restname) onlyOwner public {
        require(!checkResExist(msg.sender, _restname), "You are not the owner of this restaurant");
        require(amount > 0, "Discount amount can not be 0");
        require(expire > 0, "Please set expire");

        Cashset[_restname] = Couponset({
            amount: amount,
            expiry: expire
        });
    }

    function setPercent(uint256 amount, uint256 expire, string memory _restname) onlyOwner public {
        require(!checkResExist(msg.sender, _restname), "You are not the owner of this restaurant");
        require(amount > 0, "Discount amount can not be 0");
        require(expire > 0, "Please set expire");

        Percentset[_restname] = Couponset({
            amount: amount,
            expiry: expire
        });
    }

    function customerRegister (string memory _custName, string memory _password, string memory _password2) public {
        require(!checkaddressExist(msg.sender, cust), "Address had been Registered");
        require(bytes(_custName).length > 0, "Customer name can not be empty");
        require(bytes(_password).length > 0, "Password can not be empty");
        require(keccak256(abi.encodePacked(_password)) == keccak256(abi.encodePacked(_password2)), "types in passwords are not match");

        Customers[msg.sender] = CustomerData({
            custName: _custName,
            password: keccak256(abi.encodePacked(_password)),
            custwallet: msg.sender
        });

        cust.push(msg.sender);
    }

    function customerLogin (string memory _custName, string memory _password) public view returns (bool){
        require(bytes(_custName).length > 0, "Customer name can not be empty");
        require(bytes(_password).length > 0, "Password can not be empty");
        require(checkaddressExist(msg.sender, cust), "Address had not Registered");
        require(keccak256(abi.encodePacked(Customers[msg.sender].custName)) == keccak256(abi.encodePacked(_custName)), "Username or Password is Wrong");
        require(Customers[msg.sender].password == keccak256(abi.encodePacked(_password)), "Username or Password is Wrong");

        return true;
    }

    function removetoken(uint256[] storage list, uint256 tokenid) private {
        for (uint i =0; i < list.length; i++) {
            if (list[i] == tokenid) {
                list[i] = list[list.length - 1];
                list.pop();
                break;
            }
        }
    }

    function createCashCoupon (string memory _restname) onlyCustomer private {
        uint256 amount = Cashset[_restname].amount;
        require(amount > 0, "Discount amount can not be 0");
        uint256 expire = Cashset[_restname].expiry;
        require(expire > 0, "Please set expire");

        _mint(msg.sender, tokenId);
        // uint256 expire_time = block.timestamp + (expire * 1 days);
        uint256 expire_time = block.timestamp + (expire * 1 days);
        uint256 _securitycode = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 10000000000;

        ResCashCoupons[_restname].push(tokenId);
        CusCashCoupon[tokenId] = msg.sender;
        CashCoupons[tokenId] = Coupon({
            amount: amount,
            securityCode: _securitycode,
            expiry: expire_time,
            coupon_type: "Cash"
        });

        tokenId++;
    }

    function createPercentCoupon (string memory _restname) onlyCustomer public {
        uint256 amount = Percentset[_restname].amount;
        require(amount > 0, "Discount amount can not be 0");
        uint256 expire = Percentset[_restname].expiry;
        require(expire > 0, "Please set expire");

        _mint(msg.sender, tokenId);
        // uint256 expire_time = block.timestamp + (expire * 1 days);
        uint256 expire_time = block.timestamp + (expire * 1 days);
        uint256 _securitycode = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 10000000000;

        ResPercentCoupons[_restname].push(tokenId);
        CusPercentCoupon[tokenId] = msg.sender;
        PercentCoupons[tokenId] = Coupon({
            amount: amount,
            securityCode: _securitycode,
            expiry: expire_time,
            coupon_type: "Percent"
        });

        tokenId++;
    }

    function issueCoupon(string memory _restname, address _cust) private {
        if (CustPrice[_restname][_cust] > 10 && CustOrder[_restname][msg.sender] > 2) {
            createCashCoupon(_restname);
            CustOrder[_restname][_cust] = 0;
            CustPrice[_restname][_cust] = 0;
        }
        if (CustPrice[_restname][_cust] > 1) {
            createPercentCoupon(_restname);
            CustOrder[_restname][_cust] = 0;
            CustPrice[_restname][_cust] = 0;
        }
    }

    function useCoupon (uint256 couponid, uint256 price, string memory _restname, string memory coupon_type, uint256 securicode) onlyCustomer public returns (uint256) {
        require(ownerOf(couponid) == msg.sender, "Invalid Coupon");
        require(price > 0);
        bool check = true;
        for (uint i = 0; i < restowner.length; i++) {
            if (checkResExist(restowner[i], _restname) == false) {
                check = false;
            } 
        }
        require(!check, "Restaurant do not exist");
        if (keccak256(bytes(coupon_type)) == keccak256(bytes("Cash"))) {
            require(securicode == CashCoupons[couponid].securityCode, "Invalid Coupon");
            require(CashCoupons[couponid].expiry > block.timestamp, "Coupon Expired");
            bool check2 = false;
            for (uint i = 0; i < ResCashCoupons[_restname].length; i++) {
                if (ResCashCoupons[_restname][i] == couponid) {
                    check2 = true;
                }
            }
            require(check, "Invalid Coupon");
            price -= CashCoupons[couponid].amount;
            removetoken(ResCashCoupons[_restname], couponid);
            delete CusCashCoupon[couponid];
            delete CashCoupons[couponid];
            _burn(couponid);
        } else if (keccak256(bytes(coupon_type)) == keccak256(bytes("Percent"))){
            require(securicode == PercentCoupons[couponid].securityCode, "Invalid Coupon");
            require(PercentCoupons[couponid].expiry > block.timestamp, "Coupon Expired");
            bool check2 = false;
            for (uint i = 0; i < ResPercentCoupons[_restname].length; i++) {
                if (ResPercentCoupons[_restname][i] == couponid) {
                    check2 = true;
                }
            }
            require(check, "Invalid Coupon");
            price = price * (PercentCoupons[couponid].amount / 100);
            removetoken(ResPercentCoupons[_restname], couponid);
            delete CusPercentCoupon[couponid];
            delete PercentCoupons[couponid];
            _burn(couponid);
        } else {

        }
        return price;
        
    }

    function pay(string memory _restname, uint256 price) onlyCustomer public payable{
        bool check = true;
        address owner;
        for (uint i = 0; i < restowner.length; i++) {
            if (checkResExist(restowner[i], _restname) == false) {
                owner = restowner[i];
                check = false;
            } 
        }
        require(!check, "Restaurant do not exist");
        CustOrder[_restname][msg.sender] += 1;
        CustPrice[_restname][msg.sender] += price;
        issueCoupon(_restname, msg.sender);
    }
}