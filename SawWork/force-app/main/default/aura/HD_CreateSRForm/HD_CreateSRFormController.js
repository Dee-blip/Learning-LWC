({
	doInit : function(component, event, helper) {
         console.log("In Init");
        var action = component.get("c.getRequestDefinitionsList");
        action.setCallback(this,function(data){
            console.log("In init callback");
            var rdList = data.getReturnValue();
            console.log("returned request definitions"+data);
            var reqDefs = {};
            var key;
            for(key in rdList){
                console.log("rd.Id: "+rdList[key]+" ; "+"rd.Name: "+key);
                reqDefs[key]=rdList[key];
            }
            console.log("ReqDefs: ");
            console.log(reqDefs);
            //var temp = {'dasdas':'dasdas'};
            
            //console.log(temp['dasdas']);
            component.set("v.initialResultRD",reqDefs);
            console.log("initial result in init:");
            
            console.log(component.get("v.initialResultRD"));
            //var temp2 = component.get("v.initialResultRD");
            //console.log(temp2['dasdas']); //this works
            //for(var indx in temp2){
              //  console.log(temp2[indx]);
            //}
            helper.doneWaiting(component);
        });
        $A.enqueueAction(action);
        helper.waiting(component);
	},
    
    performSearch: function(component, event, helper) {
        var results;
    	//var elem = $A.util.getElement("reqDefInput");
    	//var value= $A.util.getElementAttributeValue(elem,"value"); 
    	//var elem = component.find("auraReqDefInput");
        //console.log("Element in perform search: ");
        //console.log(elem);
        //var value = component.find("auraReqDefInput").get("v.value");
        var value = event.target.value;
        console.log("Value: "+value);
        console.log("Initial result in performSearch: ");
        console.log(component.get("v.initialResultRD"));
        var resultsFinal=component.get("v.initialResultRD");
        console.log("Results Final: ");
        console.log(resultsFinal);
        var results1 = [];
        if(value == null || value == ''){
            //results1.push({name:"Triage Team",id:resultsFinal["Triage Team"]});
            results1 = [];
        } 
        else{
            console.log("Value not null. In else");
	    value=value.replace(/[-[\]{}()*+!<=:?.\/\\^$|#\s,]/g, '\\$&');

            var reg = new RegExp(value, 'i');
            for(var key in resultsFinal){
                console.log("In for");
                if(key.match(reg)){
                    console.log("Key match");
                    results1.push({name:key,id:resultsFinal[key]});
                }
            }
         	//results = resultsFinal;
        }//else
        //results1.push({name:"Triage Team",id:resultsFinal["Triage Team"]});
        console.log("Results1: "+results1);
    	component.set("v.results",results1);
    },
    
    reqDefSelected: function(component, event, helper){
        console.log("In reqDefSelected");
        console.log(component.getElements());
        console.log(component.getElement());
        var selectedValue = event.currentTarget.dataset.name;
        console.log("selectedValue: "+selectedValue);
        var selectedId = event.currentTarget.dataset.id;
        console.log("selectedId: "+selectedId);
        component.set("v.results",[]);
        component.set("v.searchQuery","");
        component.set("v.searchQuery",selectedValue);
        component.set("v.selectedReqDefId",selectedId);
        var element = component.find("aurahiddenReqDefId");
        console.log("Selected Id: "+selectedId);
    },
    
    onReqDefSelect : function(component, event, helper){
        var isSafari = /constructor/i.test(window.HTMLElement) || (function (p) { return p.toString() === "[object SafariRemoteNotification]"; })(!window['safari'] || safari.pushNotification);
        if(isSafari)
        {
            var windowReference = window.open();
        }
        var rdId = component.get("v.selectedReqDefId");
        console.log("RD ID: "+rdId);
        var newUrl = "/apex/bmcservicedesk__SelfServiceIncidentCustom?isServiceRequest=true&reqDefId="+rdId;
        if(isSafari)
        {
            windowReference.location = newUrl;
        } 
        else
        {
            var win = window.open(newUrl,'_blank');
            //if(win != null)
            //{
              //  win.focus();                      
            //}
        }
        //var win = window.open(newUrl,'_blank');
      	//Start of Changes for ACD. Adding the isScreenPop Check
      	if (component.get('v.isScreenPop')) 
        {
            //if from ACD, destroy the component
            component.destroy();
        }//Adding the else for the existing code 
        else
        {
            component.set("v.searchQuery","");
            var renderEvent = $A.get("e.c:hd_renderSRFormEvent");
            renderEvent.setParams({"renderSRForm":false}).fire();            
        }
        //End of changes for ACD
    },
    
    hideCreateSRForm : function(component, event, helper){
      	//helper.clearFields(component);
      	//Start of Changes for ACD. Adding the isScreenPop Check
      	if (component.get('v.isScreenPop')) 
        {
            //if from ACD, destroy the component
            component.destroy();
        }//Adding the else for the existing code 
        else
        {
            component.set("v.searchQuery","");
            var renderEvent = $A.get("e.c:hd_renderSRFormEvent");
            renderEvent.setParams({"renderSRForm":false}).fire();            
        }
        //End of changes for ACD
    }
})