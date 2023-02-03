({
	afterScriptsLoaded : function(component, event, helper) {
		helper.doInit(component,event,helper);
    },
    
    gotoURL : function(component, event, helper) {
        var evt = $A.get("e.force:navigateToComponent");
        console.log('evt'+evt);
        evt.setParams({
            componentDef: "c:License_UserByProfile",
            //componentAttributes :{ }
        });
       
        evt.fire();
    },

	gotoURL1 : function(component, event, helper) {
        var cval = confirm("This will take a few minutes to load\nWould you like to continue?");
        if(cval == true){
            var evt = $A.get("e.force:navigateToComponent");
            console.log('evt'+evt);
            evt.setParams({
                componentDef: "c:License_FrequentUse",
                //componentAttributes :{ }
            });
            
            evt.fire();
        }
        else
            return
    },
    
    // this function automatic call by aura:waiting event  
    showSpinner: function(component, event, helper) {
        // make Spinner attribute true for display loading spinner 
        component.set("v.Spinner", true); 
    },
    
    // this function automatic call by aura:doneWaiting event 
    hideSpinner : function(component,event,helper){
        // make Spinner attribute to false for hide loading spinner    
        component.set("v.Spinner", false);
    },
    
    handleChange: function (component, event, helper) {
        //var cval = confirm("This will take a few minutes to load");
        //alert("This will take a few minutes to load");
        var selectedOptionValue = event.getParam("value");
        
        //if(cval == true){
        if(selectedOptionValue == "3 Months")
        {   
            component.set("v.nomonths",90);   
            component.set("v.oldval","3 Months");
        }
        else if(selectedOptionValue == "6 Months")
        {   
            component.set("v.nomonths",180);
            component.set("v.oldval","6 Months");
        }
        else
        {
            component.set("v.nomonths",366);
            component.set("v.oldval","1 Year");
        }
        
        helper.doInit(component,event,helper);
        /*}
        else 
        {
            var val = component.get("v.oldval");
            console.log(val);
            component.find("cb").set("v.value" ,val);
            //component.set("v.progress",val);
            return
        }*/
    }
    
})