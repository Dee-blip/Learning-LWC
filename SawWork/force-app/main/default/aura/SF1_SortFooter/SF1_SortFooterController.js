({
    sort : function(component, event, helper) {
        
        document.getElementById("footer").style.display="none";  
        var panelheader = document.getElementsByClassName("panel-header")[0];
        if(panelheader)
            panelheader.style.display="none"; 
        
        var sortdetailsEvent = $A.get("e.c:SF1_showSortDetailsEvent");
        sortdetailsEvent.fire();
    }
})