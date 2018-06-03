		//Initialize JS-Smart Contract bridge
        if (typeof web3 !== 'undefined') {
            web3 = new Web3(web3.currentProvider);
        } else {
            // set the provider you want from Web3.providers
            web3 = new Web3(new Web3.providers.HttpProvider("HTTP://127.0.0.1:7545"));
        }
		
		web3.eth.defaultAccount = web3.eth.accounts[0];
		
		var EHSContract = web3.eth.contract(
			abi);
		var EHS = EHSContract.at('0xb15d21d9fed208a9a84d1823c5e33f64424267c3');
		
		//Initialize Frontend
		updateParticipants();
		
		
       	//Button handeling
		$("#registerParticipant").click(function() {
            testRegister($("#addressCreate").val(), ($("#nameCreate").val()), $("#renewCreate").val() == 'true', $("#stillAllowedCreate").val() );
			updateParticipants();
        });
		
		$("#buyToken").click(function() { 	
			EHS.buyToken({ value: $("#valuebuyToken").val()*1000000000000000000, from: $("#accountbuyToken").val() });
			updateParticipants();
        });
		
		$("#burnToken").click(function() {
			EHS.burnToken($("#amountburnToken").val(),{from:$("#accountburnToken").val()});
			updateParticipants();
        });
		
		$("#buyGreen").click(function() {
			EHS.buyGreenEnergy($("#addressGreen").val(), $("#amountbuyGreen").val(),{from:$("#accountbuyGreen").val()});
			updateParticipants();
        });
		
		$("#BurnAndWithdaw").click(function() {
			EHS.burnTokenAndWithdraw($("#amountBurnAndWithdaw").val(),{from:$("#accountBurnAndWithdaw").val()} );
			updateParticipants();
        });
		
		$("#createOrder").click(function() {
			EHS.orderIwantEther($("#createetherGet").val()*1000000000000000000, $("#createtokenGive").val(),$("#createtimeWindow").val(),$("#createNounce").val(),
			{from:$("#accountCreateOrder").val()} );
			updateParticipants();
        });
		
		$("#takeOrder").click(function() {
			EHS.trade($("#takeetherGet").val()*1000000000000000000,$("#taketokenGive").val(),$("#taketimeWindow").val(),$("#takeNounce").val(), $("#orderAccount").val(),{value:($("#amountEtherTake").val()*1000000000000000000),from: $("#accountTakeOrder").val()});
			updateParticipants();
        });
		
		$("#cancelOrder").click(function() {
			EHS.cancelOrder($("#canceletherGet").val()*1000000000000000000, $("#canceltokenGive").val(),$("#canceltimeWindow").val(),$("#cancelNounce").val(),
			{from:$("#accountcancelOrder").val()} );
			updateParticipants();
        });
		
		//Creates set of test participants
		$("#registertestParticipants").click(function() {
			(testRegister(web3.eth.accounts[1], 'Company_1', false, 10));
			(testRegister(web3.eth.accounts[2], 'Company_2', false, 20));
			(testRegister(web3.eth.accounts[3], 'Renewable_1', true, 0));
        });
		
		//Updates the shown participants attributes
		function updateParticipants(){
			
			//Owner
			$("#account0").html("Account: " +web3.eth.accounts[0]);
			
			//Smart Contract
			$("#accountSM").html("Account: " + EHS.address);
			$("#etherSM").html("Ether Balance: " + web3.fromWei(web3.eth.getBalance(EHS.address)) + " ether");
			$("#tokenPrice").html("Token Preis: " + EHS.tokenPrice()/1000000000000000000 + " ether");
			$("#punishPrice").html("Straf Preis: " + EHS.expensiveTokenPrice()/1000000000000000000 + " ether");
			$("#totalSupply").html("Anzahl existierender Token: " + EHS.totalSupply());
			$("#withdrawPrice").html("Durchschnittswert eines Tokens: " + EHS.withdrawPrice()/1000000000000000000 + " ether");
			
			//Participants
			for(var i =1; i<6;i++){
				var participant = EHS.participants(web3.eth.accounts[i]);
				//If participant does not exists: Display none
				if(!participant[1]){
					$("#participant"+i).css("display", "none");
				}else{
					$("#participant"+i).css("display", "block");
					$("#name"+i).html(participant[0]);
					$("#account"+i).html("Account: " +web3.eth.accounts[i]);
					$("#ether"+i).html("Ether Balance: " + web3.fromWei(web3.eth.getBalance(web3.eth.accounts[i]))+ " ether");	
					$("#token"+i).html("Anzahl Token: "+ participant[4].c[0]);
					//If participant is Renewable energy
					if(participant[2]) {
						$("#renewablePic"+i).css("display", "block");
						$("#factoryPic"+i).css("display", "none");
						$("#renew"+i).html("Erzeuger erneuerbarer Energien");
						$("#invested"+i).html("");
						$("#burned"+i).html("");
						$("#allowed"+i).html("");
					}
					else{
						$("#renewablePic"+i).css("display", "none");
						$("#factoryPic"+i).css("display", "block");
						$("#renew"+i).html("Unternehmen");
						$("#invested"+i).html("Anzahl von Token in erneuerbare Energien investiert: "+ participant[5].c[0]);
						$("#burned"+i).html("Anzahl von Token geburnt: "+ participant[6].c[0]);
						$("#allowed"+i).html("Frei käufliche Token: "+participant[3].c[0]);}

					
				}
			}
		}
		
		//Registers a Participants and tests the created values
		function testRegister(account, name, renew, stillAllowed){
			
			EHS.registerParticipant(account, name, renew, stillAllowed,{from: web3.eth.accounts[0], gas:2000000});
			
			if(EHS.participants(account)[0]==name
			  && EHS.participants(account)[1]==true
			  && EHS.participants(account)[2]==renew
			  && EHS.participants(account)[3].c[0]==stillAllowed){
				updateParticipants();
				return true;
			}else{return false;}
		}
		
		//Handels the select of companys options
		function selectCompanyOptions(select){
			for(var i = 1; i<=6; i++){
				if(select.value == 'CompanyOption'+i){
					document.getElementById('CompanyOption'+i).style.display = 'block';
				}else{document.getElementById('CompanyOption'+i).style.display = 'none';}

			}
		}

		//Handels the select of sidebar
		function sidebarSelectHandler(select){
			if(select.value == 'regulator'){
				document.getElementById('sidebarRegulator').style.display = 'block';
				document.getElementById('sidebarCompany').style.display = 'none';
				document.getElementById('sidebarRenewable').style.display = 'none';

			}else if(select.value == 'company'){
				document.getElementById('sidebarRegulator').style.display = 'none';
				document.getElementById('sidebarCompany').style.display = 'block';
				document.getElementById('sidebarRenewable').style.display = 'none';

			}else if(select.value == 'renew'){
				document.getElementById('sidebarRegulator').style.display = 'none';
				document.getElementById('sidebarCompany').style.display = 'none';
				document.getElementById('sidebarRenewable').style.display = 'block';
			}
		}
		
		//EVENTHANDELING
		
	   var orderCreatedEvent = EHS.OrderCreated();
       orderCreatedEvent.watch(function(error, result){
            if (!error)
                {
					$('#orderbook tr:last').after('<tr><td>'+result.args._creator+'</td><td>'+result.args.amountGet / result.args.amountGive / 1000000000000000000+'</td><td>'+result.args.amountGet / 1000000000000000000+'</td><td >'+""+result.args.amountGive+'</td><td>'+""+result.args.expires+'</td><td >'+""+result.args.nonce+'</td></tr>');		
					//$("#tokenLeft1").html("Verfügbare Token: " + result.args.nonce);
                } else {
                    console.log('error' + error);
                }
        });
 		
		/*function updateOrderbook(){
			var table = document.getElementById("#orderbook");
			for (var i = 0, row ; row = table.rows[i]; i++) {
   				console.log(row);
   				for (var j = 0, col; col = row.cells[j]; j++) {
     				console.log(col);
					}  
				}
			
		};*/

		
		/*function testbuyToken(account, _value, ){
			// company check
			if(!(EHS.participants(account)[1]==true && EHS.participants(account)[2]==false))return false;
			
			// amount before amount after
			var allowedBefore = EHS.participants(account)[3].c[0];
			var tokenBefore = EHS.participants(account)[4].c[0];
			
			EHS.buyToken({ value: _value, from: account });
			
			_value = _value / 1000000000000000000;
			
			if(!(allowedBefore - _value) == EHS.participants(account)[3].c[0])return false;
			if(!(tokenBefore + _value) == EHS.participants(account)[4].c[0])return false;
			updateParticipants();
			return true;
			
			// amount still allowed, before after
			
			// totalSupply amount before after
			
			// withdraw price after
		}*/
		/*
		function testburnToken(account, _value){
			
			//Check if enough token
			if(!(EHS.participants(account)[4].c[0] >= _value)) return false;
			
			// company check
			if(!(EHS.participants(account)[1]==true && EHS.participants(account)[2]==false))return false;
			
			//amount before vs after
			var burnedBefore = EHS.participants(account)[6].c[0];
			var tokenBefore = EHS.participants(account)[4].c[0];
			
			EHS.burnToken( _value, { from: account });
			
			
			if(!(burnedBefore + _value) == EHS.participants(account)[6].c[0])return false;
			if(!(tokenBefore - _value) == EHS.participants(account)[4].c[0])return false;
			updateParticipants();
			return true;
		}*/
		/*//(testbuyToken(web3.eth.accounts[1], 5000000000000000000));
		//(testbuyToken(web3.eth.accounts[2], 4000000000000000000));
		//(testburnToken(web3.eth.accounts[1], 2));
		//EHS.buyGreenEnergy(web3.eth.accounts[3],  2, {from: web3.eth.accounts[2]});
		//EHS.orderIwantEther(5000000000000000000,5,1,1, {from: web3.eth.accounts[1]});
		
		//EHS.trade(5000000000000000000,5,1,1, web3.eth.accounts[1],{value:3000000000000000000,from: web3.eth.accounts[2]});
		
		//EHS.orderIwantEther()
		//(EHS.tokenPrice(web3.eth.accounts[1], 2000000000000000000));
		
		
		//( EHS.participants(web3.eth.accounts[1])[4].c[0]);
		//EHS.buyToken({ value: 2000000000000000000, from: web3.eth.accounts[1] });
		//( EHS.participants(web3.eth.accounts[1])[4].c[0]);
	*/
		("Finished Loading Page");	
   
