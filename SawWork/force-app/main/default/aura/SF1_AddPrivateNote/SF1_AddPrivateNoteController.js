({
	doInit : function(cmp, event, helper) {
        helper.accessAllowedToCurrentUserProfile(cmp);
        helper.getPageObject(cmp);
    },
    
    
    saveTheNote : function(cmp, event, helper) 
    {  
      
       helper.saveTheNote(cmp);
       
  	},
    showSpinner: function(component, event, helper) {
       if(document.getElementById("oppSpinner") != null)
        {
            document.getElementById("oppSpinner").style.display = "block";
        } 
    },
        
    hideSpinner : function(component,event,helper){
        if(document.getElementById("oppSpinner") != null)
        {
            document.getElementById("oppSpinner").style.display = "none";
        }
    }
})