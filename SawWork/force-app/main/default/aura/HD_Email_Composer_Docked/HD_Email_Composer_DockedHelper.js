({
    addEmailPillsHelper : function(component,event,EmailArrayattributeName,ElementID) {
        console.log('array attribute--->'+EmailArrayattributeName);
       var emailsArray = [];
       emailsArray =  component.get(EmailArrayattributeName);
        
        if(event.getParams().keyCode === 13 ){
            //add an email if enter is pressed
            var newEmail = component.find(ElementID).get("v.value");//document.getElementById(ElementID).value;//"recipients-to"
            //console.log(newEmail);
            //console.log(newEmail.value);
            if(newEmail.length > 0)
            {
                
          
            emailsArray.push(newEmail);
            component.set(EmailArrayattributeName,emailsArray);
            var newEmail_empty =  component.find(ElementID);  
            newEmail_empty.set("v.value","");
            console.log(EmailArrayattributeName+'--> Email Status: '+ component.get(EmailArrayattributeName));
            }
        }
        
    },
    removeEmailPillsHelper : function(component,EmailArrayattributeName,index){
        var emails = component.get(EmailArrayattributeName);
        var indexLocation = emails.indexOf(index);
        if (index > -1) {
            emails.splice(indexLocation, 1);
        }
        //set the
        component.set(EmailArrayattributeName,emails); 
    },
    closeEmailComposerHelper : function(component)
    {
        var getEmailComposerElement = component.find("hdemailComposer");
        $A.util.addClass(getEmailComposerElement,'slds-hide');
        console.log('Called Close Composer !');
    },
    OpenEmailComposerHelper : function(component)
    {
        var getEmailComposerElement = component.find("hdemailComposer");
        if($A.util.hasClass(getEmailComposerElement,'slds-hide'))
        {
        $A.util.removeClass(getEmailComposerElement,'slds-hide');
        }   
    },
    
    minimizeEmailComposerHelper : function(component)
    {
        var getEmailComposerElement = component.find("hdemailComposersection");
        var expandbutton = component.find("expandbutton");
        $A.util.toggleClass(getEmailComposerElement,'slds-is-closed');
        if($A.util.hasClass(getEmailComposerElement,'slds-is-closed'))
        {
            console.log('Has Class');
            $A.util.addClass(expandbutton,'slds-hide');
        }
        else
        {
            $A.util.removeClass(expandbutton,'slds-hide');
        }
    },
    maximizeEmailComposerHelper: function(component){
        var getEmailComposerElement = component.find("hdemailComposersection");
        var minimizebutton = component.find("minimizebutton");        
        $A.util.toggleClass(getEmailComposerElement,'maximize-composer');
        if($A.util.hasClass(getEmailComposerElement,'maximize-composer'))
        {
            console.log('Has Class');
            $A.util.addClass(minimizebutton,'slds-hide');
        }
        else
        {
            $A.util.removeClass(minimizebutton,'slds-hide');
        }
    },
})