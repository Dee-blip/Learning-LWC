({
    TrimmedEmail : function(component,event,helper)
    {
        //Emails trim for cc added  
        var Email = component.get('v.email');
        if( Email.indexOf("@") !== -1)
        {
            var name = Email.split("@")[0].trim();
            if (name && name.search(/\s/) === -1) {
                component.set('v.trimmedemail',name);
            } else {
               component.set('v.trimmedemail',Email);
            }
            
        }
        else {
             component.set('v.trimmedemail',Email);
        }               
    },
})