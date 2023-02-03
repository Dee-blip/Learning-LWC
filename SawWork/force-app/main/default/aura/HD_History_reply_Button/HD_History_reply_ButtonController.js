({
    openEmailComposer : function(component,event,helper)
    {
        var ActionHistoryId = component.get("v.ActionHistoryId");
        var ActionHistory = component.get("c.classObject");
        ActionHistory.setParams({
            actionId : ActionHistoryId
        });
        ActionHistory.setCallback(this,function(resp){
            
            var state = resp.getState();
            if( state === "SUCCESS")
            {
                var respo = resp.getReturnValue(); 
                console.log("-->"+JSON.stringify(respo)+' ---> '+respo.action_History.BMCServiceDesk__Client_User__r.Email );
                
                if(respo.action_History.BMCServiceDesk__EmailConversationData__c != null)
                {
                    console.log(' ----> Has Email Conversation data !');
                }
                
                var From_Email = respo.ORG_WIDE_EMAIL;
                var ToEmailsArray = [];
                ToEmailsArray.push(respo.action_History.BMCServiceDesk__Client_User__r.Email);
                
                var CcEmailsArray = [];
                
                //Firing the event    
                var HD_Email_Composer_Docked_Event = $A.get("e.c:HD_Email_Composer_Docked_Event");
                //var HD_Email_Composer_Docked_Event = component.getEvent("HD_Email_Composer_Docked_Event");
                HD_Email_Composer_Docked_Event.setParams({
                    "fromEmail" : From_Email ,
                    "toEmails"  : ToEmailsArray,
                    "ccEmails"  : CcEmailsArray,
                    "subject"   : "RE:"+respo.action_History.BMCServiceDesk__description__c,
                    "emailBody" : respo.action_History.BMCServiceDesk__RichTextNote__c
                });
                HD_Email_Composer_Docked_Event.fire();
                console.log("Email Composer Fired !");     
                //END of Event 
               
            }//
            else if(state === "RUNNING")
            {
                
            }
                else if(state === "ERROR")
                {
                    var errors = resp.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " + 
                                        errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                    
                }
            
        });
        $A.enqueueAction(ActionHistory);
        
        
        
    },
    
    orgWideEmail : function(component,event,helper)
    {
        //calling the ORG wide email address controller
        var getOrgWideEmailAkamai = component.get("c.getOrgWideEmailAkamai");
        getOrgWideEmailAkamai.setCallback(this,function(resp){
            var state = resp.getState();
            if( state === "SUCCESS")
            {
                var akamaiorgwideEmailaddress = resp.getReturnValue();
            }
        });
        $A.enqueueAction(getOrgWideEmailAkamai);
        //END of getting ORG wide email address controller
        
    }
    
    
})