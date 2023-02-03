trigger HD_ChangeCoordinator on Change_Coordinator__c (Before Insert,after insert,Before Update,after update,Before delete) {


    if(Trigger.isAfter){
    
      List<Change_Coordinator__c> oldTrigger = new List<Change_Coordinator__c>();
      
      if(trigger.isUpdate)
        oldTrigger = Trigger.old;
 
       Integer i = 0;
       List<BMCServiceDesk__Change_Request__Share> change_share_list = new List<BMCServiceDesk__Change_Request__Share>();
       
          for(Change_Coordinator__c ch_coordinator : Trigger.new){
              if(trigger.isInsert || (trigger.isUpdate && (ch_coordinator.User__c != oldTrigger[i].User__c || ch_coordinator.change_request__c != oldTrigger[i].change_request__c)) )
              {
                  BMCServiceDesk__Change_Request__Share ChangeShare = new BMCServiceDesk__Change_Request__Share();
                  ChangeShare.ParentId =  ch_coordinator.Change_Request__c;
                  ChangeShare.UserOrGroupId =  ch_coordinator.User__c;
                  ChangeShare.RowCause = Schema.BMCServiceDesk__Change_Request__Share.RowCause.Coordinator__c;
                  ChangeShare.AccessLevel = 'edit';
                  change_share_list.add(ChangeShare);
               
               }
          }
        
          if(change_share_list.size() > 0)
            insert change_share_list;
           
    }// isAfter
        
        
        if(Trigger.isBefore){
           
         integer  i= 0;
         integer  j = 0;
         String  soqlstr = '';
         List<Change_Coordinator__c> newTrigger = new List<Change_Coordinator__c>();
         
         
         if(trigger.isUpdate )
             newTrigger = Trigger.new;

           if(trigger.isUpdate || trigger.isdelete){
           
           List<BMCServiceDesk__Change_Request__Share> SharingList = [Select Id,UserOrGroupId,ParentId from BMCServiceDesk__Change_Request__Share where RowCause = 'Coordinator__c'];
           List<BMCServiceDesk__Change_Request__Share> deleteList = new List<BMCServiceDesk__Change_Request__Share>(); 

            for(Change_Coordinator__c ch_coordinator : Trigger.old){
              if ( Trigger.isDelete || (trigger.isUpdate && (ch_coordinator.User__c != newTrigger[i].User__c || ch_coordinator.change_request__c != newTrigger[i].change_request__c) ) )
                { 
                   
                   for(BMCServiceDesk__Change_Request__Share chrShare : SharingList){
                      if(chrshare.UserOrGroupId == ch_coordinator.User__c && chrShare.ParentId == ch_coordinator.Change_request__c){
                      
                         deleteList.add(chrShare);
                      }
                   
                   }     
                 
                 }
               }
             
             
              if(deleteList.size() > 0 )
                 delete deletelist;
               
            }

            
             
 
         }  //isBefore
           
         
      
        
    
    

}