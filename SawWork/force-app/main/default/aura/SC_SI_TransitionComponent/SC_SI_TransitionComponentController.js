({
    doInit: function(component, event, helper) {
        console.log('Side section//'+component.get("v.fromSideSection"));
        console.log('disabled//'+component.get("v.disableTransition"));
        console.log('Pre Owner//'+component.get("v.previousOwner"));
        
        if(!component.get("v.fromSideSection")){
            
            
            var pageRef = component.get("v.pageReference");	        
            console.log(JSON.stringify(pageRef));	        
            var state = pageRef.state; 
            // state holds any query params	        
            console.log('state = '+JSON.stringify(state));	        
            var base64Context = state.inContextOfRef;	        
            console.log('base64Context = '+base64Context);	        
            if (base64Context.startsWith("1\.")) {	            
                base64Context = base64Context.substring(2);	            
                console.log('base64Context = '+base64Context);	        
            }	        
            var addressableContext = JSON.parse(window.atob(base64Context));	        
            console.log('addressableContext = '+JSON.stringify(addressableContext));	        
            component.set("v.recordId", addressableContext.attributes.recordId);
            
              var getUserType = component.get("c.getButtonAccess");
        
        	getUserType.setParams({
            "SIrecordId": component.get("v.recordId")
        	});
        
        	getUserType.setCallback(this, function(result)
                                { 
                                 if(result.getState() == 'SUCCESS'){
                                     var res = JSON.parse(result.getReturnValue());
                                     
                                     if(res.isTransitionAuthorized){
                                         component.set("v.disableTransition",false);
                                     }//else{
                                      //   component.set("v.disableTransition",true);
                                     //} 
                                     
                                     component.set("v.previousOwner",res.previousOwnerId);
                                     component.set("v.showSpinner",false);    
                                     
                                 }    
                                });
        	$A.enqueueAction(getUserType);
           
        } else{
            
            component.set("v.disableTransition",false);
        }
        helper.handleInit(component, event, helper);
    },
    
    handleShiftChange : function(component, event, helper) {
        helper.handleShiftChange(component, event, helper);
    },
    
    handleCancel : function(component, event, helper) {
        helper.handleCancel(component, event, helper);
    },
    
    handleSubmit: function(component, event, helper) {
        helper.handleSubmit(component, event, helper);
    }    
})