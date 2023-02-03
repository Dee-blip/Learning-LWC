({
	init : function(component, event, helper) {
        
        console.log('showCloneFromCaseeeeeee//'+ component.get("v.showCloneFromCase"));
        if(component.get("v.showCloneFromCase")==false)
        {
         component.set("v.caserecId", component.get("v.pageReference").state.c__caserecId);
        }
        console.log('caserecId INIT JS//'+component.get("v.caserecId"));
        
        helper.callServer(
            component,
            "c.getAccountData",
            function(result)
            {
                
                var returnVal = result; 
                console.log('returnVal///'+JSON.stringify(returnVal));
                var acctList = [];
                for(var key in returnVal){
                    var recList = {'label': key , 'value' : returnVal[key]};
                    console.log('recList'+JSON.stringify(recList));
                    //acctList.push({value:returnVal[key], key:key});
                    acctList.push(recList);
                    console.log('acctList//'+JSON.stringify(acctList));
                }
                //console.log('accts//'+accts);
                component.set("v.accountList", acctList);
                console.log('accountList//'+JSON.stringify(component.get("v.accountList")));
                
            },
            {
                "caseId":  component.get("v.caserecId")
            }
            
        ); 
    },
    
   spinnerShow: function(component, event, helper)   
    {
        component.set("v.showSpinner", true);
    },
    spinnerHide: function(component, event, helper)   
    {
        component.set("v.showSpinner", false);
    },
    
            handleAccountChange: function (component, event, helper) {
        //Get the Selected values   
        var selectedValues = event.getParam("value");
        console.log('selectedValues//'+selectedValues);
        
        //Update the Selected Values  
        component.set("v.selectedAccList", selectedValues);
        console.log('selectedAccList//'+ component.get("v.selectedAccList"));
        
        
    },
        
        cloneSelectedAccount : function(component, event, helper){
        //Get selected Account List on button click 
        var selectedValues = component.get("v.selectedAccList");
        console.log('selectedValues Length//'+selectedValues.length);
        if(selectedValues.length == 0)
        {
            var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "type": "Error",
                    "message": "Select atleast one Account"
                });
                toastEvent.fire();
        }
        //console.log('Selectd Account-' + selectedValues);
        else{
        helper.callServer(
            component,
            "c.cloneMulti",
            function(result)
            {
                console.log('In multii js');
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "type": "Success",
                    "message": "The Case records have been created successfully."
                });
                toastEvent.fire();
                 helper.closeCaseTab(component, event, helper);
                
                var homeEvent = $A.get("e.force:navigateToList");
                homeEvent.setParams({
                    "scope": "Case"
                });
                homeEvent.fire();
            },
         {
             "caseId":  component.get("v.caserecId"),
             "accountIds": selectedValues
         }
         
     );   
            
        }
        
    },
    handleOnSubmit:function(component, event, helper) {
        event.preventDefault();
        var fields = event.getParam("fields");
        console.log('ev'+JSON.stringify(fields));
        var accLookupId = fields.AccountId;
         console.log('accLookup//'+accLookupId);
        var optionAccs = component.get("v.accountList")
        var selectedAccs = component.get("v.selectedAccList")
        console.log('selectedAccs before helper call'+selectedAccs);
       
        var getAccsIndex = selectedAccs.indexOf(accLookupId);
        console.log('getAccsIndex/'+getAccsIndex);
        
         if(accLookupId == null)
        {
             var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "type": "Error",
                    "message": "Select an Account first!"
                });
                toastEvent.fire();
           // component.set("v.showSpinner", false);
            
        }
        
        else if(getAccsIndex == -1){
            helper.callServer(
                component,
                "c.getAccounts",
                function(result)
                {
                    
                    var returnAccVal = result; 
                    console.log('returnAccVal///'+JSON.stringify(returnAccVal));
                    var acctList = [];
                    for(var key in returnAccVal){
                        if(returnAccVal[key])
                            var accRecList = {'label': key , 'value' : returnAccVal[key]};
                        console.log('accRecList'+JSON.stringify(accRecList));
                        optionAccs.push(accRecList);
                        console.log('optionAccs//'+JSON.stringify(optionAccs));
                    }
                    //console.log('accts//'+accts);
                    component.set("v.accountList", optionAccs);
                    console.log('accountList after Lookup//'+JSON.stringify(component.get("v.accountList")));
                    
                    selectedAccs.push(accLookupId);
                    console.log('selectedAccspushh'+selectedAccs);
                    component.set("v.defaultOptions",selectedAccs);
                    component.set("v.selectedAccList",selectedAccs);
                    console.log('Final ids after helper//'+ component.get("v.selectedAccList"));                
                    
                },
                {
                    "accId":  accLookupId
                }); 
        }
        else
        {
            var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "type": "Error",
                    "message": "This Account is already added."
                });
                toastEvent.fire();
        }
        
    },
    
     closeTab:function(component, event, helper) {
        helper.closeCaseTab(component, event, helper)
    }
    
    

})