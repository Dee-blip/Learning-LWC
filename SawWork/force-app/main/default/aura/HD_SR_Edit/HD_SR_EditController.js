({
	myAction : function(component, event, helper) {
		
	},
    
    
    doInit : function(component, event, helper){

      
      
       var action1 = component.get("c.getSRDetails"); 
       var self = this;

       var spinner = component.find("mySpinner_body");
       
        
       action1.setParams({ Id : component.get("v.recordId") });
       var firstval = '';
       action1.setCallback(this, function(data) {

           var  rval = data.getReturnValue();
           console.log(rval);
           helper.addInputDetails(component,helper,rval);

           var ffs = {};
           helper.condnl_eval(component,rval.FF_Inputs);
           for(var i=0 ;i < rval.FF_Inputs.length; i++){

               ffs[rval.FF_Inputs[i].Id] = rval.FF_Inputs[i];
               
           }
                
           component.set('v.ffi_details',ffs);
           var ds =  component.get('v.ffi_details');
           $A.util.toggleClass(spinner, "slds-hide");
                  
        });

        $A.enqueueAction(action1); 
        
    },
    
    saveSR: function(component, event, helper) {
      
         var spinner = component.find("mySpinner_body");
         $A.util.toggleClass(spinner, "slds-hide");
        event.preventDefault();
        var instr =  helper.save_sr(component,event);
        
        if( instr == "ERROR"){
           // alert("Error");
              $A.util.toggleClass(spinner, "slds-hide");
            return "";
        }
      
      var action1 = component.get("c.SaveSRDetails"); 
        
      action1.setParams({ incident_id : component.get("v.recordId"), values : component.get("v.input_values") });
      action1.setCallback(this, function(data) {
             var  rval = data.getReturnValue();
             let state = data.getState();
             console.log(" State "+state);
             $A.util.toggleClass(spinner, "slds-hide");
               if (state === "SUCCESS") {
                     var formact = $A.get("e.c:Update_SR_Edit");
                     
                     formact.setParams({"form_rendering":"reload"}).fire();
               } else if (state === "ERROR") {
                   var errors = data.getError();
                   console.log(errors.message);
                   helper.handle_error(component,data.getError())

               } 
        });

       $A.enqueueAction(action1); 
        
	},
    
    cancel_edit_sr : function(component, event, helper){
        var formact = $A.get("e.c:Update_SR_Edit");
        formact.setParams({"form_rendering":"cancel"}).fire();
    }
    
})