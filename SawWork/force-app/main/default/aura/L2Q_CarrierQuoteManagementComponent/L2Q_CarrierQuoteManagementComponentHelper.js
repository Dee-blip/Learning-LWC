({
  //createAndRedirectToQuoteOrOpptyBrokenIntoMultipleTransactions
    createAccount: function(component)
    {
        console.log('before call spinner');
    	this.startSpinner(component);

        var themeRetrievalAction = component.get("c.getUIThemeDescription");
            
        themeRetrievalAction.setCallback(this, function(a)
        {
            var userThemeDisplayed = a.getReturnValue();
            component.set('v.userTheme', userThemeDisplayed);

            var opptyId= component.get("v.recordId");
            console.log('opptyid:'+opptyId);

            component.set('v.statusMessage', 'Checking if account exists in Carrier CRM. If it doesn\'t, we\'ll create one for you');


            var opptyPopulationAction = component.get("c.populateOppty");
            opptyPopulationAction.setParams({opptyId: opptyId});
            opptyPopulationAction.setCallback(this, function(a)
            {
                var state = a.getState();
                        
                if(state == "SUCCESS")
                {
                    var opptyPopulationResult = a.getReturnValue();

                    if(opptyPopulationResult!= undefined)
                    {  
                        console.log('opptyPopulationResult'+JSON.stringify(opptyPopulationResult));
                        component.set("v.oppty",opptyPopulationResult);
                        var accountCreationAction = component.get("c.createAccountAndUpdateNomAccount");
                                
                        accountCreationAction.setParams({ "opptyObj" : opptyPopulationResult});
                        accountCreationAction.setCallback(this,function(a)
                        {
                            var state = a.getState();
                                    
                            if(state == "SUCCESS")
                            {
                                var accountCreationResult = a.getReturnValue();
                                console.log('will you proceed '+accountCreationResult.link);
                                
                                if(accountCreationResult.booleanResponse){
                                    component.set('v.statusMessage', accountCreationResult.responseMessage);
                                    component.set('v.nomAccId',accountCreationResult.resultId);
                                    this.createOpptyAndQuoteAndRedirect(component);
                                }
                                else
                                {
                                    // account creation result doesnt start with success
                                    component.set('v.statusMessage', 'ERROR: '+accountCreationResult.responseMessage);
                                    this.showFailed(component);
                                }
                            }
                            else if(state == "ERROR")
                            {
                                // error in account creation action
                                var errors = a.getError();

                                if (errors)
                                {
                                    var returnMessage = '';
                                        
                                    for(let err in errors)
                                    {
                                        returnMessage += err.message;
                                    }
                                }
                                    
                                component.set('v.statusMessage', 'ERROR: '+returnMessage);
                                this.showFailed(component);
                            }
                        });
                        
                        $A.enqueueAction(accountCreationAction);
                    }
                    else
                    {
                        component.set('v.statusMessage', 'No Opportunity with this ID found.');
                        this.showFailed(component);
                    }
                }
                else if(state == "ERROR")
                {
                    // error for opptyPopulation
                    var errors = a.getError();

                    if(errors)
                    {
                        var returnMessage = '';
                            
                        for(err in errors)
                        {
                            returnMessage += err.message;
                        }
                    }
                        
                    component.set('v.statusMessage', 'ERROR: '+returnMessage);
                    this.showFailed(component);
                }
            });
                
            $A.enqueueAction(opptyPopulationAction);
                
        });

        $A.enqueueAction(themeRetrievalAction);
        
    },
    //seggregated the method to introduce pop up: SFDC-2870
    createOpptyAndQuoteAndRedirect: function(component){
        var opptyPopulationResult= component.get('v.oppty');
     var opportunityCreation = component.get('c.createOpportunityAndUpdateNomOpportunity');
    opportunityCreation.setParams({"o": opptyPopulationResult, "nomAccountId": component.get('v.nomAccId'), "carrierProducts": opptyPopulationResult.OpportunityLineItems});
    opportunityCreation.setCallback(this, function(a)
        {
        var state = a.getState();

         if(state == "SUCCESS")
        {
            var opportunityCreationResult= a.getReturnValue();
            if(opportunityCreationResult.booleanResponse)
            {
                component.set('v.statusMessage', opportunityCreationResult.responseMessage);
                var quoteCreationAndRedirection = component.get('c.createQuoteAndRedirect');
                quoteCreationAndRedirection.setParams({"o":opptyPopulationResult, "nomOpptyId": opportunityCreationResult.resultId});
                                                quoteCreationAndRedirection.setCallback(this, function(a)
                     {
                        var state = a.getState();
                        if(state == "SUCCESS")
                            {
                                var quoteCreationResult = a.getReturnValue();
                                if(quoteCreationResult.booleanResponse)
                                    {
                                       this.showSuccess(component);
                                        console.log('redirect url is'+quoteCreationResult);
                                        this.redirectTo(component, quoteCreationResult.link, component.get('v.userTheme'), true);
                                    }
                                else
                                    {
                                        //quote creation result is not a link
                                        component.set('v.statusMessage', 'ERROR: '+quoteCreationResult.responseMessage);
                                        this.showFailed(component);
                                    }
                            }
                            else if(state == "ERROR")
                               {
                                  // quote creation action error
                                    var errors = a.getError();

                                    if (errors)
                                    {
                                        var returnMessage = '';
                                        for(err in errors)
                                            {
                                                returnMessage += err.message;
                                            }
                                    }
                                                        
                                    component.set('v.statusMessage', 'ERROR: '+returnMessage);
                                                        this.showFailed(component);
                                }
                        });
                                                    
                        $A.enqueueAction(quoteCreationAndRedirection);
                    }
                else
                {
                    // opportunity creation result doesnt start with success
                    component.set('v.statusMessage', 'ERROR: '+opportunityCreationResult.responseMessage);
                    this.showFailed(component);
                }
            }
            else if(state == "ERROR")
                {
                   // opportunity creation action error
                    var errors = a.getError();

                    if (errors)
                    {
                        var returnMessage = '';
                        for(err in errors)
                        {
                            returnMessage += err.message;
                        }
                    }
                                                
                    component.set('v.statusMessage', 'ERROR: '+returnMessage);
                                            this.showFailed(component);
                }

            });
                                        
    $A.enqueueAction(opportunityCreation);
                                       
    },
    redirectTo: function(component, redirectURL, myUserTheme, isAbsoluteURL)
    {
        
        console.log('User Theme is'+myUserTheme);
        

        if(myUserTheme != undefined)
        {
            if(myUserTheme == 'Theme4t')
            {
                console.log('VF in S1');
                if(isAbsoluteURL)
                {
                    sforce.one.navigateToURL(redirectURL);    
                }
                else
                {
                    sforce.one.navigateToSObject(redirectURL);   
                }
                

            }
            else if(myUserTheme == 'Theme4d')
            {
                console.log('in lightning experience, redirecting with urlEvent'+isAbsoluteURL);
                if(isAbsoluteURL)
                {
                    var urlEvent = $A.get("e.force:navigateToURL");
                    if(urlEvent != undefined)
                    {
                        urlEvent.setParams({
                            "url": redirectURL,
                            "target": "_blank"
                        });

                        urlEvent.fire();
                    }
                    else
                    {
                        console.log('urlEvent was undefined');
                        window.location.assign(redirectURL);
                    }
                }
                else
                {
                    var sObjectEvent = $A.get("e.force:navigateToSObject");
                    if(sObjectEvent != undefined)
                    {
                        sObjectEvent.setParams({
                            "recordId": redirectURL,
                            "target": "_blank"
                        });

                        sObjectEvent.fire();
                    }
                    else
                    {
                        window.location.assign('/'+redirectURL);
                    }
                }

            }
            else
            {
                console.log('window.location assign to:'+redirectURL);
                if(isAbsoluteURL)
                {
                    window.location.assign(redirectURL);
                }
                else
                {
                    window.location.assign('/'+redirectURL);
                }
            }
        }
        else
        {
            console.log('userTheme undefined');
            if(isAbsoluteURL)
            {
                window.location.assign(redirectURL);
            }
            else
            {
                window.location.assign('/'+redirectURL);
            }
        }
    },
    startSpinner: function(cmp)
    {
    	var spinner = cmp.find("loadingSpinner");
    	$A.util.removeClass(spinner, "slds-hide");
    },
    stopSpinner: function(cmp)
    {
    	var spinner = cmp.find("loadingSpinner");
    	$A.util.addClass(spinner, "slds-hide");
    },
    showSuccess: function(cmp)
    {
    	var spinner = cmp.find("loadingSpinner");
    	$A.util.addClass(spinner, "slds-hide");
    	cmp.set('v.hasSucceeded', true);
    },
    showFailed: function(cmp)
    {
    	var spinner = cmp.find("loadingSpinner");
    	$A.util.addClass(spinner, "slds-hide");
    	cmp.set('v.hasFailed', true);
    },
    //function to create modal pop up: SFDC-2870
    createModal: function(component){
        var userResponseMessage = component.get('c.getUserResponseMessage');
   		userResponseMessage.setCallback(this, function(a)
        {
        var state = a.getState();

         if(state == "SUCCESS")
        	{
            var userResponseMsg= a.getReturnValue();
        	console.log('in createModal '+userResponseMsg);
       	 	var spinner = component.find("loadingSpinner");
    		$A.util.addClass(spinner, "slds-hide");
          	$A.createComponent("c:GenericModalComponent", {
              "windowTitle": "Do you want to proceed?",
              "content": userResponseMsg,   
              //"showHeader" : false,
              "saveButtonText": "Yes",
              "cancelButtonText": "No"
             }, function(newCmp) {
                console.log(component.isValid());
              if (component.isValid()) {
                component.set("v.body", newCmp);
                     console.log(component.get("v.body"));
              }
        	});
        }
         else if(state == "ERROR")
          {
            // error in user response action
            	var errors = a.getError();

                 if (errors)
                   {
                     var returnMessage = '';
                                        
                      for(err in errors)
                         {
                           	returnMessage += err.message;
                          }
                    }
                                    
                 component.set('v.statusMessage', 'ERROR: '+returnMessage);
               	this.showFailed(component);
           }
       });
                
            $A.enqueueAction(userResponseMessage);
    }
})