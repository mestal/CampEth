var app = angular.module("myApp", []);

app.controller("mainController", function($scope) {

    var web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
	
    var mc = getMainContract();
    var cc = getCampaignContract();

    var m = mc.at('0xb18a72f17ca7dbcc71e85c62d7804176ae20d2e7');
    
    var list = m.GetCampaignList();

    $scope.campaigns = [];
    for(var i = 0; i < list.length; i ++)
    {
        var c = cc.at(list[i]);
        var ci = c.GetCampaignInfo();
        var priceDefs = [];
        for(var j = 0; j < ci[3].length; j ++)
        {
            priceDefs.push({ quantityLevel: ci[3][j], price: ci[4][j] });
        }
        $scope.campaigns.push({contAddress: list[i], code: ci[0], name: ci[1], limit: ci[2], priceDefs: priceDefs, totalQuantity: c.getTotalQuantity(), currentPrice: c.getCurrentPrice(), quantity: 0});
    }

    //c.Buy(1, {from: web3.eth.accounts[2], gas: 3000000, value: 100000000 });

    
    $scope.Buy = function(selectedContract)
    {
        var c = cc.at(selectedContract.contAddress);
        c.Buy(selectedContract.quantity, {from: web3.eth.accounts[2], gas: 3000000, value: selectedContract.currentPrice * selectedContract.quantity});

        selectedContract.currentPrice = c.getCurrentPrice();
        selectedContract.totalQuantity = c.getTotalQuantity();
    }

    function getMainContract()
    {
        return web3.eth.contract([
        {
            "constant": true,
            "inputs": [],
            "name": "GetCampaignList",
            "outputs": [
                {
                    "name": "",
                    "type": "address[]"
                }
            ],
            "payable": false,
            "stateMutability": "view",
            "type": "function"
        },
        {
            "constant": false,
            "inputs": [
                {
                    "name": "add1",
                    "type": "address"
                }
            ],
            "name": "AddNewCampaign",
            "outputs": [],
            "payable": false,
            "stateMutability": "nonpayable",
            "type": "function"
        }
    ]);
    }

    function getCampaignContract()
    {
        return web3.eth.contract([
{
    "constant": true,
    "inputs": [],
    "name": "getTotalQuantity",
    "outputs": [
        {
            "name": "totalQuantity",
            "type": "uint256"
        }
    ],
    "payable": false,
    "stateMutability": "view",
    "type": "function"
},
{
    "constant": true,
    "inputs": [],
    "name": "getCurrentPrice",
    "outputs": [
        {
            "name": "_currentPrice",
            "type": "uint256"
        }
    ],
    "payable": false,
    "stateMutability": "view",
    "type": "function"
},
{
    "constant": true,
    "inputs": [],
    "name": "GetCampaignInfo",
    "outputs": [
        {
            "name": "",
            "type": "string"
        },
        {
            "name": "",
            "type": "string"
        },
        {
            "name": "",
            "type": "uint256"
        },
        {
            "name": "",
            "type": "uint256[]"
        },
        {
            "name": "",
            "type": "uint256[]"
        }
    ],
    "payable": false,
    "stateMutability": "view",
    "type": "function"
},
{
    "constant": true,
    "inputs": [
        {
            "name": "x",
            "type": "bytes32"
        }
    ],
    "name": "bytes32ToString",
    "outputs": [
        {
            "name": "",
            "type": "string"
        }
    ],
    "payable": false,
    "stateMutability": "view",
    "type": "function"
},
{
    "constant": true,
    "inputs": [],
    "name": "GetCoupon",
    "outputs": [
        {
            "name": "",
            "type": "string"
        }
    ],
    "payable": false,
    "stateMutability": "view",
    "type": "function"
},
{
    "constant": true,
    "inputs": [],
    "name": "GetCoupon1",
    "outputs": [
        {
            "name": "",
            "type": "string"
        }
    ],
    "payable": false,
    "stateMutability": "view",
    "type": "function"
},
{
    "constant": true,
    "inputs": [
        {
            "name": "quantity",
            "type": "uint256"
        }
    ],
    "name": "getPriceForQuantity",
    "outputs": [
        {
            "name": "_price",
            "type": "uint256"
        }
    ],
    "payable": false,
    "stateMutability": "view",
    "type": "function"
},
{
    "constant": true,
    "inputs": [],
    "name": "GetStarted",
    "outputs": [
        {
            "name": "",
            "type": "bool"
        }
    ],
    "payable": false,
    "stateMutability": "view",
    "type": "function"
},
{
    "constant": true,
    "inputs": [],
    "name": "GetEnded",
    "outputs": [
        {
            "name": "",
            "type": "bool"
        }
    ],
    "payable": false,
    "stateMutability": "view",
    "type": "function"
},
{
    "constant": false,
    "inputs": [
        {
            "name": "quantityLevel",
            "type": "uint256"
        },
        {
            "name": "price",
            "type": "uint256"
        }
    ],
    "name": "AddCampaignDetail",
    "outputs": [],
    "payable": false,
    "stateMutability": "nonpayable",
    "type": "function"
},
{
    "constant": false,
    "inputs": [
        {
            "name": "quantity",
            "type": "uint256"
        }
    ],
    "name": "Buy",
    "outputs": [],
    "payable": true,
    "stateMutability": "payable",
    "type": "function"
},
{
    "anonymous": false,
    "inputs": [
        {
            "indexed": false,
            "name": "price",
            "type": "uint256"
        }
    ],
    "name": "CampaignEnded",
    "type": "event"
},
{
    "constant": false,
    "inputs": [],
    "name": "EndCampaign",
    "outputs": [],
    "payable": false,
    "stateMutability": "nonpayable",
    "type": "function"
},
{
    "constant": false,
    "inputs": [],
    "name": "checkBalance",
    "outputs": [
        {
            "name": "",
            "type": "uint256"
        }
    ],
    "payable": false,
    "stateMutability": "nonpayable",
    "type": "function"
},
{
    "constant": false,
    "inputs": [],
    "name": "TestCreateDetail",
    "outputs": [],
    "payable": false,
    "stateMutability": "nonpayable",
    "type": "function"
},
{
    "inputs": [
        {
            "name": "code",
            "type": "string"
        },
        {
            "name": "name",
            "type": "string"
        },
        {
            "name": "limit",
            "type": "uint256"
        },
        {
            "name": "addPriceTime",
            "type": "uint256"
        },
        {
            "name": "coupons",
            "type": "bytes32[]"
        }
    ],
    "payable": false,
    "stateMutability": "nonpayable",
    "type": "constructor"
},
{
    "constant": false,
    "inputs": [],
    "name": "StartCampaign",
    "outputs": [
        {
            "name": "",
            "type": "bool"
        }
    ],
    "payable": false,
    "stateMutability": "nonpayable",
    "type": "function"
},
{
    "anonymous": false,
    "inputs": [
        {
            "indexed": false,
            "name": "price",
            "type": "uint256"
        }
    ],
    "name": "PriceDecreased",
    "type": "event"
}
]);
    }




});