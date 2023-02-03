({
    doInit : function(cmp, event, helper) {
        
        //
     
        helper.getIncidentRecords(cmp,event);
        var action = cmp.get("c.getUserColumns");
        
        action.setCallback(this,function(data){
            var delay=1; //1 ms
            setTimeout(function() {
                //alert("timeout fired");
                helper.adjustTableHeight(cmp);  
                helper.adjustTableWidth(cmp);
            }, delay);
            var response = data.getReturnValue();
            var values = [];
            var keys = [];
            for(var i in response)
            {
                values.push(response[i]);
                keys.push(i);
            }
            
            cmp.set("v.colLabels", keys);
            cmp.set("v.colApis",values);
            
            
        });
        
        $A.enqueueAction(action);
        
    },
    handleCols: function(cmp, evt, helper) {
        cmp.set("v.colLabels",evt.getParam("finalColumnsLabel"));
        cmp.set("v.colApis",evt.getParam("finalColumnsAPI"));
        var delay=1; //1 ms
        setTimeout(function() {
            //alert("timeout fired");
            helper.adjustTableHeight(cmp);  
            helper.adjustTableWidth(cmp);
        }, delay);
        
    },
    removeTilt: function(cmp, evt, helper) {
        var labels = cmp.get("v.colLabels");
        var newlabels = [];
        for(var x in labels)
        {
            if(labels[x].indexOf('~')==labels[x].length-1)
            {
                newlabels.push(labels[x].slice(0,-1));
            }
            else{
                newlabels.push(labels[x]);            
            }
            
        }
        cmp.set("v.colLabelsDisplay",newlabels);
    },
    
    adjust: function (cmp, event, helper){
        helper.adjustTableHeight(cmp);  
        helper.adjustTableWidth(cmp);
    },
    
    navToRecord : function (component, event, helper) {
        event.stopPropagation();
        var navEvt = $A.get("e.force:navigateToSObject");
        var recordId = event.currentTarget.dataset.id;
        navEvt.setParams({
            "recordId": recordId
        });
        navEvt.fire();
    },
    onChange: function(cmp, evt, helper) {
        
        helper.getIncidentRecords(cmp,evt);
        
    },
    
    gotoList : function (component, event, helper) {
        var action = component.get("c.getListViews");
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var listviews = response.getReturnValue();
                var navEvent = $A.get("e.force:navigateToList");
                navEvent.setParams({
                    "listViewId": listviews.Id,
                    "listViewName": null,
                    "scope": "BMCServiceDesk__Incident__c"
                });
                navEvent.fire();
            }
        });
        $A.enqueueAction(action);
    },
    onSelect: function(component, event, helper)
    {
        var selectedItem = event.currentTarget; // Get the target object
        var index = selectedItem.dataset.record; // Get its value i.e. the index
        var incident = component.get("v.incidents")[index];
        component.set("v.previewFlag","true");
        component.set("v.selectedIncident",incident);
    },
    onClick : function(component,event){
        event.stopPropagation();
    },
    updateColumns:function(component,event){
        var eventparam = event.getParam("columnList");
        component.set("v.customColumns",eventparam);
    },
    
    hidePreview: function (cmp, event) {
        cmp.set("v.previewFlag","false");
    }, 
    calculateWidth : function(component, event, helper) {
        var childObj = event.target
        var parObj = childObj.parentNode;
        var count = 1;
        while(parObj.tagName != 'TH') {
            parObj = parObj.parentNode;
            count++;
        }
        var mouseStart=event.clientX; 
        component.set("v.mouseStart",mouseStart);
        component.set("v.oldWidth",parObj.offsetWidth);
    },
    
    setNewWidth : function(component, event, helper) {
        var childObj = event.target
        var parObj = childObj.parentNode;
        var count = 1;
        while(parObj.tagName != 'TH') {
            parObj = parObj.parentNode;
            count++;
        }
        var mouseStart = component.get("v.mouseStart");
        var oldWidth = component.get("v.oldWidth");
        var newWidth = event.clientX- parseFloat(mouseStart)+parseFloat(oldWidth);
        if(newWidth>60)
        {
            parObj.style.width = newWidth+'px';
        }
        
    },
    
    toggleSpinner: function (cmp, event) {
        var spinner = cmp.find("ltngSpinner");
        $A.util.toggleClass(spinner, "slds-hide");
    },
    
    showSpinner: function (cmp, event) {
        var spinner = cmp.find("ltngSpinner");
        $A.util.removeClass(spinner, "slds-hide");
        $A.util.addClass(spinner, "slds-show");
        
    },
    
    hideSpinner: function (cmp, event) {
        var spinner = cmp.find("ltngSpinner");
        $A.util.removeClass(spinner, "slds-hide");
        
        $A.util.addClass(spinner, "slds-show");
        
    },
    sortColumn: function (cmp, event,helper) {
        var sortBy = event.currentTarget.dataset.field;
        var values = cmp.get("v.colApis");
        var labels = cmp.get("v.colLabels");
        var sortField ;
        if(sortBy<0)
        {
            cmp.set("v.selectedTabsoft", 'Name');
            sortField = 'Name';
        }
        else
        {
            cmp.set("v.selectedTabsoft", labels[sortBy]);  
            sortField = values[sortBy];
        }
        helper.sortHelper(cmp, event);
        var sortEvent = $A.get("e.c:HD_SortEvent");
        var sortDirection = cmp.get("v.sortDirection");
        sortEvent.setParams({"sortBy":sortField,"sortDirection":sortDirection}).fire();
        
    },
    
    showCustomColumnsForm: function(component,event,helper){ 
        var colList = component.get("v.colLabels");
        var setColumnsEvent = $A.get("e.c:hd_setColumnsEvent");
        component.set("v.renderCustomColumnsForm",true);
        //setColumnsEvent.setParams({"selectedColumns":colList}).fire();
    },
    
    hideCustomColumnsForm: function(component,event,helper){ 
        
        component.set("v.renderCustomColumnsForm",false);
    },
    
    hideOrShowCustomColumnsForm :function(component, event, helper){
        component.set("v.renderCustomColumnsForm",event.getParam("renderCustomizeForm"));
    },
    
    openContextMenu : function(component, event, helper) {
        if(component.get("v.selected").length>0)
        {
            event.preventDefault();
            var ctxMenu = document.getElementById("ctxMenu");
            ctxMenu.style.position = "absolute";
            ctxMenu.style.display = "block";
            ctxMenu.style.left = (event.clientX-45)+"px";
            ctxMenu.style.top = (event.clientY-20)+"px"; 
            
            
            
            document.onclick = function mouseDown(e) {
                if(e.button!=2)
                {
                    var ctxMenu = document.getElementById("ctxMenu");
                    ctxMenu.style.display = "none";
                }
                
            }; 
        }
    },
    openBulkUpdateCmp : function(component, event, helper){
        event.stopPropagation();
        component.set("v.componentName",event.currentTarget.dataset.cmp);
        component.set("v.label",event.currentTarget.dataset.label);
        var childCmp = component.find("cComp");
        childCmp.actionMethod(component.get("v.selected"));
        var ctxMenu = document.getElementById("ctxMenu");
        ctxMenu.style.display = "none";
    },
    clearSelection : function(component, event, helper){
        
        component.set("v.selected",[]);
        
    },
    
    lazyLoad: function(component, event, helper){
       
        var lazyInc = component.get("v.lazyIncidents");
        var ele = document.getElementById('qwerty');
        var browserHeight = document.documentElement.scrollHeight + event.target.scrollTop;
        browserHeight -= 170;
        
        if(lazyInc.length>0 && event.target.scrollTop!= null && (browserHeight  >= event.target.scrollHeight) ){
            //alert(event.target.scrollHeight);
            var x = component.get("v.incidents");
            var z = lazyInc.slice(0,40);
            lazyInc = lazyInc.slice(40, lazyInc.length);
           	x = x.concat(z);
            component.set("v.incidents",x);
            component.set("v.lazyIncidents",lazyInc);
       }
        
        
        
        
        
    },
    
    
    selectRecord: function(component, event, helper) {
        event.stopPropagation();
        var selectedItem = event.currentTarget;
        var selectedId = selectedItem.dataset.id;
        var selList = component.get("v.selected");
        var selData = component.get("v.selectedData");
        var incidents = component.get("v.incidents");
        
        
        //document.getElementById("help")
        
        if(selectedItem.checked)
        {
            if(selList.length>=10)
            {
                selectedItem.checked = false;
                console.log("check"+selectedItem.checked);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type" : "error",
                    "message": "Only 10 records can be selected at a time!"
                });
                toastEvent.fire();
                return;
            }
            else
            {
                //document.getElementById(selectedId).style.backgroundColor = "#a6a9ad";
                helper.showHelp(component);
                selList.push(selectedId);
                var index = document.getElementById(selectedId).getAttribute('data-record');
                selData.push(incidents[index]);
                
            }
            
        }
        else
        {          
            var index = selList.indexOf(selectedId);
            selList.splice(index,1);
            selData.splice(index,1);
            
        }
        component.set("v.selected", selList);
        component.set("v.selectedData", selData);
        
        
        
    }
    
    
    
})