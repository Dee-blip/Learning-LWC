({
    doInit : function(component, helper) {
        //expression to check valid dateTime format
        var re =/\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d.\d\d\dZ$/;
		
        var Incident = component.get('v.incident');
        var FieldName = component.get('v.fieldName');
        var outputText = component.find("outputTextId");
        
        var val = String(Incident[FieldName]);
        var text = val.replace(/\n/g, " ");
        var isDateTime = re.test(val.trim());
        
        
        component.set("v.isDateTime",isDateTime);
        
        if(isDateTime == true){
            component.set("v.dateTry",Incident[FieldName]);
        }else{
            if(text=="undefined"){
            	outputText.set("v.value",Incident[FieldName]);
        	}
        	else{
            	outputText.set("v.value",text);
        	}
        }
        outputText.set("v.title",Incident[FieldName]);
        
        	
       // }
       
    }
})