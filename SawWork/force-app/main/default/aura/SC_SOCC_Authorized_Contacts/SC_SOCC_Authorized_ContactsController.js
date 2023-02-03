({
    doinit: function (component, event, helper) {
        component.set("v.isOpen","false");
        var action = component.get("c.getAuthorizedContacts");
        action.setParams({
            "caseId": component.get("v.recordId")
        });
        
        action.setCallback(this, function(response) {
            var returnval = response.getReturnValue();
            if (returnval != null) {
                component.set('v.AuthorizedContacts',returnval);
                if(returnval.wrapperlist!="null"){
                    component.set('v.NumbAuthorizedContacts',returnval.wrapperlist.length);
                }
                if(returnval.case_authorized=='true'){
                    component.set('v.IsCaseApproved',"false");}
                else{component.set('v.IsCaseApproved',"true"); }
            }
            else
                 component.set('v.NumbAuthorizedContacts','0');
        });
        $A.enqueueAction(action);
    },
    
    openPop : function(component, event, helper) {
        var ID = event.target.id;
        var action = component.get("c.getContactDetails");
        action.setParams({
            "ContactId": ID
        });
        
        action.setCallback(this, function(response) {
            var returnval = response.getReturnValue();
            {
                component.set('v.AuthorizedContactDet',returnval);
                var cmpTarget = component.find('pop');
                $A.util.addClass(cmpTarget, 'slds-show');
                $A.util.removeClass(cmpTarget, 'slds-hide');
            }
        });
        $A.enqueueAction(action); 
    },
    
    closePop : function(component, event, helper) {
        var cmpTarget = component.find('pop');
        $A.util.addClass(cmpTarget, 'slds-hide');
        $A.util.removeClass(cmpTarget, 'slds-show');
        
    },
    OpenLivingSummaryModal:function(component, event, helper) {
        component.set('v.isOpen','true');
    },
    CloseModal:function(component, event, helper) {
        component.set('v.isOpen','false');
    },
})