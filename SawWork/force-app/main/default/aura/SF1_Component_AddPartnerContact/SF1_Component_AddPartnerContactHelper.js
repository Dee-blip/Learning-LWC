({

    initHelper : function(component, event, helper)
    {
                var oppId = component.get("v.recordId");
        helper.navigateToPageIfLightning(component,oppId);

        var action = component.get("c.checkForPartnerAndOwner");
            action.setParams({"oppId": oppId});
        action.setCallback(this, function(a) {

            var jsonReturn = JSON.parse(a.getReturnValue());
                        component.set("v.opptyName", jsonReturn.opptyName);
            if(jsonReturn.message == '-' )
            {
                var action1 = component.get("c.getUserContact");

                action1.setParams({"oppId":oppId,"oppOwnerId": jsonReturn.ownerId,"partnerInvolvedId":jsonReturn.partnerInvolvedId,"partnerInvolvedParentId":jsonReturn.partnerInvolvedParentId});
                action1.setCallback(this, function(b) {

                var userLIst = b.getReturnValue();

                component.set('v.contactUserList',userLIst);
                 });
                $A.enqueueAction(action1);

            }
            else
            {
                //set error message
                component.set('v.partnerError',jsonReturn.message);

            }



        });
        $A.enqueueAction(action);
    },

    navigateToPageIfLightning : function(component,oppId)
    {


        var action = component.get("c.isLightning");
        action.setCallback(this, function(a) {

            if(a.getReturnValue() == true)
            {

                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                    //"url": "/one/one.app#/alohaRedirect/apex/PRMAddPartnerToSalesTeam?id="+oppId
                    "url": "/apex/PRMAddPartnerToSalesTeam?id="+oppId // SFDC-2408 changes by Nagaraj Desai
                });
                urlEvent.fire();
            }
            else
            {
                component.set('v.isLightning', false);
            }
        });
        $A.enqueueAction(action);

    }
})