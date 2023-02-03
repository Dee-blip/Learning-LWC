({
	getOpportunity : function(cmp) {
		var action = cmp.get("c.getOpportunity");
        console.log("Oppty ID:",cmp.get("v.recordId"));
        action.setParams({
            "opptyId": cmp.get("v.recordId")
        });
        action.setCallback(this, function(response) {
			var state = response.getState();
            //var noOfExistingOpps = response.getReturnValue().length;
            if (cmp.isValid() && state === "SUCCESS") 
            {
                cmp.set("v.opp", response.getReturnValue());

            }
            
            
		});
        $A.enqueueAction(action);
		
	},
    insertAccount : function(cmp){
        var message, acname, acctry, state, opp, sObjectEvent;
		var action = cmp.get("c.AddAccnt");
        console.log("Insert Account Success",cmp.get("v.recordId"));
        cmp.set("v.ShowError",false);
        cmp.set("v.FieldError",false);
        
        acname=cmp.find("AccountName").get("v.value");
        acctry=cmp.find("PrimaryCountry").get("v.value");            
        console.log("Name:----->",acname);
        console.log("Country:------>",acctry);        
        if(!acname || !acctry){
            console.log('Inside null check for name and country');
            cmp.set("v.FieldError",true);
            return;
        }
        console.log('SubVerticalField:'+cmp.find("SubVerticalField").get("v.value"));
        action.setParams({
            "pid": cmp.get("v.recordId"),
            "AccountName": cmp.find("AccountName").get("v.value"),
            "AccountDomain":cmp.find("AccountDomain").get("v.value"),
            "PrimaryStreet":cmp.find("PrimaryStreet").get("v.value"),
            "PrimaryCity":cmp.find("PrimaryCity").get("v.value"),
            "PrimaryState":cmp.find("PrimaryState").get("v.value"),
            "zip":cmp.find("PostalCode").get("v.value"),
            "PrimaryCountry":cmp.find("PrimaryCountry").get("v.value"),
            "Vertical":cmp.find("VerticalField").get("v.value"),
            "subVertical":cmp.find("SubVerticalField").get("v.value")  
        });
        action.setCallback(this, function(response){
			state = response.getState();
            //var noOfExistingOpps = response.getReturnValue().length;
            opp  = response.getReturnValue();
            if(opp.includes("Error")){
                cmp.set("v.message",response.getReturnValue());
                cmp.set("v.ShowError",true);
                cmp.set("v.ShowtableFlag",false);

            }
            if(cmp.isValid() && state === "SUCCESS" && opp==="Success"){
                console.log("Insert Account Success");
                sObjectEvent = $A.get("e.force:navigateToSObject");
                sObjectEvent.setParams({
                    "recordId": cmp.get("v.recordId"),
                    "slideDevName": 'detail'
                })
                sObjectEvent.fire();
                $A.get('e.force:refreshView').fire();
			}
            else 
            {
                console.log('Inside else----->',response.getReturnValue());
                message = response.getReturnValue();
                console.log('TypeOf:'+typeof message);
                if(typeof message === 'string'){
                    message = message.split(";")[1];
                    if(message.includes("FIELD_CUSTOM_VALIDATION_EXCEPTION")){
                        message = message.replace("FIELD_CUSTOM_VALIDATION_EXCEPTION,","");
                    }
                    if(message.includes("FIELD_FILTER_VALIDATION_EXCEPTION")){
                        message = message.replace("FIELD_FILTER_VALIDATION_EXCEPTION,","");
                    }
                }
                cmp.set("v.message",message);
                cmp.set("v.ShowError",true);
            }
		});
        $A.enqueueAction(action);
		
	},
    
    getPicklistValuesForVerticalandSubVerticalField : function(component){
        var pickListResponse, parentkeys, parentField, pickKey, i;
        var action = component.get("c.getCustomDependablePicklist");
        action.setParams({
            strObjectName : component.get("v.getObjectName"),
            strparentField : component.get("v.getParentFieldAPI"),
            strchildField : component.get("v.getChildFieldAPI")
        });

        action.setCallback(this, function(response){
            var status = response.getState();
           if(status === "SUCCESS"){
                pickListResponse = response.getReturnValue();                
                component.set("v.getPickListMap",pickListResponse.pickListMap);
                component.set("v.getParentFieldLabel",pickListResponse.parentFieldLabel);
                component.set("v.getChildFieldLabel",pickListResponse.childFieldLabel);
               //var pickListMap = component.get("v.getPickListMap");
              
                parentkeys = [];
                parentField = [];                

                for(pickKey in pickListResponse.pickListMap){
                    if(pickKey != null){
                        parentkeys.push(pickKey);
                    }
                }
                
                if(parentkeys !== undefined && parentkeys.length > 0){
                    parentField.push('--- None ---');
                }

                for(i = 0; i < parentkeys.length; i++){
                    parentField.push(parentkeys[i]);
                }
                component.set("v.getParentList", parentField);
                console.log('parentField'+parentField);
            }
       });
       
       $A.enqueueAction(action);
    } 
})