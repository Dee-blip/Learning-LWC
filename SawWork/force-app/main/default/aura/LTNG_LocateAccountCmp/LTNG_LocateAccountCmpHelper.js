({
	getOpportunity : function(cmp) {
        console.log("Inside Helper");
		var action = cmp.get("c.getOpportunity");
        
        action.setParams({
            "opptyId": cmp.get("v.recordId")
        });
        action.setCallback(this, function(response) {
			var state = response.getState();
            //var noOfExistingOpps = response.getReturnValue().length;
            if (cmp.isValid() && state === "SUCCESS") 
            {
                cmp.set("v.opp", response.getReturnValue());
                console.log("Oppty:",response.getReturnValue());
			}
            
            
		});
        $A.enqueueAction(action);
		
	},
    AccSearch : function(cmp) {
            
                  
        cmp.set("v.flag2",false);
        cmp.set("v.btnDisable",false);        
        var off = parseInt(cmp.get("v.offset"));
        //var cnt = parseInt(cmp.get("v.counter"));
        var name=cmp.find("AccountName").get("v.value");
        var domain=cmp.find("AccountDomain").get("v.value");
        var ctry=cmp.find("AccountCountry").get("v.value");
        var province=cmp.find("AccountState").get("v.value");
        
        if(!name&&!domain&&!ctry&&!province)
        {
            console.log('All null please check');
            cmp.set("v.flag3",true);
            cmp.set("v.flag1",false);
            cmp.set("v.flag2",false);
            cmp.set("v.keyChange",false);
            return;
        }
		var action = cmp.get("c.accSearch");
       
        action.setParams({
            "AccountName": cmp.find("AccountName").get("v.value"),
            "AccountDomain":cmp.find("AccountDomain").get("v.value"),
            "AccountCountry":cmp.find("AccountCountry").get("v.value"),
            "AccountState":cmp.find("AccountState").get("v.value"),
            "offset":off
        });
        action.setCallback(this, function(response) {
            console.log('Inside setCllback!!');
			var state = response.getState();
            console.log('Return Value---->',response.getReturnValue());
            var accList=response.getReturnValue();
            var accs=cmp.get("v.acc");
           
            var noOfaccs = response.getReturnValue().length;
             console.log('Value of noOfaccs--->',noOfaccs);
            if (cmp.isValid() && state === "SUCCESS" ) 
            {   if(noOfaccs===0 && off===0)
                {
                  cmp.set("v.flag2",true);
                  cmp.set("v.flag1",false);
                  cmp.set("v.flag3",false);
                  return;
                }
             else{
 
                   if(noOfaccs<=9 && off>=0)
                      {
                         console.log('No more to load');
                         cmp.set("v.btnDisable",true);
                         
                      }
                 var keyChange=cmp.get("v.keyChange");
                 if(keyChange)
                 {
                   cmp.set("v.acc",accList);
                   cmp.set("v.keyChange",false);
                 }
                   else{
                   cmp.set("v.acc",accs.concat(accList));   
                   } //SFDC 7619                
                   
                   cmp.set("v.flag1",true);
                   cmp.set("v.flag2",false);
                   cmp.set("v.flag3",false);
                   cmp.set("v.offset",off+10);
                   //cmp.set("v.counter",cnt+1);                
                                     
             }
                 
			}
          
            /*var isphone=cmp.get("v.IsPhone");
            var isnotphone=cmp.get("v.IsNotPhone");
            
            if(!isphone && isnotphone && cnt===0 )
            {
            var evt = $A.get("e.force:navigateToComponent");
            evt.setParams({
            componentDef: "c:SF1_LocateAccountCmp",
            componentAttributes: {
               
                "recordId":cmp.get("v.recordId"),
                "opp" :cmp.get("v.opp"),
                "acc" :cmp.get("v.acc"),
                "flag1":cmp.get("v.flag1"),
                "flag2":cmp.get("v.flag2"),
                "flag3":cmp.get("v.flag3"),
                "btnDisable":cmp.get("v.btnDisable"),
                "offset":cmp.get("v.offset"),
                "counter":cmp.get("v.counter"),
                "keyChange":cmp.get("v.keyChange"),
                "IsPhone":cmp.get("v.IsPhone"),
                "IsNotPhone":cmp.get("v.IsNotPhone")
            }
        });
    evt.fire();    
            }*/    
            
           
		});
        
        $A.enqueueAction(action);
		
	}
    
    
   
})