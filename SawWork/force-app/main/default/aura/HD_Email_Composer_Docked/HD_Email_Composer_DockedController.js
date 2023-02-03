({
    init : function(component, event, helper){
        //default setting for making the email composer closed for now
        helper.closeEmailComposerHelper(component);
       
    },
    sendEmailReply : function(component, event, helper) {
     //validation 
         var toEmailArray = [];
        toEmailArray = component.get("v.toEmails");
        var ccEmailArray = component.get("v.ccAddresses");
        var subject = component.get("v.subject");
        var body = component.get("v.emailBody");
        
        if(toEmailArray.length <= 0)
        {
            component.set("v.errorflag",true);
            component.set("v.errormsg","The To Email has no email value");
            var tocontainer = component.find("to-container");
            $A.util.addClass(tocontainer,"slds-has-error");
            console.log('No To-email Value');
        }
        else //Validation else
         {
          //making the validation hidden
          component.set("v.errorflag",false);
          component.set("v.errormsg","No Error Found !");
          var tocontainer = component.find("to-container");
          $A.util.removeClass(tocontainer,"slds-has-error");
             
        
      var sendEmailreply = component.get("c.sendEmailmethod");
        sendEmailreply.setParams({
            "toAddresses"  : toEmailArray,
            "ccAddresses"  : ccEmailArray,
            "subject" : subject, 
            "body"  : body
        });
        sendEmailreply.setCallback(this,function(resp){
            var state = resp.getState();
            if( state === "SUCCESS")
            {
                helper.closeEmailComposerHelper(component);
                var respo = resp.getReturnValue(); 
                console.log('Email Reponse '+respo );
                //Starting the sending preocess
            }
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
                    
                }//else
                
            
            
        });
        $A.enqueueAction(sendEmailreply);
        }//END of //Validation else
      },
    
    addToEmail : function(component, event, helper){
        helper.addEmailPillsHelper(component,event,"v.toEmails","recipients-to");        
    },
    addccEmail : function(component, event, helper){
        var isDefined = !$A.util.isUndefined(component.get("v.ccAddresses"));
        console.log('--->'+isDefined)
       helper.addEmailPillsHelper(component,event,"v.ccAddresses","recipients-cc");
        

    },
    removeToEmail : function(component, event, helper)
    {
        helper.removeEmailPillsHelper(component,"v.toEmails",1);
    },
    removeCcEmail : function(component, event, helper)
    {
        helper.removeEmailPillsHelper(component,"v.ccAddresses",1);
    },
    //header button actions
    closeComposer: function(component, event, helper)
    {
        helper.closeEmailComposerHelper(component);
    },
    openComposer: function(component, event, helper)
    {    
        helper.OpenEmailComposerHelper(component);        
    },
    composerOpeningHandler : function(component, event, helper)
    {
        helper.OpenEmailComposerHelper(component);
        
        var fromEmail = event.getParam("fromEmail");
        component.set("v.fromEmail",fromEmail);
        
        var subject = event.getParam("subject");
        component.set("v.subject",subject);
        
        var emailBody = event.getParam("emailBody");
        component.set("v.emailBody",emailBody);
        
        var toEmails = event.getParam("toEmails");
       // var to = component.get("v.toEmails");
        component.set("v.toEmails",toEmails);
        
         var ccAddresses = event.getParam("ccEmails");
         //var cc = component.get("v.ccAddresses"); 
          component.set("v.ccAddresses",ccAddresses);
        
        
        console.log(">>>>> Event received for opening the Composer!");
    },
    minimizeComposer: function(component, event, helper)
    {
        helper.minimizeEmailComposerHelper(component);
    },
    maximizeComposer: function(component, event, helper)
    {
        helper.maximizeEmailComposerHelper(component);
    },
    CloseValidationError: function(component, event, helper)
    {
          component.set("v.errorflag",false);
          component.set("v.errormsg","No Error Found !");
    },    
})