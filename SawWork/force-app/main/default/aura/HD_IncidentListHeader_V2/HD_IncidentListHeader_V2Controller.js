({
    doInit : function(cmp, event, helper) {
        var confId = cmp.find("configureid");
        $A.util.addClass(confId,'hideForm');
        $A.util.removeClass(confId,'showForm');
     
    
        var opts2 = [];
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
        
        /*if(window.localStorage.getItem("incType")==null)
        {
             window.localStorage.setItem("incType","Incident");
        }
        
        var elem = $A.util.getElement("Incident")
        elem.checked = "checked";
        */
        var action = cmp.get("c.getListViews");
        action.setParams({
            type : 'Incident'
        }); 
        action.setCallback(this,function(data){
            
            var response = data.getReturnValue();
            
            for(var x in response)
            {
                
                opts2.push({ "class": "optionClass", label: response[x].Name, value: response[x].Id });
            }
            
            
            cmp.find("ListViews").set("v.options", opts2);
            
            if(window.localStorage.getItem("filterId")==null)
            {
                var viewVal = cmp.find("ListViews").get("v.value");
                window.localStorage.setItem("filterId",viewVal);
            }
            
            cmp.find("ListViews").set("v.value",window.localStorage.getItem("filterId"));
            
            if(window.localStorage.getItem("noOfRecords")==null)
            {
                var no_of_records = cmp.find("no_of_records").get("v.value");
                window.localStorage.setItem("noOfRecords",no_of_records);
            }
            
            cmp.find("no_of_records").set("v.value",window.localStorage.getItem("noOfRecords"));
            
           //helper.getIncidentListHelper(cmp,event);
            
            
        });
      
        $A.enqueueAction(action);
        var opts4 = [ 
            { "class": "optionClass", label: "Priority", value: "Priority" },
            { "class": "optionClass", label: "Incident Source", value: "Incident Source" },
            { "class": "optionClass", label: "Client Email", value: "Client Email" },
            { "class": "optionClass", label: "Client Phone", value: "Client Phone" },
            { "class": "optionClass", label: "Client City", value: "Client City" },
            { "class": "optionClass", label: "CC", value: "CC" }
            
        ];
        //cmp.find("Columns").set("v.options", opts4);
        cmp.find("availableFields").set("v.options", opts4);
        //cmp.find("selectedFields").set("v.options", opts3);
        //
        
        
    },
    
    getIncidentListEvent : function(cmp, event, helper) {
        //var selectedItem = event.currentTarget; // Get the target object
        //var index = selectedItem.dataset.record; // Get its value i.e. the index
        // var selectedStore = component.get("v.stores")[index]; 
        //var incident = component.get("v.incidents")[index];
        //var updateinc = $A.get("e.c:createincidentevent"); //component.getEvent("updatecontact");
        //updateinc.setParams({"incident":incident}).fire();
        //console.log('Fired'+incident);
        //console.log('Fired id: '+incident.Id);
        
        var dynamicCmp = cmp.find("InputSelectDynamic");
        var ticketType = dynamicCmp.get("v.value");
        var incList = $A.get("e.c:getIncidentList");
        incList.setParams({"type":ticketType}).fire();
    },
    
    selectinc : function(cmp, event, helper) {
        
        
    },
    
    onViewChange: function(cmp, evt, helper) {
        //cmp.find("pageInput").set("v.value",1);
        cmp.set("v.pageInput","1");
        
        var opts2 = [];
        
        var ticketType = evt.currentTarget.id;
        cmp.set("v.selectedTicketType",ticketType);
        window.localStorage.setItem("incType",ticketType)
        var action2 = cmp.get("c.getListViews");
        action2.setParams({
            type : ticketType
        }); 
        action2.setCallback(this,function(data){
            var response = data.getReturnValue();
            
            for(var x in response)
            {
                
                var filterName = response[x].Name;
                if(filterName.indexOf('SRM')==0)
                {
                    filterName = filterName.substring(filterName.indexOf('SRM')+3);
                }
                opts2.push({ "class": "optionClass", label: filterName, value: response[x].Id });
            }
            cmp.find("ListViews").set("v.options", opts2);
            if(window.localStorage.getItem("filterId")==null)
            {
                var viewVal = cmp.find("ListViews").get("v.value");
                window.localStorage.setItem("filterId",viewVal);
            }
            
            cmp.find("ListViews").set("v.value",window.localStorage.getItem("filterId"));
            helper.getIncidentListHelper(cmp);
            /*var viewCmp = cmp.find("ListViews");
        var viewVal = viewCmp.get("v.value");
        var recCmp = cmp.find("no_of_records");
        var recVal = recCmp.get("v.value");
         console.log("viewVal: "+viewVal);
        var pi = cmp.find("pageInput");
        var pival = pi.get("v.value");*/
                //var action = cmp.get("c.getIncidentList");
                //action.setParams({
                //	noOfRecs : recVal,
                //	filterId : viewVal//,
                //pageNumber : pival
                //});
                
                //action.setCallback(this,function(data){
                //  var response = data.getReturnValue();
                //cmp.set("v.incidents",response);
                //console.log("response"+response);
                //});
                //$A.enqueueAction(action);
            });
        $A.enqueueAction(action2);
    },
    onChange: function(cmp, evt, helper) {
        var searchCmp = cmp.find("searchInput");
        searchCmp.set("v.value",null);
        helper.getIncidentListHelper(cmp,evt);        
    },
    onListViewChange: function(cmp, evt, helper) {
        var searchCmp = cmp.find("searchInput");
        searchCmp.set("v.value",null);
        //cmp.find("pageInput").set("v.value",1);
        cmp.set("v.pageInput","1");
        var viewVal = cmp.find("ListViews").get("v.value");
        window.localStorage.setItem("filterId",viewVal);
        helper.getIncidentListHelper(cmp,evt);        
    },
    onRecordsChange: function(cmp, evt, helper) {
        var searchCmp = cmp.find("searchInput");
        searchCmp.set("v.value",null);
        //cmp.find("pageInput").set("v.value",1);
        cmp.set("v.pageInput","1");
        window.localStorage.setItem("noOfRecords",cmp.find("no_of_records").get("v.value"));
        helper.getIncidentListHelper(cmp,evt);        
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
            helper.getIncidentListHelper(cmp,evt);
        }
        
    },
    onSearchTicket: function(cmp, evt, helper) {
        var searchCmp = cmp.find("searchInput");
        var searchVal = searchCmp.get("v.value");
        var re = new RegExp("^((IN|SR)?[0-9]{1,8})$");
        
        if(searchVal && !searchVal.match(re)){
            searchCmp.set("v.errors", [{message:"Enter a valid ticket number."}]);
        }
        else{
            searchCmp.set("v.errors",null);
            helper.getIncidentListHelper(cmp,evt);  
        }
        
    },
    onSortEvent: function(cmp, evt, helper) {
        
        cmp.set("v.sortDirection", evt.getParam("sortDirection"));
        cmp.set("v.sortBy", evt.getParam("sortBy"));
        
        helper.getIncidentListHelper(cmp,evt);
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
    
    onColumnSelect: function(cmp, evt) {
        var dynamicCmp = cmp.find("Columns");
        var cols = dynamicCmp.get("v.value");
        
        var incList = $A.get("e.c:displayColumns");
        incList.setParams({"columnList":cols}).fire();
    },
    showConfigureWindow: function(component, event){
        
        
        var confId = component.find("configureid");
        if (confId != null)
        {
            $A.util.removeClass(confId,'hideForm');
            $A.util.addClass(confId,'showForm');
            //formId1.style.display = "none"; 
            //var sec = document.getElementsByTagName('section')[0];
            //sec.style.top = "0px";
            // console.log(" --> "+sec);
        }
    },
    hideConfigureWindow: function(component, event, helper) {
        var confId = component.find("configureid");
        if (confId != null)
        {
            $A.util.removeClass(confId,'showForm');
            $A.util.addClass(confId,'hideForm');
            
        }
    },
    addColumns: function(component, event, helper){
        var availableCmp = component.find("availableFields");
        var availableCols = availableCmp.get("v.value");
        var res = availableCols.split(";");
        var selectedCmp = component.find("selectedFields");
        var selectedCols = selectedCmp.get("v.options");
        
        for(let key in res){
            selectedCols.push({"class": "optionClass", label: res[key], value: res[key]} );
        }
        
        selectedCmp.set("v.options",selectedCols);
    },
    
    toggle : function(component, event, helper) {
        
        var menu = component.find("menulist");
        $A.util.toggleClass(menu, "slds-is-open"); 
    },
    
    
    onClear : function(component, event, helper) {
        
        var searchCmp = component.find("searchInput")
        searchCmp.set("v.value",null)
        searchCmp.set("v.errors",null)
        helper.getIncidentListHelper(component,event);
        
    },
    showCreateForm : function(component,event,helper){ 
        
        component.set("v.renderCreateForm",true);
        
        
    },
    
    hideCreateForm: function(component,event,helper){ 
        
        component.set("v.renderCreateForm",false);
    },
    
    showSRCreateForm : function(component,event,helper){ 
        component.set("v.renderCreateSRForm",true);
        /*
        var isSafari = /constructor/i.test(window.HTMLElement) || (function (p) { return p.toString() === "[object SafariRemoteNotification]"; })(!window['safari'] || safari.pushNotification);
        var newUrl = "/one/one.app?source=aloha#/n/Service_Request";
        if(isSafari)
        {
            var windowReference = window.open();
            windowReference.location = newUrl;
        }
        else{
            var win = window.open(newUrl,'_blank');
        	if(win != null){
            	win.focus();                      
        	}
        }
        */
    },
    hideCreateSRForm: function(component,event,helper){ 
        
        component.set("v.renderCreateSRForm",false);
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
        var showCustomColFormEvent = $A.get("e.c:hd_renderCustomizeFormEvent");
        showCustomColFormEvent.setParams({"renderCustomizeForm":true}).fire();
    },

    goToEditListView: function(component,event,helper){

        var filterID = component.get("v.filterId");
        var url = "/ui/list/FilterEditPage?id=" + encodeURIComponent(filterID);
        window.open(url,'_blank');

    }
})