//Added by Hitesh Chawda CR 1592464
//When a PLU is marked as archive All the Launch Items under the PLU also gets archived
trigger PLM_PLUArchivedTrigger on PLU__c (after update) {
    
        PLM_LaunchItemApprovalGeneric plmClass=new PLM_LaunchItemApprovalGeneric();
        List<PLU__c> archivedPLUs = new List<PLU__c>();
        for(PLU__c plu : Trigger.new)
     		{
     			if(Trigger.oldMap.get(plu.Id).Archive__c != plu.Archive__c )
     			  {
     			  	
    			    archivedPLUs.add(plu);
     			  }
     
     		}
         plmClass.processArchivedPLU(archivedPLUs);
        

}