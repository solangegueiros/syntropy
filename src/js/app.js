
App = {
  web3Provider: null,
  contracts: {},

  init: function() {

    return App.initWeb3();
  },

  initWeb3: function() {
    if (window.ethereum) {
      web3 = new Web3(window.ethereum);
      try { 
        window.ethereum.enable().then(function() {
            // User has allowed account access to DApp...
        });
      } catch(e) {
        // User has denied account access to DApp...
      }
    }
    // Legacy DApp Browsers
    else if (window.web3) {
        web3 = new Web3(web3.currentProvider);
    }
    // Non-DApp Browsers
    else {
        alert('You have to install MetaMask !');
    }

    App.web3Provider = web3.currentProvider;
    return App.initContract();
  },

  initContract: function() {
    $.getJSON('SolUSD.json', function(data) {
      var SolUSDArtifact = data;
      App.contracts.SolUSD = TruffleContract(SolUSDArtifact);
      App.contracts.SolUSD.setProvider(App.web3Provider);      
      return App.getSolUSDBalance();
    });

    $.getJSON('BorderFactory.json', function(data) {
      var BorderFactoryArtifact = data;
      App.contracts.BorderFactory = TruffleContract(BorderFactoryArtifact);
      App.contracts.BorderFactory.setProvider(App.web3Provider);      
      return App.borderFactoryListBorders();
    });

    $.getJSON('MovimentFactory.json', function(data) {
      var MovimentFactoryArtifact = data;
      App.contracts.MovimentFactory = TruffleContract(MovimentFactoryArtifact);
      App.contracts.MovimentFactory.setProvider(App.web3Provider);      
      return App.movimentFactoryListMoviments();
    });

    $.getJSON('Border.json', function(data) {
      var BorderArtifact = data;
      App.contracts.Border = TruffleContract(BorderArtifact);
      //console.log(JSON.stringify(App.contracts.Border.networks["1001"])); 

      //Address deve ser atualizado de acordo com a borda criada na rede determinada
      App.contracts.Border.networks["1001"].address = "0x1F48A48a110b78C1EAf924c96E8BF5B96bC5d8A4";
      App.contracts.Border.setProvider(App.web3Provider);      
      return App.borderInfo();
    });

    $.getJSON('TokenBorder.json', function(data) {
      var TokenBorderArtifact = data;      
      App.contracts.TokenBorder = TruffleContract(TokenBorderArtifact);

      //Address deve ser atualizado de acordo com a borda criada na rede determinada
      App.contracts.TokenBorder.networks["1001"].address = "0x65E40826Cc9c20828196025007861d5bF7089f1A";
      App.contracts.TokenBorder.setProvider(App.web3Provider);
      return App.tokenBorderInfo();
    }).then(function() {    
      return App.getTokenBorderBalance();
    });

    $.getJSON('Moviment.json', function(data) {
      var MovimentArtifact = data;
      App.contracts.Moviment = TruffleContract(MovimentArtifact);

      //Address deve ser atualizado de acordo com a borda criada na rede determinada
      App.contracts.Moviment.networks["1001"].address = "0xfDCed6fFfad96525BB355EFc368A3F44f0Cf091d";      
      App.contracts.Moviment.setProvider(App.web3Provider);      
      return App.movimentInfo();
    });    

    return App.bindEvents();
  },

  bindEvents: function() {
    $(document).on('click', '#solUSDMintButton', App.handleSolUSDMint);
    $(document).on('click', '#solUSDTransferButton', App.handleSolUSDTransfer);
    $(document).on('click', '#solUSDApproveButton', App.handleSolUSDApprove);
    $(document).on('click', '#borderTokenTransferButton', App.handleTokenBorderTransfer);
    $(document).on('click', '#borderTokenApproveButton', App.handleTokenBorderApprove);
    $(document).on('click', '#movimentSetRatioOwnerButton', App.handleMovimentSetRatioOwner);
    $(document).on('click', '#movimentSetRatioShareButton', App.handleMovimentSetRatioShare);
    $(document).on('click', '#movimentReportIncomingButton', App.handleMovimentReportIncoming);
    $(document).on('click', '#movimentBorderIncomingButton', App.handleMovimentBorderIncoming);
    $(document).on('click', '#borderFactoryCreateButton', App.handleBorderFactoryCreate);
    $(document).on('click', '#movimentFactoryCreateButton', App.handleMovimentFactoryCreate);
  },

  handleSolUSDMint: function() {
    event.preventDefault();

    var amount = parseInt($('#SolUSDMintAmount').val());
    var toAddress = $('#SolUSDMintAddress').val();
    console.log('Mint ' + amount + ' USD to ' + toAddress);

    var tokenInstance;
    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }

      var account = accounts[9];
      App.contracts.SolUSD.deployed().then(function(instance) {
        tokenInstance = instance;

        return tokenInstance.mint(toAddress, amount, {from: account});
      }).then(function(result) {
        return App.getSolUSDBalance();
      }).catch(function(err) {
        console.log(err.message);
      });
    });
  },

  handleSolUSDTransfer: function(event) {
    event.preventDefault();

    var amount = parseInt($('#SolUSDTransferAmount').val());
    var toAddress = $('#SolUSDTransferAddress').val();
    console.log('Transfer ' + amount + ' USD to ' + toAddress);

    var tokenInstance;
    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }

      var account = accounts[0];
      App.contracts.SolUSD.deployed().then(function(instance) {
        tokenInstance = instance;

        return tokenInstance.transfer(toAddress, amount, {from: account});
      }).then(function(result) {
        //alert('Transfer Successful!');
        return App.getSolUSDBalance();
      }).catch(function(err) {
        console.log(err.message);
      });
    });
  },  

  handleSolUSDApprove: function(event) {
    event.preventDefault();

    var amount = parseInt($('#SolUSDApproveAmount').val());
    var toAddress = $('#SolUSDApproveAddress').val();
    console.log('Approve ' + amount + ' USD to ' + toAddress);

    var tokenInstance;
    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }

      var account = accounts[0];
      App.contracts.SolUSD.deployed().then(function(instance) {
        tokenInstance = instance;

        return tokenInstance.approve(toAddress, amount, {from: account});
      }).then(function(result) {
        return App.getSolUSDBalance();
      }).catch(function(err) {
        console.log(err.message);
      });
    });
  },

  getSolUSDBalance: function() {
    //console.log('Getting balances...');

    var tokenInstance;
    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }

      var account = accounts[0];
      App.contracts.SolUSD.deployed().then(function(instance) {
        tokenInstance = instance;

        return tokenInstance.balanceOf(account);
      }).then(function(result) {
        balance = result.c[0];
        $('#SolUSDBalance').text(balance);
      }).catch(function(err) {
        console.log(err.message);
      });
    });
  },


  handleBorderFactoryCreate: function(event) {
    event.preventDefault();

    var name = $('#BorderFactoryCreateName').val();
    var tokenName = $('#BorderFactoryCreateTokenName').val();
    var tokenSymbol = $('#BorderFactoryCreateTokenSymbol').val();
    console.log('Create border ' + name + ' token '  + tokenName + ' symbol ' + tokenSymbol);

    var contractInstance;
    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }

      var account = accounts[0];
      App.contracts.BorderFactory.deployed().then(function(instance) {
        contractInstance = instance;

        return contractInstance.createBorder(name, tokenName, tokenSymbol, {from: account});
      }).then(function(result) {
        return App.borderFactoryListBorders();
      }).catch(function(err) {
        console.log(err.message);
      });
    });
  },  

  borderFactoryListBorders: function() {
    //console.log('Getting borders...');

    var contractInstance;
    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }
      var account = accounts[0];
      App.contracts.BorderFactory.deployed().then(function(instance) {
        contractInstance = instance;
        //console.log(contractInstance.address);

        return contractInstance.listBorders();
      }).then(function(result) {
        //console.log(JSON.stringify(result));        
        list = result;
        $('#ListBorders').text(list);
      }).catch(function(err) {
        console.log(err.message);
      });
    });
  },

  borderInfo: function() {
    //console.log('Getting border info...');

    var contractInstance;
    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }
      var account = accounts[0];
      App.contracts.Border.deployed().then(function(instance) {
        contractInstance = instance;
        //console.log(contractInstance.address);

        $('#BorderAddress').text(contractInstance.address);
        return contractInstance.name();
      }).then(function(result) {
        //console.log(JSON.stringify(result));        
        $('#BorderName').text(result);

        return contractInstance.listOwners();
      }).then(function(result) {
        //console.log(JSON.stringify(result));        
        $('#ListBorderOwners').text(result);
      }).catch(function(err) {
        console.log(err.message);
      });

    });
  },  

  tokenBorderInfo: function() {
    //console.log('Getting token border info...');

    var contractInstance;
    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }
      var account = accounts[0];
      App.contracts.TokenBorder.deployed().then(function(instance) {
        contractInstance = instance;
        //console.log(contractInstance.address);

        $('#TokenBorderAddress').text(contractInstance.address);
        return contractInstance.name();
      }).then(function(result) {
        //console.log(JSON.stringify(result));        
        $('#TokenBorderName').text(result);
      }).catch(function(err) {
        console.log(err.message);
      });

    });
  },  

  getTokenBorderBalance: function() {
    //console.log('Getting Token Border balances...');

    var tokenInstance;
    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }

      var account = accounts[0];
      App.contracts.TokenBorder.deployed().then(function(instance) {
        tokenInstance = instance;

        return tokenInstance.balanceOf(account);
      }).then(function(result) {
        //console.log(JSON.stringify(result)); 
        balance = result.c[0];
        $('#BorderTokenBalance').text(balance);
        return tokenInstance.symbol();
      }).then(function(result) {
        $('#BorderTokenSymbol').text(result);
      }).catch(function(err) {
        console.log(err.message);
      });
    });
  },

  handleTokenBorderTransfer: function(event) {
    event.preventDefault();

    var amount = parseInt($('#BorderTokenTransferAmount').val());
    var toAddress = $('#BorderTokenTransferAddress').val();
    console.log('Transfer ' + amount + ' Token Border to ' + toAddress);

    var tokenInstance;
    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }

      var account = accounts[0];
      App.contracts.TokenBorder.deployed().then(function(instance) {
        tokenInstance = instance;

        return tokenInstance.transfer(toAddress, amount, {from: account});
      }).then(function(result) {
        //alert('Transfer Successful!');
        return App.getTokenBorderBalance();
      }).catch(function(err) {
        console.log(err.message);
      });
    });
  },  

  handleTokenBorderApprove: function(event) {
    event.preventDefault();

    var amount = parseInt($('#BorderTokenApproveAmount').val());
    var toAddress = $('#BorderTokenApproveAddress').val();
    console.log('Approve ' + amount + ' USD to ' + toAddress);

    var tokenInstance;
    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }

      var account = accounts[0];
      App.contracts.TokenBorder.deployed().then(function(instance) {
        tokenInstance = instance;

        return tokenInstance.approve(toAddress, amount, {from: account});
      }).then(function(result) {
        return App.getTokenBorderBalance();
      }).catch(function(err) {
        console.log(err.message);
      });
    });
  },  

  movimentInfo: function() {
    //console.log('Getting moviment info...');

    var contractInstance;
    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }
      var account = accounts[0];
      App.contracts.Moviment.deployed().then(function(instance) {
        contractInstance = instance;
        //console.log(contractInstance.address);

        $('#MovimentAddress').text(contractInstance.address);
        return contractInstance.name();
      }).then(function(result) {
        //console.log(JSON.stringify(result));        
        $('#MovimentName').text(result);
        return contractInstance.listOwners();
      }).then(function(result) {
        //console.log(JSON.stringify(result));        
        //Retirar o primeiro: 0x0000000000000000000000000000000000000000
        $('#ListMovimentOwners').text(result);
        return contractInstance.listBorders();
      }).then(function(result) {
        //console.log(JSON.stringify(result));        
        //Retirar o primeiro: 0x0000000000000000000000000000000000000000
        $('#ListMovimentBorders').text(result);
      }).catch(function(err) {
        console.log(err.message);
      });

    });
  },  

  handleMovimentSetRatioOwner: function() {
    event.preventDefault();

    var value = parseInt($('#MovimentSetRatioOwnerPerc').val());
    var toAddress = $('#MovimentSetRatioOwnerTo').val();
    var contractInstance;
    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }
      var account = accounts[0];
      App.contracts.Moviment.deployed().then(function(instance) {
        contractInstance = instance;

        return contractInstance.setRatioOwner(toAddress, value, {from: account});        
      }).then(function(result) {
        console.log(JSON.stringify(result));
      }).catch(function(err) {
        console.log(err.message);
      });

    });
  },

  handleMovimentSetRatioShare: function() {
    event.preventDefault();

    var value = parseInt($('#MovimentSetRatioSharePerc').val());
    var fromAddress = $('#MovimentSetRatioShareFrom').val();
    var toAddress = $('#MovimentSetRatioShareTo').val();
    var contractInstance;
    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }
      var account = accounts[0];
      App.contracts.Moviment.deployed().then(function(instance) {
        contractInstance = instance;

        return contractInstance.setRatioShare(fromAddress, toAddress, value, {from: account});        
      }).then(function(result) {
        console.log(JSON.stringify(result));
      }).catch(function(err) {
        console.log(err.message);
      });

    });
  },

  handleMovimentReportIncoming: function() {
    event.preventDefault();

    var value = parseInt($('#MovimentReportIncomingValue').val());
    var description = $('#MovimentReportIncomingDescription').val();
    var contractInstance;
    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }
      var account = accounts[0];
      App.contracts.Moviment.deployed().then(function(instance) {
        contractInstance = instance;

        return contractInstance.reportIncoming(value, description, {from: account});        
      }).then(function(result) {
        //console.log(JSON.stringify(result));
        $('#movimentReportIncomingEvents').text(JSON.stringify(result.logs));
      }).catch(function(err) {
        console.log(err.message);
      });

    });
  },

  handleMovimentBorderIncoming: function() {
    event.preventDefault();

    var total = parseInt($('#MovimentBorderIncomingTotal').val());
    var value = parseInt($('#MovimentBorderIncomingBorderValue').val());
    var contractInstance;
    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }
      var account = accounts[0];
      App.contracts.Moviment.deployed().then(function(instance) {
        contractInstance = instance;

        return contractInstance.borderIncoming(total, value, {from: account});        
      }).then(function(result) {
        //console.log(JSON.stringify(result));
        $('#movimentBorderIncomingEvents').text(JSON.stringify(result.logs));
      }).catch(function(err) {
        console.log(err.message);
      });

    });
  },


  handleMovimentFactoryCreate: function(event) {
    event.preventDefault();

    var name = $('#MovimentFactoryCreateName').val();
    console.log('Create moviment ' + name);

    var contractInstance;
    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }
      var account = accounts[0];
      App.contracts.MovimentFactory.deployed().then(function(instance) {
        contractInstance = instance;

        return contractInstance.createMoviment(name, {from: account});
      }).then(function(result) {
        return App.movimentFactoryListMoviments();
      }).catch(function(err) {
        console.log(err.message);
      });
    });
  },   
  
  movimentFactoryListMoviments: function() {
    //console.log('Getting moviments...');

    var contractInstance;
    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }
      var account = accounts[0];
      App.contracts.MovimentFactory.deployed().then(function(instance) {
        contractInstance = instance;
        //console.log(contractInstance.address);

        return contractInstance.listMoviments();
      }).then(function(result) {
        //console.log(JSON.stringify(result));        
        list = result;
        $('#ListMoviments').text(list);
      }).catch(function(err) {
        console.log(err.message);
      });
    });
  },   

};

$(function() {
  $(window).load(function() {
    App.init();
  });
});