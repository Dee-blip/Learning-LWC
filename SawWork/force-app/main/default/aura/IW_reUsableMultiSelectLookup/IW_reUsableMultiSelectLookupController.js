({
    onblur : function(component,event,helper){
        // on mouse leave clear the listOfSeachRecords & hide the search result component 
       // component.set("v.listOfSearchRecords", null );
        //component.set("v.SearchKeyWord", '');
        //var forclose = component.find("searchRes");
        //$A.util.addClass(forclose, 'slds-is-close');
        //$A.util.removeClass(forclose, 'slds-is-open');
        var getInputkeyWord = component.get("v.SearchKeyWord");
        helper.searchHelper(component,event,getInputkeyWord);
    },
    onfocus : function(component,event,helper){
        // show the spinner,show child search result component and call helper function
        $A.util.addClass(component.find("mySpinner"), "slds-show");
        component.set("v.listOfSearchRecords", null ); 
        var forOpen = component.find("searchRes");
        $A.util.addClass(forOpen, 'slds-is-open');
        $A.util.removeClass(forOpen, 'slds-is-close');
        // Get Default 5 Records order by createdDate DESC 
        var getInputkeyWord = '';
        helper.searchHelper(component,event,getInputkeyWord);
    },
    
    keyPressController : function(component, event, helper) {
        //$A.util.addClass(component.find("mySpinner"), "slds-show");
        // get the search Input keyword   
        var getInputkeyWord = component.get("v.SearchKeyWord");
        // check if getInputKeyWord size id more then 0 then open the lookup result List and 
        // call the helper 
        // else close the lookup result List part.   
        if(getInputkeyWord.length > 2){
            var forOpen = component.find("searchRes");
            $A.util.addClass(forOpen, 'slds-is-open');
            $A.util.removeClass(forOpen, 'slds-is-close');
            helper.searchHelper(component,event,getInputkeyWord);
        }
        else{  
            component.set("v.listOfSearchRecords", null ); 
            var forclose = component.find("searchRes");
            $A.util.addClass(forclose, 'slds-is-close');
            $A.util.removeClass(forclose, 'slds-is-open');
        }
    },
    
    // function for clear the Record Selaction 
    clear :function(component,event,heplper){
        var selectedPillId = event.getSource().get("v.name");
        var AllPillsList = component.get("v.lstSelectedRecords"); 
        
        for(var i = 0; i < AllPillsList.length; i++){
            if(AllPillsList[i].Id == selectedPillId){
                AllPillsList.splice(i, 1);
                component.set("v.lstSelectedRecords", AllPillsList);
            }  
        }
        component.set("v.SearchKeyWord",null);
        component.set("v.listOfSearchRecords", null );
        if(AllPillsList.length < 1){
            component.set("v.accountStatus",undefined);
        }
        console.log(' acc status while cleraing : ' , component.get("v.accountStatus") );
    },
    
    // This function call when the end User Select any record from the result list.   
    handleComponentEvent : function(component, event, helper) {
        component.set("v.SearchKeyWord",null);
        // get the selected object record from the COMPONENT event 	 
        var listSelectedItems =  component.get("v.lstSelectedRecords");
        var selectedAccountGetFromEvent = event.getParam("recordByEvent");

        console.log('use these vals : ' , selectedAccountGetFromEvent );
        
        // Added check on the result returned and restrict the results to only Initernal Accounts or non internal accounts when the returned result
        if(selectedAccountGetFromEvent.Id.toString().startsWith('001') )
        {
            let getAccountInternal = component.get("c.getAccountInternal");
            getAccountInternal.setParams({
                "accountId":selectedAccountGetFromEvent.Id.toString()
            });
            
            getAccountInternal.setCallback(this, function(result){
                var state = result.getState();
                if (component.isValid() && state === "SUCCESS"){
                    console.log(' com acc stat val : ' , component.get("v.accountStatus") );
                    console.log(' cmprs valss :  ' , JSON.parse(result.getReturnValue()) );
                    if( component.get("v.accountStatus") === undefined )
                    {
                        component.set("v.accountStatus",JSON.parse(result.getReturnValue()) );

                        let selectedItem = [];
                        if(listSelectedItems !== null && listSelectedItems !== undefined){
                            console.log("listSelectedItems"+listSelectedItems);
                            listSelectedItems.push(selectedAccountGetFromEvent);
                            component.set("v.lstSelectedRecords" , listSelectedItems);
                            console.log(' list sected :: ' , listSelectedItems);
                        }
                        else{
                            selectedItem.push(selectedAccountGetFromEvent);
                            component.set("v.lstSelectedRecords" , selectedItem);
                        }

                    }
                    else if( component.get("v.accountStatus") !== undefined && component.get("v.accountStatus") === JSON.parse(result.getReturnValue()) )
                    {

                        let selectedItem = [];
                        if(listSelectedItems !== null && listSelectedItems !== undefined){
                            console.log("listSelectedItems"+listSelectedItems);
                            listSelectedItems.push(selectedAccountGetFromEvent);
                            component.set("v.lstSelectedRecords" , listSelectedItems);
                            console.log(' list sected :: ' , listSelectedItems);
                        }
                        else{
                            selectedItem.push(selectedAccountGetFromEvent);
                            component.set("v.lstSelectedRecords" , selectedItem);
                        }

                    } else if(component.get("v.accountStatus") !== undefined && component.get("v.accountStatus") !== JSON.parse(result.getReturnValue()))
                    {
                        console.log('accounts must of same TYPE!' , component.get("v.passMsg") );
                        
                        component.set("v.passMsg" , true);

                    }
                    
                }
                else if(component.isValid()){
                    console.log('some issue in verifying account' , result);
                }
            });
            
            $A.enqueueAction(getAccountInternal);
        } else {
            let selectedItem = [];
            if(listSelectedItems !== null && listSelectedItems !== undefined){
                console.log("listSelectedItems"+listSelectedItems);
                listSelectedItems.push(selectedAccountGetFromEvent);
                component.set("v.lstSelectedRecords" , listSelectedItems);
            }
            else{
                selectedItem.push(selectedAccountGetFromEvent);
                component.set("v.lstSelectedRecords" , selectedItem);
            }
        }


        
         
        
        var forclose = component.find("lookup-pill");
        $A.util.addClass(forclose, 'slds-show');
        $A.util.removeClass(forclose, 'slds-hide');
        
        var forclose = component.find("searchRes");
        $A.util.addClass(forclose, 'slds-is-close');
        $A.util.removeClass(forclose, 'slds-is-open'); 
    },
})