({
  doInit : function(component, event, helper)
    {

    helper.initHelper(component,event,helper);

  },
  clickOnCheckBox: function(component, event, helper)
  {

    var selectedUserId =  event.target.name;

    var selectedId = component.get("v.selectedContactUserId");
    component.set("v.uncheckBoxes",false);
    if(selectedId == selectedUserId)
    {
        component.set("v.selectedContactUserId",null);
        component.find("updateButton").set("v.disabled", true);
    }
    else
    {
      component.set("v.selectedContactUserId",selectedUserId);
      event.target.checked = true;
      component.find("updateButton").set("v.disabled", false);
    }

  },

  addToSalesTeam: function(component, event, helper)
  {
    var selectedId = component.get("v.selectedContactUserId");
      var oppId = component.get("v.recordId");
    var action = component.get("c.addUserToSalesTeam");
    action.setParams({"oppId": oppId,"userId":selectedId});
        action.setCallback(this, function(a) {

            var message = a.getReturnValue();
            if(message.includes("Success"))
            {
        // component.set("v.sucessMessage",message);
        // component.set("v.otherError","");
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
          "title": "Success!",
          "message": message,
          "type": "success",
          //"mode": "sticky"
        });
        toastEvent.fire();

        var uList = component.get('v.contactUserList');
        var uListNew = new Array();
        for(var i=0;i<uList.length;i++)
        {
          if(uList[i].Id != selectedId)
          {
            uListNew.push(uList[i]);
          }
        }
        component.set('v.contactUserList',uListNew);
            }
            else
            {
              // component.set("v.otherError",message);
        // component.set("v.sucessMessage","");
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
          "title": "Error",
          "message": message,
          "type": "error",
          //"mode": "sticky"
        });
        toastEvent.fire();

        component.set("v.uncheckBoxes",false);
            }
            component.set("v.selectedContactUserId",null);
            component.find("updateButton").set("v.disabled", true);
            helper.initHelper(component,event,helper);


        });
        $A.enqueueAction(action);
  }
})