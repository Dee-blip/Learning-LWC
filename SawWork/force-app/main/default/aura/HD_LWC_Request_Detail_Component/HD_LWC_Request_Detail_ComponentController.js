({
    edit_sr : function(component){
        component.set("v.sredit_mode",true);
        component.set("v.srdt_mode",false);
        
    },
    
    cancel_sr_form : function(component){
        component.set("v.sredit_mode",false);
        component.set("v.srdt_mode",true);
        
    },
    
    
    updateEditForm : function(component, event){
        var frmRendering = event.getParam("form_rendering");
        if(frmRendering === "reload"){
            component.find("srDetailLWC").fireRefresh();
        }
        component.set("v.srdt_mode",true);
        component.set("v.sredit_mode",false);
        
        
    }
    
})