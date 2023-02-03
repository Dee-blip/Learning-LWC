global class FundRequestEditBeforeApprovalController
{
    public SFDC_MDF__c pageObject {get; set;} 
    public String updateErrorMessage {get;set;}
    public Boolean showPage {get; set;}
    private string recordID= '' ;
    public FundRequestEditBeforeApprovalController(ApexPages.standardController stdController) 
    {
        recordID = ApexPages.currentPage().getParameters().get('id');
        // SFDC-5895 - Added By Prabhanjan
        if(recordID != null && recordID != '') {
            recordID = String.escapeSingleQuotes(recordID.escapeHtml4());
        }
        if(!hasEditingRights(recordID))
        {
            ApexPages.Message cantEditMessage=new ApexPages.Message(ApexPages.Severity.ERROR,'Error: You dont have the editing rights for this Fund Request');
            ApexPages.addMessage(cantEditMessage);
            showPage=false;
        }


        List<String> listOfStatusesWhichAllowEdit = Label.FundRequestAllowEditStatuses.split(', ');
        List<SFDC_MDF__c> listOfRecords= [select id, Name,SOE_or_PubSec_Event__c,Spender_Confirmed__c, Activity_Leader__c,Amount__c, Total_Activity_Event_Cost__c, Fund_Request_Contact__c, Fund_Request_Campaign__c, Program_Type__c, Activity_Date__c, Program_End_Date__c, Other_Program_Type__c, Plan_Activity__c, Program_Location__c, Program_Description__c from SFDC_MDF__c where id=:recordID and Status__c in :listOfStatusesWhichAllowEdit];
        if(listOfRecords.size()>0)
        {
          pageObject = listOfRecords[0];
        }
        else
        {
            ApexPages.Message noIDMessage = new ApexPages.Message(ApexPages.Severity.ERROR,'Error: Not a valid Fund Request ID.');
            ApexPages.addMessage(noIDMessage);
            showPage=false;
         }
        showPage = true;
           
       
    }
        
    public PageReference save()
    {
      try
      {
        update pageObject;
      }
      catch (Exception e)
      {
          ApexPages.Message updateErrorMessage= new ApexPages.Message(ApexPages.Severity.ERROR,'Error: Some error occurred ' + e.getMessage());
          ApexPages.addMessage(updateErrorMessage);
          return null;
      }
      return new PageReference('/'+recordID);
    }

    public PageReference cancel() 
    {
        PageReference rPage = new PageReference('/'+recordId);
        rPage.setRedirect(true);
        return rPage;
    }


    webservice static Boolean hasEditingRights(String fundRequestId)
    {
        String currentUserProfileId = Userinfo.getProfileId();
        String profileName = [Select Name from Profile where Id=:currentUserProfileId][0].Name;
        for(String ithProfile : Label.FundRequestAllowedProfilesForEdit.split(','))
        {
            if(ithProfile.trim()==profileName)
                return true;
        }
        // If Fund request > 5k USD, then after first approval, the approval request goes to Fund Request Queue
        // They wont be able to edit
        

        //Check if user is the next approver
        List<ProcessInstanceWorkItem> processInstanceWorkItemList = [select id, actorid, originalactorid from ProcessInstanceWorkItem where ProcessInstance.TargetObjectId=:fundRequestId order by createddate desc];
        System.Debug('###processInstanceList p' + processInstanceWorkItemList);
        if(processInstanceWorkItemList!=null && processInstanceWorkItemList.size()>0)
        {

            String currentUserId = Userinfo.getUserId();
            for(ProcessInstanceWorkItem ithWorkItem : processInstanceWorkItemList)
            {
                System.Debug('### Magic');
                if(ithWorkItem.actorid==currentUserId || ithWorkItem.originalactorid==currentUserId)
                {
                    System.Debug('##FundRequestEditBeforeApprovalController isNextApprover');
                    return true;
                }
            }
        }
        System.Debug('##FundRequestEditBeforeApprovalController isNotNextApprover');

        return false;
    }
                
}