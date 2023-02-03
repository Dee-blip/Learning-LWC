({
	validateServiceOutageForm: function(component) {
        var errorMessage = '';
        var elems = component.find('soField');
        for( var i = 0; i < elems.length; i++){
            let elem = elems[i];
        console.log("ELE "+elem);
           if(elem.hasAttribute('required') && (elem.value == '' || elem.value == null) ){
             errorMessage = 'Required field cannot be blank ';
              break;
           }
        }   
        var startdate = component.find('startdatetime').get('v.value');
        var enddate = component.find('enddatetime').get('v.value');
            
            if(startdate > enddate){
                errorMessage = "Start datetime can't be greater end date time.";
            }
            if(errorMessage != ''){
             component.set("v.newServiceOutageError", errorMessage);  
            }
 
      
	},
    
    saveSO: function(component,event,helper){
            component.set("v.newServiceOutageError", '');  
            
            helper.populateSO(component,helper);
       
            if(component.get("v.newServiceOutageError") != ''){
            return;
            } 
           component.set("v.isSpinnerEnabled",true);
           var action = component.get('c.saveSO');
           action.setParams({ pso: component.get("v.objectParams") });
           var btn = event.getSource();
           btn.set('v.disabled',true);
           action.setCallback(this,function(data){
           var state=data.getState();
           var result=data.getReturnValue();   
           var compEvent = component.getEvent("closeModalEvt"); 
               console.log(" state -- "+state+" -- "+result.Id);
            if(state==="SUCCESS" && result.Id != ''){
                  compEvent.setParams({"eventtype": 'Saved', "message":'Service Outage created successfully'});
                   
                }
                else{
                    
                    compEvent.setParams({"eventtype": 'Error', message:'Unable to create service outage.'});
                        var errors = data.getError();
                        HD_Error_Logger.createLogger(component, event, helper, errors[0].message, errors[0].message, false);
         
                }
                   
                   compEvent.fire();
                btn.set('v.disabled',false);
               component.set("v.isSpinnerEnabled",false);
           });
        $A.enqueueAction(action); 
    },
            
    checkMandatoryfileds: function(component, cmparr){
       var isValid =  true;
        for(var i = 0; i< cmparr.length; i++){
            var cmp = cmparr[i];
            
            console.log(" VALL "+cmp.get("v.value"));
            if(cmp.get("v.value") == null || cmp.get("v.value").trim() == ''){
                 component.set("v.newServiceOutageError", 'Mandatory fields can not be blank. ');
                
            }
        }
    },
    
    populateSO: function(component,helper){
               
          
        
           var soname = component.find("soname");
           
           var descr =  component.find("description");
           var sdate =  component.find('startdatetime');
           var edate =  component.find('enddatetime');
           var isValid = true;
           var cmpArr = [soname,descr,sdate,edate];
           helper.checkMandatoryfileds(component,cmpArr);
        
          if (sdate.get('v.value') > edate.get('v.value'))
          {
              var msg = component.get("v.newServiceOutageError");
              msg += ' Scheduled end datetime should be greater then Scheduled start datetime.'
              component.set("v.newServiceOutageError",msg );
          }
        
        if(component.get("v.newServiceOutageError") != ''){
            return;
        }
        
        var params = {};
        params["Name"] = soname.get("v.value");
        params["BMCServiceDesk__Description__c"] = descr.get("v.value");

                 params["BMCServiceDesk__Start_Date__c"] = sdate.get('v.value');
                 params["BMCServiceDesk__End_Date__c"] = edate.get('v.value');
                
                params["Sub_Services_Affected__c"] = component.find("subservices").get("v.value");
                params["Service_Outage_Type__c"] = component.find("serviceoutagetype").get("v.value");
                params["BMCServiceDesk__Blackout__c"] = component.find("blackoutperiod").get('v.checked');
                params["BMCServiceDesk__Display_in_Self_Service__c"] = component.find("displayinselfservice").get('v.checked');
                params["BMCServiceDesk__Inactive__c"] = component.find("soinactive").get('v.checked');
                
              var multiselect = document.getElementById("service_multiselect");
              var servicevalues = [];
            for ( var i = 0; i < multiselect.selectedOptions.length; i++) {
             
                servicevalues.push(multiselect.selectedOptions[i].value);
            }
             params["Affected_Services_Picklist__c"] = servicevalues.join(";");
             component.set("v.objectParams",JSON.stringify(params));
        
        
        },
    
    getMatchingCMRList: function(component){
        
            var appEvent = $A.get("e.c:HD_CMR_EventOutageMatchingCMRList");
            //console.log(' INSIDE FORM '+component.find('outagecondition').get('v.value'));
              var multiselect = document.getElementById("service_multiselect");
              var servicevalues = [];
            for ( var i = 0; i < multiselect.selectedOptions.length; i++) {
                 
                servicevalues.push(multiselect.selectedOptions[i].value);
            }
              
        
        appEvent.setParams({
                e_startdate: component.find('startdatetime').get('v.value'),
                e_enddate: component.find('enddatetime').get('v.value'),
                e_services: servicevalues.join(";"),
                e_subservices: component.find('subservices').get('v.value'),
                e_serviceoutage: null
      		});
        
        appEvent.fire();
        console.log("FIRED")
    
    },
    
    populateServiceOptions: function(component,event,helper){
        console.log(" KLKLK");
        var action = component.get('c.getOptionlist');
          
           action.setCallback(this,function(data){
           var state=data.getState();
           var result=data.getReturnValue();   
          
               console.log(" RES = "+result);
               if(state==="SUCCESS" ){
                  component.set("v.serviceoptions", result);
               }else if (state === "ERROR") {
                var errors = data.getError();
                HD_Error_Logger.createLogger(component, event, helper, errors[0].message, errors[0].message, false);
               }
               component.set("v.isSpinnerEnabled",false);
           });
        $A.enqueueAction(action); 
    },
    
    clearserviceselection: function(component){
        document.getElementById("service_multiselect").selectedIndex = -1;
    },
    
    getMultiselectServices: function(){
        
    }
})