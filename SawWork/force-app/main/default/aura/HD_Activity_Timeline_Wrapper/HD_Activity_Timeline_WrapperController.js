({
    handleForceRefreshViewForLWC: function (component) {
        component.find("activityTimeline").refreshTimeline();
    },
    replyMailController: function (component, event) {

        var ActionHistoryId = event.getParam('historyId'); //component.get("v.ActionHistoryId");
        var ActionHistory = component.get("c.classObject");
        ActionHistory.setParams({
            actionId: ActionHistoryId
        });
        ActionHistory.setCallback(this, function (resp) {

            var state = resp.getState();
            var respo;
            var From_Email;
            var ToEmailsArray = [];
            var CcEmailsArray = [];
            var errors;
            var HD_Email_Composer_Docked_Event;
            if (state === "SUCCESS") {
                respo = resp.getReturnValue();

                if (respo.action_History.BMCServiceDesk__EmailConversationData__c != null) {
                    console.log(' ----> Has Email Conversation data !');
                }

                From_Email = respo.ORG_WIDE_EMAIL;

                ToEmailsArray.push(respo.action_History.BMCServiceDesk__Client_User__r.Email);

                //Firing the event    
                HD_Email_Composer_Docked_Event = $A.get("e.c:HD_Email_Composer_Docked_Event");
                //var HD_Email_Composer_Docked_Event = component.getEvent("HD_Email_Composer_Docked_Event");
                HD_Email_Composer_Docked_Event.setParams({
                    "fromEmail": From_Email,
                    "toEmails": ToEmailsArray,
                    "ccEmails": CcEmailsArray,
                    "subject": "RE:" + respo.action_History.BMCServiceDesk__description__c,
                    "emailBody": respo.action_History.BMCServiceDesk__RichTextNote__c
                });
                HD_Email_Composer_Docked_Event.fire();
                //END of Event 

            }//
            else if (state === "RUNNING") {
                console.log('In running state');
            }
            else if (state === "ERROR") {
                errors = resp.getError();
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

    }
})