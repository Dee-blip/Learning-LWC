({
  init: function (component, event, helper) {
    var getUserRecordId = component.get("c.getCurrentContactAndUserDetails");
    getUserRecordId.setParams({
      "contactId": component.get("v.contactId")
    });
    getUserRecordId.setCallback(this, function (response) {
      var state = response.getState();
      if (component.isValid() && state === "SUCCESS") {
        var returnVal = response.getReturnValue();
        if (returnVal['errorMessage'] != undefined && returnVal['errorMessage'] != '') {
          component.set("v.returnErrorMessage", returnVal['errorMessage']);
          component.set("v.hasReturnErrors", true);
          component.set("v.showBackButton", true);
        } else {
          component.set("v.isAccountConcierge", returnVal['isAccountConcierge']);
          var partnerContactRecord = JSON.parse(returnVal['partnerContact']);
          partnerContactRecord.Has_Akamai_University_Access__c = true;
          component.set("v.partnerContactRecord", partnerContactRecord);
          var userRecord = JSON.parse(returnVal['partnerUser']);
          console.log(userRecord);
          if (userRecord.IsActive == undefined || userRecord.IsActive == null) {
            userRecord.IsActive = false;
          }
          component.set("v.partnerUserRecord", userRecord);
          if (returnVal['userNotPresentInDB'] == 'true') {
            component.set("v.userNotPresentInDB", true);
          } else {
            component.set("v.userNotPresentInDB", false);
          }

          if (returnVal['isSFCommunityUser'] == 'true') {
            component.set("v.isSFCommunityUser", true);
          } else {
            component.set("v.isSFCommunityUser", false);
          }
          //SFDC-5666
          if (returnVal['hasTableauEditAccess'] == 'true') {
            component.set("v.hasTableauEditAccess", true);
          } else {
            component.set("v.hasTableauEditAccess", false);
          }

          console.log('isSFCommunityUser');
          console.log(component.get("v.isSFCommunityUser"));
          component.set("v.partnerUserRoleName", returnVal['partnerUserRoleName']);
          component.set("v.partnerUserProfileName", returnVal['partnerUserProfileName']);
          component.set("v.userFoundFlag", returnVal['userFoundFlag']);
          component.set("v.listOfRoleOptions", JSON.parse(returnVal['userRole_PicklistVals']));
          component.set("v.listOfProfileOptions", JSON.parse(returnVal['userProfile_PicklistVals']));
          component.set("v.idToName", JSON.parse(returnVal['idToName']));
          component.set("v.userThemeDisplayed", returnVal['userThemeDisplayed']);
          if (returnVal['isUserInNap'] == 'true') {
            component.set("v.isUserInNap", true);
          } else {
            component.set("v.isUserInNap", false);
          }
          /*  If user is not active and Active Portal logic is false, then show the Edit View (Create User view)
           *
           */
          if ((!userRecord.IsActive && returnVal['userFoundFlag'] == 'true' ) || component.get("v.isSFCommunityUser")) {
            component.set("v.showUserDetail_Edit", true);
          } /*else if ((userRecord.IsActive && returnVal['userNotPresentInDB'] == 'false') /*|| (returnVal['userNotPresentInDB'] == 'true' && partnerContactRecord.Has_Akamai_University_Access__c)) { // show user detail view component
            component.set("v.showUserDetail_View", true);
          }*/ else {
            component.set("v.showUserDetail_View", true);
          }
        }
        component.set("v.renderAfterInitialCallBack", true);
      } else {
        helper.showErrors(component, event, response);
      }
    });
    $A.enqueueAction(getUserRecordId);
  },

  enableUserAccess: function (component, event, helper) {
    helper.resetReturnValues(component, event);
    helper.scrollTop(component, event);
    helper.setDoNotSyncFlagJS(component, event, helper);
    //component.set("v.updateTransaction", false);
    //component.set("v.TransactionType", 'Enable');
  },

  updateUserAccessJS: function (component, event, helper) {
    helper.closeModal(component, event);
    helper.resetReturnValues(component, event);
    var updatUserVar = component.get("c.updateUserAccess");
    updatUserVar.setParams({
      "updatedUserJSON": JSON.stringify(component.get("v.partnerUserRecord")),
      "partnerContactJSON": JSON.stringify(component.get("v.partnerContactRecord"))
    });
    updatUserVar.setCallback(this, function (response) {
      var state = response.getState();
      if (component.isValid() && state === "SUCCESS") {
        var returnVal = response.getReturnValue();
        if (returnVal['UpdatedUser'] != null && returnVal['UpdatedUser'] != undefined && returnVal['UpdatedUser'] != {}) {
          component.set("v.partnerUserRecord", JSON.parse(returnVal['UpdatedUser']));
          component.set("v.partnerUserRoleName", returnVal['partnerUserRoleName']);
          component.set("v.partnerUserProfileName", returnVal['partnerUserProfileName']);
          component.set("v.isTransactionSuccessful", true);
          component.set("v.returnSuccessMessage", "User access has been updated successfully!");
        } else {
          component.set("v.hasReturnErrors", true);
        }
      } else {
        helper.showErrors(component, event, response);
      }
    });
    $A.enqueueAction(updatUserVar);
  },

  handleMenuActions: function (component, event, helper) {
    helper.resetReturnValues(component, event);
    helper.scrollTop(component, event);
    if (event.getParam("value") == "ResetPassword") {
      console.log("ResetPassword Menu Action");
      helper.resetUserPasswordJS(component, event, helper);
    } else if (event.getParam("value") == "DisableAccess") {
      component.set("v.updateTransaction", false);
      component.set("v.TransactionType", 'Enable');
      helper.disablContactAccessJS(component, event, helper);
    } else if (event.getParam("value") == "UpdateAccess") {
      component.set("v.updateTransaction", true);
      component.set("v.TransactionType", 'Update');
      // component.set("v.resetPasswordFlag", false);

      component.set("v.showUserDetail_Edit", true);
      component.set("v.showUserDetail_View", false);
      //helper.openModal(component, event, helper);
    }
  },

  backToContact: function (component, event, helper) {
    var contactId = component.get("v.contactId");
    if (component.get("v.userThemeDisplayed") == 'Theme3') {
      if (component.get("v.isUserInNap")) {
        window.parent.location = '/partners/' + contactId;
      } else {
        window.parent.location = '/' + contactId;
      }
    } else {
      sforce.one.navigateToSObject(contactId);
    }
  },

  openModal: function (component, event, helper) {
    var cmpTarget = component.find('Modalbox');
    var cmpBack = component.find('ModalClose');
    $A.util.addClass(cmpTarget, 'slds-fade-in-open');
    $A.util.addClass(cmpBack, 'slds-backdrop--open');
  },

  closeModal: function (component, event) {
    var cmpTarget = component.find('Modalbox');
    var cmpBack = component.find('ModalClose');
    $A.util.removeClass(cmpBack, 'slds-backdrop--open');
    $A.util.removeClass(cmpTarget, 'slds-fade-in-open');
  },
})