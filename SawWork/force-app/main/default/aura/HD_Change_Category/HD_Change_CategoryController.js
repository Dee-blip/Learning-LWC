({
    doInit: function(component, event, helper) {
        

        
        var action = component.get("c.getCategories");
                action.setCallback(this, function(response) {
            var categories = {}, results,parent;
            var state = response.getState();
            if(state == 'ERROR'){
                
                var errors = response.getError();
                /* eslint-disable-next-line */
                HD_Error_Logger.createLogger(component, event, helper, errors[0].message, errors[0].message,false,'error');
                return;
            }
                results = response.getReturnValue();
                component.set("v.initResults",results);
          
        });
        $A.enqueueAction(action);
    },
    
    performSearch: function(component, event, helper) {
        var results;
        var elem = component.find("auraCategoryInput");
        var value = elem.elements["0"].value;
    	var resultsFinal=component.get("v.initResults");
        var results1 = [];
        if(value == null || value == '' ){
            results1 = [];
        } 
        else{
            value=value.replace(/[-[\]{}()*+!<=:?.\/\\^$|#\s,]/g, '\\$&');
            var reg = new RegExp(value, 'i');
            
         	results = component.get("v.initResults");
         	results.forEach(function(category) {
               	var key = category.Name;
                var parentcat = category.BMCServiceDesk__parentTree__c ;
                if(parentcat == null || parentcat == '' || parentcat == 'null'){
                    parentcat = "No parent. Top level category";
                }

                if(key && key.match(reg)){
                    results1.push({name:key,id:category.Id,parent:parentcat});
                }
                    
                });
        }
    	component.set("v.results",results1);
        //alert(results1[0].id);
    },
    
    categorySelected: function(component, event, helper){
 
        var selectedValue = event.currentTarget.dataset.category;
        var selectedId = event.currentTarget.dataset.categoryid;
        component.set("v.results",[]);
        component.set("v.searchQuery","");
        component.set("v.searchQuery",selectedValue);
        component.set("v.selectedCategoryId",selectedId);
        $A.util.getElement("hiddenCategoryId").value = selectedId;
    },
    hideModal : function(component,event, helper){

		component.set("v.modalFlag",false);
   },
    showModal : function(component,event,helper){
               
        component.set("v.modalFlag",true);
    },
	modifyCategory : function(component, event, helper) {
        var warningMessages = [];
        var index = 0;
        component.set("v.warnings"," ");
        
        //validating category
        var category; 
        category = component.get("v.selectedCategoryId");
        if(category == null || category == ' '){
            warningMessages[index] = "Please select a valid category";
            index++;
        }
        
        component.set("v.warnings",warningMessages);
        
        if(warningMessages.length==0){
            component.set("v.searchQuery","");
         	var incId = component.get("v.recordId");
         	
         	var action = component.get("c.changeCategory");
           
            action.setParams({
        		incidentId : incId,
                categoryName : category
      		});
            action.setCallback(this,function(data){
                component.set("v.searchQuery","");
                
                component.set("v.selectedCategoryId","");
                var state = data.getState();
                //alert(state);
                if(state == 'ERROR'){
                    var errors = data.getError();
                    /* eslint-disable-next-line */
                    HD_Error_Logger.createLogger(component, event, helper, errors[0].message, errors[0].message,false, 'error');
            		helper.doneWaiting(component);
                    $A.get("e.c:HD_ActionAuditEvent").setParams({ "state" : state }).fire();
                    return;
                }
                var data = data.getReturnValue();
                $A.get('e.force:refreshView').fire();
                helper.doneWaiting(component);
                $A.get("e.c:HD_ActionAuditEvent").setParams({ "state" : state }).fire();
    		});
            $A.enqueueAction(action);
            helper.waiting(component);
        }
    },
    onSelectCategory: function(component, event, helper){
       var cmp=component.find("resolutionId");
        $A.util.addClass(cmp,"custom-hide-modal");
        $A.util.removeClass(cmp,"custom-show-modal");
        component.set("v.modalFlag",false);
        component.set("v.results",[]);
        component.set("v.searchQuery","");
        component.set("v.searchQuery",event.getParam("categoryName"));
        component.set("v.selectedCategoryId",event.getParam("categoryId"));
        $A.util.getElement("hiddenCategoryId").value = event.getParam("categoryId");
    }
    
})