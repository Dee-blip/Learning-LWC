({
    doInit : function(component, event, helper) {
        var indx = component.get("v.indexVar");
        var ascId = "ascId_"+indx;
        var descId = "descId_"+indx;
        var presentationID = "presentation_"+indx;
        var stateIndicatorID = "stateIndicator_"+indx;
        var indicatorBoxID = "indicatorBox__"+indx;
        component.set("v.AscID",ascId);
        component.set("v.DescID",descId);
        component.set("v.presentationID",presentationID);
        component.set("v.stateIndicatorID",stateIndicatorID);
        component.set("v.indicatorBoxID",indicatorBoxID);
        
    }
    ,
    presentationLI : function(component, event, helper) {
        
        var indx = component.get("v.indexVar");
        var ascId ,descId,stateIndicatorID,indicatorBoxID;
        
        stateIndicatorID = component.get("v.stateIndicatorID");
        var stateIndicator= document.getElementById(stateIndicatorID);
        
        //make desc-asc indicator of all other divs clean first
        var noOfFields = $('div[id^=ascId_]').length;
        
        for(var i=0;i<noOfFields;i++)
        {
            indicatorBoxID = "indicatorBox__"+i;
            if(i!==indx)
            {
                ascId = "ascId_"+i;
                descId = "descId_"+i;
                
                document.getElementById(ascId).style.display = "none";
                document.getElementById(descId).style.display = "none";
                document.getElementById(indicatorBoxID).style.backgroundColor  = "rgb(244, 246, 249)";
                
            }
            
        }
        
        ascId = component.get("v.AscID");
        descId = component.get("v.DescID");
        indicatorBoxID = component.get("v.indicatorBoxID");
        
        document.getElementById(indicatorBoxID).style.backgroundColor  = "white";
        
        if(document.getElementById(ascId).style.display == "block")
        {
            document.getElementById(ascId).style.display = "none";
            document.getElementById(descId).style.display = "block";
            component.set("v.ascOrDesc","Desc");
        }
        else
        {
            document.getElementById(ascId).style.display = "block";
            document.getElementById(descId).style.display = "none";
            component.set("v.ascOrDesc","Asc");
        }
        
        stateIndicator.style.display="block";
        
        var ascOrDesc = component.get("v.fieldName") +"##"+component.get("v.ascOrDesc");
        var setEvent = $A.get("e.c:SF1_showSortDetailsEvent");
        setEvent.setParams({
            "sortingOrder":ascOrDesc
        });
        setEvent.fire();
        
    }
})