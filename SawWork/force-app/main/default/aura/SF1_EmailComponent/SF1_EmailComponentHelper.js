({
  sendEmailFromSF1: function(component, event, helper) {
    var sendEmailVar = component.get("c.sendOAEmail");

    sendEmailVar.setParams({
      "orderApprovalId": component.get("v.orderApprovalId"),
      "listOfCheckedIds": component.get("v.selectedAttachmentIds"),
      "htmlDataObj": helper.getEmailDataObject(component, helper)
    });

    sendEmailVar.setCallback(this, function(response) {
      var state = response.getState();
      console.log(state);
      var returnVal = response.getReturnValue();

      if (component.isValid() && state === "SUCCESS") {
        console.log(returnVal);
        var returnValObj = JSON.parse(returnVal);
        helper.fireToast(returnValObj.returnMessage, returnValObj.errorOccured, component.get("v.orderApprovalId"));
      }
    });
    $A.enqueueAction(sendEmailVar);

  },

  fireToast: function(returnMessage, errorOccured, orderApprovalId) {
    var toastEvent = $A.get("e.force:showToast");
    if (errorOccured == 'true') {
      toastEvent.setParams({
        "title": "Error!",
        "message": returnMessage,
        "type": "error"
      });
    } else {
      toastEvent.setParams({
        "title": "Succesful!",
        "message": returnMessage,
        "type": "success"
      });
      //navigate to Order Approval
      var navEvt = $A.get("e.force:navigateToSObject");
      navEvt.setParams({
        "recordId": orderApprovalId,
        "slideDevName": "related"
      });
      navEvt.fire();
    }
    toastEvent.fire();
  },

  removeExcessStyling: function(htmlBodyOfEmail) {
    htmlBodyOfEmail = htmlBodyOfEmail.replace(/<p><br><\/p>/gi, "<br/>");
    htmlBodyOfEmail = htmlBodyOfEmail.replace(/<p>/gi, "");
    htmlBodyOfEmail = htmlBodyOfEmail.replace(/<\/p>/gi, "<br/>");

    return htmlBodyOfEmail;
  },

  getEmailDataObject: function(component, helper) {
    var htmlDataObj = component.get("v.htmlDataObj");
    console.log(htmlDataObj);
    var mapObject = new Map();
    //set map for content type v/s slds icon names
    var refactoredData = {
      'contactName': htmlDataObj.contactName.Name,
      'contactId': htmlDataObj.contactName.Id,
      'htmlBodyOfEmail': helper.removeExcessStyling(htmlDataObj.htmlBodyOfEmail),
      'emailSubject': htmlDataObj.emailSubject,
      'partnerCcEmail': htmlDataObj.partnerCcEmail
    };

    // mapObject.set('contactName', htmlDataObj.contactName.Name);
    // mapObject.set('contactId', htmlDataObj.contactName.Id);
    // mapObject.set('htmlBodyOfEmail', htmlDataObj.htmlBodyOfEmail);
    // mapObject.set('emailSubject', htmlDataObj.emailSubject);
    // mapObject.set('partnerCcEmail', htmlDataObj.partnerCcEmail);

    console.log('refactoredData: ');
    console.log(refactoredData);
    console.log(JSON.stringify(refactoredData));
    return refactoredData;
  },

  closeModal: function(component, event) {
    var cmpTarget = component.find('Modalbox');
    var cmpBack = component.find('ModalClose');
    $A.util.removeClass(cmpBack, 'slds-backdrop--open');
    $A.util.removeClass(cmpTarget, 'slds-fade-in-open');
  },
})