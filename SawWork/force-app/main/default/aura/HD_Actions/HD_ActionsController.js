({
	ActionMenuRenderer : function(component, event, helper) {
		helper.ActionMenuHelper(component,event);
        helper.calculateInactiveTime(component,event);
        
	},
    
    clearIdleTime: function(component, event, helper) {
		component.set("v.idleTime",0);
	},
    resetStartTime: function(component, event, helper) {
		component.set("v.startTime",new Date());        
	},
    
    activateAccordian : function(component, event, helper)
    {
        var buttonKey = event.currentTarget.dataset.key.split(';')[0];
        var keyName = event.currentTarget.dataset.key.split(';')[1];
        //console.log('Pressed --> '+buttonKey);
        //var activatedAccordian = component.find(buttonKey);
        var activatedAccordian = document.getElementById(buttonKey);
        //console.log('new accordian --> '+activatedAccordian);
        //
        helper.collapseAllAccordianHelper(component,buttonKey);
        //lets toggle the accordian section
        if($A.util.hasClass(activatedAccordian,"slds-is-collapsed")){
            //$A.util.swapClass(activatedAccordian, "slds-is-collapsed","slds-is-expanded"); // This swapClass is deprecated.
            $A.util.removeClass(activatedAccordian,"slds-is-collapsed");
            $A.util.addClass(activatedAccordian,"slds-is-expanded");
            component.set("v.startTime",new Date());
            component.set("v.actionName",keyName);
            
        } else {
           // $A.util.swapClass(activatedAccordian, "slds-is-expanded","slds-is-collapsed"); // This swapClass is deprecated.
            $A.util.removeClass(activatedAccordian,"slds-is-expanded");
            $A.util.addClass(activatedAccordian,"slds-is-collapsed");  
        }//else
        
        
        
    },
     recordUpdated: function(component, event, helper) {

    var changeType = event.getParams().changeType;

    if (changeType === "ERROR") { /* handle error; do this first! */ }
    else if (changeType === "LOADED") { /* handle record load */ }
    else if (changeType === "REMOVED") { /* handle record removal */ }
    else if (changeType === "CHANGED") { /* handle record change */ }
}
    
})