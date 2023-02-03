({
  
	keyPressController : function(component, event, helper) {
      // get the search Input keyword   
		var getInputkeyWord = component.get("v.SearchKeyWord");
      // check if getInputKeyWord size id more then 0 then open the lookup result List and 
      // call the helper 
      // else close the lookup result List part.   
        if( getInputkeyWord.length > 0 ){
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

          console.log('inside accLookup.keyPressController');
         
	},

  //SFDC-3903 
  doInit : function(component, event, helper) {
    //component.set("v.SearchKeyWord",component.get("v.selectedRecord").Id);
    var getInputkeyWord = component.get("v.selectedRecordId").Id;
    if(getInputkeyWord != null && getInputkeyWord != undefined) {
      helper.searchHelperBasedOnId(component,event,getInputkeyWord);
    }
  },
  
  // function for clear the Record Selaction 
    clear :function(component,event,helper){
      
         var pillTarget = component.find("lookup-pill");
         var lookUpTarget = component.find("lookupField"); 
        
         $A.util.addClass(pillTarget, 'slds-hide');
         $A.util.removeClass(pillTarget, 'slds-show');
        
         $A.util.addClass(lookUpTarget, 'slds-show');
         $A.util.removeClass(lookUpTarget, 'slds-hide');
      
         component.set("v.SearchKeyWord",null);
         component.set("v.listOfSearchRecords", null );
         component.set("v.selectedRecord", null );

         var selectedRecord = component.get("v.selectedRecord");

         console.log('inside accLookup.clear:' + selectedRecord);

         
         // helper.fireAccSelectionEvent(component, event, selectedRecord);
         //helper.fireOnChangeEvent(component, event, helper);

         var appEvent = $A.get("e.c:accountChangeEvent");
          appEvent.setParams({ "acc" : selectedRecord });
          appEvent.fire();

    },
    
  // This function call when the end User Select any record from the result list.   
    handleComponentEvent : function(component, event, helper) {

      console.log('inside accLookup.handleComponentEvent');
     
    // get the selected Account record from the COMPONETN event 	 
       var selectedAccountGetFromEvent = event.getParam("accountByEvent");
	   
	   component.set("v.selectedRecord" , selectedAccountGetFromEvent); 
       
        var forclose = component.find("lookup-pill");
           $A.util.addClass(forclose, 'slds-show');
           $A.util.removeClass(forclose, 'slds-hide');
      
        
        var forclose = component.find("searchRes");
           $A.util.addClass(forclose, 'slds-is-close');
           $A.util.removeClass(forclose, 'slds-is-open');
        
        var lookUpTarget = component.find("lookupField");
            $A.util.addClass(lookUpTarget, 'slds-hide');
            $A.util.removeClass(lookUpTarget, 'slds-show');  
        
        helper.fireOnChangeEvent(component, event, helper);
      
	},
  // automatically call when the component is done waiting for a response to a server request.  
    hideSpinner : function (component, event, helper) {
        var spinner = component.find('spinner');
        var evt = spinner.get("e.toggle");
        evt.setParams({ isVisible : false });
        evt.fire();    
    },
 // automatically call when the component is waiting for a response to a server request.
    showSpinner : function (component, event, helper) {
        var spinner = component.find('spinner');
        var evt = spinner.get("e.toggle");
        evt.setParams({ isVisible : true });
        evt.fire();    
    },
    
})