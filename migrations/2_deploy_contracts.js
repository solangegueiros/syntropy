const SolUSD = artifacts.require("SolUSD");
const Border = artifacts.require("Border");
const TokenBorder = artifacts.require("TokenBorder");
const BorderFactory = artifacts.require("BorderFactory");
const Moviment = artifacts.require("Moviment");
const MovimentFactory = artifacts.require("MovimentFactory");


module.exports = async (deployer, network, accounts)=> {

    await deployer.deploy(SolUSD, {from: accounts[1]});
    solUSD = await SolUSD.deployed();
    usdAddress = solUSD.address;
    //console.log(solUSD.address);


    borderFactory = await deployer.deploy(BorderFactory, usdAddress, {from: accounts[1]});
    console.log("borderFactory: " + borderFactory.address);

    movimentFactory = await deployer.deploy(MovimentFactory, usdAddress, borderFactory.address, {from: accounts[1]});
    console.log("movimentFactory: " + movimentFactory.address);

    name = "Border 01";
    tokenName = "Token Border";
    tokenSymbol = "TB01";

    border = await borderFactory.createBorder (name, tokenName, tokenSymbol, {from: accounts[0]});
    borderAddress = border.logs[0].args[0];
    console.log("border address: " + border.logs[0].args[0]);

    border = await Border.at(borderAddress);
    console.log("token border address: " + await border.tokenBorder());

    name = "Moviment 01";
    moviment01 = await movimentFactory.createMoviment(name, {from: accounts[0]});    
    moviment01Address = moviment01.logs[0].args[0];
    console.log("moviment01Address: " + moviment01Address);
    moviment01 = await Moviment.at(moviment01Address);
    console.log("moviment01: " + await moviment01.name.call());

};



