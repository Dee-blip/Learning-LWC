({
    itemSelected : function(component, event, helper) {
        var target = event.target;   
        var SelIndex = helper.getIndexFrmParent(target,helper,"data-selectedIndex");  
        if(SelIndex){
            var serverResult = component.get("v.server_result");
            var selItem = serverResult[SelIndex];
            if(selItem.val){
               console.log(" just sel item : " + selItem );
               console.log("whats sel : " +  selItem.val );
               component.set("v.selItem",selItem);
               component.set("v.last_ServerResult",serverResult);
            } 
            component.set("v.server_result",null);
        } 
    }, 
    serverCall : function(component, event, helper) {  
        var target = event.target;  
        var searchText = target.value; 
        var last_SearchText = component.get("v.last_SearchText");
        //Escape button pressed 
        if (event.keyCode == 27 || !searchText.trim()) { 
            helper.clearSelection(component, event, helper);
        }
        // 20.5 removing the check for space/ enter key - && (/\s+$/.test(searchText) || event.keyCode == 13)
        else if(searchText.trim() != last_SearchText ){ 
            //Save server call, if last text not changed
            //Search only when space character entered
         
            var objectName = component.get("v.objectName");
            var field_API_text = component.get("v.field_API_text");
            var field_API_val = component.get("v.field_API_val");
            var field_API_search = component.get("v.field_API_search");
            var limit = component.get("v.limit");
            var field_boolean_flag = component.get("v.field_boolean_flag") ? component.get("v.field_boolean_flag") : undefined;
            var search_addedFilter = component.get("v.search_addedFilter") ? component.get("v.search_addedFilter") : undefined;

            //19.5 Adding project and Account Filters
            //20.5 iwSecAc can be used as Account Id for Projects/opportunities to search 
            var iwSecAc = component.get("v.search_ProjForAcc") ? component.get("v.search_ProjForAcc") : undefined;
            var recordtype = component.get("v.search_ProjRecType") ? component.get("v.search_ProjRecType") : undefined;
            
            
            console.log('James :: ' + field_boolean_flag);
            console.log('James :: ' + search_addedFilter);
            
            var action = component.get('c.searchDB');
            action.setStorable();
            
            action.setParams({
                objectName : objectName,
                fld_API_Text : field_API_text,
                fld_API_Val : field_API_val,
                lim : limit, 
                fld_API_Search : field_API_search,
                searchText : searchText,
                addSearchFilter : search_addedFilter,
                fieldFilter : field_boolean_flag,
                iwSecAcc : iwSecAc,
                recordtyp : recordtype
            });
    
            action.setCallback(this,function(a){
                this.handleResponse(a,component,helper);
            });
            
            component.set("v.last_SearchText",searchText.trim());
            console.log('Server call made');
            $A.enqueueAction(action); 
        }
            
        else if(searchText && last_SearchText && searchText.trim() == last_SearchText.trim()){ 
            component.set("v.server_result",component.get("v.last_ServerResult"));
            console.log('Server call saved');
        }         
    },
    handleResponse : function (res,component,helper){
        if (res.getState() === 'SUCCESS') {

            console.log("check bfor parse: " + res.getReturnValue() );

            var retObj = JSON.parse(res.getReturnValue());
            
            console.log("check after parse: " + retObj );
            
            if(retObj.length <= 0){
                var noResult = JSON.parse('[{"text":"No Results Found"}]');
                component.set("v.server_result",noResult); 
                component.set("v.last_ServerResult",noResult);
            }else{
                component.set("v.server_result",retObj); 
                component.set("v.last_ServerResult",retObj);
            }  
        }else if (res.getState() === 'ERROR'){
            var errors = res.getError();
            if (errors) {
                if (errors[0] && errors[0].message) {
                    alert(errors[0].message);
                }
            } 
        }
    },
    getIndexFrmParent : function(target,helper,attributeToFind){
        //User can click on any child element, so traverse till intended parent found
        var SelIndex = target.getAttribute(attributeToFind);
        while(!SelIndex){
            target = target.parentNode ;
            SelIndex = helper.getIndexFrmParent(target,helper,attributeToFind);           
        }
        return SelIndex;
    },
    clearSelection: function(component, event, helper){
        component.set("v.selItem",null);
        component.set("v.server_result",null);
    } 
})