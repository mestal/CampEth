pragma solidity ^0.4.17;
//import "github.com/Arachnid/solidity-stringutils/strings.sol";

contract MainContract {
    
    address[] _addressList;
    
    function AddNewCampaign(address add1) public
    {
        _addressList.push(add1);
    }
    
    function GetCampaignList() constant public returns (address[])
    {
        return _addressList;
    }
}