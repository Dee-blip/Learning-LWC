/****************************************************************************
* Class name          :   SC_DD_DealTriggerHandler.cls
* Author              :   Vishnu Vardhan
* Created             :   06-December-2019
* Purpose             :   Deal Desk Trigger Handler
* Test Class          :   SC_DD_DealDeskTest
-------------------------------------------------------------------------------
* MethodName          : Purpose
-------------------------------------------------------------------------------
* +onAfterInsertDeal  :   Handler for onAfterInsert trigger
* +onAfterUpdateDeal  :   Handler for onAfterUpdate Trigger
* +sendEmailNotification  :  on change of Evaluation_Action__c/ Approval_Stage__c => Send Email to Requestor/ Approvers
* -getGraztApproverEmails :   Get List Of SLM/SLD, SLD1, SLD2, SPO emails - to be notified by email
* -getGraztSpecialApprovers : Get Map of GRAZT and their Special Approvers
DATE             DEVELOPER          CR              DESCRIPTION
===========      =========          =======         ===========
 07-May-2020     Vishnu Vardhan     ESESP-3580      Supress approve and reject email notifications to SLD2
 11-May-2020     Vishnu Vardhan     ESESP-3581      To enable special approvers at GRAZT level (in addition to SPOs)
June 18, 2020    Vishnu Vardhan     ESESP-3579      Email Notifications for "Other" Deals
March 12, 2021   Vishnu Vardhan     ESESP-4937      GRAZT changes
****************************************************************************/
public without sharing class SC_DD_DealTriggerHandler {
    static final String SPO_PERMSET = 'SC_DD_SPO';

    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   06-December-2019
    * +onAfterInsertDeal  :   Handler for onAfterInsert trigger
    ****************************************************************************/
    public static void onAfterInsertDeal() {
        sendEmailNotification(Trigger.new, null);
        INSERT SC_DD_DealSharing.getDealSharingRules(Trigger.new);        
    }

    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   06-December-2019
    * +onAfterUpdateDeal  :   Handler for onAfterUpdate Trigger
    ****************************************************************************/
    public static void onAfterUpdateDeal() {
        sendEmailNotification((List<SC_DD_Deal__c>)Trigger.new, (Map<Id, SC_DD_Deal__c>)Trigger.oldMap);
    }

    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   06-December-2019
    * +sendEmailNotification :  on change of Evaluation_Action__c/ Approval_Stage__c => Send Email to Requestor/ Approvers
    ****************************************************************************/
    public static void sendEmailNotification(List<SC_DD_Deal__c> newDeals, Map<Id, SC_DD_Deal__c> oldDealMap) { 

        Id dealEmailTemplateId, otherDealEmailTemplateId;
        
        for(EmailTemplate et: [SELECT Id, Subject, Body, HtmlValue, developerName FROM EmailTemplate WHERE DeveloperName IN ('DD_Deal_Notification', 'DD_Other_Deal_Notification')]) {
            if(et.developerName == 'DD_Deal_Notification') {
                dealEmailTemplateId = et.Id;
            } else if(et.developerName == 'DD_Other_Deal_Notification') {
                otherDealEmailTemplateId = et.Id;
            }
        }

        
        // Get SPO Emails - through SPO Permission set Assignments
        List<String> spoEmails = new List<String>();

        for(PermissionSetAssignment psa: [select id, AssigneeId, Assignee.email from PermissionSetAssignment where PermissionSet.Name = :SPO_PERMSET]) {
            spoEmails.add(psa.Assignee.email);
        }
        // Map: grazt => List of Approvers
        //ESESP-3581      To enable special approvers at GRAZT level (in addition to SPOs)
        Map<String, Set<String>> graztSpecialApprovers = getGraztSpecialApprovers(newDeals);

        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
                //TERR_HIER_1__c, TERR_HIER_2__c, TERR_HIER_3__c, TERR_HIER_4__c, TERR_HIER_5__c

        for(SC_DD_Deal__c deal: [select Id, Name, Evaluation_Action__c, Approval_Stage__c, GSS_Product_Name__c, requestor__r.Name, requestor__r.email, Auto_Escalated__c, Account__r.Name, DGRAT__c,
                                Account__r.TERR_HIER_1__c, Account__r.TERR_HIER_2__c, Account__r.TERR_HIER_3__c, Account__r.TERR_HIER_4__c, Account__r.TERR_HIER_5__c
                                from SC_DD_Deal__c where Id in :newDeals]) 
        { 
            SC_DD_Deal__c oldDeal =  oldDealMap != null ?  oldDealMap.get(deal.Id) : null;

            if(oldDeal == null || deal.Evaluation_Action__c != oldDeal.Evaluation_Action__c || deal.Approval_Stage__c != oldDeal.Approval_Stage__c) {

                Set<string> toAddresses = new Set<string>();
                Set<string> ccAddresses = new Set<string>();
                Account acc = deal.Account__r;
                Set<String> dealGraztSpecialApprovers = graztSpecialApprovers != null && graztSpecialApprovers.containsKey(deal.dgrat__c) ? graztSpecialApprovers.get(deal.dgrat__c): new Set<String>();

                Map<String, Set<String>> dApprovers = getGraztApproverEmails(acc.TERR_HIER_1__c, acc.TERR_HIER_2__c, acc.TERR_HIER_3__c, acc.TERR_HIER_4__c, acc.TERR_HIER_5__c);
                
                // Set TO for Approved and Rejected Deals
                if(deal.Evaluation_Action__c == 'Approved' || deal.Evaluation_Action__c == 'Rejected') {
                    toAddresses.add(System.UserInfo.getUserEmail());

                    // If Deal is Approved/ Rejected by SPO or GRAZT Special Approver, send notification to other SPOs and GRAZT Special Approvers
                    if(FeatureManagement.checkPermission('DD_SPO') || dealGraztSpecialApprovers.contains(UserInfo.getUserEmail())) {
                        ccAddresses.addAll(spoEmails);
                        ccAddresses.addAll(dealGraztSpecialApprovers);
                    }
                    // Requestor - DDA / SPO who created
                    ccAddresses.add(deal.requestor__r.email);
                    // SLM, SLD1, SLD2 in the GRAZT    
                    ccAddresses.addAll(dApprovers.get('SLM/SLD'));
                    ccAddresses.addAll(dApprovers.get('SLD1'));
                    // ESESP-3580 - To Supress approve and reject email notifications to SLD2
                    // ccAddresses.addAll(dApprovers.get('SLD2'));
                } 
                // If Deal is sent back to DDA (by any approver), send email to DDA
                else if(deal.Evaluation_Action__c == 'Pending with DDA') {
                    toAddresses.add(deal.requestor__r.email);
                    ccAddresses.add(System.UserInfo.getUserEmail());
                }
                // If Escalated(Manual), notify SPOs and GRAZT Special Approvers
                // If auto escalated, notify users relevant to the Approval Stage
                else if(deal.Evaluation_Action__c == 'Escalated' ) {
                    if(deal.Approval_Stage__c == 'SPO') {
                        toAddresses.addAll(spoEmails);
                        toAddresses.addAll(dealGraztSpecialApprovers);
                    } else if(dApprovers.containsKey(deal.Approval_Stage__c)){
                        toAddresses.addAll(dApprovers.get(deal.Approval_Stage__c));
                    }
                    ccAddresses.add(deal.requestor__r.email);
                }

                ccAddresses.removeAll(toAddresses);

                // ESESP-3579  Email template is Different for "Other" product deal and normal deals
                Id emailTemplId = deal.GSS_Product_Name__c == 'Other'? otherDealEmailTemplateId: dealEmailTemplateId;

                Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(emailTemplId, System.UserInfo.getUserId(), deal.Id); 
                
                String emailSubject = deal.Auto_Escalated__c? 'Deal ' + deal.Name + ': Auto-Escalated!': mail.getSubject();
                String emailTextBody = mail.getPlainTextBody();
                String updatedHtmlBody = mail.getHtmlBody() 
                                            .replace('{#SC_DD_Deal__c._RequestorName}', deal.requestor__r.Name)
                                            .replace('{#SC_DD_Deal__c._AccountName}', deal.Account__r.Name);

                mail.setHtmlBody(updatedHtmlBody);
                mail.setTargetObjectId(System.UserInfo.getUserId());
                mail.setToAddresses(new List<String>(toAddresses));
                mail.setCcAddresses(new List<String>(ccAddresses));
                mail.saveAsActivity = false;
                mail.setSubject(emailSubject);
                mail.setPlainTextBody(emailTextBody);
                mails.add(mail);
            }
        }

        if(!mails.isEmpty()) {
            Messaging.sendEmail(mails);
        }
    }

    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   06-December-2019
    * -getGraztApproverEmails :   Get List Of SLM/SLD, SLD1, SLD2, SPO emails - to be notified by email
    ****************************************************************************/
    static Map<String, Set<String>> getGraztApproverEmails(String geo, String region, String area, String zone,  String territory) {

        Map<String, Set<String>> graztApproverEmails = new Map<String, Set<String>>{ 'SLM/SLD' => new Set<String>(), 
                                                                                     'SLD1' => new Set<String>(),
                                                                                     'SLD2' => new Set<String>()};
        for( Inv_WorkBox_Region_Mapping__c apprvr : [ select Id, TERR_HIER_1_F__c, TERR_HIER_2_F__c, TERR_HIER_3_F__c, TERR_HIER_4_F__c, TERR_HIER_5_F__c, User__r.email, User__r.manager.email, User__r.manager.manager.email, User__r.manager.manager.manager.email
                                            from  Inv_WorkBox_Region_Mapping__c 
                                            where RecordType.Name = 'DealDesk' 
                                            AND Is_Old__c = false
                                            and TERR_HIER_1_F__c = :geo and 
                                                (  (TERR_HIER_2_F__c = :region and TERR_HIER_3_F__c = :area and TERR_HIER_4_F__c = :zone and TERR_HIER_5_F__c = :territory) 
                                                or (TERR_HIER_2_F__c = :region and TERR_HIER_3_F__c = :area and TERR_HIER_4_F__c = :zone and TERR_HIER_5_F__c = '*') 
                                                or (TERR_HIER_2_F__c = :region and TERR_HIER_3_F__c = :area and TERR_HIER_4_F__c = '*' and TERR_HIER_5_F__c = '*') 
                                                or (TERR_HIER_2_F__c = :region and TERR_HIER_3_F__c = '*' and TERR_HIER_4_F__c = '*' and TERR_HIER_5_F__c = '*') 
                                                or (TERR_HIER_2_F__c = '*' and TERR_HIER_3_F__c = '*' and TERR_HIER_4_F__c = '*' and TERR_HIER_5_F__c = '*') 
                                                )] ) 
        {
            graztApproverEmails.get('SLM/SLD').add(apprvr.User__r.Email);        
            graztApproverEmails.get('SLD1').add(apprvr.User__r.Manager.Email);        
            graztApproverEmails.get('SLD2').add(apprvr.User__r.Manager.Manager.Email);        
        }

        return graztApproverEmails;
    }

    // ESESP-3581 To enable special approvers at GRAZT level (in addition to SPOs)      
    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   11-May-2019
    * -getGraztSpecialApprovers : Get Map of GRAZT and their Special Approvers
    ****************************************************************************/
    public static Map<String, Set<String>> getGraztSpecialApprovers(List<SC_DD_Deal__c> deals) {
        
        // Get GRAZTs of deals
        Set<String> dealGrazts = new Set<String>();
        for(SC_DD_Deal__c dl: deals) {
            dealGrazts.add(dl.dgrat__c);
        }


        Map<String, Set<String>> groupGraztMap = new Map<String, Set<String>>();
        // Fetch SpecialApprovers GroupName of GRAZTs
        for(SC_Utility__mdt dga: [select DeveloperName, Value__c from SC_Utility__mdt where value_text__c = 'DealDesk_DGRAT_Access' and Active__c = true]) {
            
            groupGraztMap.put(dga.DeveloperName, new Set<String>());
            for(String grazt: dga.Value__c.split('\n')) {
                grazt = grazt.trim();
                if(dealGrazts.contains(grazt)) {
                    groupGraztMap.get(dga.DeveloperName).add(grazt);
                }
            }
        }

        // If no SpecialApprovers group found, return. further processing is not needed
        if(groupGraztMap.isEmpty()) {
            return null;
        }

        Map<String, Set<String>> graztSpecialApprovers = new Map<String, Set<String>>();
        // Query for Group Members of SpecialApprovers Group
        // User Email cannot be queried from GroupMember, so it will be fetched seperately
        List<GroupMember> groupMembers = [select id, UserOrGroupId, group.developername from groupmember 
                                                where group.developername in :groupGraztMap.keyset()];
        Set<Id> apprUserIds = new Set<Id>();
        for(GroupMember gm: groupMembers) {
            apprUserIds.add(gm.UserOrGroupId);
        }

        // Map to get Eamil from User ID
        Map<Id, User> userIdMap = new Map<Id, User>([select id, email from user where id in :apprUserIds]);

        // Build Map of DGAT and Approver List
        for(groupmember gm: groupMembers) 
        {
            for( String grazt: groupGraztMap.get(gm.group.developername)){
                if(!graztSpecialApprovers.containsKey(grazt)) {
                    graztSpecialApprovers.put(grazt, new Set<String>());
                }
                String apprEmail = userIdMap.get(gm.UserOrGroupId).email;
                graztSpecialApprovers.get(grazt).add(apprEmail);
            }
            
        }
        return graztSpecialApprovers;
    }
}