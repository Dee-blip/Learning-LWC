({
    MAX_FILE_SIZE: 750 000, /* 1 000 000 * 3/4 to account for base64 */
    NUM_OF_ATTACHMENTS: 0,
    
	waiting: function(component) {
        var ele = component.find("Accspinner");
        console.log("waiting called");
        $A.util.addClass(ele,"slds-show");
        $A.util.removeClass(ele,"slds-hide");
     },
     
      doneWaiting: function(component) {
            var ele = component.find("Accspinner");
          	console.log(ele);
            $A.util.addClass(ele,"slds-hide");
            $A.util.removeClass(ele,"slds-show");
     },
    
    clearFields: function(component) {
        console.log("In clearFields function of helper");
        component.find("priorityid").set("v.value","");
        component.find("categoryid").set("v.value","");
        component.find("descid").set("v.value","");
        component.find("clientidx").set("v.value","");
        component.find("ccid").set("v.value","");
		component.find("sourceid").set("v.value"," ");
		component.find("clientvipid").set("v.checked",false);
        console.log("clientnotificationid")
        console.log(component.find("clientnotificationid"));
		component.find("clientnotificationid").set("v.checked",false);
        component.find("uiSbi").set("v.checked",false);
        if(component.get("v.pageSupport")==true){
			console.log("v.pageSupport is true");
            component.find("pagesupportid").set("v.checked",false);
        }
        
         if(component.get("v.sbi")==true){
			component.find("whitehatincid").set("v.checked",false);
			component.find("dlEIS").set("v.checked",false);
        }
         if(component.get("v.ntfy")==true){
			component.find("ntfyCreation").set("v.checked",false);
			component.find("ntfyStatus").set("v.checked",false);
			component.find("ntfyNotes").set("v.checked",false);
        }
        component.find("file").getElement().value='';
    },
    
    searchUsers : function(component){
        var value = component.find("clientid").get("v.value");
         var actionGetUsr = component.get("c.getActiveUsers");
        actionGetUsr.setParams({
            startsWith : value
        });
        actionGetUsr.setStorable();
        actionGetUsr.setCallback(this,function(data){
            console.log("In init callback");
            var userList = data.getReturnValue();
            console.log("returned users"+data);
            console.log(data);
            var users = [];
            for(key in userList){
                console.log("user.Id: "+userList[key]+" ; "+"user.Name: "+key);
                users[key]=userList[key];
            }
            component.set("v.initialResultUsr",users);
            var results1 = [];
            for(user in userList){
                //if(count<10){
                	var name = user.split("|")[0];
                    var usrTitle = user.split("|")[1];
                    var usrPhone = user.split("|")[2];
                	var usrEmail = user.split("|")[3];
                    var usrRole = user.split("|")[4];
                    var usrProfile = user.split("|")[5];
                	console.log("Name: "+name);
               		//if(name.match(reg)){
                       results1.push({name:name,id:users[user],title:usrTitle,phone:usrPhone,email:usrEmail,role:usrRole,profile:usrProfile});
                       // count = count +1;
               		 //}
                //}
            }
            console.log("Results1: "+results1);
    		component.set("v.resultsUsr",results1);
            this.doneWaiting(component);
        });
        $A.enqueueAction(actionGetUsr);
        this.waiting(component);
    },
    
    createIncidentHelper : function(component,event) {
        var fileInput;
    	console.log("fileInput: ");
    	console.log(fileInput);
    	var file = null;    	
    	var fileContents = null;
    	var fr;
    	var fileData = [];
        var num_of_files = 0;
        //Changes for ACD: Moved the file component code inside the if condition
        if (!component.get('v.isScreenPop')) 
        {
            fileInput = component.find("file").getElement();
	    	console.log("fileInput.files: ");
    		console.log(fileInput.files);
            
        	num_of_files = fileInput.files.length;    
        }
        //End of changes for ACD
   		console.log('num_of_files:'+num_of_files);
        
    	if(num_of_files>0)
    	{
    		if(num_of_files>10){
                var msg = "Cannot attach more than 10 files at a time";
                var createToastEvent = $A.get("e.force:showToast");
                createToastEvent.setParams({
                            "title": "Error",
                            "message": msg
                });
                createToastEvent.fire();
                component.find("file").getElement().value='';
                return;
            }
    		for(i=0;i<num_of_files;i++)
    		{
                file = fileInput.files[i];
                //console.log("File "+i+": "+file);
                console.log('File size cannot exceed ' + this.MAX_FILE_SIZE);
                console.log('Selected file size: ' + file.size);
       
                if (file.size > this.MAX_FILE_SIZE) {
                    var msg = 'File size cannot exceed ' + this.MAX_FILE_SIZE+' Selected file size: ' + file.size;
                	var createToastEvent = $A.get("e.force:showToast");
                	createToastEvent.setParams({
                            "title": "Error",
                            "message": msg
                	});
                	createToastEvent.fire();
                	component.find("file").getElement().value='';
                	return;
                }
                var self = this;
                fr = new FileReader();
                fr.onload = (function(f)
                {
                    return function(e)
                    {
                        fileContents = this.result;
                    	var base64Mark = 'base64,';
                    	var dataStart = fileContents.indexOf(base64Mark) + base64Mark.length;
        
                    fileContents = fileContents.substring(dataStart);
                    console.log('json');
                    fileContents =  encodeURIComponent(fileContents)
                  	fileData.push(JSON.stringify({fileName : f.name, fileType : f.type, fileContents: fileContents}));

                    console.log(f.name);
                    console.log('len'+fileData.length+num_of_files);
                	if(fileData.length == num_of_files)
                    {
                        console.log("last file");
                        self.createIncidentAction(component,event,fileData);
                    }
                        
                    };
                     
     
                })(file);
					
                fr.readAsDataURL(file);
			}
            
            
		}
        else
        {
            this.createIncidentAction(component,event, fileData);
        }
     
    	
   },
    
    createIncidentAction : function(component,event, fileData){
        
        var isSafari = /constructor/i.test(window.HTMLElement) || (function (p) { return p.toString() === "[object SafariRemoteNotification]"; })(!window['safari'] || safari.pushNotification);
        if(isSafari)
        {
            var windowReference = window.open();
        }
        var selectedUsr = component.get("v.selectedUserId");
        console.log("User in save: "+component.get("v.selectedUserId"));
        if(component.get("v.selectedUserId") == undefined){
            selectedUsr = null;
        }
		var priorityCmp = component.find("priorityid");
        console.log(priorityCmp);
        var selectedpriority = priorityCmp.get("v.value");
        console.log(selectedpriority);
        var catCmp = component.find("categoryid");
        console.log("catCmp:");
        console.log(catCmp);
        var selectedcat = component.get("v.selectedCategoryId");
        console.log("selectedcat: "+selectedcat);
        var descmp = component.find("descid");
        var desc = descmp.get("v.value");
        console.log("descmp");
        console.log(descmp);
        var vipVal = component.find("clientvipid").get("v.checked");
        var exclNtfyVal = component.find("clientnotificationid").get("v.checked");
        var srcVal = component.find("sourceid").get("v.value");
        var whitehatVal = false,
            dlEISVal = false,
            ntfyCreationVal =false,
            ntfyStatusVal = false,
            ntfyNotesVal = false;
        var	pgSprtVal = false;
        if(selectedpriority == 1){
            console.log("Priority is 1");
            pgSprtVal = component.find("pagesupportid").get("v.checked");
            console.log("pgSprtVal"+pgSprtVal);
        }
        var sbiVal = component.find("uiSbi").get("v.checked");
       	console.log("sbiVal"+sbiVal);
        console.log("whitehatVal"+component.find("whitehatincid"));
        if(sbiVal)
        {
            whitehatVal = component.find("whitehatincid").get("v.checked");
       		console.log("whitehatVal"+whitehatVal);
        	dlEISVal = component.find("dlEIS").get("v.checked");   
       		console.log("dlEISVal"+dlEISVal);
        }
        if(sbiVal && dlEISVal)
        {
            ntfyCreationVal = component.find("ntfyCreation").get("v.checked");
       		console.log("ntfyCreationVal"+ntfyCreationVal);
            ntfyStatusVal = component.find("ntfyStatus").get("v.checked");
       		console.log("ntfyStatusVal"+ntfyStatusVal);
            ntfyNotesVal = component.find("ntfyNotes").get("v.checked");
       		console.log("ntfyNotesVal"+ntfyNotesVal);
        }
        var cclist = component.find("ccid").get("v.value");
        
        var warningMessages = [];
        var index = 0;
        component.set("v.warnings"," ");
        
        if(selectedpriority == null || selectedpriority == '')
        {
            console.log("No priority");
            warningMessages[index] = "Please provide Priority of the incident";
            index++;
        }
        if(selectedcat == null || selectedcat == '')
        {
            console.log("No category");
            warningMessages[index] = "Please provide Category of the incident";
            index++;
        }
        if(desc == null || desc == ''){
            console.log("No description");
            warningMessages[index] = "Please provide Description of the incident";
            index++;
        }
        
        component.set("v.warnings",warningMessages);
        if(warningMessages.length==0)
        {
        	var action = component.get("c.createIncident");
        	action.setParams({
                userId : selectedUsr,
        		priority : selectedpriority,
            	category : selectedcat,
            	description : desc,
                sbi:sbiVal,
                whitehat:whitehatVal,
                dlEIS:dlEISVal,
                ntfyCreation:ntfyCreationVal,
                ntfyStatus:ntfyStatusVal,
                ntfyNotes:ntfyNotesVal,
                pageSupportValue:pgSprtVal,
                vipValue:vipVal,
                excludeNotificationValue:exclNtfyVal,
                sourceValue:srcVal,
                ccValues:cclist,
                fileData:fileData
                
      		}); 
        	console.log("After setting parameters");
        	console.log("Priority: "+selectedpriority+ " Category: "+selectedcat);
            action.setCallback(this,function(data){
            	console.log("In callback");
                var state = data.getState();
                if(state == 'SUCCESS')
                {
                    var response = data.getReturnValue();
            		var splitRes = response.split(';');
            		console.log("Created: "+response);
            		console.log(splitRes);
            		var incId = splitRes[0];
                    component.set("v.incidentId",incId);
                    //helper.saveFile(component);
                    var successMsg = "Incident # "+splitRes[1]+" created";
                                        
                    //Start of changes for ACD
 					if (component.get('v.isScreenPop')) 
                     {
                        console.log('attempting to navigate to '+splitRes[0]);
                        window.open('/'+ splitRes[0],"_self");
                        return;
                     } 
                     //End of changes for ACD 

                    var createToastEvent = $A.get("e.force:showToast");
                    createToastEvent.setParams({
                        "title": "Incident Created",
                        "message": successMsg
                    });
                    createToastEvent.fire();
                    console.log("Event source");
            		console.log(event.getSource().getLocalId());
                    if(event.getSource().getLocalId() == "Save"){
                        var newUrl = "/lightning/r/BMCServiceDesk__Incident__c/"+incId+"/view";
            			console.log(newUrl);
                		if(isSafari)
                        {
                    		windowReference.location = newUrl;
                		} 
                        else{
                			var win = window.open(newUrl,'_blank');
                        	if(win != null){
								win.focus();                      
                        	}
                        }//else
                        //helper.clearFields(component);
                        this.clearFields(component);
						var renderEvent = $A.get("e.c:hd_renderCreateFormEvent"); 
       					renderEvent.setParams({"renderForm":false}).fire();
                    }
                    	
                    
                    else if(event.getSource().getLocalId() == "SaveAndNew"){
                        console.log("Event source was Save and New");
                		this.clearFields(component);
                    }
                    
                    this.doneWaiting(component);
                }
                else if(state == 'ERROR')
                {
                    /*
                    this.doneWaiting(component);
                    var errors = data.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " +
                                    errors[0].message);
                            
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "title": "Error!",
                                "type": "error",
                                "message": errors[0].message
                            });
                            toastEvent.fire();

                            
                        }
                    } else {
                        console.log("Unknown error");
                        var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "title": "Error!",
                                "type": "error",
                                "message": "Unknown error"
                            });
                            toastEvent.fire();
                    }
                    */
                    var errors = data.getError();
                    HD_Error_Logger.createLogger(component, event, this, errors[0].message, errors[0].message,false);
            		this.doneWaiting(component);
                    return;
                    
                }
                
            });
			$A.enqueueAction(action);
            this.waiting(component);
        }
    
    } 
})