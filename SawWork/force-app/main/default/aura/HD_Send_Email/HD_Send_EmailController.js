({
   
    doInit : function(component, event, helper) {
        //component.find("toAddress").set("v.value",);
        
        var action = component.get("c.getEmailTemplates");
        var opts = [{"class": "optionClass", label: "None", value: null}];
        action.setCallback(this,function(data){
            
            if(data.getState() == 'SUCCESS'){     
               var response = data.getReturnValue();
               var tmpMap = {};

                for(var x in response)
                {
                    //console.log('x '+x);
                    //console.log('response: '+response[x].Name);
                    opts.push({ "class": "optionClass", label: response[x].Name, value: response[x].Id });
                	//tmpMap[response[x].Id] = response[x].Subject;
                	var sub;
                    var str = response[x].Markup;
                    if(str)
                    {
                        var n = str.indexOf("subject=\"");
                    	sub = str.substring(n+9,str.indexOf("\"",n+10));
                    }
                    else
                    {
                        console.log('markup null'+response[x].Name);
                        sub = ' ';
                    }
                    
                	tmpMap[response[x].Id] = sub;                    
                }
                
                component.find("emailTemplates").set("v.options", opts);
            	component.set("v.templateMap",tmpMap);
            
             }else if(data.getState() == 'ERROR'){
                    //console.log('Failed to get initialized in getEmailTemplates');
                    var errors = data.getError();
                    /* eslint-disable-next-line */
                    HD_Error_Logger.createLogger(component, event, helper, errors[0].message,errors[0].message, false, 'error');
                    return;
            }
        });
        
		$A.enqueueAction(action);
        var incId = component.get("v.recordId");
        
        var action2 = component.get("c.getIncident");
            action2.setParams({
        		incidentId : incId
      		});
        action2.setCallback(this,function(data){
            var state = data.getState();
                if(state == 'SUCCESS'){
                    var retVal = data.getReturnValue();
                    
                    component.set('v.incident',retVal);
                    //console.log('clientEmail'+component.get("v.incident").BMCServiceDesk__clientEmail__c);
            		component.find("toAddress").set("v.value",retVal.BMCServiceDesk__clientEmail__c);
                    component.find("subject").set("v.value","#(Ref:IN:"+retVal.Name+")");
                    
                }else if(state == 'ERROR'){
                    //console.log('Failed in send email');
                    var errors = data.getError();
                    /* eslint-disable-next-line */
                    HD_Error_Logger.createLogger(component, event, helper, errors[0].message,errors[0].message, false, 'error');
                    return;
            }
            
            
        });
        
        $A.enqueueAction(action2);
        helper.getFromAddresses(component, event);
    },
    
	sendEmailAction : function(component, event, helper) {
        
		//console.log("sendEmail");
        helper.send(component,event,helper);
        
        
    },
    onTemplateChange : function(component, event, helper) {
		
		//console.log("onTemplateChange");
        var template = component.find("emailTemplates").get("v.value");
        
        //console.log('doInit'+t['Hi']);
        if(!template)
        {
            
            component.find("message").set("v.placeholder","");
            component.find("subject").set("v.disabled","false");
            component.find("subject").set("v.value","#(Ref:IN:"+component.get("v.incident").Name+")");
			component.set("v.previewFlag","false");
        }
        else
        {
            var t = component.get("v.templateMap");
            component.find("message").set("v.placeholder","Please insert the additional information here.");
			var subCmp = component.find("subject");
            subCmp.set("v.disabled","true");
            var re = /\{!\s*relatedto\.[A-z_]+\}/gi;
            var sub = t[template];
            var subject = sub;
            var match;
                while ( match = re.exec(sub)) 
                {
 
                    var field = match[0].substring(match[0].indexOf('\.')+1,match[0].indexOf('\}'));
                    var fieldVal = component.get("v.incident")[field];
                    //console.log("field2"+fieldVal);
                    subject=subject.replace(match[0],fieldVal);
                    //console.log("subject"+subject);
                   	
				}
 		    subCmp.set("v.value",subject);
            component.set("v.previewFlag","true");
            component.find("subjectHeader").set("v.value",subject);
        }
        
    },
    showPreview : function(component, event, helper) {
        var cmp=component.find("resolutionId");
		$A.util.addClass(cmp,"custom-show-modal");
        $A.util.removeClass(cmp,"custom-hide-modal");
        //helper.waiting(component);
		var template = component.find("emailTemplates").get("v.value");
        var incId = component.get("v.recordId");
		//url = "https://akamai--p2rdemo--c.cs54.content.force.com/email/templaterenderer?id="+template+"&recipient_type_id=005G0000007r8kh&related_to_id="+incId+"&base_href=https%3A%2F%2Fakamai--p2rdemo.cs54.my.salesforce.com&preview_frame=previewFrame&render_type=REPLACED_HTML_BODY&setupid=CommunicationTemplatesEmail";
       	
        
        var action = component.get("c.getContentForceURL");
        action.setCallback(this,function(data){
        var baseURL = data.getReturnValue();
        	if(data.getState() == 'SUCCESS'){
                //baseURL = response.replace("my.salesforce.com", "content.force.com");
                //baseURL = baseURL.replace(response.split('.')[0],response.split('.')[0].concat('--c'));
                
                var url = "https://"+baseURL+".content.force.com/email/templaterenderer?id="+template+"&related_to_id="+incId+"&base_href=https://"+baseURL+"my.salesforce.com"+"&preview_frame=previewFrame&render_type=REPLACED_HTML_BODY&setupid=CommunicationTemplatesEmail";
                //url = baseURL+"content.force.com";
                component.set("v.ifmsrc",encodeURI(url));
            
            }else if(data.getState() == 'ERROR'){
                    //console.log('Failed  in getContentForceURL');
                    var errors = data.getError();
                    /* eslint-disable-next-line */
                    HD_Error_Logger.createLogger(component, event, helper, errors[0].message,errors[0].message, false, 'error');
                	return;
            }
        });
        
		$A.enqueueAction(action);
        
        
        
    
        
    },
    hideEmailPreview : function(component,event, helper){
       //document.getElementById("resolutionId").style.display = "none" ;
       var cmp=component.find("resolutionId");
       //console.log(document.getElementById("summaryId").style.display);
        $A.util.addClass(cmp,"custom-hide-modal");
        $A.util.removeClass(cmp,"custom-show-modal");

   },
    waiting: function(component,event, helper) {
        var ele = component.find("Accspinner");
        //console.log("waiting called");
        $A.util.addClass(ele,"slds-show");
        $A.util.removeClass(ele,"slds-hide");
     },
      doneWaiting: function(component,event, helper) {
            var ele = component.find("Accspinner");
          	//console.log(ele);
            $A.util.addClass(ele,"slds-hide");
            $A.util.removeClass(ele,"slds-show");
     },
    handleUploadFinished: function (cmp, event) {
        // Get the list of uploaded files
        var uploadedFiles = event.getParam("files");
        var docIds = [];
        var fNames = [];
        
         for(var i in uploadedFiles)
         {
             if(uploadedFiles[i].documentId!=null)
             {
                 docIds.push(uploadedFiles[i].documentId);
           		 fNames.push(uploadedFiles[i].name);
             }
           
            
         }
        
        if(uploadedFiles.length>1)
        {
            cmp.set("v.fileLabel",uploadedFiles.length+' files uploaded');
        }
        else
        {
               cmp.set("v.fileLabel",uploadedFiles[0].name);     
        }
                    
                    
                    
        
        cmp.set("v.documentId", docIds);
        cmp.set("v.fileName", fNames);
        
    }

})