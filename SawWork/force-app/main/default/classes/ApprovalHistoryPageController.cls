/**
History:
 * =========================
 * Developer        Date        Description
 * --------------------------------------------------------------------------------------------------
 
 * Lisha Murthy     11/2011     Created the class. CR 1396306: VF page for Approval History section
 
 * Lisha Murthy     01/2012     CR 1463401: PRM: Need two Deal Registration approval WFs.
                                -> Added two Approval links for rebate.
                                
 * Lisha Murthy     07/2013      2295218 - New/Churn field not updating for PAEs
                                -> Changes made for churn approval: update Registration_Status__c = 'Approved Churn'.
                                -> Adding a new parameter to be passed to ApprovalProcessPage from this controller.
                                * Hitesh Chawda     01/2016      CR 3267821 - Deal Reg -- 2016 Go To Market Changes
                                -> Made the Approval Process logic dynamic to take care of more then 2 steps - Previously it was hardcoded
*/

global class ApprovalHistoryPageController 
{
    public Opportunity opp {get;set;}
    public static Id opptyId {get;set;}
    public List<ProcessInstance> allPIList;
    public List<ProcessInstanceStep> piStepList;
    public List<ProcessInstanceNode> piNodeList;
    public List<List<string>> displayList {get;set;}
    public Set<Id> userIdSet;
    public List<User> userList;
    public String ActorName;
    public String OriginalActorName;
    public String LongDate;
    public Boolean showTable {get;set;}
    public Boolean showLink {get;set;}
    public Id ProcessInstanceWorkitemId {get;set;}      
    public Boolean noAccount {get;set;} 
    public PageReference oppId {get;set;} 
    public Boolean isApprover {get;set;}
    public String AccStr {get;set;}
    public static String publicSectorLinkName {get;set;}
    public static String publicSectorRebatePercent {get;set;}
    public static String dealRegAccountStatus {get;set;}
    public static String dealRegOpptyStatus {get;set;}
    public static Decimal dealRegAccountDiscount {get;set;}
    public static Decimal dealRegOpptyDiscount {get;set;}
    public static Integer mode {get;set;}
    /** Begin Rajesh Kumar SFDC-5781 **/

   public static Boolean issrRequired {get;set;}
    List<String> subresPartlis {get;set;}

    /** End Rajesh Kumar SFDC-5781 **/
    public static String prebateType;
   // public Map<Id,String> nodeIdToNodeNameMap {get; set;} //sequenceToNodeNameMap
    public Map<Id,String> sequenceToNodeNameMap {get; set;}
    public static String PAEStepName {get; set;}
    public static String PAEStepName2 {get; set;}
    public static Boolean isPAEStep {get; set;}
    //public static Integer isPAEStepCheck {get;set;}

    /*getMode()
    -> Returns value as 1 for PUBLIC Sector Partners
    -> Returns value as 0 for all other Partners

    */
    public static Integer getMode()
    {
        Opportunity opportunity = new Opportunity();
        for(Opportunity o: [SELECT Id, Channel_Manager__r.Partner_Group__c FROM Opportunity where Id =: opptyId])
        {
            opportunity = o;

            //return the mode as 1 when the Channel Mapping's Partner Group (Partner_Group__c) is of Public sector
            if(opportunity.Channel_Manager__r.Partner_Group__c == 'PUBSEC VAR')
                return 1;
        }
        return 0;
    }

    /*Constructor
    - Initializes Oppty
    - Sets the value of Mode
    - Rebate values from the Labels are taken and set into the Variables
    - Approval Process: Process Instance Work Item, Process Instance Steps, the users involved in the Approval Process are all initialized
    - Ensure that the Oppty has Account value set.
    */
    /*public ApprovalHistoryPageController()
    {
        isPAEStep = false;

    }*/

    public ApprovalHistoryPageController(ApexPages.StandardController controller)
    {
        //Initialize Oppty
        this.opp = (opportunity)controller.getRecord();
        allPIList = new List<ProcessInstance>();
        opptyId = opp.Id;
        mode = 0;
        dealRegOpptyDiscount = 0.0;
        dealRegAccountDiscount = 0.0;
        dealRegAccountStatus =' ';
        dealRegOpptyStatus =' ';
        publicSectorLinkName = '';
        publicSectorRebatePercent ='';
        //nodeIdToNodeNameMap = new Map<Id,String>();
        piNodeList = new List<ProcessInstanceNode>();
        //get the value of Mode
        mode = getMode();
        PAEStepName = GsmUtilClass.getGSMSettingValue('ApprovalHistory_Step2');
        PAEStepName2 = GsmUtilClass.getGSMSettingValue('ApprovalHistory_Step3');
        isPAEStep = false;
       // isPAEStepCheck = 0;
        system.debug('PAE Step set to false '+isPAEStep);
        sequenceToNodeNameMap = new Map<Id,String>();
        //Initialize Rebate variables
        initRebateValues();

        //Get all the Process Instance records.
        //Hitesh - Added Nodes in the query to get the Step Name
        allPIList = [Select Id,CompletedDate ,
        (Select Id, OriginalActorId, ActorId, CreatedDate From Workitems ORDER BY CreatedDate DESC),
        (Select Id, StepStatus, OriginalActorId, ActorId, Comments, CreatedDate, StepNodeId  From Steps ORDER BY CreatedDate DESC) ,
        (Select  Id, IsDeleted, LastActorId, NodeStatus, ProcessInstanceId, ProcessNodeId, ProcessNodeName From Nodes ORDER BY CreatedDate DESC) From ProcessInstance p WHERE TargetObjectId =: opp.Id ORDER BY CreatedDate DESC];



        //allPIList = [Select (Select Id, OriginalActorId, ActorId, CreatedDate From Workitems ORDER BY CreatedDate DESC), (Select Id, StepStatus, OriginalActorId, ActorId, Comments, CreatedDate From Steps ORDER BY CreatedDate DESC) From ProcessInstance p WHERE TargetObjectId =: opp.Id ORDER BY CreatedDate DESC];
        piStepList = new List<ProcessInstanceStep>();
        displayList = new List<List<String>>();
        userList = new List<User>();
        userIdSet = new Set<Id>();
        ActorName = null;
        OriginalActorName = null;
        showTable = true;
        showLink = true;
        ProcessInstanceWorkitemId = null;
        isApprover = false;
        AccStr = ' ';
        /** Begin Rajesh Kumar SFDC-5781 **/
        issrRequired = false;
        /** End Rajesh Kumar SFDC-5781 **/


        if (allPIList.size() == 0)
            showTable = false;
        else
        {
            for (ProcessInstance pi: allPIList)
            {
                //If the Approval Process is Pending for approval, there will be Workitem associated with Process Instance.
                if (pi.Workitems.size() > 0)
                {
                for(ProcessInstanceNode pin: pi.Nodes){

                        if(pin.NodeStatus == 'Pending' && (PAEStepName.contains(pin.ProcessNodeName) || PAEStepName2.contains(pin.ProcessNodeName)) )

                           {

                             isPAEStep = True;
                             //isPAEStepCheck = 1;
                             system.debug('PAE Step '+isPAEStep);
                         }

                    }

                 //Added for loop to go over all the WorkItems and add all the Approvers in case of multiple Approvers
                    for(ProcessInstanceWorkitem piWI : pi.Workitems)
                    {
                        userIdSet.add(piWI.OriginalActorId);
                        userIdSet.add(piWI.ActorId);


                    }
                    String sysAdminIdSettings = GsmUtilClass.getGSMSettingValue('ApprovalHistory_SysAdminId');
                    String suppIdSettings = GsmUtilClass.getGSMSettingValue('ApprovalHistory_partnerSupportID');
                   // Profile p =[select id from Profile Where Name ='Partner Support'];
                    if ((userIdSet.contains(UserInfo.getUserId()) || UserInfo.getProfileId().contains(sysAdminIdSettings) || UserInfo.getProfileId().contains(suppIdSettings)) && Apexpages.currentPage().getParameters().get('noAction') != '1')
                        {
                            showLink = true;
                            isApprover = true;
                        }
                        else
                        {
                            showLink = false;
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
                    if (UserInfo.getUserId() == IdUserMap.get(pi.Workitems[0].ActorId).DelegatedApproverId)
                    {
                        showLink = true;
                        isApprover = true;
                    }
                }
            }
        }

        //Refresh Opportunity to check the AccountID field. Show a custom error when the AccountId of the Opportunity is null.
         /** Begin Rajesh Kumar SFDC-5781 **/ // Added Partner_Involved__c and SubReseller Account  field name in select query
        Opportunity oppty = [SELECT Id, Discount_Percentage__c,AccountId, Deal_Reg_Account_Status__c, Deal_Reg_Opportunity_Status__c,Deal_Reg_Opportunity_Discount__c, Deal_Reg_Account_Discount__c,partner_involved__c,Sub_Reseller_Account__c FROM Opportunity WHERE Id=: opp.Id];
        /** End Rajesh Kumar SFDC-5781 **/
        dealRegAccountStatus = oppty.Deal_Reg_Account_Status__c;
        dealRegOpptyStatus = oppty.Deal_Reg_Opportunity_Status__c;

        /** Begin Rajesh Kumar SFDC-5781 **/
      //  isPartnertechdata = oppty.partner_involved__r.name == GsmUtilClass.getGSMSettingValue('Oppty_Tech_Data_Partner_Config').split(';')[0]? true : false;
        subresPartlis = GsmUtilClass.getGSMSettingValue('Sub_reseller_partner_list').split(';');
        for (String srprtner : subresPartlis)
        {
        if (oppty.partner_involved__c == srprtner && String.isBlank(oppty.Sub_Reseller_Account__c))
         {
          issrRequired = true;
          break;
         }
        }
       /** End Rajesh Kumar SFDC-5781 **/

        if(oppty.AccountId == null)
        {
            AccStr = null;
            noAccount = true;
        }
        else
        {
            AccStr = String.valueOf(oppty.AccountId);
            noAccount = false;
        }

        ApprovalHisoryTable();
    }
    
    public static void initRebateValues()
    {
        //get public sector rebate
        List<String> tempList = new List<String>();
        tempList = Label.Oppty_Approval_Rebate_3.split(':');

        publicSectorRebatePercent = tempList[0];
        publicSectorLinkName= tempList[1];
    }
    
    /*ApprovalHistoryTable()
    - Adds all the values to a List<List<String>> to show in tabular format    
    */
    public void ApprovalHisoryTable()
    {        
        List<ProcessInstanceWorkitem> piwiList = new List<ProcessInstanceWorkitem>();
        piStepList = new List<ProcessInstanceStep>();
        String pstepName;   
        if (allPIList.size()>0)
        {
            for (ProcessInstance pi: allPIList)
            {
                //If the Opportunity is pending to be approved, get the list of Workitems and add to the Display List.
                if(pi.Workitems.size() > 0)
                {
                    List<string> tempHeaderList = new List<String>();
                    Id pActorId = null;
                    Id pOriginalActorId = null;
                    //Dynamically fetching the current Pending Step of active Instance and removed the Hardcoded value here
                    for(ProcessInstanceNode pin: pi.Nodes){
                        if(pin.NodeStatus == 'Pending')
                         pstepName = 'Step: '+pin.ProcessNodeName; 
                    } 
                    ProcessInstanceWorkitemId = pi.Workitems[0].Id;
                    tempHeaderList.add(pstepName);
                    tempHeaderList.add(' ');
                    tempHeaderList.add(' ');
                    tempHeaderList.add(' ');
                    tempHeaderList.add(' ');
                    tempHeaderList.add(' ');
                    tempHeaderList.add('Pending');
                    tempHeaderList.add(' ');
                    tempHeaderList.add(' ');
                    displayList.add(tempHeaderList);
                    
                    for (ProcessInstanceWorkitem w: pi.Workitems)
                    {
                        List<string> tempList = new List<String>();
                        for (User u: userList)
                        {
                            if(w.ActorId == u.Id)
                                ActorName = u.Name;
                            if(w.OriginalActorId == u.Id)
                                OriginalActorName = u.Name;
                        }
                        LongDate = w.CreatedDate.format();
                        tempList.add('Approve / Reject');
                        tempList.add(LongDate);
                        tempList.add('Pending');
                        tempList.add(OriginalActorName);
                        tempList.add(ActorName);
                        tempList.add(' ');
                        tempList.add(' ');
                        tempList.add(w.OriginalActorId);
                        tempList.add(w.ActorId);
                        displayList.add(tempList);
                    }
                }
                
                //Get the list of all the Process Instance Steps and add to the list. List to be processed later.
                if(pi.Steps.size() > 0)
                {
                    for (ProcessInstanceStep s: pi.Steps)
                    {
                        piStepList.add(s);
                    }
                }
                
                //For all the Nodes of an Instance - Add the node id and name to the map
                
                for(ProcessInstanceNode piNodeItem : pi.Nodes)
                {
                    sequenceToNodeNameMap.put(piNodeItem.ProcessNodeId,piNodeItem.ProcessNodeName);
                    piNodeList.add(piNodeItem);

                }
                
               
        
                
            }
        }
        
        //Based on the Status of the step, the step name and the status message is added to the Display List.
        for (ProcessInstanceStep s: piStepList)
        {
            
            
            
            List<string> tempHeaderList ;
            String stepName = null;
            String stepStat = null; 
            //Commenting the hard coded value
            //Fetching the Step NAme and Status dynamically based on ProcessNodeID in Steps and using created Map
            /*if(s.StepStatus == 'Approved')
            {
                stepName =  'Step: Akamai Partner Account Executive Assignment';
                stepStat = 'Approved';
            }
            if (s.StepStatus == 'Rejected')
            {
                stepName = 'Step: Akamai Partner Account Executive Review';
                stepStat = 'Rejected';
            }*/
            if(s.StepStatus == 'Approved')
            {
                for(ProcessInstanceNode pii : piNodeList)
                {
                    if(s.StepNodeId == pii.ProcessNodeId )
                    {
                       stepName =  sequenceToNodeNameMap.get(pii.ProcessNodeId);
                       stepStat = 'Approved';
                    }
                }
            }
            if(s.StepStatus == 'Rejected' )
            {
                for(ProcessInstanceNode pii : piNodeList)
                {
                    if(s.StepNodeId == pii.Id )
                    {
                       stepName =  sequenceToNodeNameMap.get(pii.ProcessNodeId);
                       stepStat = 'Rejected';
                    }
                }
            }
            if (s.StepStatus == 'Started')
            {
                stepName = 'Approval Request Submitted';
                stepStat = ' ';
            }
            if (s.StepStatus == 'Removed')
            {
                stepName = 'Approval Request Recalled';
                stepStat = 'Recalled';
            }
                    
            if(stepName != null)
            {
                tempHeaderList = new List<string>();
                tempHeaderList.add(stepName);
                tempHeaderList.add(' ');
                tempHeaderList.add(' ');
                tempHeaderList.add(' ');
                tempHeaderList.add(' ');
                tempHeaderList.add(' ');
                tempHeaderList.add(stepStat);
                tempHeaderList.add(' ');
                tempHeaderList.add(' ');
                
                if(tempHeaderList != null && tempHeaderList.size() > 0)
                    displayList.add(tempHeaderList);                        
           } 
            
            List<string> tempList = new List<String>();
            for (User u: userList)
            {
                if(s.ActorId == u.Id)
                    ActorName = u.Name;
                if(s.OriginalActorId == u.Id)
                    OriginalActorName = u.Name;
            }
            LongDate = s.CreatedDate.format();
            tempList.add(' ');
            tempList.add(LongDate);
            tempList.add(s.StepStatus);
            tempList.add(OriginalActorName);
            tempList.add(ActorName);
            if(s.Comments != null)
                tempList.add(s.Comments);
            else
                tempList.add(' ');
            tempList.add(' ');            
            tempList.add(s.OriginalActorId);
            tempList.add(s.ActorId);
            displayList.add(tempList);
         }
    }
    
    //Based on the mode, update the appropriate values on Oppty
    public static string setOpptyRebateValue(String pRebateVal,String oppid)
    {
        opptyId=oppid;
        Opportunity opp = new Opportunity(Id=oppid);
        mode = getMode();
        
        if(mode == 0)
            opp.Rebate__c = pRebateVal;
        else if (mode == 1)
            opp.MDF__c = pRebateVal;
        
        if(pRebateVal== '0')
            opp.Churn_Approval__c = true;
        
        opp.Validation_Override__c = true;
        
        try
        {
            update opp;
        }
        catch (System.Dmlexception ex)
        {
            for (Integer i = 0; i < ex.getNumDml(); i++)
            {
                return '0:'+ex.getDMLMessage(i);    
            }
        }
        //String url = '/p/process/ProcessInstanceWorkitemWizardStageManager?id=' + ProcessInstanceWorkitemId;
        String url = '1:/apex/ApprovalProcessPage?oppId=' + opp.Id + '&noAction=1';
        return(url);
    }

    WebService static String redirectErrorURL(String oppid,Boolean isPAEStepNameCheck,String dealRegOpptyStatusCheck)
    { 
        
        system.debug('Inside web service method' + 'Values '+isPAEStepNameCheck +' ====  '+dealRegOpptyStatusCheck);
        if( isPAEStepNameCheck && (dealRegOpptyStatusCheck == '' || dealRegOpptyStatusCheck == null))
            {
                return '/apex/ErrorPage?ErrorType=6&retURL=/"'+ oppid;
            }
        else
        { 
            return '';
        }

    }

    
    //Set the values of Rebate/ MDF and return to Oppty
    WebService static String redirectURL(String oppid,String rebateType,Boolean isPAEStep1) 
    {
        Id processInstanceId = null;
        if(isPAEStep1)
        {
                pRebateType = rebateType;
                //CR 1899496: Validation Check if deal is already approved
                Opportunity oppty = [SELECT Id, Rebate__c, Discount_Percentage__c, Channel_Manager__r.Partner_Group__c,Sales_Rep_Acknowledge__c,Registration_Status__c,Rebate_TC_Status__c,isRebateTCToShow__c, Deal_Reg_Account_Discount__c, Deal_Reg_Opportunity_Discount__c, Deal_Reg_Opportunity_Status__c, Deal_Reg_Account_Status__c FROM Opportunity where Id = :oppId];
                /**dealRegAccountStatus = oppty.Deal_Reg_Account_Status__c;
                dealRegOpptyStatus = oppty.Deal_Reg_Opportunity_Status__c;
                dealRegAccountDiscount = oppty.Deal_Reg_Account_Discount__c;
                dealRegOpptyDiscount = oppty.Deal_Reg_Opportunity_Discount__c;**/
                if(oppty.Registration_Status__c != 'Pending')
                {
                    return '0:Error - Opportunity approval request already processed';
                }
                if(!oppty.Sales_Rep_Acknowledge__c && isPAEStep1)
                {
                    return '0:Error - Sales Rep Acknowledge needs to be checked to approve this request';
                }
                Boolean isRebateAccepted=false;
                Boolean isRebateRejected=false;
               
                
                    if(oppty.Rebate_TC_Status__c!=null && oppty.Rebate_TC_Status__c=='Accepted')
                       isRebateAccepted=true;
                    else if (oppty.Rebate_TC_Status__c!=null && oppty.Rebate_TC_Status__c=='Rejected')
                       isRebateRejected=true;
                    
                         
                initRebateValues();
                     
               if(isRebateAccepted  && !isRebateRejected)
               {
                    // SFDC-1337
                   if(rebateType == 'approveXPercent')
                   {
                       //Decimal totalRebate = dealRegOpptyDiscount + dealRegAccountDiscount;
                       String totalRebate = oppty.Rebate__c;
                       //return setOpptyRebateValue(String.valueof(totalRebate.intValue()), oppid);
                       return setOpptyRebateValue(totalRebate, oppid);

                   }
                   if(rebateType == 'approvePublicSector')
                       return setOpptyRebateValue(publicSectorRebatePercent, oppid);
                   else if(rebateType=='reject')
                       return '1:/apex/ApprovalProcessPage?oppId=' + oppId + '&noAction=1&reject=1';

                   else 
                       return '0:Error occured';          
               }
                else if (!isRebateAccepted && isRebateRejected)
                {
                    if(rebateType=='reject')
                   {
                    return '1:/apex/ApprovalProcessPage?oppId=' + oppId + '&noAction=1&reject=1';
                   }
                   else 
                     return setOpptyRebateValue('0',oppid);
                }
                else if(rebateType=='reject')
                {
                    return '1:/apex/ApprovalProcessPage?oppId=' + oppId + '&noAction=1&reject=1';
                }
                else 
                    return '0:Error occured';
                }

                else
                {
                    if(rebateType=='reject')
                   {
                    return '1:/apex/ApprovalProcessPage?oppId=' + oppId + '&noAction=1&reject=1';
                   }

                   else
                    {
                        System.debug('ST here');
                        return '1:/apex/ApprovalProcessPage?oppId=' + oppId + '&noAction=1';

                    }
                }
        
    }
}