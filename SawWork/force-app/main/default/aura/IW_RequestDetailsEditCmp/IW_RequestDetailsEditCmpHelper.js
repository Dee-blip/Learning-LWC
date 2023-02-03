({
    handleDoInit : function(component, event) {
        
        console.log('In HelperdoInt');
        var recId = component.get("v.recordId");
        //var securityChecked = component.find("securityCheckId").get("v.value"); 
        if(recId != undefined && recId != null && recId != '')
        {
            //this.showSpinner(cmp);
            var action = component.get("c.getIWDetails");
            action.setParams({
                "recordId" : recId, 
            });
            action.setCallback(this,function(res) {
            //this.hideSpinner(cmp);
            var state = res.getState();
            console.log('state ::::::::'+ state);
            if(state == 'SUCCESS') 
            {
                var result = res.getReturnValue();
                //alert('result ::' + result);
                if(result !=='No Records')
                {
                    var iwDetails = JSON.parse(result);
                    console.log('result : ' + result);
                    var initRecords = [];
                    console.log('iwDetails : ' + iwDetails);
                    //set Project when Security is checked
                    // if(iwDetails != undefined)
                    // {
                    //     var mappingRecord = iwDetails;
                        
                    //     if(iwDetails.Security__c){
                    //         console.log('mappingRecord : ' + mappingRecord);
                    //         var rec = {};
                    //         rec['SObjectType'] = 'pse__Proj__c';                        
                    //         rec['text'] = mappingRecord.Project__r.Name;                        
                    //         rec['val'] = mappingRecord.Project__r.Id;
                    //         if(mappingRecord != undefined)
                    //         {
                    //             component.set('v.projRec',rec);
                    //             component.set('v.displayProjectForSecurity', true);
                    //             component.set('v.toggleSecurity',true);
                    //         }  
                    //     }
                    // }
                }
                
            }
            else 
            {
                    //this.showErrorToast(cmp,event,'Failed due to unknown error','error','Error Message');
            }
         });
         $A.enqueueAction(action);

        }

    },

    afterRender : function(){
        
        console.log(' beforeee :: ');
        this.superAfterRender();
        console.log('just after!!');

        
    },
    
    navigateTo: function(component, recId) {
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": recId
        });
        navEvt.fire();
    },
    
    setToastVar: function(sMsg){
        console.log("--sMsg--"+sMsg);
        var type = "Error"; 
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            mode: 'dismissible',
            message: sMsg,
            type : type,
            duration:'5000',
        });
        toastEvent.fire();
    },
    
    setToastVarSuccess: function(sMsg){
        var type = "Success"; 
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            mode: 'dismissible',
            message: sMsg,
            type : type,
            duration:'5000',
        });
        toastEvent.fire();
    },
    
    waiting: function(component, event, helper) {
        component.set("v.HideSpinner", true);
    },
    
    doneWaiting: function(component, event, helper) {
       component.set("v.HideSpinner", false);
    },
    
    navigateToDetail: function(recordId){
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": recordId,
            "slideDevName": "detail"
        });
        navEvt.fire();
    },
    
    getAccountDetailsHelper : function(component, event, helper,accountId) {
        return new Promise(function(resolve,reject){
           //19.5 Adding Security check to find the number of slots available for Security / non Security Slots
           var securityChecked = component.get("v.displayProjectForSecurity"); 
           var regOrGeo = securityChecked ? regOrGeo = "Geography" : regOrGeo = "Region";
           console.log(' iw classfo : ' , component.find("iwClassificationCustom").get("v.value"));

           var getAvailableBudgetAction = component.get("c.availableLoeBudget");
            getAvailableBudgetAction.setParams({
                "accountInfo":accountId.toString(),
                "regORGeo" : regOrGeo,
                "classification" : component.find("iwClassificationCustom").get("v.value")
            });
            
            getAvailableBudgetAction.setCallback(this, function(result){
                var state = result.getState();
                if (component.isValid() && state === "SUCCESS"){
                    var loeResult = result.getReturnValue();
                    var obj = JSON.parse(loeResult);
                    console.log("availableLoeBud--: " + obj.Area);
                    console.log("availableLoeBud--: " + obj.Division);
                    console.log("availableLoeBud--: " + obj.Geography);
                    console.log("availableLoeBud--: " + obj.Owner);
                    
                    component.set("v.availableLoeBud",obj.slotHrs);
                    component.set("v.ClassificationOutput", component.find("iwClassificationCustom").get("v.value") );
                    component.set("v.showBudget",true);
                    component.set("v.OwnerId",obj.Owner);
                    component.set("v.Region",obj.Region);
                    component.set("v.Geography",obj.Geography);
                    //component.set("v.Division",obj.Division);
                    component.set("v.Zone",obj.Zone);
                    component.set("v.Area",obj.Area);
                    component.set("v.Territory",obj.Territory);
                    resolve(loeResult);
                }
                else if(component.isValid()){
                   	var errors = result.getError();
                    console.log("getLoeBudget Unknown error"+JSON.stringify(errors[0]));
                    //helper.setToastVar("Error: Failed to get available LOE for the selected Account.");
                    reject("Error: Failed to get available LOE for the selected Account.");
                }
            });
            $A.enqueueAction(getAvailableBudgetAction); 
        })
    }
    
})