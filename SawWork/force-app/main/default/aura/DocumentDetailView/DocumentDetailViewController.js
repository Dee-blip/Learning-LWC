({
  doInit : function(component) 
    {
        //
        var ResultValue = component.get("v.DocuId");
        var networkIdAction = component.get("c.fetchCommunityId");
        networkIdAction.setCallback(this, function(response){
            component.set("v.communityId",response.getReturnValue());
        });
     let action = component.get("c.getdocuments"); 
         action.setParams({
            DocumentId:ResultValue
         });
        
         action.setCallback(this, function(response){
            var similarProperties = response.getReturnValue();
            
            //var DocuDesc = similarProperties.Description__c.replace(/<(.|\n)*?>/g, '');;
            component.set("v.Docu", similarProperties);
            component.set("v.TitleModal", similarProperties.Title__c);
            component.set("v.DocuModal", similarProperties.Description__c);
             
            //Get date in correct format for CreatedDate
             let tempcdate = similarProperties.CreatedDate;
             let cdate =  tempcdate.substring(0, tempcdate.indexOf('T'));
            
             //Get date in correct format for LastModifiedDate
             let templmdate = similarProperties.LastModifiedDate;
             let lmdate =  templmdate.substring(0, templmdate.indexOf('T'));
             
             //setting the createddate & Last Modified Date
              component.set("v.createddate",cdate);
              component.set("v.lastmodifieddate",lmdate);
             
             
        });
        
        let action1 = component.get("c.getGroupName"); 
         action1.setParams({
            DocumentId:ResultValue
         });
        
         action1.setCallback(this, function(response){
            var similarProperties = response.getReturnValue();
            
            //var DocuDesc = similarProperties.Description__c.replace(/<(.|\n)*?>/g, '');;
            component.set("v.GrpName", similarProperties);
            //component.set("v.DocuDesc", DocuDesc);
        });
        
       //Check delete access
       let action2 = component.get("c.hasDeltAccess"); 
         action2.setParams({
            DocumentId:ResultValue
         });
        
         action2.setCallback(this, function(response){
            var similarProperties = response.getReturnValue();
            
            //var DocuDesc = similarProperties.Description__c.replace(/<(.|\n)*?>/g, '');;
            component.set("v.hasDel", similarProperties);
            //component.set("v.DocuDesc", DocuDesc);
        });
         
     //Check edit access
     let action3 = component.get("c.hasEditAccess"); 
         action3.setParams({
            DocumentId:ResultValue
         });
        
         action3.setCallback(this, function(response){
            var similarProperties = response.getReturnValue();
            
            //var DocuDesc = similarProperties.Description__c.replace(/<(.|\n)*?>/g, '');;
            component.set("v.hasEdit", similarProperties);
            //component.set("v.DocuDesc", DocuDesc);
        });
        
        $A.enqueueAction(networkIdAction);
        $A.enqueueAction(action);
        $A.enqueueAction(action1);
        $A.enqueueAction(action2);
        $A.enqueueAction(action3);
  },
    
    openModel: function(component) {
      // for Display Model,set the "isOpen" attribute to "true"
      
      component.set("v.isOpen", true);
   },
 
   DeleteDocument: function(component) {
      // for Hide/Close Model,set the "isOpen" attribute to "False"
      // Delete Document First
      
       //alert(component.get("v.recordId"));
      var action = component.get("c.DeleteDocumentApex"); 
      var ResultValue = component.get("v.DocuId");
         action.setParams({
            DocumentId:ResultValue
         });
        
         action.setCallback(this, function(response){
              var state = response.getState();
             
            if(state === "SUCCESS"){
               
               
               component.set("v.isOpen", false);
                window.history.go(-1);
            } else if(state === "ERROR"){
               let errorMsg = $A.get('$Label.c.JV_Apex_Error');
               alert(errorMsg);  // eslint-disable-line no-alert
            }
        });
        
         $A.enqueueAction(action);
      
      
   },
 
   DoNothing: function(component) {
      // Display alert message on the click on the "Like and Close" button from Model Footer 
      // and set set the "isOpen" attribute to "False for close the model Box.
      //alert('thanks for like Us :)');
      component.set("v.isOpen", false);
   },
    
   openModelEdit: function(component) {
      // for Display Model,set the "isOpen" attribute to "true"
      component.set("v.DocuModalEdit", component.get("v.DocuModal"));
      component.set("v.TitleModalEdit", component.get("v.TitleModal"));
      component.set("v.isOpenEdit", true);
       
   },
    
   SaveDocument: function(component) {
       
      var action = component.get("c.UpdateDocument"); 
      var TitleComp = component.get("v.TitleModal");
      var Description = component.get("v.DocuModal");
      var ResultValue = component.get("v.DocuId");
         action.setParams({
            DocumentId:ResultValue,
             Title: TitleComp,
             Description : Description
         });
        
         action.setCallback(this, function(response){
              var state = response.getState();
             
            if(state === "SUCCESS"){
               
              
              
              
              
               component.set("v.isOpen", false);
                $A.get('e.force:refreshView').fire();

            } else if(state === "ERROR"){
               alert('Error in calling server side action');  // eslint-disable-line no-alert
            }
        });
        
         $A.enqueueAction(action);
   },
   
   CloseModelEdit: function(component) {
      // Display alert message on the click on the "Like and Close" button from Model Footer 
      // and set set the "isOpen" attribute to "False for close the model Box.
     
      component.set("v.isOpenEdit", false);
      //$A.get('e.force:refreshView').fire();
      //component.set("v.Docu", component.get("v.DocuEdit"));
      //component.get("v.Docu").Description__c = component.get("v.DocuEdit");
      component.set("v.TitleModal", component.get("v.TitleModalEdit"));
       component.set("v.DocuModal", component.get("v.DocuModalEdit"));
      component.set("v.DocuModalEdit", '');
      component.set("v.TitleModalEdit", '');
   },
    
   closeModel: function(component) {
      // Display alert message on the click on the "Like and Close" button from Model Footer 
      // and set set the "isOpen" attribute to "False for close the model Box.
     
      component.set("v.isOpen", false);
   },
   
   navigatetoGroup: function(component) {
      // Display alert message on the click on the "Like and Close" button from Model Footer 
      // and set set the "isOpen" attribute to "False for close the model Box.
     
      var navEvt = $A.get("e.force:navigateToSObject");
      navEvt.setParams({
      "recordId": component.get("v.GrpName.Id"),
      "slideDevName": "related"
    });
    navEvt.fire();
   },
   
   navigatetoDocument : function(component) 
    {
       
        var GroupName = component.get("v.GrpName.Name");
        var GroupId   = component.get("v.GrpName.Id");
        
    //Find the text value of the component with aura:id set to "address"
    var url = '/customers/s/group/' + GroupId +'/'+GroupName+'?tabset-6e987=2';
        
     window.location.href =url;
   
}


})