({
  // call getOpportunitiesWithoutBL controller function and set opportunities
  sortOpportunities: function(component, event, sortField, sortOrder) {
    var accountId = component.get('v.accountDetails.Id');
    var action = component.get('c.getOpportunitiesWithoutBL');
    action.setParams({
      "accountId": accountId,
      "sortField": sortField,
      "sortOrder": sortOrder
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var results = response.getReturnValue();
        component.set("v.opportunities", results.rows);
        if (results.rows.length == 0) {
          component.set("v.noOpenOpportunities", true);
        }
      }
    });

    $A.enqueueAction(action);
  },

  scrollTop: function(component, event) {
    var elmnt = document.getElementById("scrollableDiv");
    elmnt.scrollLeft = 0;
    elmnt.scrollTop = 0;
  },

})