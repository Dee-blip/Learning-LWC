public class ApprovalDetailClass 
{
    public static void mailAppDetailsForCase(Map<Id,Id> adCaseMap,Map<Id,Approval_Details__c> newMap)
    {
        List<Messaging.Singleemailmessage> emailList = new List<Messaging.Singleemailmessage>();
		List<String> adCaseRT = new List<String>(); 
        String orgWideName = ''; Id orgWideEmailId;  
        System.debug('Entered ApprovalDetailClass');
        EmailTemplate adEmailTemp = [SELECT Id,Name,DeveloperName
                                     FROM EmailTemplate
                                     WHERE Folder.Name = 'Order Approval'
                                     AND Name = 'Escalation Template' limit 1
                                    ];
        
        List<SC_Order_Approval__mdt> utilMDT = [SELECT MasterLabel,Value__c 
                                                FROM SC_Order_Approval__mdt 
                                                WHERE Active__c = TRUE
                                                AND MasterLabel IN ('AutoEmail AD for Case RT','OrgWide Name')
                                               ];
        Environment_Setup__c environmentSetup = Environment_Setup__c.getOrgDefaults();
        String akamCaseIdStart = environmentSetup.Akam_Id_Start_String__c;
        
        for(SC_Order_Approval__mdt mdt : utilMDT)
        {
            if(mdt.MasterLabel == 'AutoEmail AD for Case RT')
            {
                adCaseRT = mdt.Value__c.split(',');
            }
            else if(mdt.MasterLabel == 'OrgWide Name')
            {
                orgWideName = mdt.Value__c;
            }
        }
        
        if(String.isNotBlank(orgWideName))
            orgWideEmailId = [SELECT Id 
                              FROM OrgWideEmailAddress 
                              WHERE DisplayName = :orgWideName limit 1].Id;        
        
        Map<Id,String> caseRTNameMap = new Map<Id,String>();
        
        Map<Id,Case> caseMap = new Map<Id,Case>();
        
        caseMap = new Map<Id,Case>();
        Map<Id,Case> RelatedCaseMap = new Map<Id,Case>([SELECT AccountId,Account.Name,RecordTypeId,RecordType.Name,AKAM_Case_ID__c,
                                    Opportunity__r.Name,Opportunity__r.Owner.Name,Order_Approval__c,Approver__c,Approver__r.Email,
                                    Order_Approval__r.AKAM_OrderApproval_ID__c,OwnerId,Owner.Name,CaseAutoId__c,Opportunity__r.Owner.Email,
                                    Approver__r.FirstName,Approver__r.LastName, Sub_Type__c 
                                    FROM Case
                                    WHERE ID IN :adCaseMap.values()
                                   ]);
        for(Case cs: RelatedCaseMap.Values()){
           if( adCaseRT.contains(cs.RecordType.Name)) {
               caseMap.put(cs.Id,cs);           
           }
        }
        Environment_Setup__c es = Environment_Setup__c.getInstance();
        for(Approval_Details__c ad : [Select Id, Related_To__c, Name,Related_To__r.Account.Name,Related_To__r.Opportunity__r.Name, Approval_Requested_By__c,
                                      Approval_Details_Description__c, Approver_New__c, AKAM_Created_Date__c, Related_To__r.AKAM_Case_ID__c,
                                      Related_To__r.Opportunity__r.Owner.Email,Approval_Requested_By__r.Name,recordtype.name
                                      FROM Approval_Details__c where ID IN :newMap.KeySet()]){
            if(ad.Related_To__r.Opportunity__r.Owner.Email != 'eae-ops@akamai.com'){
            	Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                String approver = '';
                if(RelatedCaseMap.get(ad.Related_To__c).Approver__r.FirstName != null && RelatedCaseMap.get(ad.Related_To__c).Approver__r.LastName != NULL){
                    approver = RelatedCaseMap.get(ad.Related_To__c).Approver__r.FirstName + ' ' + RelatedCaseMap.get(ad.Related_To__c).Approver__r.LastName;                                  
                }                              
                                               
                String subject = 'Approval Request for Case ['+akamCaseIdStart + RelatedCaseMap.get(ad.Related_To__c).CaseAutoId__c+'] is Created';
                String body = 'Go to Approval Request: <a href="'+es.CName_Url__c +akamCaseIdStart + RelatedCaseMap.get(ad.Related_To__c).CaseAutoId__c+'">'+ es.CName_Url__c+akamCaseIdStart + RelatedCaseMap.get(ad.Related_To__c).CaseAutoId__c+'</a> <br><br>'+
                '<table border="1" style="border-collapse: collapse;">'+
                           '<tr><td>Case #:</td><td>'+akamCaseIdStart + RelatedCaseMap.get(ad.Related_To__c).CaseAutoId__c+'</td></tr>'+
                           '<tr><td>Account: </td><td>'+RelatedCaseMap.get(ad.Related_To__c).Account.Name+'</td></tr>'+
                           '<tr><td>Opportunity:</td><td>'+RelatedCaseMap.get(ad.Related_To__c).Opportunity__r.Name+'</td></tr>'+
                           '<tr><td>Type:</td><td>'+RelatedCaseMap.get(ad.Related_To__c).RecordType.Name+'</td></tr>'+
                           '<tr><td>Requested By:</td><td>'+ad.Approval_Requested_By__r.Name+'</td></tr>'+
                           '<tr><td>Approval Description:</td><td>'+ad.Approval_Details_Description__c+'</td></tr>'+
                           '<tr><td>Approver:</td><td>'+approver+'</td></tr>'+
                           '<tr><td>Date Time Opened/Created:</td><td>'+System.now()+'</td></tr>'+
                '</table>';
                email.setHtmlBody(body);
                email.setSubject(subject);
                email.setToAddresses(new List<String>{RelatedCaseMap.get(ad.Related_To__c).Opportunity__r.Owner.Email} );
                email.setOrgWideEmailAddressId(orgWideEmailId);
                email.setSaveAsActivity(false);
                emailList.add(email);                                  
            }                              
            
        }
        
        String subject = '';
        for(Id appDetId : adCaseMap.keyset())
        {
            if(caseMap.containsKey(adCaseMap.get(appDetId) ))
            {
                Messaging.Singleemailmessage email = new Messaging.Singleemailmessage();
                subject = 'Action Required: [AKAM-CASE #' + akamCaseIdStart + caseMap.get(adCaseMap.get(appDetId)).CaseAutoId__c + '](Detail :' + newMap.get(appDetId).Name + ') for '+caseMap.get(newMap.get(appDetId).Related_To__c).Account.Name+' has been requested for '+ caseMap.get(newMap.get(appDetId).Related_To__c).Sub_Type__c +' Approval.';

                email = Messaging.renderStoredEmailTemplate(adEmailTemp.Id, caseMap.get(newMap.get(appDetId).Related_To__c).Approver__c,appDetId);
                email.setSubject(subject);
                //email.setTemplateId(adEmailTemp.Id);
                //email.setTargetObjectId(caseMap.get(newMap.get(appDetId).Related_To__c).OwnerId);
                //email.setWhatId(adCaseMap.get(appDetId));
                email.setOrgWideEmailAddressId(orgWideEmailId);
                email.setSaveAsActivity(false);
                emailList.add(email);
            }
        }
        if(emailList.size()>0)
        	Messaging.sendEmail(emailList);
    }
}