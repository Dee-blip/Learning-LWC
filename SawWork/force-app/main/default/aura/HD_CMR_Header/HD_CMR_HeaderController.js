({
    getChangeRequest : function(component, event, helper) {
        
        component.set("v.isSpinnerEnabled",true);
        helper.populateChange(component, event, helper);
        helper.populateActionApprovals(component, event, helper);
        component.set("v.isSpinnerEnabled",false);
        /*
        var action = component.get("c.getChange"); 
        var RecordID = component.get("v.recordId");
        if(!RecordID)
        {
            RecordID = 'a5E0S0000008caTUAQ'; //fail safe ID code for testing
        }
        console.log('->> Record ID: '+RecordID);
        action.setParams({ Id : RecordID });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var statustxt = '';
                var ch = response.getReturnValue();
                console.log(ch);
                    component.set("v.change", ch);
                    
            }//if (state === "SUCCESS")
            
            helper.showActions(component);
            component.set("v.st_hlp",statustxt);
        });
        
        $A.enqueueAction(action); */
        
        
    },    
    
    moreActionsToggle: function(component, event, helper)
    {
        var moreAction = component.find('moreactionparent');
        //console.log('-->> More actions Please '+moreAction);
        $A.util.toggleClass(moreAction,'slds-is-open');
    },
    
    refreshPage: function(component, event, helper){
     console.log(" INSIDE Header REFRESH")
      component.set("v.isSpinnerEnabled",true);
      $A.get('e.force:refreshView').fire();
      helper.populateChange(component, event, helper);
      helper.populateActionApprovals(component, event, helper); 
      component.set("v.isSpinnerEnabled",false);  
    },
    
   showApprovalHist : function(component, event, helper) {
       console.log(' HISTT')
       helper.shAppr(component,event);
    } 
})