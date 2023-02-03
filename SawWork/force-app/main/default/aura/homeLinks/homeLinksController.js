({
    
    onRecordUpdatedUser: function(component, event, helper) 
    {
        var eventParams = event.getParams();
        var outOfOffice = false;
        var setLabel;
        if(eventParams.changeType === "LOADED") 
        {
            console.log("Record is loaded successfully.");
            
            var currentUser = component.get("v.currentUser");
            outOfOffice = currentUser.PS_Out_of_Office__c;
         }  
        setLabel = outOfOffice === true?'Unset Overage Approval Out Of Office' : 'Set Overage Approval Out Of Office';
        console.log('outOfOffice: ' + setLabel);
        component.set('v.outOfOfficeLabel',setLabel);
                  
    },
    navigateToPage : function(component, event, helper) 
    {
        event.preventDefault();
        var pageName = event.getParam('name');
        window.open(pageName);
        
    },
    doInit: function(component, event, helper) 
    {
		 var action = component.get("c.getSavedDashboardView");
        action.setParams({
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var view=response.getReturnValue();
                if(view==='TSC')
                {
                    component.set("v.caseViewVal",true);
                }
                else
                {
                    component.set("v.caseViewVal",false);
                }
                 /*var payload = {caseView: view};
        component.find("ucdMessageChannel").publish(payload);*/
            }
            
         });
        $A.enqueueAction(action);
    },
    
    caseViewChange : function(component, event, helper) 
    {
        var viewVal;
        if(component.get("v.caseViewVal"))
        {viewVal= 'TSC';} // TSC = Case Management View
        else
        {viewVal = 'GS2';} // GS2 = Daily Case Management
        
        //Lightning messaging service send payload to UCD dashboard
        var payload = {caseView: viewVal};
        component.find("ucdMessageChannel").publish(payload);
        
       //Saving choice
        var action = component.get("c.saveUserUCDView");
        action.setParams({
            choosenView : viewVal
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log("save success")
            }
            
         });
        $A.enqueueAction(action);
       
    }
})