({
    
    doInit : function(component, event, helper) {
        
        component.set("v.spinnerBool",true);
        var recordId = component.get("v.recordId");
        var action=component.get("c.getErrorMessage");
        action.setParams({ recordId : recordId });
        action.setCallback(this,function(a){
            component.set("v.spinnerBool",false);
            if(a.getState()==="SUCCESS"){
                var SIRecs=a.getReturnValue();
                component.set("v.ErrorMessage",SIRecs);
                if(SIRecs!=null && SIRecs.length > 0 ){
                    component.set("v.showHideSection",true);
                    //component.set("v.ShowtableFlag",false);
                }else{
                    component.set("v.showAccountEdit",true);
                }
            }
            else if(a.getState()==="ERROR"){
                $A.log("Errors",a.getError());
            }
        });
        $A.enqueueAction(action); 
        
    },
    CreateAccount : function(component, event, helper) {
        helper.AccountCreate(component, event, helper);
        
    },
    cancellRecord : function (component, event, helper) {
        
        var recordId = component.get("v.recordId");
        //alert(recordId); 
        var url = '/'+recordId;
        window.location.href =url;
    },
    CheckDupAccount : function (component, event, helper) {
        component.set("v.spinnerBool",true);
        
        var action=component.get("c.DupAccountCheck");
        var recordId = component.get("v.recordId");
        component.set('v.mycolumns', [
            {label: 'Account Name', fieldName: 'linkName', type: 'url', 
            typeAttributes: {label: { fieldName: 'Name' }, target: '_blank'}},
            {label: 'AKAM Account Id', fieldName: 'AKAM_Account_ID__c', type: 'Text'},
            {label: 'Website', fieldName: 'Website', type: 'Text'},
            {label: 'City', fieldName: 'city', type: 'Text'},
            {label: 'State', fieldName: 'state', type: 'Text'},
            {label: 'Country', fieldName: 'country', type: 'Text'},
            {label: 'Account Status', fieldName: 'Type', type: 'Text'}
            ]);
        action.setParams({ RecIds : recordId
         });
        action.setCallback(this,function(a){
            component.set("v.spinnerBool",false);
            if(a.getState()==="SUCCESS"){
                var SIRecs=a.getReturnValue();
                 SIRecs.forEach(function(record){
                    record.linkName = '/'+record.Id;
                    record.country = record.BillingAddress.country;
                    record.state = record.BillingAddress.state;
                    record.city = record.BillingAddress.city;
                });
                //var xxx=
               // alert(JSON.stringify(SIRecs));
                if(SIRecs!=null && SIRecs.length > 0 ){
                    component.set("v.ShowtableFlag",true);
                    component.set("v.showAccountEdit",false);
                     //component.set("v.showHideSection",true);

                    component.set("v.acctList", SIRecs);
                    //alert(component.get("v.acctList"));
                }else{
                    helper.AccountCreate(component, event, helper);
                }
            }
            else if(a.getState()==="ERROR"){
                $A.log("Errors",a.getError());
            }
        });
        $A.enqueueAction(action);

    }
    
})