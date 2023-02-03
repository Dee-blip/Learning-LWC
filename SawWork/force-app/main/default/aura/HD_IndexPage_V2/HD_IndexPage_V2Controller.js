({
    hideForm : function(component, event, helper) {
      
    },
    toastMessage : function(component, event, helper){
        var message = event.getParam("message");
        component.set("v.error_message",message);        
        setTimeout(function(){ component.set("v.error_message","");   }, 3000);
        
        //alert(message);
        
    }
    
})