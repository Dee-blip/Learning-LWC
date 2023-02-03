({
    showWalkthroughtIntroHelper: function(cmp){
        var welcome = document.getElementById("welcome");
        $A.util.removeClass(welcome,'slds-hide');
        // $A.util.addClass(welcome,'animated zoomIn');
    },
    hideWalkthroughtIntroHelper: function(cmp){
        var welcome = document.getElementById("welcome");
        $A.util.addClass(welcome,'slds-hide');
    },
    IntroConfiguratorHelper: function(cmp){
        var introConfig = cmp.get('c.getIntroConfig'); 
        introConfig.setCallback(this,function(resp){
            var state = resp.getState();
            if( state === "SUCCESS")
            {  
                var introconfigResp = resp.getReturnValue();
                //DO the logic here
                console.log('Resp>> '+introconfigResp);
                for(let key in introconfigResp)
                {
                    //console.log('from Custom Settings >> '+introconfigResp[key].dataauraclass__c+' >> '+introconfigResp[key].dataintro__c);
                    console.log('>>> [data-aura-class="'+introconfigResp[key].dataauraclass__c+'"]');
                    var dataattribute = document.querySelector("[data-aura-class=\""+introconfigResp[key].dataauraclass__c+"\"]");
                    if(dataattribute!=null)
                    {
                        // console.log('>>>'+dataattribute.innerHTML);
                        dataattribute.setAttribute('data-intro',introconfigResp[key].dataintro__c);
                        dataattribute.setAttribute('data-step',introconfigResp[key].datastep__c); 
                    }//
                    else if(dataattribute===null){
                        console.log('This is Rejected Attribute>>> '+ introconfigResp[key].dataauraclass__c);
                    }
                }//for
                
            }//SUCCESS
            else if(state === "RUNNING")
            {
                consle.log('Intro Config is ready !');
            }//RUNNING
                else if(state === "ERROR")
                {
                    
                    var errors = resp.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " + 
                                        errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                }//ERROR
            
        });
        $A.enqueueAction(introConfig);
        
    },
    StartIntroHelper: function(cmp)
    {
        introJs().start();   
    },
    DisplayIntroButton: function(cmp) // this method is used to enable disable help text
    {
        var getIntroStartedFlag = cmp.get('c.getIntroStartedFlag');
        getIntroStartedFlag.setCallback(this,function(resp){
          var state = resp.getState();
            if( state === "SUCCESS")
            {
                var introStartedFlag = resp.getReturnValue();
                
                cmp.set('v.introStartedFlag',introStartedFlag);
                console.log('introStartedFlag >> '+introStartedFlag);
                
                
            } 
            else if(state === "RUNNING")
            {
                console.log('Intro Config is ready !');
            }//RUNNING
            else if(state === "ERROR")
                {
                    
                    var errors = resp.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " + 
                                        errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                }//ERROR
            
            
        }); 
        $A.enqueueAction(getIntroStartedFlag);
    },
    
    
})