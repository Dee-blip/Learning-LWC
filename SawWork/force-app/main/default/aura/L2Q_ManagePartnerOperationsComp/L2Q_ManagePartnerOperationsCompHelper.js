({
  resetReturnValues: function (component, event) {
    component.set("v.hasReturnErrors", false);
    component.set("v.returnErrorMessage", "An unexpeced error orrcurred! Please contact your System Administrator");
    component.set("v.isTransactionSuccessful", false);
    component.set("v.returnSuccessMessage", "The transaction was successful!");
  },
  resetUserPasswordJS: function (component, event, helper) {
    var resetUserPasswordVar = component.get("c.resetUserPassword");
    resetUserPasswordVar.setParams({
      "userRecordJSON": JSON.stringify(component.get("v.partnerUserRecord")),
      "contactRecordJSON": JSON.stringify(component.get("v.partnerContactRecord"))
    });
    resetUserPasswordVar.setCallback(this, function (response) {
      var state = response.getState();
      if (component.isValid() && state === "SUCCESS") {
        var returnVal = response.getReturnValue();
        if (returnVal['errorMessage'] != undefined && returnVal['errorMessage'] != [] && returnVal['errorMessage'] != "") {
          component.set("v.hasReturnErrors", true);
          component.set("v.returnErrorMessage", returnVal['errorMessage']);
        } else {
          component.set("v.isTransactionSuccessful", true);
          component.set("v.returnSuccessMessage", returnVal['successMessage']);
        }
      }
    });
    $A.enqueueAction(resetUserPasswordVar);
  },

  createUser: function (component, sendEmail_Required) {
    var createUserVar = component.get("c.addUser");
    createUserVar.setParams({
      "userRecordJSON": JSON.stringify(component.get("v.partnerUserRecord")),
      "partnerContactJSON": JSON.stringify(component.get("v.partnerContactRecord")),
      "userNotPresentInDB": component.get("v.userNotPresentInDB"),
      "sendEmail_Required": sendEmail_Required,
      "partnerUserRoleName": component.get("v.partnerUserRoleName"),
      "partnerUserProfileName": component.get("v.partnerUserProfileName")
    });
    createUserVar.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        var returnVal = response.getReturnValue();
        if (returnVal.hasOwnProperty('partnerUserRoleName')) {}

        if (returnVal['errorMessage'] != undefined && returnVal['errorMessage'] != [] && returnVal['errorMessage'] != "") {
          component.set("v.returnErrorMessage", returnVal['errorMessage']);
          component.set("v.hasReturnErrors", true);
        } else {
          // as user is added to db
          component.set("v.userNotPresentInDB", false);
          // refresh user Data
          // change component view
          component.set("v.partnerUserRecord", JSON.parse(returnVal['userRecord']));

          component.set("v.partnerUserProfileName", returnVal['partnerUserProfileName']);
          component.set("v.partnerUserRoleName", returnVal['partnerUserRoleName']);
          component.set("v.showUserDetail_View", true);
          component.set("v.showUserDetail_Edit", false);

          component.set("v.returnSuccessMessage", returnVal['successMessage']);
          component.set("v.isTransactionSuccessful", true);
        }
        if (returnVal['userNotPresentInDB'] == 'true') {
          component.set("v.userNotPresentInDB", true);
        } else {
          component.set("v.userNotPresentInDB", false);
        }
      } else {
        var errors = response.getError();
        helper.showErrors(component, event, response);
      }
    });
    $A.enqueueAction(createUserVar);
  },

  disablContactAccessJS: function (component, event, helper) {
    var disablContactAccessVar = component.get("c.disablContactAccess");
    disablContactAccessVar.setParams({
      "partnerContactJSON": JSON.stringify(component.get("v.partnerContactRecord")),
    });
    disablContactAccessVar.setCallback(this, function (response) {
      var state = response.getState();
      if (component.isValid() && state === "SUCCESS") {
        var returnVal = response.getReturnValue();
        if (returnVal['errorMessage'] != undefined && returnVal['errorMessage'] != [] && returnVal['errorMessage'] != "") {
          component.set("v.hasReturnErrors", true);
          component.set("v.returnErrorMessage", returnVal['errorMessage']);
        } else if (returnVal['successMessage'] != undefined && returnVal['successMessage'] != [] && returnVal['successMessage'] != "") {
          //component.set("v.isTransactionSuccessful", true);
          if (!component.get("v.userNotPresentInDB")) {
            helper.disableUserAccessJS(component, event, helper);
          } else {
            component.set("v.partnerContactRecord", JSON.parse(returnVal['partnerContactRecord']));
            component.set("v.returnSuccessMessage", returnVal['successMessage']);
            component.set("v.isTransactionSuccessful", true);
            component.set("v.showUserDetail_Edit", true);
            component.set("v.showUserDetail_View", false);
          }
        }
      } else {
        helper.showErrors(component, event, response);
      }
    });
    $A.enqueueAction(disablContactAccessVar);
  },

  disableUserAccessJS: function (component, event, helper) {
    var disableUserAccessVar = component.get("c.disablUserAccess");
    disableUserAccessVar.setParams({
      "userRecordJSON": JSON.stringify(component.get("v.partnerUserRecord")),
    });
    disableUserAccessVar.setCallback(this, function (response) {
      var state = response.getState();
      if (component.isValid() && state === "SUCCESS") {
        var returnVal = response.getReturnValue();
        if (returnVal['errorMessage'] != undefined && returnVal['errorMessage'] != [] && returnVal['errorMessage'] != "") {
          component.set("v.hasReturnErrors", true);
          component.set("v.returnErrorMessage", returnVal['errorMessage']);
        } else if (returnVal['successMessage'] != undefined && returnVal['successMessage'] != [] && returnVal['successMessage'] != "") {
          if (returnVal['userRecord'] != undefined && returnVal['userRecord'] != null && returnVal['userRecord'] != []) {
            component.set("v.partnerUserRecord", JSON.parse(returnVal['userRecord']));
            component.set("v.userNotPresentInDB", false);
          }
          component.set("v.returnSuccessMessage", returnVal['successMessage']);
          component.set("v.isTransactionSuccessful", true);
          component.set("v.showUserDetail_Edit", true);
          component.set("v.showUserDetail_View", false);
        }
      } else {
        helper.showErrors(component, event, response);
      }
    });
    $A.enqueueAction(disableUserAccessVar);
  },

  setDoNotSyncFlagJS: function (component, event, helper) {
    var setDoNotSyncFlagVar = component.get("c.setDoNotSyncFlag");
    setDoNotSyncFlagVar.setParams({
      "contactRecordJSON": JSON.stringify(component.get("v.partnerContactRecord")),
    });
    setDoNotSyncFlagVar.setCallback(this, function (response) {
      var state = response.getState();
      if (component.isValid() && state === "SUCCESS") {
        var returnVal = response.getReturnValue();
        helper.enableAccessToUserHelper(component, event, helper);
      } else {
        helper.showErrors(component, event, response);
      }
    });
    $A.enqueueAction(setDoNotSyncFlagVar);
  },

  enableAccessToUserHelper: function (component, event, helper) {
    var idToName = component.get('v.idToName');
    var pUser = component.get("v.partnerUserRecord");
    var enableUserAccessVar = component.get("c.enableAccessToUser");
    enableUserAccessVar.setParams({
      "updatedUserJSON": JSON.stringify(component.get("v.partnerUserRecord")),
      "partnerContactJSON": JSON.stringify(component.get("v.partnerContactRecord")),
      "userNotPresentInDB": component.get("v.userNotPresentInDB"),
      "partnerUserRoleName": idToName[pUser.UserRoleId],
      "partnerUserProfileName": idToName[pUser.ProfileId]
    });
    component.set("v.partnerUserRoleName", idToName[pUser.UserRoleId]);
    component.set("v.partnerUserProfileName", idToName[pUser.ProfileId]);

    enableUserAccessVar.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        var returnVal = response.getReturnValue();
        console.log(returnVal);
        if (returnVal['errorMessage'] != undefined && returnVal['errorMessage'] != [] && returnVal['errorMessage'] != "") {
          component.set("v.hasReturnErrors", true);
          if (returnVal['errorMessage'] != "Argument cannot be null.") {
            component.set("v.returnErrorMessage", returnVal['errorMessage']);
          }
        } else {
          //component.set("v.isTransactionSuccessful", true);
          if (returnVal['AKAM_Contact_ID__c'] != null && returnVal['AKAM_Contact_ID__c'] != undefined && returnVal['AKAM_Contact_ID__c'] != '') {
            component.set("v.partnerContactRecord.AKAM_Contact_ID__c", returnVal['AKAM_Contact_ID__c']);
          }
          
          /*
           * SFDC-7423 setting the partner contact for temp password
           */
          if (returnVal['partnerContact'] != null) {
            component.set("v.partnerContactRecord", JSON.parse(returnVal['partnerContact']));
          }

          if (returnVal['isAU_Mode'] == 'false') {
            if (component.get("v.isSFCommunityUser")) {
              console.log('calling disableSFCommunityUserJS function');
              helper.disableSFCommunityUserJS(component);
            }
            console.log('returnVal[sendEmail_Required]');
            if (returnVal['sendEmail_Required'] == 'true') {
              console.log(returnVal['sendEmail_Required']);
              helper.createUser(component, true);
            } else {
              console.log(returnVal['sendEmail_Required']);
              helper.createUser(component, false);
            }
            component.set("v.partnerUserProfileName", returnVal['partnerUserProfileName']);
            component.set("v.partnerUserRoleName", returnVal['partnerUserRoleName']);
          } else {
            component.set("v.showUserDetail_View", true);
            component.set("v.showUserDetail_Edit", false);
            component.set("v.returnSuccessMessage", 'Akamai University Access has been provided successfully');
            component.set("v.isTransactionSuccessful", true);
            component.set("v.partnerUserRoleName", '');
            component.set("v.partnerUserProfileName", '');
          }
        }
        helper.deSetDoNotSyncFlagJS(component);
      } else {
        var errors = response.getError();
        helper.showErrors(component, event, response);
      }
    });
    $A.enqueueAction(enableUserAccessVar);
  },

  disableSFCommunityUserJS: function (component) {
    var disableSFCommunityUserVar = component.get("c.deactivateSFCommunityUser");
    console.log('partnerContactRecord.Id : ' + component.get("v.partnerContactRecord.Id"));
    disableSFCommunityUserVar.setParams({
      "contactId": (component.get("v.partnerContactRecord.Id")),
    });
    disableSFCommunityUserVar.setCallback(this, function (response) {
      var state = response.getState();
      if (component.isValid() && state === "SUCCESS") {
        var returnVal = response.getReturnValue();
        console.log('returnVal from disableSFCommunityUserJS : ' + returnVal);
      } else {
        helper.showErrors(component, event, response);
      }
    });
    $A.enqueueAction(disableSFCommunityUserVar);
  },

  deSetDoNotSyncFlagJS: function (component) {
    var deSetDoNotSyncFlagVar = component.get("c.deSetDoNotSyncFlag");
    deSetDoNotSyncFlagVar.setParams({
      "contactRecordJSON": JSON.stringify(component.get("v.partnerContactRecord")),
    });
    deSetDoNotSyncFlagVar.setCallback(this, function (response) {
      var state = response.getState();
      if (component.isValid() && state === "SUCCESS") {
        var returnVal = response.getReturnValue();
      } else {
        helper.showErrors(component, event, response);
      }
    });
    $A.enqueueAction(deSetDoNotSyncFlagVar);
  },

  scrollTop: function (component, event) {
    var elmnt = document.getElementById("scrollableDiv");
    elmnt.scrollLeft = 0;
    elmnt.scrollTop = 0;
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
  showErrors: function (component, event, response) {
    var errors = response.getError();
    var returnMessage = '';
    if (errors) {
      errors.forEach(function (ithError) {
        returnMessage += ithError.message;
      });

    }
    component.set('v.returnErrorMessage', 'ERROR: ' + returnMessage);
    component.set("v.hasReturnErrors", true);
  }
})