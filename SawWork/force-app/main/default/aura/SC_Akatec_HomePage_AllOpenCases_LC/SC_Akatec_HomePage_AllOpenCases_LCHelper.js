({
    showToastMessage : function(component, event, helper,p_title,p_message,p_type,p_mode) 
    {
        
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : p_title,
            message: p_message,
            messageTemplate: 'Record {0} created! See it {1}!',
            duration:' 5000',
            key: 'info_alt',
            type: p_type,
            mode: p_mode
        });
        toastEvent.fire();
    },
    
    getAllCases : function(component,event,helper,selectedOptionValue)
    {
        //console.log('Get cases called!');
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        var caseLst;
        var action = component.get("c.getCases");
        //console.log("Action " +action );
        if (action != null)
        {

            action.setParams({
                "IsUpsert":'false',
                "userID": userId,
                "SelectedGeoFromUser":'',
                "QueryType":selectedOptionValue
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") 
                {
                    //console.log("Executed Tech Cases");
                    caseLst=response.getReturnValue();
                    component.set('v.TechnicalCount', caseLst.length);
                    component.set('v.AllCaseList', caseLst);
                     //Changing the save button back to the original button
                
                    var btn=document.getElementById("savebtn").innerHTML="Save and Apply";
                    document.getElementById("savebtn").className = "slds-button slds-button_brand";
                    component.set('v.spinner', false);
    
                }
            });
            $A.enqueueAction(action); 
        }
    },
     
    //Changes by Sharath for ESESP-3407: Adding the helper methods: Create and Destroy pollers
    destroyPollerHelper:function(component, event, helper) {
        //console.log("destroy");
        var pollId=component.get("v.PollID");
        window.clearInterval(pollId);
        //console.log("Destroyed! v.PollID: ");        
    },
        
    createPollerHelper:function(component, event, helper) {
        
        var pollId = window.setInterval(
            $A.getCallback(function() { 
                var Queue=component.find("queue").get("v.value");
                helper.getAllCases(component,event,helper,Queue);
                console.log('Poller Running!!!');
            }), 100000
        );
        //console.log("Created! v.PollID: "+ pollId);
        component.set('v.PollID', pollId);
        
    }
        
})