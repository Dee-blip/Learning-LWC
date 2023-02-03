({
  doInit: function(component, event, helper) {
    helper.getInitialValidation(component, event, helper);
  },
  moveBack: function(component) {
    window.history.back();
  },

  handleClick: function(component, event) {
    var selectedAttachmentIds = component.get("v.selectedAttachmentIds");
    var targetId = event.target.name;
    var isSelected = event.target.checked;

    if (isSelected) {
      if (selectedAttachmentIds.indexOf(targetId) == -1) {
        selectedAttachmentIds.push(targetId);
      }
    } else {
      if (selectedAttachmentIds.indexOf(targetId) > -1) {
        selectedAttachmentIds.splice(selectedAttachmentIds.indexOf(targetId), 1);
      }
    }
    component.set("v.selectedAttachmentIds", selectedAttachmentIds);
    //console.log(component.get("v.oaAttachmentList"));
  },

  moveToEmailComponent: function(component, event, helper) {
    var evt = $A.get("e.force:navigateToComponent");
    evt.setParams({
      componentDef: "c:SF1_EmailComponent",
      componentAttributes: {
        orderApprovalId: component.get("v.orderApprovalId"),
        showHeader: true,
        htmlDataObj: component.get("v.htmlDataObj"),
        selectedAttachmentIds: component.get("v.selectedAttachmentIds"),
        associatedOppty: component.get("v.associatedOppty")
      }
    });
    evt.fire();
  }
})