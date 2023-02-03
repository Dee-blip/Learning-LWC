/*
SFDC-6590 : sausharm : Daily job to send Reminders and Auto approve Account Merge Requests
Tesclass : GSM_AccountMergeApprovalJobTest
*/

global class GSM_AccountMergeApprovalJob  implements Schedulable{
    global void execute(SchedulableContext ctx){
        evaluateForReminderEmailAndAutoApproval();
    }
    
    // SFDC-6590 this Job does following
    // 1. If reminderdays have passed since approval step is not approved,send email to RSM Approver
    // 2. If request remains unapproved after reminder, auto approve only the Step (Winning or Losing)
    public void evaluateForReminderEmailAndAutoApproval(){
        
        
        List<Account_Merge_Request__c> eligibleAMRList = new List<Account_Merge_Request__c>();
        Map<String,Account_Merge_Request__c> eligibleAMRMap = new Map<String,Account_Merge_Request__c>();
        
        // Requests created in last 2 weeks and still unapproved
        // Profile should not be Business Ops and with selective StatusType
        for(Account_Merge_Request__c amr : [select id,CreatedDate,Merge_Status__c,Merge_Account_Status_Type__c, 
                                            Losing_Account_RSM__r.Email,Winning_Account_RSM__r.Email,Approval_Level__c,
                                            Losing_Account_RSM__c,Winning_Account_RSM__c,Losing_Account_Owner__r.Name,
                                            Losing_Account_RSM__r.Name,Winning_Account_Owner__r.Name,
                                            Winning_Account_RSM__r.Name,Losing_Account_AKAM_ID_Text__c,Losing_Account_Name__c,
                                            Winning_Account_Name__c ,Winning_Account_AKAM_ID__c,
                                            Losing_Account_Status_Text__c,Losing_Account_Must_Map_Text__c,
                                            CreatedBy.Name,Winning_Account_Status__c,Winning_Account_Must_Map__c,ORG_URL__c,
                                            Winning_Account_RSM__r.IsActive, Winning_Account_Owner__r.IsActive
                                            
                                            from Account_Merge_Request__c 
                                            where CreatedDate = LAST_N_DAYS:14 AND Merge_Status__c = 'Approval Pending' AND
                                                  CreatedBy.Profile.Name != 'Business Operations' AND
                                           
                                                  (Merge_Account_Status_Type__c = 'Lead to Lead' OR
                                                   Merge_Account_Status_Type__c = 'Lead to Active' OR
                                                   Merge_Account_Status_Type__c = 'Lead to Inactive')]){
     
                 eligibleAMRList.add(amr);
                 eligibleAMRMap.put(amr.id,amr);                                        
        }

        // Get Approval Process related Objects; ProcessInstanceWorkitem fetches the pending Approval
        
        Map<String,String> processInstanceTOWorkitemMap = new Map<String,String>();
        Map<String,Account_Merge_Request__c> processInstanceToAMRMap = new Map<String,Account_Merge_Request__c>();
        List<String > processInstanceIds = new List<String >();
        Set<String> excludeApprovers = new Set<String>{'SPOOL','ONA','POOLUSR1','POOLUSR2','POOLUSR3','POOLUSR4','POOLUSR5','POOLUSR6'};

        for(ProcessInstanceWorkitem pItem : [Select Id,ProcessInstance.TargetObjectId, ProcessInstanceId,OriginalActor.Alias  from ProcessInstanceWorkitem       
                                                 where ProcessInstance.TargetObjectId in: eligibleAMRList])
        {

            if(!excludeApprovers.contains(pItem.OriginalActor.Alias) && 
               eligibleAMRMap.get(pItem.ProcessInstance.TargetObjectId).Winning_Account_RSM__r.IsActive &&  
                eligibleAMRMap.get(pItem.ProcessInstance.TargetObjectId).Winning_Account_Owner__r.IsActive ){
                processInstanceTOWorkitemMap.put(pItem.ProcessInstanceId,pItem.Id);
                processInstanceIds.add(pItem.ProcessInstanceId);
                processInstanceToAMRMap.put(pItem.ProcessInstanceId,eligibleAMRMap.get(pItem.ProcessInstance.TargetObjectId));
            }
            
            
        }
        
        // Based on Process Instance get Node object which holds a Step under a Approval Process
                
        List<Account_Merge_Request__c> reminderEmailToRSMListLosing = new List<Account_Merge_Request__c>();
        List<Account_Merge_Request__c> reminderEmailToRSMListWinning = new List<Account_Merge_Request__c>();
        List<String> autoApproveList = new List<String>();
        
        Integer reminderHours = GsmUtilClass.getGSMSettingValue('Account_Merge_Request_ReminderinHours')==null?72:Integer.valueof(GsmUtilClass.getGSMSettingValue('Account_Merge_Request_ReminderinHours'));
        Integer autoApproveHoursAfterReminder = GsmUtilClass.getGSMSettingValue('Account_Merge_Request_AutoApproveinHours')==null?168:Integer.valueof(GsmUtilClass.getGSMSettingValue('Account_Merge_Request_AutoApproveinHours'));
        
        for( ProcessInstanceNode node : [SELECT Id, NodeStatus, ProcessNodeName, ProcessInstanceId,CreatedDate 
                                           FROM ProcessInstanceNode 
                                           WHERE ProcessInstanceId IN: processInstanceIds AND
                                                 NodeStatus = 'Pending'
                                            ])
        {
            
            // Get Account Merge Requests to Send Email to RSMs for Winning and Losing Accounts
            boolean reminderCondition = node.CreatedDate.addHours(reminderHours)<=DateTime.now();
            if(reminderHours>24){
                reminderCondition = node.CreatedDate.addHours(reminderHours).isSameDay(DateTime.now());
            }
            if(reminderCondition){
                if(node.ProcessNodeName.contains('Losing')){
                    reminderEmailToRSMListLosing.add(processInstanceToAMRMap.get(node.ProcessInstanceId));
                }
                if(node.ProcessNodeName.contains('Winning')){
                    reminderEmailToRSMListWinning.add(processInstanceToAMRMap.get(node.ProcessInstanceId));
                }
            }
            
            // The Approval steps that need to be Approved
            boolean approvalCondition = node.CreatedDate.addHours(reminderHours+autoApproveHoursAfterReminder)<=DateTime.now();
            if(reminderHours+autoApproveHoursAfterReminder>24){
                approvalCondition = node.CreatedDate.addHours(reminderHours+autoApproveHoursAfterReminder).isSameDay(DateTime.now());
            }
            if(approvalCondition){
                autoApproveList.add(processInstanceTOWorkitemMap.get(node.ProcessInstanceId));
            }
            
        }
                                                     
         approveSteps(autoApproveList)  ;                                    
         sendEmailToRSM(reminderEmailToRSMListLosing,reminderEmailToRSMListWinning);
    }
    
    // Approve the Approval steps that have met eligibility
    public void approveSteps(List<String> autoApproveList){
        for(String pid : autoApproveList){
                  
        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        req.setComments('Auto-Approve request based on time elapsed');
        
        //Approve  Record
        req.setAction('Approve');
  
        req.setWorkitemId(pId);
        // Submit the request for approval
        Approval.ProcessResult result = Approval.process(req);
        }
        
    }
    
    // For respective RSMs send Email
    public void sendEmailToRSM(List<Account_Merge_Request__c> amrListLosing,
                                      List<Account_Merge_Request__c> amrListWinning)
    {
        
        EmailTemplate template = [select Id, DeveloperName, Subject, HtmlValue, Body 
                                  from EmailTemplate 
                                  where DeveloperName = 'Account_Merge_Approval_Email_New'];
        
        
        
        
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        
        for(Account_Merge_Request__c amr : amrListLosing){
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage(); 
            String msgSubject = 'Reminder: '+template.Subject;
            msgSubject = msgSubject.replace('{!Account_Merge_Request__c.Losing_Account_Name__c}', amr.Losing_Account_Name__c);
            String htmlbody = template.HtmlValue;
            htmlbody = htmlbody.replace('{!Account_Merge_Request__c.Losing_Account_Name__c}', amr.Losing_Account_Name__c);
            htmlbody = htmlbody.replace('{!Account_Merge_Request__c.Winning_Account_Name__c}', amr.Winning_Account_Name__c );
            htmlbody = htmlbody.replace('{!Account_Merge_Request__c.CreatedBy}', amr.CreatedBy.Name);
            htmlbody = htmlbody.replace('{!Account_Merge_Request__c.Losing_Account_Owner__c}', amr.Losing_Account_Owner__r.Name   );
            htmlbody = htmlbody.replace('{!Account_Merge_Request__c.Losing_Account_RSM__c}', amr.Losing_Account_RSM__r.Name   );
            htmlbody = htmlbody.replace('{!Account_Merge_Request__c.Losing_Account_AKAM_ID_Text__c}', amr.Losing_Account_AKAM_ID_Text__c!=null?amr.Losing_Account_AKAM_ID_Text__c:''  );
            htmlbody = htmlbody.replace('{!Account_Merge_Request__c.Losing_Account_Status_Text__c}', amr.Losing_Account_Status_Text__c !=null?amr.Losing_Account_Status_Text__c:'' );
            htmlbody = htmlbody.replace('{!Account_Merge_Request__c.Losing_Account_Must_Map_Text__c}', amr.Losing_Account_Must_Map_Text__c != null? amr.Losing_Account_Must_Map_Text__c:'' );
            htmlbody = htmlbody.replace('{!Account_Merge_Request__c.Winning_Account_Owner__c}', amr.Winning_Account_Owner__r.name   );
            
            htmlbody = htmlbody.replace('{!Account_Merge_Request__c.Winning_Account_RSM__c}', amr.Winning_Account_RSM__r.name   );
            htmlbody = htmlbody.replace('{!Account_Merge_Request__c.Winning_Account_AKAM_ID__c}', amr.Winning_Account_AKAM_ID__c != null?amr.Winning_Account_AKAM_ID__c:''   );
            htmlbody = htmlbody.replace('{!Account_Merge_Request__c.Winning_Account_Status__c}', amr.Winning_Account_Status__c != null?amr.Winning_Account_Status__c:''   );
            htmlbody = htmlbody.replace('{!Account_Merge_Request__c.Winning_Account_Must_Map__c}', amr.Winning_Account_Must_Map__c == true?'Yes':'No'  );
            htmlbody = htmlbody.replace('{!Account_Merge_Request__c.Org_URL__c}', amr.ORG_URL__c != null?amr.ORG_URL__c:'' );
            htmlbody = htmlbody.replace('{!Account_Merge_Request__c.Id}', amr.id );
            
            List<String> toListEmail = new List<String>();
            toListEmail.add(amr.Losing_Account_RSM__r.email);
            message.setTargetObjectId(amr.Losing_Account_RSM__c);
            message.sethtmlbody(htmlbody);
            message.setsubject(msgSubject);
            message.setSenderDisplayName('Akamai Salesforce'); 
            message.setReplyTo('no-reply@akamai.com');
            
            
            message.setToAddresses(toListEmail);
            message.setSaveAsActivity(false);
            messages.add(message);
        }
        for(Account_Merge_Request__c amr : amrListWinning){
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage(); 
            String msgSubject = 'Reminder: '+template.Subject;
            msgSubject = msgSubject.replace('{!Account_Merge_Request__c.Losing_Account_Name__c}', amr.Losing_Account_Name__c);
            String htmlbody = template.HtmlValue;
            htmlbody = htmlbody.replace('{!Account_Merge_Request__c.Losing_Account_Name__c}', amr.Losing_Account_Name__c);
            htmlbody = htmlbody.replace('{!Account_Merge_Request__c.Winning_Account_Name__c}', amr.Winning_Account_Name__c );
            htmlbody = htmlbody.replace('{!Account_Merge_Request__c.CreatedBy}', amr.CreatedBy.Name);
            htmlbody = htmlbody.replace('{!Account_Merge_Request__c.Losing_Account_Owner__c}', amr.Losing_Account_Owner__r.Name   );
            htmlbody = htmlbody.replace('{!Account_Merge_Request__c.Losing_Account_RSM__c}', amr.Losing_Account_RSM__r.Name   );
            htmlbody = htmlbody.replace('{!Account_Merge_Request__c.Losing_Account_AKAM_ID_Text__c}', amr.Losing_Account_AKAM_ID_Text__c!=null?amr.Losing_Account_AKAM_ID_Text__c:''  );
            htmlbody = htmlbody.replace('{!Account_Merge_Request__c.Losing_Account_Status_Text__c}', amr.Losing_Account_Status_Text__c !=null?amr.Losing_Account_Status_Text__c:'' );
            htmlbody = htmlbody.replace('{!Account_Merge_Request__c.Losing_Account_Must_Map_Text__c}', amr.Losing_Account_Must_Map_Text__c != null? amr.Losing_Account_Must_Map_Text__c:'' );
            htmlbody = htmlbody.replace('{!Account_Merge_Request__c.Winning_Account_Owner__c}', amr.Winning_Account_Owner__r.name   );
            
            htmlbody = htmlbody.replace('{!Account_Merge_Request__c.Winning_Account_RSM__c}', amr.Winning_Account_RSM__r.name   );
            htmlbody = htmlbody.replace('{!Account_Merge_Request__c.Winning_Account_AKAM_ID__c}', amr.Winning_Account_AKAM_ID__c != null?amr.Winning_Account_AKAM_ID__c:''   );
            htmlbody = htmlbody.replace('{!Account_Merge_Request__c.Winning_Account_Status__c}', amr.Winning_Account_Status__c != null?amr.Winning_Account_Status__c:''   );
            htmlbody = htmlbody.replace('{!Account_Merge_Request__c.Winning_Account_Must_Map__c}', amr.Winning_Account_Must_Map__c == true?'Yes':'No'  );
            htmlbody = htmlbody.replace('{!Account_Merge_Request__c.Org_URL__c}', amr.ORG_URL__c != null?amr.ORG_URL__c:'' );
            htmlbody = htmlbody.replace('{!Account_Merge_Request__c.Id}', amr.id );
            List<String> toListEmail = new List<String>();
            toListEmail.add(amr.Winning_Account_RSM__r.email);
            message.setTargetObjectId(amr.Winning_Account_RSM__c);
            message.sethtmlbody(htmlbody);
            message.setsubject(msgSubject);
            message.setSenderDisplayName('Akamai Salesforce'); 
            message.setReplyTo('no-reply@akamai.com');
            message.setTemplateID(template.Id); 
            
            message.setToAddresses(toListEmail);
            message.setSaveAsActivity(false);
            messages.add(message);
        }
        
        Messaging.sendEmail(messages); 
    }




}