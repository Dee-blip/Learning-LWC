({
	doInit : function(component, event, helper){
        var device = $A.get("$Browser.formFactor");
        console.log('You are on'+device);
        helper.getOpportunity(component);
        helper.getPicklistValuesForVerticalandSubVerticalField(component);
	},
    
    doInsert : function(component, event, helper) {
        console.log("Inside Controller doInsert");
        helper.insertAccount(component);
	},
    showSpinner: function(cmp) {
       /*if(document.getElementById("oppSpinner") != null)
        {
            document.getElementById("oppSpinner").style.display = "block";
           }*/ 
        var spinner = cmp.find("ltngSpinner");
        $A.util.removeClass(spinner, "slds-hide");
        $A.util.addClass(spinner, "slds-show");
    },
        
    hideSpinner : function(cmp){
        /*if(document.getElementById("oppSpinner") != null)
        {
            document.getElementById("oppSpinner").style.display = "none";
           }*/
        var spinner = cmp.find("ltngSpinner");
        $A.util.removeClass(spinner, "slds-show");
        $A.util.addClass(spinner, "slds-hide");
    },

    Navigate : function(component){
        var evt
        var device = $A.get("$Browser.formFactor");
        
        if(device==='PHONE')
        {
            evt = $A.get("e.force:navigateToComponent");
            evt.setParams({
            componentDef: "c:SF1_LocateAccountCmp",
            componentAttributes: {
               
                "recordId":component.get("v.recordId")
            }
        });
             evt.fire();    
        }
        else
        {
            evt = $A.get("e.force:navigateToComponent");
            evt.setParams({
            componentDef: "c:LTNG_LocateAccountCmp",
            componentAttributes: {
                "recordId":component.get("v.recordId")
            }
        });
    evt.fire();    
        }
	},
    CheckDupAccount : function (component, event, helper){
        var SIRecs;
        var vertical = component.find("VerticalField").get("v.value");
        var subVertical = component.find("SubVerticalField").get("v.value");
        var action=component.get("c.DupAccountCheck");
       // var recordId = component.get("v.recordId");
        console.log('Inside CheckDupAccount:'+vertical+':'+subVertical);
        if(vertical === '--- None ---' || subVertical === '--- None ---' || vertical === '' || subVertical === ''){
            component.set("v.FieldError",true);
        }
        else{
            component.set("v.FieldError",false);
            component.set('v.mycolumns', [
                {label: 'Account Name', fieldName: 'linkName', type: 'url', 
                 typeAttributes: {label: { fieldName: 'Name' }, target: '_blank'}},
                {label: 'AKAM Account Id', fieldName: 'AKAM_Account_ID__c', type: 'Text'},
                {label: 'Website', fieldName: 'Website', type: 'Text'}
            ]);
            action.setParams({
                "pid": component.get("v.recordId"),
                "AccountName": component.find("AccountName").get("v.value"),
                "AccountDomain":component.find("AccountDomain").get("v.value"),
                "PrimaryStreet":component.find("PrimaryStreet").get("v.value"),
                "PrimaryCity":component.find("PrimaryCity").get("v.value"),
                "PrimaryState":component.find("PrimaryState").get("v.value"),
                "zip":component.find("PostalCode").get("v.value"),
                "PrimaryCountry":component.find("PrimaryCountry").get("v.value")
            });
            action.setCallback(this,function(a){
                if(a.getState()==="SUCCESS"){
                    SIRecs = a.getReturnValue();
                    SIRecs.forEach(function(record){
                        record.linkName = '/'+record.Id;
                    });
                    //alert(SIRecs);
                    //alert('outside ');
                    component.set("v.ProceedFlag",true);
                    
                    if(SIRecs !== null && SIRecs.length > 0 ){
                        component.set("v.ShowtableFlag",true);
                        component.set("v.acctList", SIRecs);
                        // alert(component.get("v.acctList"));
                    }
                    else{
                        helper.insertAccount(component);
                    }
                }
                else if(a.getState()==="ERROR"){
                    console.log('Errors:',a.getError());
                    let toastParams = {
                        title: "Error",
                        message: "Something went wrong", // Default error message
                        type: "error"
                    };
                    let toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams(toastParams);
                    toastEvent.fire();
                }
            });
            $A.enqueueAction(action);
        }

    },

    ObjFieldByParent : function(component){
        var childValues, childValueList, i;
        var controllerValue = component.find("VerticalField").get("v.value");
        var pickListMap = component.get("v.getPickListMap");
        if(controllerValue !== '--- None ---'){            
            childValues = pickListMap[controllerValue];            
            childValueList = [];
            childValueList.push('--- None ---');
            if(childValueList.length > 0){
                for (i = 0; i < childValues.length; i++){
                    childValueList.push(childValues[i]);
                }
            }
            component.set("v.getChildList", childValueList);
            if(childValues.length > 0){
                component.set("v.getDisabledChildField" , false);  
            }
            else{
                component.set("v.getDisabledChildField" , true); 
            }  
        } 
        else{
            component.set("v.getChildList", ['--- None ---']);
            component.set("v.getDisabledChildField" , true);
        }
	}
  
})