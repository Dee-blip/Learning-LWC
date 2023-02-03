({  
	
    // method on mouseover
    mouseOver : function(component, event, helper) {
       // helper.handleMouseOver(component, event, helper);
        },
        doInit: function(component, event, helper) {
            // helper.handleMouseOver(component, event, helper);
             },

    //method on mouseout  
    mouseOut : function(component, event, helper) {
       // helper.handleMouseOut(component, event, helper);
        },

    recordUpdated : function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
        debugger;
      if( !$A.util.isUndefinedOrNull(component.get("v.sObjectRecord").Status__c)){
          var values = [];
          values=component.get("v.picklistValueList");
          component.set("v.location",values.indexOf(component.get("v.sObjectRecord").Status__c) + 1);
          component.set("v.chevronState",component.get("v.sObjectRecord").Status__c);
      }
    }      
    
})