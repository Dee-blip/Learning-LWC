({
	doInit : function(cmp, event, helper) {
       var opts3 = [
                     { "class": "optionClass", label: "10", value: "10" },
                     { "class": "optionClass", label: "20", value: "20" },
                     { "class": "optionClass", label: "40", value: "40" , selected: "true"},
                     { "class": "optionClass", label: "60", value: "60" },
                     { "class": "optionClass", label: "70", value: "70" },
                     { "class": "optionClass", label: "80", value: "80" },
                     { "class": "optionClass", label: "100", value: "100" },
                     { "class": "optionClass", label: "200", value: "200" }
               ];
        cmp.find("no_of_records").set("v.options", opts3);
  		cmp.find("prevPage").set("v.disabled","true");
        
	},
    showCreateForm : function(component,event,helper){
        console.log("button clicked")
        var createRecordEvent = $A.get("e.force:createRecord");
        createRecordEvent.setParams({
            "entityApiName": "BMCServiceDesk__Change_Request__c",
            'defaultFieldValues': {
                'HD_Change_Status__c':'OPENED'
            }
		});
        createRecordEvent.fire();
    },
    changeView : function(cmp,event,helper){
		
		console.log("cal view fired")
        var cmpEvent = cmp.getEvent("HD_CMR_View_Change");
        cmpEvent.setParams({
       		"current_view" : "cal" });
        cmpEvent.fire();
        
        
    },
       
    onChange: function(cmp, evt, helper) {
        var searchCmp = cmp.find("searchInput");
        searchCmp.set("v.value",null);
        helper.getRecordListHelper(cmp,evt,helper);        
   	},
    
    onListViewChange: function(cmp, evt, helper) {
        var searchCmp = cmp.find("searchInput");
        searchCmp.set("v.value",null);
       	cmp.set("v.pageInput","1");
        var viewVal = cmp.find("ListViews").get("v.value");
        localStorage.setItem("filterId",viewVal);
        helper.getRecordListHelper(cmp,evt,helper);        
   	},
    
    onRecordsChange: function(cmp, evt, helper) {
        var searchCmp = cmp.find("searchInput");
        searchCmp.set("v.value",null);
        cmp.set("v.pageInput","1");
        localStorage.setItem("noOfRecords",cmp.find("no_of_records").get("v.value"));
        helper.getRecordListHelper(cmp,evt,helper);        
    },
    
    onPageInputChange: function(cmp, evt, helper) {
        
            var searchCmp = cmp.find("searchInput");
            var searchVal = searchCmp.set("v.value",null);
            var pageCmp = cmp.find("pageInput");
            var pageNo = pageCmp.get("v.value").trim();
            var totalPages = cmp.get("v.noOfPages");
        	if(isNaN(pageNo)|| !pageNo)
            {
               cmp.set("v.warnings","Enter a vaild page number");
               return;
            }
        	
        	if(parseInt(pageNo) == 1)
        	{
            	cmp.find("prevPage").set("v.disabled","true");
        	}
            else
            {
                cmp.find("prevPage").set("v.disabled","false");
            }
        	if(totalPages == parseInt(pageNo))
        	{
            	cmp.find("nextPage").set("v.disabled","true");
        	}
            else
            {
                cmp.find("nextPage").set("v.disabled","false");
            }
            if(parseInt(pageNo)<1 || parseInt(pageNo)>totalPages)
            {
                //pageCmp.set("v.errors",[{message:"Enter a valid ticket number."}]);
                cmp.set("v.warnings","Enter the page number between 1 and "+totalPages);
    				

            }
            else
            {
                cmp.set("v.warnings",null);
                helper.getRecordListHelper(cmp,evt,helper);
            }
                    
        },
    onSearchTicket: function(cmp, evt, helper) {
        var searchCmp = cmp.find("searchInput");
        var searchVal = searchCmp.get("v.value");
        var re = new RegExp("^((CR)?[0-9]{1,8})$");
        
        if(searchVal && !searchVal.match(re)){
           searchCmp.set("v.errors", [{message:"Enter a valid ticket number."}]);
        }
        else{
         	searchCmp.set("v.errors",null);
         	helper.getRecordListHelper(cmp,evt,helper);  
        }
              
      },
    
    handleListViewOptions: function(cmp, evt, helper) {
        
		
        var opts2 = [];
        for(var x in cmp.get("v.listViewOptions")){
        	opts2.push({ "class": "optionClass", label: cmp.get("v.listViewOptions")[x].Name, value: cmp.get("v.listViewOptions")[x].Id });
        }
        cmp.find("ListViews").set("v.options", opts2);
        //cmp.find("ListViews").set("v.options", opts2);

                if(localStorage.getItem("filterId")==null)
                {
                    var viewVal = cmp.find("ListViews").get("v.value");
                    localStorage.setItem("filterId",viewVal);
                }

 				cmp.find("ListViews").set("v.value",localStorage.getItem("filterId"));
                
                if(localStorage.getItem("noOfRecords")==null)
                {
                    var no_of_records = cmp.find("no_of_records").get("v.value");
                    localStorage.setItem("noOfRecords",no_of_records);
                }

 				cmp.find("no_of_records").set("v.value",localStorage.getItem("noOfRecords"));
				
                helper.getRecordListHelper(cmp,evt,helper);
    },
    
    
    
    onSortEvent: function(cmp, evt, helper) {
        
        cmp.set("v.sortDirection", evt.getParam("sortDirection"));
        cmp.set("v.sortBy", evt.getParam("sortBy"));
        
        helper.getRecordListHelper(cmp,evt,helper);
    },
    onPagesEvent: function(cmp, evt, helper) {
        
        cmp.set("v.noOfPages", evt.getParam("noOfPages")>0?evt.getParam("noOfPages"):1);
        cmp.set("v.noOfRecords", evt.getParam("noOfRecords"));
        
    },
    onNoOfPagesChange: function(cmp, evt, helper) {
        
        if( cmp.get("v.noOfPages") == 1)
        {
            cmp.find("nextPage").set("v.disabled","true");
        }
        else
        {
            cmp.find("nextPage").set("v.disabled","false");
        }
        
    },
    
    
    
    toggle : function(component, event, helper) {
        var menu = component.find("menulist");
        $A.util.toggleClass(menu, "slds-is-open"); 
    },
    
    onClear : function(component, event, helper) {
        var searchCmp = component.find("searchInput")
        searchCmp.set("v.value",null)
        searchCmp.set("v.errors",null)
        helper.getRecordListHelper(component,event,helper);   
    },
    
    nextPage : function(component,event,helper){
    	var searchCmp = component.find("searchInput");
        var searchVal = searchCmp.set("v.value",null);
 		var pageNumCmp = component.find("pageInput");
        var pageNum = pageNumCmp.get("v.value");
        var totalPages = component.get("v.noOfPages");
        if(totalPages>parseInt(pageNum))
        {	
       		component.set("v.pageInput",(parseInt(component.get("v.pageInput"))+1).toString());
        }
     },
    
    prevPage : function(component,event,helper){
        var searchCmp = component.find("searchInput");
        var searchVal = searchCmp.set("v.value",null);
        var pageNumCmp = component.find("pageInput");
        var pageNum = pageNumCmp.get("v.value");
        if(parseInt(pageNum)>1)
        {
			component.set("v.pageInput",(parseInt(component.get("v.pageInput"))-1).toString());
        }
     },
    
    showCustomizeColumnsForm : function(component, event, helper){
		 var renderFormEvent = component.getEvent("renderCustomizeForm");
        renderFormEvent.setParams({"renderCustomizeForm":true}).fire();
        
        //var showCustomColFormEvent = $A.get("e.c:hd_renderCustomizeFormEvent");
       // showCustomColFormEvent.setParams({"renderCustomizeForm":true}).fire();
    },

    goToEditListView: function(component,event,helper){

        var filterID = component.get("v.filterId");
        var url = "/ui/list/FilterEditPage?id=" + encodeURIComponent(filterID);
        window.open(url,'_blank');

    }
})