({
    doInit: function(component,event,helper) {
        var businessSupport = {};
        businessSupport.label = component.get("v.businessSupportLabel");
        businessSupport.value = 'AMG';
        var technicalSupport = {};
        technicalSupport.label = component.get("v.technicalSupportLabel");
        technicalSupport.value = 'Technical';
        var optionList = [];
        optionList.push(businessSupport);
        optionList.push(technicalSupport);
        component.set("v.liveChatOptions",optionList) ;
        var totalOptions = component.get("v.liveChatOptions").length;
        for (var index = 0; index < totalOptions; index++){
            component.get("v.liveChatOptions")[index].label.bold();
            if(component.get("v.liveChatOptions")[index].value == 'AMG')
                component.get("v.liveChatOptions")[index].label = component.get("v.liveChatOptions")[index].label +" "+component.get("v.businessSupportLabelTag");
            if(component.get("v.liveChatOptions")[index].value == 'Technical')
                component.get("v.liveChatOptions")[index].label = component.get("v.liveChatOptions")[index].label +" "+component.get("v.technicalSupportLabelTag");
        }
        var typeSelected = component.get("v.liveChatType");
        
        if(typeSelected == 'AMG'){
            component.set("v.showBusinessBtn",true);
            component.set("v.showTechnicalBtn",false);
        }
        else if(typeSelected == 'Technical'){
            component.set("v.showBusinessBtn",false);
            component.set("v.showTechnicalBtn",true);
        }
    },
    handleChange: function(component,event,helper){
        var typeSelected = component.get("v.liveChatType");
        if(typeSelected == 'AMG'){
            component.set("v.showBusinessBtn",true);
            component.set("v.showTechnicalBtn",false);
        }
        else if(typeSelected == 'Technical'){
            component.set("v.showBusinessBtn",false);
            component.set("v.showTechnicalBtn",true);
        }
    }
})