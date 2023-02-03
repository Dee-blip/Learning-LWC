({
    applyFilter : function(component,event, filterApi) {
   
        var current_filter = component.get("v.current_filter");
        var records = component.get("v.records");
        
        //if provided filterApi use it to change the state of the filter
        if(filterApi){
            var params =  event.getParam('value')||event.getParam('values');
            current_filter[filterApi] = params;
            component.set("v.current_filter",current_filter);
        }
        
        var filterObject = {};
        
        for (var property in current_filter) {
            filterObject[property] = new Set(current_filter[property]);      
        }
        
        //console.log("records after filter");
        //console.log(component.get("v.records"));
        records = records.filter((item)=> {
            return (filterObject.HD_Sponsor_Name__c.size==0 || filterObject.HD_Sponsor_Name__c.has(item.HD_Sponsor_Name__c) )&&
            (filterObject.HD_Facility_Location__c.size==0 || filterObject.HD_Facility_Location__c.has(item.HD_Facility_Location__c)) &&
            (filterObject.HD_Change_Status__c.size==0 || filterObject.HD_Change_Status__c.has(item.HD_Change_Status__c))&&
            (filterObject.HD_Owner_Name__c.size==0 || filterObject.HD_Owner_Name__c.has(item.HD_Owner_Name__c))&&
            (filterObject.BMCServiceDesk__Change_Category__c.size==0 || filterObject.BMCServiceDesk__Change_Category__c.has(item.BMCServiceDesk__Change_Category__c))
           //BMCServiceDesk__Change_Category__c
        });
        //alert("inside fun");
        //component.set("v.records",records);
        component.getEvent("fiteredChangeList").setParams({"records":records}).fire();
        //hide unhide clearoptions
        
        this.showClearOptions(component,event);
        
        
        
    },
    
    clearFilters : function(component,event,helper){
        var records = component.get("v.records");
        component.getEvent("fiteredChangeList").setParams({"records":records}).fire();
    },
    
    buildOptionValues : function(component,event,helper){
        
        var records = component.get("v.records")
        console.log("New records to filter");
        console.log(records);
        var filterApi = new Set(['rating','HD_Sponsor_Name__c','HD_Facility_Location__c','HD_Change_Status__c','HD_Owner_Name__c','BMCServiceDesk__Change_Category__c']);
        
        var nameOptions = new Set();  
        var megaOptions = {};
        filterApi.forEach((item)=> {megaOptions[item] = new Set();});
        records.forEach((item)=>{
        	nameOptions.add(item.name);
            filterApi.forEach((api)=>{
            	megaOptions[api].add(item[api])                     
         	});
     	});                         
       	var options = [];
       	nameOptions.forEach((item)=>{
       		options.push({label:item,value:item});
    	});  
    	component.set("v.options",options);
    	var apiOptions =[];  
    
        for (var property in megaOptions) {
        	if (megaOptions.hasOwnProperty(property)) {
        		var opts = Array.from(megaOptions[property]);
        		var temp = [];
        		opts.forEach((item)=>{ temp.push({'label':item,'value':item}); });
				apiOptions.push(temp)
			}
		}


        component.set("v.megaOptions",apiOptions);
        component.set("v.options1",apiOptions[1]);
        component.set("v.options2",apiOptions[2]);
        component.set("v.options3",apiOptions[3]);
		component.set("v.options4",apiOptions[4]);
		component.set("v.options5",apiOptions[5]);
		

	},
        
        initCurrentFilter : function(component,event){
            var cF = component.get("v.current_filter");
        	//initializing the filter object with api sets
            cF.HD_Sponsor_Name__c = new Set();
            cF.HD_Facility_Location__c = new Set();
            cF.HD_Change_Status__c = new Set();
        	cF.BMCServiceDesk__Initiator_ID__c = new Set();
        	cF.HD_Owner_Name__c  = new Set(); 
            cF.BMCServiceDesk__Change_Category__c  = new Set(); 
            component.set("v.current_filter",cF);
        },
        
        showClearOptions : function(component,event) {
            var current_filter = component.get("v.current_filter");
            var show = false;
            for (var property in current_filter) {
                console.log(`current filter ${current_filter[property]}`)
                console.log(current_filter[property].length)
                if(current_filter[property].length>0){
                    show = true;
                    component.set("v.show",true);
                    return;
                }
                    
            }
            component.set("v.show",false);
        },
        
        emitFilterConfig : function(component,event, filterApi) {
            var compEvent = component.getEvent("filterConfigChanged");
            compEvent.setParams({"filterId":component.get("v.currentFilterId"),"applyFilter":component.get("v.applyListViewFilter")}).fire();            
          
            //console.log(`"filterId":${component.get("v.currentFilterId")},"applyFilter":${(component.get("v.applyListViewFilter")}`);
        }
            

})