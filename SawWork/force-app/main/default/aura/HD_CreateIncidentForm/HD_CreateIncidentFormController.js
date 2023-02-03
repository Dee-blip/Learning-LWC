({
    
    doinit : function(component,event,helper){
       /* //console.log("In Init");
        var action = component.get("c.getCategories");
        action.setCallback(this,function(data){
            //console.log("In init callback");
            var queueList = data.getReturnValue();
            //console.log("returned queues"+data);
            var queues = [];
            for(key in queueList){
                //console.log("queue.Id: "+queueList[key]+" ; "+"queue.Name: "+key);
                queues[key]=queueList[key];
            }
            component.set("v.initialResult",queues);
            helper.doneWaiting(component);
        });
        $A.enqueueAction(action);*/
        console.log('searchQueryUsr: ' + component.get("v.searchQueryUsr") + 'selectedUserId: ' + component.get("v.searchQueryUsr"));
		console.log('isScreenPop: ' + component.get("v.isScreenPop"));        
        var action = component.get("c.getCategories");
                action.setCallback(this, function(response) {
            var categories = {}, results,parent;
            var state = response.getState();
            if(state == 'ERROR'){
                
                var errors = response.getError();
                HD_Error_Logger.createLogger(component, event, helper, errors[0].message, errors[0].message,false);
                return;
            }
                results = response.getReturnValue();
                component.set("v.initResults",results);
                //Changes for ACD
                if(component.get("v.isScreenPop") )
                {
                    var value = component.find("clientid").get("v.value");
                    if(value != null && value != '' && value.length>=3)
                    {
						helper.searchUsers(component);
                    }
                    else
                    {
                        helper.doneWaiting(component);    
                    }
                }
                else
                {
                	helper.doneWaiting(component);    
                }
                //End of Changes for ACD                                    
        });
        $A.enqueueAction(action);
        helper.waiting(component);
    },
    
     performSearch: function(component, event, helper) {
        var results;
    	var elem = component.find("categoryid");
        var value = component.find("categoryid").get("v.value");
    	var resultsFinal=component.get("v.initResults");
        var results1 = [];
        if(value === null || value === '' ){
            results1 = [];
        } 
        else{
            value=value.replace(/[-[\]{}()*+!<=:?.\/\\^$|#\s,]/g, '\\$&');
            var reg = new RegExp(value, 'i');
            results = component.get("v.initResults");
         	results.forEach(function(category) {
               	var key = category.Name;
                var parentcat = category.BMCServiceDesk__parentTree__c ;
                if(parentcat == null || parentcat == '' || parentcat == 'null'){
                    parentcat = "No parent. Top level category";
                }

                if(key && key.match(reg)){
                    results1.push({name:key,id:category.Id,parent:parentcat});
                }
                    
                });

        }//else
    	component.set("v.results",results1);
    },
    
    categorySelected: function(component, event, helper){
        var selectedValue = event.currentTarget.dataset.category;
        var selectedId = event.currentTarget.dataset.categoryid;
        component.set("v.results",[]);
        component.set("v.searchQuery","");
        component.set("v.searchQuery",selectedValue);
        component.set("v.selectedCategoryId",selectedId);
    },
    
    openClientSearch: function(component,event,helper)
    {
        var clientForm = component.find("auraclientsearch")
        $A.util.removeClass(clientForm,'slds-hide');
        $A.util.addClass(clientForm,'slds-show');
        helper.searchUsers(component);
    },
    
    performUserSearch: function(component, event, helper) {
        var results;
    	console.log("In perform user search");
    	
    	var elem = component.find("clientid");
    	console.log(elem);
    	
         var value = component.find("clientid").get("v.value");
         console.log("Value:");
    	console.log(value);         
        var results1 = [];
        if(value == null || value == '' || value.length<3){
            
            results1 = [];
            component.set("v.resultsUsr",results1);
        } 
        else{
                    helper.searchUsers(component);
            var resultsFinal=component.get("v.resultsUsr");
           var reg = new RegExp(value, 'i');
            var count = 0;
            var flag = false;
            for(let user in resultsFinal){
                if(count<15){
                	var name = user.split("|")[0];
                    var usrTitle = user.split("|")[1];
                    var usrPhone = user.split("|")[2];
                	var usrEmail = user.split("|")[3];
                    var usrRole = user.split("|")[4];
                    var usrProfile = user.split("|")[5];
                	console.log("Key: "+key);
                    
               		if(name.match(reg)){
                        flag = true;
                        results1.push({name:name,id:resultsFinal[user],title:usrTitle,phone:usrPhone,email:usrEmail,role:usrRole,profile:usrProfile});
                        count = count +1;
               		 }
                }
            }
            console.log("Results1: "+results1);
            //get new set of users for the new search
            if(flag == false){
                //helper.searchUsers(component);
            }
        }//else
    	component.set("v.resultsUsr",results1);
    },
    
    userSelected: function(component, event, helper){
        console.log("In user selected");
        console.log(component.getElements());
        console.log(component.getElement());
        var selectedValue = event.currentTarget.dataset.user;
        var selectedId = event.currentTarget.dataset.userid;
        console.log(selectedValue);
        component.set("v.resultsUsr",[]);
        component.set("v.searchQueryUsr","");
        component.set("v.searchQueryUsr",selectedValue);
        component.set("v.selectedUserId",selectedId);
        console.log("Selected User Id: "+selectedId);
        var clientForm = component.find("auraclientsearch")
        $A.util.removeClass(clientForm,'slds-show');
        $A.util.addClass(clientForm,'slds-hide');
    },
   
    hideCreateForm : function(component, event, helper){
        //Start of Changes for ACD. Checking if the call is from ACD
        if (component.get('v.isScreenPop')) 
        {
            //Close the window
            window.close();
        }//Else block for the original code
        else
        {
        
            helper.clearFields(component);
            var renderEvent = $A.get("e.c:hd_renderCreateFormEvent");
            renderEvent.setParams({"renderForm":false}).fire();
        }  
        //End of Changes for ACD        
    },
    
        changeSbi : function(component,event,helper)
        {
            console.log("In changeSbi");
            console.log(component.find("uiSbi"));
            console.log(component.find("uiSbi").get("v.checked"));
         	var flag = component.find("uiSbi").get("v.checked");
            component.set("v.sbi",flag);  
            console.log('flag sbi '+flag);
            if(flag == false)
            {
                component.set("v.ntfy",flag);
            }
        },
		changeNtfy : function(component,event,helper)
        {
         	var flag = component.find("dlEIS").get("v.checked");
            component.set("v.ntfy",flag); 
            console.log('flag ntfy '+flag);
                      
        } ,
    priorityChange: function(component,event,helper)
    {
        var priVal = component.find("priorityid");
    	if(priVal.get("v.value")=="1")
        {
            component.set("v.pageSupport",true); 
        }
        else
        {
            component.set("v.pageSupport",false); 
        }
    },
    
    hideClientForm: function(component,event,helper)
    {
            var clientForm = component.find("auraclientsearch")
            $A.util.removeClass(clientForm,'slds-show');
            $A.util.addClass(clientForm,'slds-hide');            
    },
    
    saveIncident: function(component,event,helper){
        helper.createIncidentHelper(component,event);
    },
    hideModal : function(component,event, helper){
		component.set("v.modalFlag",false);
   },
    showModal : function(component,event,helper){
        component.set("v.modalFlag",true);
    },
    onSelectCategory: function(component, event, helper){
       	var cmp=component.find("resolutionId");
        $A.util.addClass(cmp,"hideForm");
        $A.util.removeClass(cmp,"showForm");
        component.set("v.modalFlag",false);
        component.set("v.results",[]);
        component.set("v.searchQuery","");
        component.set("v.searchQuery",event.getParam("categoryName"));
        component.set("v.selectedCategoryId",event.getParam("categoryId"));
    }
    
})