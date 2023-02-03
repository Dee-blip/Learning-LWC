({
    //For tooltip display toggle
    /*toggleToolTip : function(component, event, helper) {
        var currentToolTipId = event.target.id;
        let lAvailability = component.get("v.lAvailability");
        for(let i=0; i<lAvailability.length; i++){
            if(lAvailability[i].Id == currentToolTipId){
                let toggleText = component.find("tooltipText");
                $A.util.toggleClass(toggleText[i], "toggle");
                $A.util.addClass(toggleText[i], lAvailability[i].Day_Of_Week__c);
                break;
            }
        }
    }*/
})