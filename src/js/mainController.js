var app = angular.module("myApp", []);

app.controller("mainController", function($scope) {

    $scope.newCampaignDetail = {};
    $scope.showCreation = false;
    
    $scope.mainContractAddress = "0x5c3113089344f18b2b7d90c53b36e9590a180bad";
    $scope.newCampaignDetail.CampaignAddress = "0x895537cfc410fa60546cc8a50e02c7cc9252b4c3";
    
    $scope.newCamp = { code: "Code001", name: "IPhone", limit: 2, coupons: ["cp1","cp2"]};

    //var web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:9545"));
    // Is there is an injected web3 instance?
    if (typeof web3 !== 'undefined') {
        web3 = new Web3(web3.currentProvider);
    } 
    else
    {
        alert("web3 not found");
        return;
    }

    $scope.selectedAccount = web3.eth.accounts[0];
    Api = { contracts: {}};

    $.getJSON('MainContract.json', function(data) {
        // Get the necessary contract artifact file and instantiate it with truffle-contract
        var MainContractArtifact = data;
        Api.contracts.MainContractSpec = TruffleContract(MainContractArtifact);
        Api.contracts.MainContractSpec.setProvider(web3.currentProvider);

        var mainCont1 = Api.contracts.MainContractSpec.at($scope.mainContractAddress);
    });
    

    $.getJSON('CampEth.json', function(data) {
        // Get the necessary contract artifact file and instantiate it with truffle-contract
        var CampEthArtifact = data;
        Api.contracts.CampEthSpec = TruffleContract(CampEthArtifact);
        Api.contracts.CampEthSpec.setProvider(web3.currentProvider);

    });

    $scope.CreateMainContract = function()
    {
        //var contact = web3.eth.contract.new(abi,{from: web3.eth.accounts[0], data: bc});
        Api.contracts.MainContractSpec.new({from: $scope.selectedContract}).then(function( cont)
        {
            alert("Main Contract was created : " + cont.address);
            var a = cont;
            console.log("success");
            console.log(a);
        }, function(err)
        {
            alert("Main Contract cannot be created : " + err);
            var b = err;
            console.log("error");
            console.log(b);
        });
    }
    
    $scope.LoadCampaigns = function()
    {
        var mainCont1 = Api.contracts.MainContractSpec.at($scope.mainContractAddress);
        var m = Api.contracts.MainContractSpec.at($scope.mainContractAddress);
    
        m.GetCampaignList().then(function(list)
            {
                $scope.NewPriceDefs = [];
    
                $scope.campaigns = [];
                var yy = list;
                
                for(var i = 0; i < list.length; i ++)
                {
                    var c = Api.contracts.CampEthSpec.at(list[i]);
                    c.GetCampaignInfo().then(function(info)
                    {
                        var priceDefs = [];
                        for(var j = 0; j < info[5].length; j ++)
                        {
                            priceDefs.push({ quantityLevel: info[4][j], price: info[5][j] });
                        }
                        $scope.campaigns.push({
                            contAddress: info[7], 
                            code: info[0], 
                            //name: info[1], 
                            limit: info[1], 
                            priceDefs: priceDefs, 
                            totalQuantity: info[8], 
                            currentPrice: findPriceByQuantity(info[8], info[4], info[5]), 
                            quantity: 0, //for input
                            started: info[2],
                            ended: info[3],
                            owner: info[6]
                        }, function(error)
                        {
                            alert(error);
                        });
                    });
                }
            }, function(err)
            {
                var b = err;
                console.log("error");
                console.log(b);
            });

            //string code, string name, uint limit, uint addPriceTime, bytes32[] coupons
    }

    function findPriceByQuantity(quantity, quantityLevels, priceDefs)
    {
/*
        if(quantityLevels[0] > quantity)
        {
            _price = 0;
            return;
        }
  */      
        var maxValidIndex = 0;
        for(var i = 1; i < quantityLevels.length; i ++)
        {
            if(quantityLevels[i] <= quantity)
                maxValidIndex = i;
            else
                break;
        }
        
        return priceDefs[maxValidIndex];
    }

    $scope.AddCampaignToMainContract = function()
    {
        
        var mainCont1 = Api.contracts.MainContractSpec.at($scope.mainContractAddress);

        mainCont1.AddNewCampaign($scope.newCampaignDetail.CampaignAddress).then(function(response)
        {
            alert("Campaign was added to Main Contract successfully");
            console.log("success");
            console.log(response);    
        },function(err)
        {
            alert("Campaign cannot be added to Main Contract");
            var b = err;
            console.log("error");
            console.log(b);
        });
    }

    $scope.CreateNewCampaign = function(newCamp)
    {
        var coupons = ["ccc1", "ccc2"];

        var response = Api.contracts.CampEthSpec.new(newCamp.code, newCamp.name, newCamp.limit, 100, coupons, {
            //data: '0x' + bytecode,
            from: $scope.selectedAccount,
            gas: 3000000
        }).then(function(cont)
        {
            alert("New Campaign was created : " + cont.address);
            var a = cont;
            console.log("success");
            console.log(a);
            $scope.newCampaignDetail.CampaignAddress = cont.address;


        }, function( err)
        {
            alert("Campaign cannot be created : " + err);
            var b = err;
            console.log("error");
            console.log(b);
        });

        //string code, string name, uint limit, uint addPriceTime, bytes32[] coupons
    }

    $scope.AddCampaignDetail = function(newCampaignDetail)
    {
        if($scope.newCampaignDetail == null)
            return;

        var c = Api.contracts.CampEthSpec.at($scope.newCampaignDetail.CampaignAddress);
        c.AddCampaignDetail(newCampaignDetail.QuantityLevel, newCampaignDetail.Price, {from: $scope.selectedAccount, gas: 3000000}).then(function(response)
        {
            alert("Campaign Detail was added successfully");
            console.log("success");
            console.log(response);

            

        },function(err)
        {
            alert("Campaign Detail cannot be added : ");
            var b = err;
            console.log("error");
            console.log(b);
        });

        $scope.NewPriceDefs.push({
            quantityLevel: newCampaignDetail.QuantityLevel,
            price: newCampaignDetail.Price
        });
    }

    $scope.StartCampaign = function()
    {
        if($scope.newCampaignDetail.CampaignAddress == null)
            return;

        var c = Api.contracts.CampEthSpec.at($scope.newCampaignDetail.CampaignAddress);
        c.StartCampaign({from: $scope.selectedAccount, gas: 3000000}).then(function(cont)
        {
            alert("Campaign was started");
            var a = cont;
            console.log("success");
            console.log(a);
        }, function( err)
        {
            alert("Campaign can not be started");
            var b = err;
            console.log("error");
            console.log(b);
        });
    }
    
    $scope.Buy = function(selectedContract)
    {
        var c = Api.contracts.CampEthSpec.at(selectedContract.contAddress);
        c.Buy(selectedContract.quantity, {from: $scope.selectedAccount, gas: 3000000, value: selectedContract.currentPrice * selectedContract.quantity}).then(function(response)
        {
            alert("Success (Buy)");
        }, function( err)
        {
            alert("Error (Buy) : " + error);
            alert(error);
        });

        //selectedContract.currentPrice = c.getCurrentPrice();
        //selectedContract.totalQuantity = c.getTotalQuantity();
    }

    $scope.End = function(selectedContract)
    {
        var c = cc.at(selectedContract.contAddress);
        c.EndCampaign({ from: $scope.selectedAccount, gas: 3000000 });
    }

    $scope.GetMyCoupon = function(selectedContract)
    {
        var c = cc.at(selectedContract.contAddress);
        alert(c.GetCoupon({ from: $scope.selectedAccount, gas: 3000000 }));
    }

    angular.element(document).ready(function () {
        $scope.LoadCampaigns();
    });
});