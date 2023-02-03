({
	setToastVar: function(component, sMsg){
        debugger;
        console.log('component :::::::::::::::' + component);
        component.set("v.msgTheme",'slds-theme_error');                 
        //alert(document.getElementById("msgPanelComp").style.display);
        component.set("v.isDispMsg","block");
        document.getElementById("msgPanel").innerHTML = sMsg;

    },
    setToastVarSuccess: function(component, sMsg){
        debugger;
        console.log('component :::::::::::::::' + component);
        component.set("v.msgTheme",'slds-theme_success');                 
        //alert(document.getElementById("msgPanelComp").style.display);
        component.set("v.isDispMsg","block");
        document.getElementById("msgPanel").innerHTML = sMsg;
    },
})