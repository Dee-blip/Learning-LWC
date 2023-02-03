({
    initRec : function(component, event, helper) {
        	
        	helper.buildOptionValues(component,event);
        	helper.initCurrentFilter(component,event)
			
         
	},
        
    reInit : function(component, event, helper) {
       
        helper.applyFilter(component,event);
        helper.buildOptionValues(component,event);
        
    },
    
    handleChange: function(component, event, helper) {
        console.log(event.getParam('value'));
        var filterId = event.getParam('value');
        component.set("v.currentFilterId",filterId);
        helper.emitFilterConfig(component,event);
    },
    
    handleApplyListView: function(component, event, helper) {
        console.log(' TEST -'+component.get("v.applyListViewFilter"));
        component.set("v.applyListViewFilter", component.get("v.applyListViewFilter")?false:true);
        console.log(' TEST 1 -'+component.get("v.applyListViewFilter"));
        helper.emitFilterConfig(component,event);
    },
   
    //handle HD_Sponsor_Name__c
    handleChange1 : function(component, event, helper) {
        helper.applyFilter(component,event,'HD_Sponsor_Name__c');
    },
    
    //handle HD_Facility_Location__c
    handleChange2 : function(component, event, helper) {
   		helper.applyFilter(component,event,'HD_Facility_Location__c');
    },
    
    //HD_Change_Status__c
    handleChange3 : function(component, event, helper) {
    	helper.applyFilter(component,event,'HD_Change_Status__c');
 	},
    handleChange4 : function(component, event, helper) {
    	helper.applyFilter(component,event,'HD_Owner_Name__c');
 	},
    handleChange5 : function(component, event, helper) {
    	helper.applyFilter(component,event,'BMCServiceDesk__Change_Category__c');
 	},
    clearFilters : function(component, event, helper) {
        helper.initCurrentFilter(component,event)
        helper.clearFilters(component,event);
        
        var cmp1 = component.find("cComp1");
        var cmp2 = component.find("cComp2");
        var cmp3 = component.find("cComp3");
        var cmp4 = component.find("cComp4");
        var cmp5 = component.find("cComp5");
        cmp1.reset();
        cmp2.reset();
        cmp3.reset();
        cmp4.reset();
        cmp5.reset();
        component.set("v.show",false)
        
    }
    
    
    
})