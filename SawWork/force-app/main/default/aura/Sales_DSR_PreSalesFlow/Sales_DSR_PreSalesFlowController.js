({
    init : function(component, event, helper){
        var defaultDate = new Date();
        var day = defaultDate.getDay();
        var nextBusinessDay = 3;
        defaultDate.setDate(defaultDate.getDate() + nextBusinessDay + (day === 6 ? 2 : +!day) + (Math.floor((nextBusinessDay - 1 + (day % 6 || 1)) / 5) * 2));
        //defaultDate.setDate(defaultDate.getDate() + 3);
        defaultDate = defaultDate.toISOString().slice(0, 10);
        //alert(defaultDate);
        component.set("v.defaultDateValue",defaultDate);
    },

    handleSuccess : function(component, event, helper) {
        var newDSRPayload = event.getParams().response;
        component.set('v.newDSRId',newDSRPayload.id);
        var navigate = component.get("v.navigateFlow");

        navigate("NEXT");
       
    },

    handleError : function(component, event, helper) {
        var errors = event.getParams();
        console.log("Error Response", JSON.stringify(errors));
        component.set('v.errorOnSubmit', true);
    },

    saveRecord: function(component, event, helper) {
        /*event.preventDefault();
        var confirmBox = confirm("Are you sure you want to create a new Pre-Sales Intake request?");
        if (confirmBox == true) {
            component.find('dsrPreSalesNew').submit();
        } else {
            
        }*/
    },

    onPicklistChange : function(component, event, helper){
        var requestType = component.find("requestType").get("v.value");
        //alert(requestType);
        if(requestType === "Solution Engineer"){
            component.set("v.option", false);
        }
        else{
            component.set("v.option", true);
        }
        if(!requestType || 0 === requestType.length){
            component.set("v.optionNoneRequestType", false);
        }
        else{
            component.set("v.optionNoneRequestType", true);
        }
    },

    onDateChangeValidation : function(component, event, helper){
        var dueDate = new Date(component.find("duedate").get("v.value"));
        dueDate.setTime(dueDate.getTime() + dueDate.getTimezoneOffset()*60000);
        //alert(dueDate);
        var today = new Date();
        today.setHours(0,0,0,0);
        //alert(today);
        if(dueDate < today){
            component.set("v.validDate",true);
        }else{
            component.set("v.validDate",false);
        }
    }
})