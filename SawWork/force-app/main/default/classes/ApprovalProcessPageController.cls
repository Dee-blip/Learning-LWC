/**
History:
 * =========================
 * Developer        Date        Description
 * --------------------------------------------------------------------------------------------------
 
 * Lisha Murthy     01/2012     Created the class. CR 1497943: Approval Process VF page for Oppty
  
*/
public class ApprovalProcessPageController 
{

    public String rebateLastYearDefaultMessage { get; set; }
    //public Map<string, PRM_Settings__c> PRMSettingsMap = PRM_Settings__c.getAll(); //SFDC-2573
    public Id oppId {get;set;}
    public Opportunity opp {get;set;}
    public String approvalHistoryURL {get;set;}
    public String approvalComments {get;set;}
    public List<ProcessInstance> allPIList;
    public Boolean isApprover {get;set;}
    public List<User> userList;
    public Set<Id> UserIdSet;
    public String ActorName;
    public String OriginalActorName;
    public Id piwiId;
    public Boolean isReject {get;set;}
    public Boolean isSubmitted;
    public Integer mode {get;set;}
    public String rebateRejectionMessage{get;set;}
    public  Boolean isPAEStep {get; set;}
    public  String PAEStepName2 {get; set;}
    public  String PAEStepName3 {get; set;}

       
    /*init()
    - Retrieves the Oppty record.
    - Returns true when Oppty is found, else returns false    
    */
    public Boolean init()
    {
        for(Opportunity o : [select Id, MDF__c,Discount_Status__c,Discount_Percentage__c, Channel_Manager__r.Partner_Group__c, MDF_Justification__c,
                               Rebate__c, Rebate_Justification__c,Managed_by__c,Partner_Led_POC__c, AKAM_Opportunity_Id__c,
                               Customer_Company_Name__c, Name, Owner__c, Registration_Status__c, StageName,
                               Primary_Product__c, Total_Contract_Value__c, Associated_Account_Name__c,
                               Partner_Involved__c,isRebateTCToShow__c,Rebate_TC_Status__C from Opportunity where Id =: Apexpages.currentPage().getParameters().get('oppId')])
            opp = o;
        rebateRejectionMessage=GsmUtilClass.getGSMSettingValue('ApprovalPage_RebateRejectionMsg');
        if(opp != null)
            return true;
        else
            return false;
     
    }
    
    /*getProcessInstanceWorkitem()
    - Approval Process initialization: Process Instance Work Item, Process Instance Steps, the users involved in the Approval Process are all initialized
    */
    public Boolean getProcessInstanceWorkitem()
    {
        approvalHistoryURL = '/apex/ApprovalHistoryPage?Id=' + opp.Id + '&noAction=1';
        approvalComments = ' ';
        allPIList = new List<ProcessInstance>();
        piwiId = null;
        PAEStepName2 = GsmUtilClass.getGSMSettingValue('ApprovalHistory_Step2');
        PAEStepName3 = GsmUtilClass.getGSMSettingValue('ApprovalHistory_Step3');    
        //Get all the Process Instance records.        
        for(ProcessInstance p : [Select (Select Id, OriginalActorId, ActorId, CreatedDate From Workitems ORDER BY CreatedDate DESC), (Select Id, StepStatus, OriginalActorId, ActorId, Comments, CreatedDate From Steps ORDER BY CreatedDate DESC),(Select  Id, IsDeleted, LastActorId, NodeStatus, ProcessInstanceId, ProcessNodeId, ProcessNodeName From Nodes ORDER BY CreatedDate DESC) From ProcessInstance p WHERE TargetObjectId =: opp.Id ORDER BY CreatedDate DESC])
            allPIList.add(p);        
            
        if(allPIList.size() > 0)
        {
            userList = new List<User>();
            userIdSet = new Set<Id>();
            ActorName = null;
            OriginalActorName = null;
            isApprover = false;
        
           for (ProcessInstance pi: allPIList)
           {
                //If the Approval Process is Pending for approval, there will be Workitem associated with Process Instance.
                if (pi.Workitems.size() > 0)
                {
                    userIdSet.add(pi.Workitems[0].OriginalActorId);
                    userIdSet.add(pi.Workitems[0].ActorId);
                    //GSM_Custom_Settings__c sysAdminIdSettings = GSM_Custom_Settings__c.getInstance('ApprovalHistory#SysAdminId');
                    if (UserInfo.getUserId().contains(pi.Workitems[0].ActorId) || UserInfo.getProfileId().contains(GsmUtilClass.getGSMSettingValue('ApprovalHistory_SysAdminId')) || Apexpages.currentPage().getParameters().get('noAction') != '0')
                    {
                        isApprover = true;
                    }
                    for(ProcessInstanceNode pin: pi.Nodes){
                         
                        if(pin.NodeStatus == 'Pending' && (PAEStepName2.contains(pin.ProcessNodeName) || PAEStepName3.contains(pin.ProcessNodeName)) )
                            
                           {

                             isPAEStep = True;
                             system.debug('PAE Step '+isPAEStep);
                         }
                            
                    } 
                }
                    
                //All the Approval process steps apart from pending step -> Process Instance Steps
                if (pi.Steps.size() > 0)
                {
                    for(Integer i=0;i<pi.Steps.size();i++)
                    {
                        userIdSet.add(pi.Steps[i].OriginalActorId);
                        userIdSet.add(pi.Steps[i].ActorId); 
                    }
                }
            }
                  
            //Get all the users listed in the Approval Process
            userList = [SELECT Id, Name, DelegatedApproverId FROM User WHERE Id IN :userIdSet];
            Map<Id, User> IdUserMap = new Map<Id, User>();
            for(Id pId: userIdSet)
            {
                for(User u: userList)
                {
                    if(pId == u.Id)
                       IdUserMap.put(pId,u);
                }   
            }
            for (ProcessInstance pi: allPIList)
            {
                if (pi.Workitems.size() > 0)
                {         
                    piwiId = pi.Workitems[0].Id; 
                    if (UserInfo.getUserId() == IdUserMap.get(pi.Workitems[0].ActorId).DelegatedApproverId)
                    {
                        isApprover = true;
                    }
                }
            }
            return true;
       }
            else
            {
                return false;
            }               
    }
    
    //This method returns 1 if Partner is PUBLIC Sector, else returns 0
    public Integer getMode()
    {
        if(opp.Channel_Manager__r.Partner_Group__c == 'PUBSEC VAR')
            return 1;
        else
            return 0;
    } 
    
    /*Constructor
    - If Oppty found
    --> Get the mode of this Oppty
    --> Initialize the Approval Process variables
    
    - Add errors to the page as necessary    
    */
    public ApprovalProcessPageController()
    {
        opp = null; 
        isReject = false;
        isSubmitted = false;
        mode = 0;
        isPAEStep = False;
        
        if(init())
        {
            mode = getMode();
            isSubmitted = getProcessInstanceWorkitem();
                
            if (!isSubmitted)
            {
                //Apexpages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, PRMSettingsMap.get('ApprovalProcess#OpptyNotSubmitted').Value__c); //SFDC-2573
                Apexpages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, GsmUtilClass.getPRMSettingValue('ApprovalProcess_OpptyNotSubmitted')); //SFDC-2573
                Apexpages.addMessage(msg);
            }
        }
        else
        {
            //Apexpages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, PRMSettingsMap.get('ApprovalProcess#OpptyNotFound').Value__c); //SFDC-2573
            Apexpages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, GsmUtilClass.getPRMSettingValue('ApprovalProcess_OpptyNotFound')); //SFDC-2573
            Apexpages.addMessage(msg);
        }
        if(Apexpages.currentPage().getParameters().get('reject')=='1')
            isReject = true;

    }
    
    /*approve()
    - Based on Mode value, Rebate/ MDF Justification values are checked for not null
    - Approve it by setting the comments and other values    
    */
    public PageReference approve()
    {
        if((mode == 0 && (opp.Rebate_Justification__c == null || opp.Rebate_Justification__c == '')) && isPAEStep)
        {
            //Apexpages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, PRMSettingsMap.get('ApprovalProcess#RebJustRequired').Value__c); //SFDC-2573
            Apexpages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, GsmUtilClass.getPRMSettingValue('ApprovalProcess_RebJustRequired')); //SFDC-2573
            Apexpages.addMessage(msg);
            return null;
        }
        if((mode == 0 && (opp.Managed_By__c == 'Partner' && (opp.Partner_Led_POC__c == null || opp.Partner_Led_POC__c ==''))) && isPAEStep)
        {
            //Apexpages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, PRMSettingsMap.get('ApprovalProcess#RebJustRequired').Value__c); //SFDC-2573
            Apexpages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, GsmUtilClass.getPRMSettingValue('ApprovalProcess_POCValueRequired')); //SFDC-2573
            Apexpages.addMessage(msg);
            return null;
        }
        if ((mode == 1 && (opp.MDF_Justification__c == null || opp.MDF_Justification__c == '')) && isPAEStep)
        {
            //Apexpages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, PRMSettingsMap.get('ApprovalProcess#MDFJustRequired').Value__c); //SFDC-2573
            Apexpages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, GsmUtilClass.getPRMSettingValue('ApprovalProcess_MDFJustRequired')); //SFDC-2573
            Apexpages.addMessage(msg);
            return null;
        }
        else
        {   
            opp.Validation_Override__c = true;
        
            try
            {
                update opp;
            }
            catch (System.Dmlexception ex)
            {
                for (Integer i = 0; i < ex.getNumDml(); i++)
                {                           
                    Apexpages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDMLMessage(i));
                    Apexpages.addMessage(msg);     
                }
                return null;
            }
            
            Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
            req2.setComments(approvalComments);
            req2.setAction('Approve');
                    
            // Use the ID from the newly created item to specify the item to be worked 
            //throw new customException('PIWI-Id'+piwiId);
            req2.setWorkitemId(piwiId);
            
            // Submit the request for approval 
        
            Approval.ProcessResult result2 =  Approval.process(req2);
            
            String url = '/' + opp.Id;
            PageReference pr = new PageReference(url);
            return pr;
        }
    }
    
    /*reject()
    - Rejects the Oppty without any validations.    
    */
    public PageReference reject()
    {
        Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
        req2.setComments(approvalComments);
        req2.setAction('Reject');
        // Use the ID from the newly created item to specify the item to be worked 
        req2.setWorkitemId(piwiId);
        // Submit the request for approval 
        Approval.ProcessResult result2 =  Approval.process(req2);  
        String url = '/' + opp.Id;
        PageReference pr = new PageReference(url);
        return pr;    
    }
    
    /*cancel()
    - returns back to Oppty page
    */
    public PageReference cancel()
    {
        opp.Rebate__c = null;
        opp.Validation_Override__c = true;
        
        try
        {
            update opp;
        }
        catch (System.Dmlexception ex)
        {
            for (Integer i = 0; i < ex.getNumDml(); i++)
            {                           
                Apexpages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDMLMessage(i));
                Apexpages.addMessage(msg);     
            }
            return null;
        }
        String url = '/' + opp.Id;
        PageReference pr = new PageReference(url);
        return pr;
    }
}