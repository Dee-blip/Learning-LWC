({
	existingSHMapInitHandler : function(component, event, helper) 
    {
        console.log('Entering existingSHMapInitHandler of component SC_SOCC_Situation_to_Handler_Mapping');
        
        //Setting Handler to null
        component.set('v.selectedHandler','');
        component.set('v.HandlerOptions','');
        
		let recordId = component.get('v.recordId');
        var action = component.get("c.getSituationToHandlerMappings");
        action.setParams({
            "pdId":recordId
        });
        action.setCallback(this,function(response){
            if(response.getState()==="SUCCESS")
            {
                
                let result = response.getReturnValue();
                console.log('----The result'+result)
                Object.keys(result).forEach(key=>{
                   result[key].CreatedDate = result[key].CreatedDate.split('T')[0];
                });
                    component.set('v.ExistingSHMap',result);
                    this.sortData(component,"Situation__r.Name",helper);
                    //var data = component.get('v.ExistingSHMap');
                    //console.log('----The result is '+JSON.stringify(data));
                console.table(result);
                
                //Set varibale for avaoiding mapping of one situation to multiple handlers
                let existingSituationArray = [];
                Object.keys(result).forEach(key=>{
                    let varSituation = result[key].Situation__c;
                    existingSituationArray.push(varSituation);
                });
                
                component.set('v.SituationArray',existingSituationArray);
               
                
                //Set Variable to avoid duplication
                let duplicatePreventionArray = [];
                Object.keys(result).forEach(key=>{
                   let concatvar =  result[key].Situation__c+result[key].Handler__c+result[key].Policy_Domain__c;
                   duplicatePreventionArray.push(concatvar);
                });
                
                component.set('v.SHMapExistingArray',duplicatePreventionArray);
                
            }
            
        });
        $A.enqueueAction(action);
        console.log('Exiting existingSHMapInitHandler of component SC_SOCC_Situation_to_Handler_Mapping');
        
	},
    getRelevantSituationsHandler:function(component, event, helper)
    {
        console.log('Entering getRelevantSituationsHandler of component SC_SOCC_Situation_to_Handler_Mapping');
        let recordId = component.get('v.recordId');
        var action = component.get("c.getSituationsforPD");
        action.setParams({
            "pdId":recordId
        });
        action.setCallback(this,function(response){
            if(response.getState()==="SUCCESS")
            {   //Create an empty object
                let empObj ={};
                let result = response.getReturnValue();
                result.unshift(empObj);
                console.log('situation values'+result);
                console.table(result);
                component.set('v.situationOptions',result);
                
                
                console.log('situationOptions'+component.get('v.situationOptions'));
                component.set('v.isdisabled',true);
                window.setTimeout(
                $A.getCallback( function() {
                    // Now set our preferred value
                    component.find("SituationSelect").set("v.value", result[0]);
                }));
                
            }
            
        });
        $A.enqueueAction(action);
                
        console.log('Exiting getRelevantSituationsHandler of component SC_SOCC_Situation_to_Handler_Mapping');
    },
    componentToastHandler:function(component,title,message,type)
    {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message":message,
            "type":type
        });
        toastEvent.fire();   
    },
    
    sortData : function(component,fieldName){
        
        var currentDir;
        var sortDirection;
        var data;
        var key;
        var reverse;
        var splits;
        var parentObj;
        var childObj;
        currentDir = component.get("v.arrowDirection");
        console.log('Calling sorting');
        if (currentDir === 'arrowdown') {
         // set the arrowDirection attribute for conditionally rendred arrow sign 
         component.set("v.arrowDirection", 'arrowup');
         // set the isAsc flag to true for sort in Assending order.  
         component.set("v.isAsc", true);
         sortDirection = 'asc';
      } else {
         component.set("v.arrowDirection", 'arrowdown');
         component.set("v.isAsc", false);
         sortDirection = 'desc';
      }
        component.set("v.selectedTabsoft",fieldName);
        data = component.get('v.ExistingSHMap');
        //function to return the value stored in the field
        key = function(a) { 
            //Console.log('Field name '+fieldName);
            if(fieldName.includes('.')){
            //    Console.log('test');
                splits = fieldName.split(".");
                //Console.log('splits obj'+splits);
                parentObj=splits[0];
                childObj=splits[1];
                //Console.log('parent obj'+parentObj);
                //Console.log('child obj'+childObj);
                return a[parentObj][childObj]; 
                //return a[fieldName];
            }
            

                return a[fieldName];
        }
        reverse = sortDirection === 'asc' ? 1: -1;
        
        // to handel number/currency type fields 
        /*if(fieldName == 'NumberOfEmployees'){ 
            data.sort(function(a,b){
                var a = key(a) ? key(a) : '';
                var b = key(b) ? key(b) : '';
                return reverse * ((a>b) - (b>a));
            }); 
        }
        else{// to handel text type fields 
            data.sort(function(a,b){ 
                var a = key(a) ? key(a).toLowerCase() : '';//To handle null values , uppercase records during sorting
                console.log('the a data is'+a);
                var b = key(b) ? key(b).toLowerCase() : '';
                console.log('the b data is'+b);
                return reverse * ((a>b) - (b>a));
            });    
        }*/
        
        data.sort(function(a,b){ 
                a = key(a) ? key(a).toLowerCase() : '';//To handle null values , uppercase records during sorting
                console.log('the a data is'+a);
                b = key(b) ? key(b).toLowerCase() : '';
                console.log('the b data is'+b);
                return reverse * ((a>b) - (b>a));
            }); 
        
        //set sorted data to accountData attribute
        console.log('----The data is '+JSON.stringify(data));
        component.set('v.ExistingSHMap',data);
    }
})