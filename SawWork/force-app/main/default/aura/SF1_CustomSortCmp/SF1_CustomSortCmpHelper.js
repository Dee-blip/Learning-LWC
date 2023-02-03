({
    hideVisibleAfterClickingOnSort : function(component, event, helper){
        document.getElementById("visibleAfterClickingOnSort").style.display="none";
        document.getElementById("footer").style.display="block"; 
        var panelheader = document.getElementsByClassName("panel-header")[0];
        if(panelheader)
            panelheader.style.display="flex"; 
    }
})