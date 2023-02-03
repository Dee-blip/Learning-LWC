({
        //fetch contact from apex controller
        getContact: function(component){
            console.log("helper contact");

            /*var actionTskStatus = component.get("c.getTaskStatus");
    		var inputsel = component.find("InputSelectDynamic");
    		var opts=[];
    		actionTskStatus.setCallback(this, function(a) {
                for(var i=0;i< a.getReturnValue().length;i++){
                    opts.push({"class": "optionClass", label: a.getReturnValue()[i], value: a.getReturnValue()[i]});
                }
                inputsel.set("v.options", opts);

   			 });
    		$A.enqueueAction(actionTskStatus); 
            //InputSelectType
            var actionTskType = component.get("c.getTaskType");
    		var inputselType = component.find("InputSelectType");
    		var optsType=[];
    		actionTskType.setCallback(this, function(a) {
                for(var i=0;i< a.getReturnValue().length;i++){
                    optsType.push({"class": "optionClass", label: a.getReturnValue()[i], value: a.getReturnValue()[i]});
                }
                inputselType.set("v.options", optsType);

   			 });
    		$A.enqueueAction(actionTskType);*/
            //Set action to invoke Apex controller method
            var leadId= component.get("v.theOppty.Associated_Lead__c");
            if($A.util.isEmpty(leadId) || leadId == 'null'){
                console.log("Invalid Associated Lead value :"+leadId);
                return;
        	}
            var action = component.get("c.getContact");
            action.setParams({
            	//assocLeadId: JSON.stringify(component.get("v.theOppty.Associated_Lead__c"))
            	assocLeadId: component.get("v.theOppty.Associated_Lead__c")
            });
            console.log("v.theOppty.id: "+component.get("v.theOppty.Id"));
            console.log("v.theOppty.Associated_Lead__c: "+component.get("v.theOppty.Associated_Lead__c"));
			console.log("v.theContact.id in con: "+component.get("v.theContact.Id"));
            console.log("action: "+action);
            //Set up the callback
            var self = this;
            var contactId = '';
            action.setCallback(this, function(actionResult){
                var state = actionResult.getState();
                console.log('state: '+state);
                if (component.isValid() && state === "SUCCESS") {
                
                    var fields = actionResult.getReturnValue();
                    component.set("v.fields", fields);
                    console.log('v.fields');
                    console.log(component.get("v.fields"));
                    self.createForm(component, fields,"Contact");
                }
/*				if (component.isValid() && state === "SUCCESS") {
                    //Reset value of component contact with controller output
                    console.log("actionResult.getReturnValue() before: "+actionResult.getReturnValue());
                    component.set("v.contact",actionResult.getReturnValue());
                    console.log("v.theOppty.Associated_Lead__c: "+component.get("v.theOppty.Associated_Lead__c"));
					contactId = component.get("v.contact.Id");    
                    console.log('component.get("v.contact.Name"): '+component.get("v.contact.Name"));
                    console.log("actionResult.getReturnValue(): "+actionResult.getReturnValue());
                    this.getFields(component,"Contact",component.get("v.contact"));
                }*/
            });
             
            $A.enqueueAction(action);
            console.log("helper contact exit");
            //Get Campaign
             var campId= component.get("v.theOppty.CampaignId");
            if($A.util.isEmpty(campId) || campId == 'null'){
                console.log("Invalid Associated Campaign value :"+campId);
                return;
        	}
            var actionCamp = component.get("c.getCampaign");
            console.log("v.theOppty.CampaignId");
            console.log(JSON.stringify(component.get("v.theOppty.CampaignId")));
            actionCamp.setParams({
                campaignId: component.get("v.theOppty.CampaignId")
            });
            console.log("v.theOppty.id: "+component.get("v.theOppty.id"));
            //Set up the callback
            var self = this;
            actionCamp.setCallback(this, function(actionResult){
                var state = actionResult.getState();
                console.log('state: '+state);
                if (component.isValid() && state === "SUCCESS") {
                
                    var fields = actionResult.getReturnValue();
                    component.set("v.fields", fields);
                    console.log('v.fields');
                    console.log(component.get("v.fields"));
                    self.createForm(component, fields,"Campaign");
                }else if (state === "ERROR") {
                    console.log('Error');
                    console.log(component.get("v.camvalues.length"));
                }
				/*if (component.isValid() && state === "SUCCESS") {
                    //Reset value of component contact with controller output
                    console.log("actionResult.getReturnValue() before: "+actionResult.getReturnValue());
                    component.set("v.camp",actionResult.getReturnValue());
                    console.log("v.theOppty.CampaignId: "+component.get("v.theOppty.CampaignId"));
                    this.getFields(component,"Campaign",component.get("v.camp"));
                }*/
            });
            $A.enqueueAction(actionCamp);
            
            //get TasksEventWrapper
            /* var actionTsk = component.get("c.getTaskEvents");
            actionTsk.setParams({
            	conId: component.get("v.theContact.Id")
            });
            console.log("v.theContact.id in actionTsk: "+component.get("v.theContact.Id"));
           
            console.log("actionTsk: "+actionTsk);
            //Set up the callback
            var self = this;
            
            actionTsk.setCallback(this, function(actionResult){
                var state = actionResult.getState();
                console.log('state actionTsk: '+state);
				if (component.isValid() && state === "SUCCESS") {
                    //Reset value of component contact with controller output
                    console.log("actionResult.getReturnValue() before tskEWrapper: ");
                    console.log(actionResult.getReturnValue());
                    component.set("v.tskEWrapper",actionResult.getReturnValue());
                    console.log("v.tskEWrapper.Id: "+component.get("v.tskEWrapper[0].Id"));
                }
            });
           
            $A.enqueueAction(actionTsk);*/
            
            console.log("helper tskEWrapper exit");
        },
    getsObjectRecords : function(component,page) {
		var page = page || 1;
        var evp = component.get("v.eventOffset") || 0;
        var evl = component.get("v.eventLimit") || 0;
        var contId = component.get("v.theContact.Id");
        if($A.util.isEmpty(contId) || contId == 'null'){
                console.log("Invalid Associated Campaign value :"+contId);
                return;
        	}
        var action = component.get("c.getRecords");
        //var fields = component.get("v.fields");
        action.setParams({
            conId : contId,
           // limits : component.get("v.limit"),
           // fieldstoget : fields.join(),
            pageNumber : page,
            pageSize : component.get("v.pageSize"),
            eventOffset: evp,
            eventLimit: evl
            
        });
        console.log('pageSize: '+component.get("v.pageSize"));
        action.setCallback(this,function(response){
            var state = response.getState();
            if(state === 'SUCCESS'){
                //document.getElementById("data").innerHTML ='';
                //component.set("v.latestRecords",response.getReturnValue());
                component.set("v.page",page);
                var retResponse = response.getReturnValue();
                console.log('getRecords');
                console.log(retResponse);
                component.set("v.total",retResponse.total);
                console.log('logging: ');
                console.log(retResponse.total);
                console.log(component.get("v.pageSize"));
                console.log(component.get("v.eventOffset"));
                component.set("v.eventOffset",retResponse.eventOffset);
                component.set("v.eventLimit",retResponse.eventLimit);
                console.log(component.get("v.eventOffset"));
                if(retResponse.total!=0)
	                component.set("v.pages",Math.ceil(retResponse.total/component.get("v.pageSize")));
                else
                    component.set("v.pages",1);
                var retRecords = retResponse.taskEventWrapperRecords;
                component.set("v.tskEWrapper",retRecords);
                console.log('component.get(v.tskEWrapper)');
                console.log(component.get("v.tskEWrapper"));
                /*retRecords.forEach(function(s) {
                    var tableRow = document.createElement('tr');
                    fields.forEach(function(field){ 
                        var tableData = document.createElement('td');
                        var tableDataNode = document.createTextNode(s[field]);
                        tableData.appendChild(tableDataNode);
                        tableRow.appendChild(tableData);
                    });
                    document.getElementById("data").appendChild(tableRow);
                 });*/
                
             }else if (state === "ERROR") {
                 component.set("v.page",0);
                 component.set("v.total",0);
                 component.set("v.pages",0);
                console.log('Error');
            }
        });
        $A.enqueueAction(action);
	},

    configMap: {
        "anytype": { componentDef: "markup://ui:inputText" },
        "base64": { componentDef: "markup://ui:inputText" },
        "boolean": {componentDef: "markup://ui:inputCheckbox" },
        "combobox": { componentDef: "markup://ui:inputText" },
        "currency": { componentDef: "markup://ui:inputText" },
        "datacategorygroupreference": { componentDef: "markup://ui:inputText" },
        "date": { componentDef: "markup://ui:inputDate" },
        "datetime": { componentDef: "markup://ui:inputDateTime" },
        "double": { componentDef: "markup://ui:inputNumber", attributes: { values: { format: "0.00"} } },
        "email": { componentDef: "markup://ui:inputEmail" },
        "phone": { componentDef: "markup://ui:inputPhone" },
        "encryptedstring": { componentDef: "markup://ui:inputText" },
        "id": { componentDef: "markup://ui:inputText" },
        "integer": { componentDef: "markup://ui:inputNumber", attributes: { values: { format: "0"} } },
        "multipicklist": { componentDef: "markup://ui:inputText" },
        "percent": { componentDef: "markup://ui:inputNumber", attributes: { values: { format: "0"} } },
        "picklist": { componentDef: "markup://ui:inputText" },
        "reference": { componentDef: "markup://ui:inputText" },
        "string": { componentDef: "markup://ui:inputText" },
        "textarea": { componentDef: "markup://ui:inputText" },
        "time": { componentDef: "markup://ui:inputDateTime", attributes: { values: { format: "h:mm a"} } },
        "url": { componentDef: "markup://ui:outputURL" }
    },

    // Adds the component via newComponentAsync and sets the value handler
    addComponent: function(component, facet, config, fieldPath,sObjectType) {
        $A.componentService.newComponentAsync(this, function(cmp) {
            cmp.addValueHandler({
                value: "v.value",
                event: "change",
                globalId: component.getGlobalId(),
                method: function(event) {
                    var values;
				if(sObjectType==='Contact')
                    values = component.get("v.convalues");
                else if(sObjectType==='Campaign')
                    values = component.get("v.convalues");
                    for (var i = 0; i < values.length; i++) {
                        if (values[i].name === fieldPath) {
                            values[i].value = event.getParams().value;
                        }
                    }
                    if(sObjectType==='Contact')
	                    component.set("v.convalues", values);
                    else if(sObjectType==='Campaign')
			        	component.set("v.camvalues", values);
                }
            });

            facet.push(cmp);
        }, config);
    },

    // Create a form given the set of fields
    createForm: function(component, fields,sObjectType) {
        var field = null;
        var cmp = null;
        var def = null;
        var config = null;
        var self = this;

        // Clear any existing components in the form facet
        component.set("v.form", []);

        var facet = component.get("v.form");
        var values = [];
        for (var i = 0; i < fields.length; i++) {
            field = fields[i];
            console.log('Json:');
            console.log(this.configMap[field.type.toLowerCase()]);
            // Copy the config, note that this type of copy may not work on all browsers!
            config = JSON.parse(JSON.stringify(this.configMap[field.type.toLowerCase()]));
            console.log('config: ');
            console.log(config);
            // Add attributes if needed
            config.attributes = config.attributes || {};
            // Add attributes.values if needed
            config.attributes.values = config.attributes.values || {};

            // Set the required and label attributes
            config.attributes.values.required = field.required;
            config.attributes.values.label = field.label;
            //config.attributes.values.value = field.value;
            console.log('values:');
            console.log(values);
            // Add the value for each field as a name/value            
            values.push({name: field.label, value: field.value});

            // Add the component to the facet and configure it
            if(sObjectType==='Contact')
            	self.addComponent(component, facet, config, field.fieldPath,'Contact');
            else if(sObjectType==='Campaign')
                self.addComponent(component, facet, config, field.fieldPath,'Campaign');
        }
        console.log('sObjectType');
        console.log(sObjectType);
        if(sObjectType==='Contact')
        	component.set("v.convalues", values);
        else if(sObjectType==='Campaign')
        	component.set("v.camvalues", values);
    },
    getFields: function(component,sObjectName,record) {
        var action = component.get("c.getFields");
        var self = this;
        console.log('getFields:');
        console.log(component);
        console.log(sObjectName);
        console.log(record);
//        var sObjectName = 'Contact';
//        var record = component.get("v.contact");
      // var fsName = component.get("v.fsName");
        action.setParams({sObjectName: sObjectName,sobjRecord: record});
        action.setCallback(this, function(a) {
            var state = a.getState();
             console.log('state getFields: '+state);
			if (component.isValid() && state === "SUCCESS") {
                
            var fields = a.getReturnValue();
            component.set("v.fields", fields);
            console.log('v.fields');
            console.log(component.get("v.fields"));
            self.createForm(component, fields,sObjectName);
            }
        });
        $A.enqueueAction(action);        
    },
    saveContact: function(component){
            var uiCon = component.get("v.theContact");
        	var action = component.get("c.save");
			action.setParams({ record : uiCon });  
        console.log('uiCon: '+component.get("v.theContact.Name"));
        console.log('uiCon id: '+component.get("v.theContact.Id"));
        //Set a callback function to Id of the new task and add it to the list if we get a successful result
    		action.setCallback(this, function(response) {
       		var state = response.getState();
	        if (state === "SUCCESS") {
    	        component.set("v.theContact", response.getReturnValue());
        	  
    	    } else if (state === "ERROR") {
        	    var errors = response.getError();
            	if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                        }
                } else {
                    console.log("Unknown error");
                }
        }
    });

    //Queue the action to run
    $A.enqueueAction(action);
  
    }
 })
})