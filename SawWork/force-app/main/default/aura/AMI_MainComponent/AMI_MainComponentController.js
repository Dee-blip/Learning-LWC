({
  onInit: function (component, event, helper) {
    component.set("v.loading", true);
    console.time('timer: app initialised');
    var loadComponent = false;
    var subscriptionId = helper.getQueryString('token', null);
    if (subscriptionId && subscriptionId != '') {
      localStorage.setItem('subscriptionId', subscriptionId);
      loadComponent = true;
    } else if (localStorage.getItem('subscriptionId') && localStorage.getItem('subscriptionId') !== '') {
      loadComponent = true;
    } else {
      loadComponent = false;
    }
    if (loadComponent) {
      if (window === window.parent) {
        component.set("v.typingTimer", null);
        var action = component.get('c.getClientIdForAppOperations');
        action.setCallback(this, function (response) {
          response = JSON.parse(response.getReturnValue());
          var state = response.status;
          if (state === "SUCCESS") {
            helper.getUserProfile(component, response.responseObj);
          } else {
            var message = JSON.parse(response.responseObj);
            console.log("Failed with state: " + state, message);
            component.set("v.loading", false);
            component.set("v.erroMessage", "Some error occured.");
            //alert("Some error occured!");
          }
        });
        $A.enqueueAction(action);
      }
    } else {
      console.log('error');
      component.set('v.loading', false);
      component.set('v.showPanel', false);
      component.set('v.showError', true);
      console.timeEnd('timer: app initialised');
    }
  },
  doInit: function (component, event, helper) {
    console.log('comp loaded');
  },
  onKeyUpEvent: function (component, event, helper) {
    var timer = 1000;
    var typingTimer;
    clearTimeout(component.get("v.typingTimer"));
    typingTimer = setTimeout(helper.setSubmitButtonState(component, event, helper), timer);
    component.set("v.typingTimer", typingTimer);
  },
  saveSubscriptionObject: function (component, event, helper) {
    var requestPayload = component.get('v.subscription');
    var requiredFields = component.get('v.requireFields');
    var count = 0;
    var errorFields = [];
    var displayNameMap = {
      givenName: 'name',
      companyName: 'company name',
      mobilePhone: 'mobile phone',
      emailId: 'email Id',
      jobTitle: 'job title'
    };
    for (var key in requestPayload.beneficiary) {
      if (requestPayload.beneficiary.hasOwnProperty(key) && requiredFields.indexOf(key) > -1) {
        if (typeof requestPayload.beneficiary[key] === 'object' && requestPayload.beneficiary[key] && requestPayload.beneficiary[key].constructor && requestPayload.beneficiary[key].constructor === Array) {
          for (var i = 0; i < requestPayload.beneficiary[key].length; i++) {
            requestPayload.beneficiary[key][i] = helper.escapeBlackListChars(requestPayload.beneficiary[key][i]);
          }
        } else {
          requestPayload.beneficiary[key] = helper.escapeBlackListChars(requestPayload.beneficiary[key]);
        }
      }
    }
    /*if(requestPayload.beneficiary.givenName.trim().split(' ').length > 1) {
      var nameArr = requestPayload.beneficiary.givenName.trim().split(' ');
      var firstName = nameArr[0];
      var lastName = nameArr.shift();
      requestPayload.beneficiary.givenName = firstName;
      requestPayload.beneficiary.surname = lastName.join(' ');
    }*/
    //logic for givenName and surname
    if (errorFields.length == 0) {
      component.set("v.showFormError", false);
      component.set("v.errorString", null);
      component.set("v.submissionFailed", false);
      var action = component.get("c.saveSubscription");
      action.setParams({
        request: JSON.stringify(requestPayload)
      });
      component.set("v.loadingSaveSubscription", true);
      component.set("v.showPanel", true);
      action.setCallback(this, function (response) {
        //var state = response.getState();
        response = JSON.parse(response.getReturnValue());
        var state = response.status;
        if (state === "SUCCESS") {
          component.set("v.loadingSaveSubscription", false);
          component.set("v.showError", false);
          component.set("v.showPanel", false);
          component.set("v.productSaved", true);
          component.set("v.submissionFailed", false);
        } else {
          var message = JSON.parse(response.responseObj);
          console.log("Failed with state: " + state, message);
          component.set("v.loadingSaveSubscription", false);
          component.set("v.errorMessage", "You may be either already subscribed or request is being processed. No action needed from your end.");
          component.set("v.showError", true);
          component.set("v.showPanel", false);
          component.set("v.productSaved", false);
          component.set("v.submissionFailed", true);
          //alert("Some error occured!");
        }
      });
      $A.enqueueAction(action);
    } else {
      component.set("v.showFormError", true);
      component.set("v.errorString", errorFields.join(','));
      alert('please provide the following details' + errorFields.join(','));
    }
  },

  getSubscriptionDetails: function (component, event, helper) {
    //component.set("v.loading", false);
    component.set('v.loading', true);
    component.set('v.showPanel', false);
    component.set('v.showError', false);
    console.log('called component contrlle');
    var action = component.get("c.resolveSubscription");
    var token = component.get("v.token");
    var __self = helper;
    var graphDetails = component.get("v.graphDetails");
    /*graphDetails = {
      displayName: "Deepali Rathore",
      surname: "",
      givenName: "Deepali",
      id: "444a179bb020f246",
      userPrincipalName: "deepali.rathore3011@gmail.com",
      businessPhones: [
        "23323"
      ],
      jobTitle: "",
      mail: null,
      mobilePhone: null,
      officeLocation: null,
      preferredLanguage: null
    }*/
    action.setParams({
      apiToken: decodeURIComponent(token)
    });
    console.log('calling apex method- resolve subscription--->', action);
    action.setCallback(this, function (response) {
      console.timeEnd('test for subscription details');
      console.time('test for after subscription details are fetched');
      console.log('subscription resolved');
      var response = JSON.parse(response.getReturnValue());
      //var state = response.getState();
      var state = response.status;
      window.addEventListener("beforeunload", function (e) {
        var confirmationMessage = "\o/";
        localStorage.removeItem('subscriptionId');
        (e || window.event).returnValue = confirmationMessage; //Gecko + IE
        return confirmationMessage;                            //Webkit, Safari, Chrome
      });
      if (state === "SUCCESS") {
        component.set("v.loading", false);
        var subscription = {};
        subscription = JSON.parse(response.responseObj);
        subscription.beneficiary.companyName = __self.unescapeBlackListChars(graphDetails.companyName);
        subscription.beneficiary.givenName = __self.unescapeBlackListChars(graphDetails.givenName);
        subscription.beneficiary.surname = __self.unescapeBlackListChars(graphDetails.surname);
        subscription.beneficiary.jobTitle = __self.unescapeBlackListChars(graphDetails.jobTitle);
        subscription.beneficiary.displayName = __self.unescapeBlackListChars(graphDetails.displayName);
        subscription.beneficiary.mobilePhone = __self.unescapeBlackListChars(graphDetails.mobilePhone);
        subscription.beneficiary.businessPhones = graphDetails.businessPhones.length == 0 ? [] : graphDetails.businessPhones;
        subscription.beneficiary.emailId = graphDetails.mail && __self.unescapeBlackListChars(graphDetails.mail) || subscription.beneficiary.emailId;
        subscription.beneficiary.streetAddress = __self.unescapeBlackListChars(graphDetails.streetAddress);
        subscription.beneficiary.city = __self.unescapeBlackListChars(graphDetails.city);
        subscription.beneficiary.state = __self.unescapeBlackListChars(graphDetails.state);
        subscription.beneficiary.country = __self.unescapeBlackListChars(graphDetails.country);
        subscription.beneficiary.postalCode = __self.unescapeBlackListChars(graphDetails.postalCode);
        var requireFields = ['givenName', 'surname', 'companyName', 'emailId', 'jobTitle', 'businessPhones', 'streetAddress', 'city', 'state', 'country', 'postalCode'];
        var errorFields = {};
        requireFields.forEach(function (element) {
          if (__self.hasNull(subscription.beneficiary[element])) {
            errorFields[element] = undefined;
            component.set('v.showFormError', true);
          } else {
            errorFields[element] = true;
          }
        });
        component.set('v.errorFields', errorFields);
        component.set('v.requireFields', requireFields);
        component.set('v.subscription', subscription);
        component.set('v.showPanel', true);
        component.set('v.showError', false);
        console.timeEnd('test for after subscription details are fetched');
        //component.set("v.productSaved", true);
      } else {
        console.log("Failed with state: ", state, response);
        component.set("v.loading", false);
        component.set('v.showPanel', false);
        component.set('v.showError', true);
        component.set("v.erroMessage", "Error fetching your details.");
        //alert("Some error occured!");
      }
      console.timeEnd('timer: app initialised');
    });
    console.log('action getting queued');
    $A.enqueueAction(action);
    window.dispatchEvent(new Event('resize'));
  }
})