({
    doInit : function(component, event, helper) {
        helper.handleDoInit(component, event);
    },
    
    onSave : function(component, event, helper) {
        helper.handleOnSave(component, event);
    },

    close1 : function (component, event, helper) {
        //alert('before event fired.');
        //component.set("v.openNewuserRec");
        //var appEvent = $A.get("e.c:InvWB_closeNewUserRegionMap");
        //alert(appEvent);
        //appEvent.fire();
        //alert('event fired.');
    },
    
    close: function(component, event, helper) {
        helper.handleOnClose(component, event);
        /*var recId = component.get("v.recordId");
        if (!recId) {
            var homeEvt = $A.get("e.force:navigateToObjectHome");
            homeEvt.setParams({
                "scope": "Inv_WorkBox_Region_Mapping__c"
            });
            homeEvt.fire();
        } else {
            helper.navigateTo(component, recId);
        }*/
    },
    
    showSpinner : function(component, event, helper) {
       // make Spinner attribute true for display loading spinner 
        component.set("v.Spinner", true); 
    },
    
     // this function automatic call by aura:doneWaiting event 
    hideSpinner : function(component,event,helper){
     // make Spinner attribute to false for hide loading spinner    
       component.set("v.Spinner", false);
    },
    
    add : function(cmp, event, helper) {
        var records = cmp.get("v.records");
        records.unshift({'SObjectType':'pse__region__c', 'id':'', 'type':event.target.id});
        cmp.set("v.records",records);
    },
    
    remove : function(cmp, event, helper) {
        var index = event.target.id;
        //alert(index);     
        var records = cmp.get("v.records");
        if(records.length >= 1) {
            if(index) {
                records.splice(index, 1);
            }
            else {
                records.pop();
            }
        }
        cmp.set("v.records",records);
    },
    handleChange: function (cmp, event) {
        // This will contain the string of the "value" attribute of the selected option
        var selectedOptionValue = event.getParam("value");
        console.log("Option selected with value: '" + selectedOptionValue + "'");
        console.log(typeof selectedOptionValue );
        if (selectedOptionValue) {
            cmp.set("v.recordTypeName", selectedOptionValue);
        } 
    }
    
})