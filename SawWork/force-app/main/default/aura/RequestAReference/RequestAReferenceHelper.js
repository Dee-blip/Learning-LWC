({
    getOpportunity : function (component) {
       var action = component.get("c.FetchOpportunity");
       action.setParams({ recordId : component.get("v.recordId")});
       action.setCallback(this, function(response) {
           var state = response.getState();
           if (state === "SUCCESS") {
               var res = JSON.parse(response.getReturnValue());
               if (res.isOpptyValid) {
                   var url = 'https://sfdcintegration.influitive.com/corporate/request_reference?embedded=true&salesforce_org_id=';
                   url += res.orgId;
                   url += '&salesforce_opp_id=' + res.opptyId;
                   url += '&owner_id=' + res.userId;
                   url += '&opp_name=' + res.opptyName;
                   url += '&session_id=' +  res.APISessionId;
                   url += '&api_partner_server_url=' + res.APIPartnerServerURL90;
                   window.open(url);
                   
                   var dismissActionPanel = $A.get("e.force:closeQuickAction"); 
                   dismissActionPanel.fire();
               } else {
                   component.set('v.showErrorMessage',true);
               }
           }
           else if (state === "ERROR")
           {
               return 'Failed';
           }
       });
       $A.enqueueAction(action);
   }
})