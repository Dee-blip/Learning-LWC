({
    afterScriptsLoaded: function(cmp,evt,helper){
        var events = cmp.get("v.Changes");
        var header = document.getElementById("oneHeader");        
 
        if (header != null)
        {
            header.style.display = "none"; 
            var sec = document.getElementsByTagName('section')[0];
            sec.style.top = "0px";
        }
        
        if(!events.length)
        {
            helper.fetchEvents(cmp,evt,helper);
        }
    },
    
    changeView : function(cmp,evt,helper){
      	var cmpEvent = cmp.getEvent("c.HD_CMR_View_Change");
        cmpEvent.setParams({
            current_view:"cal" 
        }).fire();
    },
   
    
    hideHeader : function(cmp,evt,helper){
        var header = document.getElementById("oneHeader");        
 
        if (header != null)
        {
            header.style.display = "none"; 
            var sec = document.getElementsByTagName('section')[0];
            sec.style.top = "0px";
        }
       
    },
    
    doInit: function(cmp,evt,helper){
     	helper.setDates(cmp,evt,helper);
        helper.fetchEvents(cmp,evt,helper);
        helper.setUserType(cmp,evt,helper);
        helper.getListViewOptions(cmp,evt,helper);

    },
    
    onViewChange: function(cmp,evt,helper){
       var selected = cmp.find("SelectView").get("v.value");
        cmp.set("v.flId",selected);
        helper.getViewsRecords(cmp,evt,helper,selected);
    },
    
    showListView: function(cmp,evt,helper){
        	
      		
            var cmpEvent = cmp.getEvent("HD_CMR_View_Change");
        	cmpEvent.setParams({
       		"current_view" : "list" });
        	cmpEvent.fire();
            helper.inverseViewIcon(cmp,'list');
            $A.util.removeClass(cmp.find('a_lst_container'), "slds-hide");
            $A.util.addClass(cmp.find('a_cal_container'), "slds-hide");
        
    },
    
     showCalView: function(cmp,evt,helper){
       
            cmp.set("v.isCalView", true);
            helper.inverseViewIcon(cmp,'');
            $A.util.addClass(cmp.find('a_lst_container'), "slds-hide");
            $A.util.removeClass(cmp.find('a_cal_container'), "slds-hide");
         
     },    
    
    showCreateForm: function(component){
      
    var createRecordEvent = $A.get("e.force:createRecord");
    createRecordEvent.setParams({
        "entityApiName": "BMCServiceDesk__Change_Request__c",
        'defaultFieldValues': {
        'HD_Change_Status__c':'OPENED',
            
   },
    });
    createRecordEvent.fire();
    },
    
    updateQuickCMR : function(cmp,evt,helper){
        
        var changecmr = evt.getParam("changecmr");
        var show = evt.getParam("showQuick");
        if (show == false){
            cmp.set("v.showQuickView", false);
            
            
            
        }else{
        cmp.set("v.change",changecmr);
        cmp.set("v.showQuickView", true);
        }
    },
    hideQuickView : function(cmp,evt,helper){
        cmp.set("v.showQuickView", false);
        
    },
    quickPreviewState : function(cmp,evt,helper){
       	var dateCmp = cmp.find('dateId');
        if(cmp.get("v.showQuickView"))
        {
            
        $A.util.addClass(dateCmp, 'slds-hide');

        }
        else
        {
            $A.util.removeClass(dateCmp, 'slds-hide');
        }
        
    },
    
    navigateToDate: function(cmp,evt,helper){
        if(evt.getSource().checkValidity() && evt.getSource().get("v.value"))
        {
            
            helper.navigateToDateHelper(cmp,evt,helper);
        }
		        
    },
    
    handleComponentEvent: function(component, event, helper){
        if(event.getParam("eventtype") == "fetchEvent" ){
            helper.compareDateRange(component,event,helper); 
        }
    },
    
    openServiceOutage : function(component, event, helper) {
		 window.open('Service_Outage_Listing');
	},
    
    applyFilter : function(c,e,helper){
       
        var records = e.getParam('records');
		helper.filter(c,records);
    },
    
    loadListview : function(cmp,evt,helper){
     
        var showFilter  = evt.getParam('applyFilter');
        var flid  = evt.getParam('filterId');
        cmp.set("v.isListView", showFilter);
        
        if(showFilter == true && flid != ''){
         helper.getViewsRecords(cmp,evt,helper,flid);
        }
        if(showFilter == false){
            helper.fetchEvents(cmp,evt,helper);
        }        
               
       
    }
})