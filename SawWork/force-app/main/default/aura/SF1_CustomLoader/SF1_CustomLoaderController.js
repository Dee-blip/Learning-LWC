({
	
	showSpinner: function(component, event, helper) 
	{

        if(document.getElementById("customSpinnerId") != null)
        {
            document.getElementById("customSpinnerId").style.display = "block";
        }
    },
    hideSpinner : function(component,event,helper)
    {

        if(document.getElementById("customSpinnerId") != null)
        {
            document.getElementById("customSpinnerId").style.display = "none";
        }
    }
}
)