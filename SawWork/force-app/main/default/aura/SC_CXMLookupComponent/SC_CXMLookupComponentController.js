({
    
  doInit : function(component){
    var forclose;
    var lookUpTarget;
    
    if(component.get('v.selectedRecordId') !== undefined  && component.get('v.selectedRecordId') !== null && component.get('v.selectedRecordId') !== ''){
  forclose = component.find("lookup-pill");
            $A.util.addClass(forclose, 'slds-show');
            $A.util.removeClass(forclose, 'slds-hide');
            forclose = component.find("searchRes");
            $A.util.addClass(forclose, 'slds-is-close');
            $A.util.removeClass(forclose, 'slds-is-open');
        
         lookUpTarget = component.find("lookupField");

             $A.util.addClass(lookUpTarget, 'slds-hide');
             $A.util.removeClass(lookUpTarget, 'slds-show'); 
    }
  },       


  onfocus : function(component,event,helper){
    var forOpen;
    var getInputkeyWord = '';
        $A.util.addClass(component.find("mySpinner"), "slds-show");
        forOpen = component.find("searchRes");
             $A.util.addClass(forOpen, 'slds-is-open');
             $A.util.removeClass(forOpen, 'slds-is-close');
         // Get Default 5 Records order by createdDate DESC  
          
          helper.searchHelper(component,getInputkeyWord);
     },
     onblur : function(component){    
      var forclose;   
         component.set("v.listOfSearchRecords", null );
         forclose = component.find("searchRes");
         $A.util.addClass(forclose, 'slds-is-close');
         $A.util.removeClass(forclose, 'slds-is-open');
     },
     keyPressController : function(component, event, helper) {
        // get the search Input keyword   
          var getInputkeyWord = component.get("v.SearchKeyWord");
          var forOpen;
          var forclose ;
        // check if getInputKeyWord size id more then 0 then open the lookup result List and 
        // call the helper 
        // else close the lookup result List part.   
         if( getInputkeyWord.length > 0 ){
              forOpen = component.find("searchRes");
                $A.util.addClass(forOpen, 'slds-is-open');
                $A.util.removeClass(forOpen, 'slds-is-close');
             helper.searchHelper(component,getInputkeyWord);
         }
         else{  
              component.set("v.listOfSearchRecords", null ); 
              forclose = component.find("searchRes");
                $A.util.addClass(forclose, 'slds-is-close');
                $A.util.removeClass(forclose, 'slds-is-open');
           }
     },
     
   // function for clear the Record Selaction 
     clear :function(component){
       
          var pillTarget = component.find("lookup-pill");
           
          var lookUpTarget = component.find("lookupField"); 
         
          $A.util.addClass(pillTarget, 'slds-hide');
          $A.util.removeClass(pillTarget, 'slds-show');
         
          $A.util.addClass(lookUpTarget, 'slds-show');
          $A.util.removeClass(lookUpTarget, 'slds-hide');
       
          component.set("v.SearchKeyWord",null);
          component.set("v.listOfSearchRecords", null );
          component.set("v.selectedRecord", {} );   
          
     },
     
   // This function call when the end User Select any record from the result list.   
     handleComponentEvent : function(component, event) {
     // get the selected Account record from the COMPONETN event 	
     var forclose; 
     var lookUpTarget;
        var selectedAccountGetFromEvent;
        selectedAccountGetFromEvent = event.getParam("recordByEvent");
        component.set("v.selectedRecord" , selectedAccountGetFromEvent); 
        component.set("v.selectedRecordId" , selectedAccountGetFromEvent.Id); 
        
         forclose = component.find("lookup-pill");
            $A.util.addClass(forclose, 'slds-show');
            $A.util.removeClass(forclose, 'slds-hide');
   
         forclose = component.find("searchRes");
            $A.util.addClass(forclose, 'slds-is-close');
            $A.util.removeClass(forclose, 'slds-is-open');
         
         lookUpTarget = component.find("lookupField");
             $A.util.addClass(lookUpTarget, 'slds-hide');
             $A.util.removeClass(lookUpTarget, 'slds-show');  
       
     },
 })