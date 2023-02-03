({
    init: function(component) {

    //note, we get options and set options_
    //options_ is the private version and we use this from now on.
    //this is to allow us to sort the options array before rendering
    if (component.get("v.initialized")){
        return;
    }
    component.set("v.initialized",true);

    console.log("Intialized:  "+component.get("v.initialized"));
    var action;
    var values=[];

    if(component.get("v.multiselectComponentDataType")=="serviceRequests"){
        component.set("v.label","Select Service Requests");
        action = component.get("c.getListOfActiveServiceRequest");
    }else if(component.get("v.multiselectComponentDataType")=="status"){
        component.set("v.label","Select Status");
        component.set("v.infoText","-----All-----");
        action = component.get("c.getListOfStatus");
    }


    var values=[];

    action.setCallback(this,function(data){
        var delay=4000; 

        var response = data.getReturnValue();
        var keys = [];
        for(var i in response)
        {
            values.push({
                label:response[i].Name,
                value:response[i].Id
            });
            keys.push(response[i].Id);
        }
        component.set("v.options",values);

        var options = component.get("v.options");
        component.set("v.options_", options);
        var labels = this.getSelectedLabels(component);
        this.setInfoText(component, labels);

    });

    $A.enqueueAction(action);  
},  

    setInfoText: function(component, values) {

    if (values.length == 0) {
        component.set("v.infoText", component.get("v.label"));
    }
    if (values.length == 1) {
        component.set("v.infoText", values[0]);
    }
    else if (values.length > 1) {
        component.set("v.infoText", values.length + " options selected");
    }
},

    getSelectedValues: function(component){
    var options = component.get("v.options_");
    var values = [];
    options.forEach(function(element) {
        if (element.selected) {
            values.push(element.value);
        }
    });
    return values;
},

    getSelectedLabels: function(component){
    var options = component.get("v.options_");
    var labels = [];
    options.forEach(function(element) {
        if (element.selected) {
            labels.push(element.label);
        }
    });
    return labels;
},

    despatchSelectChangeEvent: function(component,values){
    
    var compEvent = component.getEvent("selectChange");
    var myMap;

    if(component.get("v.multiselectComponentDataType")=="serviceRequests"){
        myMap={"key":"serviceRequestSelected","values":values};
    }else if(component.get("v.multiselectComponentDataType")=="status"){
        myMap={"key":"statusSelected","values":values};
    }
    compEvent.setParams({ "selectedOptions": myMap });
    compEvent.fire();
}
})