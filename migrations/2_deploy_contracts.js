const UsdS = artifacts.require("UsdS");
const Border = artifacts.require("Border");
const BorderFactory = artifacts.require("BorderFactory");
const Moviment = artifacts.require("Moviment");
const MovimentFactory = artifacts.require("MovimentFactory");
const MovimentView = artifacts.require("MovimentView");

module.exports = async (deployer, network, accounts)=> {

    //console.log("deploying UsdS ...");
    await deployer.deploy(UsdS, {from: accounts[0]});
    usdS = await UsdS.deployed();
    usdAddress = usdS.address;
    //console.log(usdS.address);

    borderFactory = await deployer.deploy(BorderFactory, usdAddress, {from: accounts[0]});
    console.log("borderFactory: " + borderFactory.address);

    movimentFactory = await deployer.deploy(MovimentFactory, usdAddress, borderFactory.address, {from: accounts[0]});
    console.log("movimentFactory: " + movimentFactory.address);
    //console.log(await movimentFactory.borderFactory.call());

    movimentView = await deployer.deploy(MovimentView, {from: accounts[0]});  
    console.log("movimentView: " + movimentView.address);

    
    name = "Border 01";
    border01 = await borderFactory.createBorder (name, {from: accounts[1]});
    //console.log("border: " + border);    
    //console.log("border: " + JSON.stringify(border));
    borderAddress = border01.logs[0].args[0];
    console.log("border address: " + border01.logs[0].args[0]);    
    border01 = await Border.at(borderAddress);
    //console.log("border: " + await border.name.call());
    console.log("border address: " + border01.address);

    name = "Moviment 01";
    moviment01 = await movimentFactory.createMoviment(name, {from: accounts[1]});    
    //console.log("moviment01: " + JSON.stringify(moviment01));
    moviment01Address = moviment01.logs[0].args[0];
    console.log("moviment01Address: " + moviment01Address);
    moviment01 = await Moviment.at(moviment01Address);
    console.log("moviment01: " + await moviment01.name.call());
    //owners = await moviment01.listOwners({from: accounts[1]});
    //console.log("owners: " + JSON.stringify(owners));

    console.log("\n\n");


};


