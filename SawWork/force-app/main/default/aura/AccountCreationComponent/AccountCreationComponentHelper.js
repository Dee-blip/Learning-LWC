({
    // Generic component Promise to handle server calls
    AccountCreate : function(component, event, helper) {
        component.set("v.spinnerBool",true);
        
        var action=component.get("c.CreateNewAccount");
        var recordId = component.get("v.recordId");
        action.setParams({ RecId : recordId
         });

        action.setCallback(this,function(response){
            component.set("v.spinnerBool",false);
            
            if(response.getState()==="SUCCESS"){
                var recordId=response.getReturnValue();
                //alert(recordId);
                if(recordId!=null && recordId.length > 0 ){
                   
                    if(recordId.includes("Error")){
                        //alert('inside if');

                        component.set("v.showHideSection",true);
                        component.set("v.showAccountEdit",false);
                        component.set("v.ErrorMessage",recordId);
                        component.set("v.ShowtableFlag",false);
                           

                    }
                    else{
                    var url = '/'+ recordId;
                    window.location.href =url;
                    }
               
                }
            }
            else if(response.getState()==="ERROR"){
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        //alert(errors[0].message);
                        component.set("v.showHideSection",true);
                        component.set("v.showAccountEdit",false);
                        component.set("v.ErrorMessage",errors[0].message);
                    }
                } 
            }else {
                component.set("v.showHideSection",true);
                component.set("v.showAccountEdit",false);
                component.set("v.ErrorMessage","Unknown error");
            }
        });
        $A.enqueueAction(action); 
        
    }
})