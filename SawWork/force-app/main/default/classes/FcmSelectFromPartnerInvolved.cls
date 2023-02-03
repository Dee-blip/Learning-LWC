/**
 * FCM select from Partner involved
 * This is a controller class for SelectFcmFromPartnerInvolved page
 * History:
 * =========================
 * Developer        Date        Description
 * --------------------------------------------------------------------------------------------------
   Vinayendra T N   01/2011     Created Class
   
   Lisha Murthy     10/2011     Add the selected PAE as the Approver of the Opportunity
 **/
public class FcmSelectFromPartnerInvolved {

    public static list<Channel_Mapping__c> channelMapping = new list<Channel_Mapping__c>();
    public String FCM { get; set; }
    public List<Channel_Mapping__c> fcmIds  {get;set;}
    private ID Partner =null;
    private Id opptyId=null;
    private Id currentFCMId = null;
    public Id ProcessInstanceId = null;
    public Boolean showPage {get;set;}
    public static List<ProcessInstanceWorkitem> piWorkItemList = new List<ProcessInstanceWorkitem>();
    public static void initilizeChannelMappingdata()
    {   
      //Select Id, Partner_Name__c, PAE_ID__c, VAR_Manager_Team_Role__c From Channel_Mapping__c
        for (Channel_Mapping__c cm :[SELECT Id, Partner_Name__c,Temp_PAE__c, PAE_ID__c, VAR_Manager_Team_Role__c,Partner_Name__r.Name,PAE_ID__r.Name FROM Channel_Mapping__c WHERE Active__c = true AND VAR_Manager_Status__c='Active'])
            {
                channelMapping.add(cm);
            }
    }
    public FcmSelectFromPartnerInvolved ()
    {
        showPage = true;
        opptyId=ApexPages.currentPage().getParameters().get('oppty');
        piWorkItemList = [SELECT Id,ActorId  FROM ProcessInstanceWorkitem WHERE ProcessInstance.Status = 'Pending' AND ProcessInstance.TargetObjectId =: opptyId ];
        
        if(piWorkItemList.size() > 0)
        {
            for(ProcessInstanceWorkitem piwi: piWorkItemList)
            {
                ProcessInstanceId = piwi.Id;
                GSM_Custom_Settings__c suppIdSettings = GSM_Custom_Settings__c.getInstance('ApprovalHistory#partnerSupportID');
                    //Check if the current user is the approver or System Admin
                if (UserInfo.getUserId().contains(piwi.ActorId) || UserInfo.getProfileId().contains(GSM_Custom_Settings__c.getInstance('ApprovalHistory#SysAdminId').Value__c) || UserInfo.getProfileId().contains(suppIdSettings.Value__c) )
                    init();
                
                else
                {
                    String errMessage = 'You are not the approver for the Opportunity and cannot reassign the Opportunity.';
                    showPage = false;
                    Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMessage));
                }
            }
        }
        else 
        {
            String errMessage = 'This Opportunity has not been submitted for Approval or You are not the approver for the Opportunity ';
            showPage = false;
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMessage));
        }
    } 
    
    public void init()
    {
        FCM='';
        if(opptyId!=null)
        {
            Opportunity oppty= [select id,Partner_Involved__c, FCM__c from Opportunity where id=:opptyId];
            currentFCMId = oppty.FCM__c;
            Partner=oppty.Partner_Involved__c;
        }
        search();
        
    }
    // Search() gives a list of all the users whose names contain the search string given on VF page and present in the Channel Mapping.
    public PageReference search() {
           initilizeChannelMappingdata(); 
           fcmIds = new List<Channel_Mapping__c>();
           for (Channel_Mapping__c cm : channelMapping)
           { 
             if ((cm.Partner_Name__c == Partner) && cm.PAE_ID__r.Name.toLowerCase().contains(FCM.toLowerCase()) && cm.PAE_ID__r.Id != currentFCMId)             
                  fcmIds.add(cm);
           }
        return null;
    }
    
    /*AddFCM() 
    - Updates the Opportunity's FCM to the user selected.
    - Reassigns the Approval process to the FCM selected.
    */
    public PageReference AddFCM() 
    {
        if(opptyId!=null)
        {
                Opportunity oppty= [select id,Channel_Manager__c from Opportunity where id=:opptyId];
                oppty.FCM__c=ApexPages.currentPage().getParameters().get('pid');//ApexPages.currentPage().getParameters().get('pid');
                
                //Add the selected PAE as Approver of the Opportunity                
                ProcessInstanceWorkitem p = new ProcessInstanceWorkitem(Id = ProcessInstanceId);
                p.ActorId =ApexPages.currentPage().getParameters().get('pid');
                update p;
                
                oppty.Validation_Override__c=true;
                update oppty;
                PageReference rPage = new PageReference('/'+opptyId);
                rPage.setRedirect(true);
                return rPage;
        }
        else
        return null;
    }
    public PageReference cancel() {
      PageReference rPage = new PageReference('/'+opptyId);
      rPage.setRedirect(true);
      return rPage;
      }

}