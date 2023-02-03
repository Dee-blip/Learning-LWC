({
    getAccessToken: function () {
        var result = null;
        var field = 'access_token';
        if (window.location.href.indexOf(field) > -1) {
            result = window.location.href.substr(window.location.href.indexOf('access_token=') + 'access_token='.length, window.location.href.length);
        }
        return result
    },
    getQueryString: function (field, url) {
        var href = url ? url : window.location.href;
        var reg = new RegExp('[?&#]' + field + '=([^&#]*)', 'i');
        var string = reg.exec(href);
        return string ? string[1] : null;
    },
    getUserProfile: function (component, clientId) {
        component.set('v.showError', false);
        //(window === window.parent) && (this.getAccessToken('access_token') === '' || this.getAccessToken('access_token') === undefined || this.getAccessToken('access_token') === null)
        if ((window === window.parent) && (this.getAccessToken('access_token') === '' || this.getAccessToken('access_token') === undefined || this.getAccessToken('access_token') === null)) {
            var accessToken = null;
            /* var appScope = {
                 scopes: ['5ae82146-f8e5-408b-9d54-a92d0ef6332f']};*/
            var appScope = {
                scopes: ['user.read', 'mail.send']
            }
            var msalConfig = {
                auth: {
                    clientId: clientId
                },
                cache: {
                    cacheLocation: "sessionStorage",
                    storeAuthStateInCookie: true
                }
            };

            var msalInstance = new Msal.UserAgentApplication(msalConfig);
            msalInstance.handleRedirectCallback(function(error, response){
                component.set("v.loading", true);
                // handle redirect response or error
                localStorage.setItem('token', JSON.stringify(response));
                if (response.accessToken) {
                    accessToken = response.accessToken;
                    localStorage.azureresponse = response;
                    localStorage.setItem('token', JSON.stringify(response));
                    this.callMSGraph(response.accessToken);
                } else {
                    localStorage.azureresponse = null;
                }
            });
            component.set("v.loading", true);
            if (msalInstance.getAccount()) {
                var tokenRequest = {
                    scopes: ["user.read"]
                };
                msalInstance.acquireTokenSilent(appScope)
                    .then(function(response){
                        //acquireTokenPopupAndCallMSGraph();
                        this.callMSGraph(response.accessToken);
                        // get access token from response
                        // response.accessToken
                    })
                    .catch(function(err) {
                        // could also check if err instance of InteractionRequiredAuthError if you can import the class.
                        //console.log('login error', err);
                        if (err) {
                            msalInstance.acquireTokenRedirect(appScope);
                        }
                    });
            } else {
                // user is not logged in, you will need to log them in to acquire a token

                var loginRequest = {
                    scopes: ["user.read", "mail.send"] // optional Array<string>
                };
                msalInstance.loginRedirect(appScope);
            }
        } else {
            var access_token = this.getQueryString('access_token', null);
            if (access_token && access_token !== '') {
                this.callMSGraph(access_token, component);
                //component.resolveSubscription();
            }
        }
    },
    callMSGraph: function (accessToken, component) {
        console.log('calling graph API ------>');
        console.time('test for graph api');
        component.set("v.loading", true);
        component.set('v.showPanel', false);
        component.set('v.showError', false);
        var xmlHttp = new XMLHttpRequest();
        var __self = this;
        var theUrl = 'https://graph.microsoft.com/v1.0/me?$select=companyName,givenName,mail,jobTitle,businessPhones,mobilePhone,displayName,surname,streetAddress,city,state,country,postalCode';
        xmlHttp.onreadystatechange = function () {
            if (this.readyState == 4 && this.status == 200) {
                var graphResponse = JSON.parse(this.responseText);
                console.timeEnd('test for graph api');
                console.log('graph api finsihed, calling subscription details  ------>');
                console.time('test for resolve api function');
                component.set('v.showPanel', false);
                component.set('v.showError', false);
                __self.getSubscription(component, localStorage.getItem('subscriptionId'), graphResponse)
            } else {
                component.set("v.loading", false);
                component.set('v.showPanel', false);
                component.set('v.showError', true);
                component.set("v.erroMessage", "Error fetching your details.");
                console.log('graph API failed');
                console.timeEnd('timer: app initialised');
            }
            //component.set("v.loading", false);
        }
        xmlHttp.open("GET", theUrl, true); // true for asynchronous
        xmlHttp.setRequestHeader('Authorization', 'Bearer ' + accessToken);
        xmlHttp.send();
        component.set("v.loading", true);
        component.set('v.showPanel', false);
        component.set('v.showError', false);
    },
    getSubscription: function (component, token, graphDetails) {
        console.timeEnd('test for resolve api function');
        console.time('test for subscription details');
        component.set('v.showPanel', false);
                component.set('v.showError', false);
        component.set("v.loading", true);
        component.set('v.token',token);
        component.set('v.graphDetails', graphDetails);
        var a = component.get('c.getSubscriptionDetails');
        $A.getCallback(function() {
            $A.enqueueAction(a);
        })();
        window.dispatchEvent(new Event('resize'));
    },
    escapeBlackListChars: function (toOutput) {
        var ic = "\"";
        var ac = "\'";
        if (!toOutput) {
            return "";
        }
        return toOutput.replace(new RegExp("&", "g"), '&amp;')
            .replace(new RegExp("<", "g"), '&lt;')
            .replace(new RegExp(">", "g"), '&gt;')
            .replace(new RegExp(ic, "g"), '&quot;')
            .replace(new RegExp(ac, "g"), '&#x27')
            .replace(new RegExp("/", "g"), '&#x2F');
    },
    unescapeBlackListChars: function (toOutput) {
        var ic = "\"";
        var ac = "\'";
        if (!toOutput) {
            return toOutput;
        }
        return toOutput.replace(new RegExp('&amp;', "g"), "&")
            .replace(new RegExp("&lt;", "g"), '<')
            .replace(new RegExp("&gt;", "g"), '>')
            .replace(new RegExp('&quot;', "g"), ic)
            .replace(new RegExp('&#x27', "g"), ac)
            .replace(new RegExp('&#x2F', "g"), "/");
    },
    hasNull: function (target) {
        var __self = this;
        if (typeof target === 'string' && (target === null || target.trim() === '' || target === undefined)) {
            return true;
        }
        if (typeof target === 'undefined' && (target === undefined)) {
            return true;
        }
        if (target && typeof target === 'object' && target.constructor === Array) {
            if (target.length === 0) {
                return true;
            } else {
                target.forEach(function(element){
                    __self.hasNull(element);
                });
            }
        }
        if (typeof target === 'object') {
            if (target == null) {
                return true;
            }
            for (var member in target) {
                var value = target[member];
                if (typeof target[member] === 'string' && (target[member] === null || target[member].trim() === '' || target[member] === undefined)) {
                    return true;
                }
                if (value && typeof value === 'object' && value.constructor === Array) {
                    if (value.length === 0) {
                        return true;
                    } else {
                        value.forEach(function(element){
                            __self.hasNull(element);
                        });
                    }
                }
                if (target[member] === null) {
                    return true;
                }
            }
        }
        return false;
    },
  setSubmitButtonState: function (component, event, helper) {
    var ignorableFields = ['surname'];
    var data = component.get('v.subscription');
    var requiredFields = component.get('v.requireFields');
    var errorCount = 0;
    requiredFields.forEach(function(element){
      if (!ignorableFields.includes(element) &&  helper.hasNull(data.beneficiary[element])) {
        errorCount = errorCount + 1;
      }
    });
    if(errorCount > 0) {
      component.set("v.showFormError", true);
    } else {
      component.set("v.showFormError", false);
    }

  }
})