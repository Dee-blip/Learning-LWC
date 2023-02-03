({
	doInit : function(component, event, helper) {
        console.log("In init");
	},
    
    print : function(component, event, helper) {
        if (event !== null && typeof event.getParam === 'function' && event.getParam("quickAction") && event.getParam("quickAction") !== 'Print') {
            return;
        }
        
        var url = '/c/HD_PrintTicketApp.app#'+component.get("v.recordId");
         sessionStorage.setItem("sent", window.self); 
        window.open(url,'','top=100,left=100,height=750,width=1100');
        
    }
})