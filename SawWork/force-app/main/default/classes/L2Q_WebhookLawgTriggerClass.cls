public without sharing class L2Q_WebhookLawgTriggerClass {
    
    public static void extractDocuSignEnvelopFromLawgs(List<WebhookLawg__c> newHookList) {
            try {
        Map<String, L2Q_DocuSignStatusListener.DocuSignEnvelopHook> mapOfDocuSignEnvelopIdVsLawgObject = new Map<String, L2Q_DocuSignStatusListener.DocuSignEnvelopHook>();
        Map<String, WebhookLawg__c> mapOfDocuSignEnvelopIdVsWebhookLawg = new Map<String, WebhookLawg__c>();
        for(WebhookLawg__c eachLawg : newHookList) {
            L2Q_DocuSignStatusListener.DocuSignEnvelopHook lawgObject = (L2Q_DocuSignStatusListener.DocuSignEnvelopHook) JSON.deserialize(eachLawg.JSON_Response__c, L2Q_DocuSignStatusListener.DocuSignEnvelopHook.Class);
            mapOfDocuSignEnvelopIdVsLawgObject.put(lawgObject.envelopeId, lawgObject);
            mapOfDocuSignEnvelopIdVsWebhookLawg.put(lawgObject.envelopeId, eachLawg);
        }
        Map<Id, String> mapOfPassthroughDetailIdVsDocuSignEnvelopId = new Map<Id, String>();

        Map<Id, Partner_Passthrough_Detail__c> mapOfPOAIdVsPassthroughDetail = new Map<Id, Partner_Passthrough_Detail__c>();
        List<Partner_Passthrough_Detail__c> listOfDocuSignEnvelopDetailToUpdate = new List<Partner_Passthrough_Detail__c>();
        Set<Id> listOfCompletedDocuSignEnvelopPOAIds = new Set<Id>();
        Set<Id> listOfRejectedDocuSignEnvelopPOAIds = new Set<Id>();
        Set<Id> listOfAcceptedAccountIds = new Set<Id>();
        for(Partner_Passthrough_Detail__c eachDetail : [SELECT Id, DocuSignEnvelopId__c, End_Customer_Account__c,DocuSignEnvelopStatus__c, Partner_Order_Acceptance_Document__c, CreatedBy.Email, Customer_Name__c FROM 
                                                            Partner_Passthrough_Detail__c WHERE DocuSignEnvelopId__c IN :mapOfDocuSignEnvelopIdVsLawgObject.keySet()]) {
            L2Q_DocuSignStatusListener.DocuSignEnvelopHook requiredLawg = mapOfDocuSignEnvelopIdVsLawgObject.get(eachDetail.DocuSignEnvelopId__c);
            eachDetail.DocuSignEnvelopStatus__c = requiredLawg.status;
            if(requiredLawg.status.equalsIgnoreCase('completed')) {
                eachDetail.DocuSignEnvelopCompletionDateTime__c = DateTime.valueOf(requiredLawg.completedDateTime.replace('T', ' ').subString(0, 19));
                listOfCompletedDocuSignEnvelopPOAIds.add(eachDetail.Partner_Order_Acceptance_Document__c);
                listOfAcceptedAccountIds.add(eachDetail.End_Customer_Account__c);
            } else {
                listOfRejectedDocuSignEnvelopPOAIds.add(eachDetail.Partner_Order_Acceptance_Document__c);
            }

            mapOfPOAIdVsPassthroughDetail.put(eachDetail.Partner_Order_Acceptance_Document__c, eachDetail);
            listOfDocuSignEnvelopDetailToUpdate.add(eachDetail);

            WebhookLawg__c requiredHook = mapOfDocuSignEnvelopIdVsWebhookLawg.get(eachDetail.DocuSignEnvelopId__c);
            requiredHook.Partner_Passthrough_Detail__c = eachDetail.Id;

            mapOfPassthroughDetailIdVsDocuSignEnvelopId.put(eachDetail.Id, eachDetail.DocuSignEnvelopId__c);
            
            
        }
            
        sendEmail(listOfCompletedDocuSignEnvelopPOAIds, listOfRejectedDocuSignEnvelopPOAIds, mapOfPOAIdVsPassthroughDetail);
          

        if(listOfDocuSignEnvelopDetailToUpdate.size() > 0) {
                update listOfDocuSignEnvelopDetailToUpdate;
                List<ContentVersion> listOfContentVersion = new List<ContentVersion>();
                for(Partner_Passthrough_Detail__c ptd : listOfDocuSignEnvelopDetailToUpdate) {
                    if(ptd.DocuSignEnvelopStatus__c.equalsIgnoreCase('completed')) {
                        L2Q_DocuSignCalloutClass.getCompletedDocumentDetails(mapOfPassthroughDetailIdVsDocuSignEnvelopId.get(ptd.Id), ptd.Id);
                    }
                }
        }

        if(listOfAcceptedAccountIds.size() > 0) {
            List<Account> acceptedAccounts = [SELECT Id, T_Cs_Signed__c FROM Account WHERE Id IN :listOfAcceptedAccountIds];
            for(Account ithAccount : acceptedAccounts) {
                ithAccount.T_Cs_Signed__c = true;
                ithAccount.Validation_Override__c = true;
            }
            update acceptedAccounts;
        }
    }catch(Exception ee)
    {
        Sawyer.saw(ee);
    }
    }

    public static void sendEmail(Set<Id> completedPOAIds, Set<Id> rejectedPOAIds, Map<Id, Partner_Passthrough_Detail__c> mapOfPOAIdVsPassthroughDetail) 
    {
        try {

            Set<Id> listOfPOAIds = new Set<Id>();
            listOfPOAIds.addAll(completedPOAIds);
            listOfPOAIds.addAll(rejectedPOAIds);

            Map<Id, Partner_Order_Acceptance_Document__c> mapOfPOA = new Map<Id, Partner_Order_Acceptance_Document__c> 
                ([SELECT Id, CreatedBy.Email, POA_Email_List__c, Name , Opportunity__r.Partner_Involved__r.Name, Opportunity__r.Account.Name, Opportunity__r.Channel_Manager__r.PAE_email__c
                 FROM Partner_Order_Acceptance_Document__c 
                 WHERE Id IN :listOfPOAIds]);

            EmailTemplate completedTemplate;
            EmailTemplate rejectedTemplate;
            String partnerSupportEmailId = NAPSettings.getValue('PartnerSupportOrgWideEmailId');
            String urlPrefix;

            if(System.URL.getSalesforceBaseUrl().getHost().contains('qa'))
                urlPrefix = NAPSettings.getValue('PartnerCommunityURL_QA');
            else
                urlPrefix = NAPSettings.getValue('PartnerCommunityURL_Prod');

            for(EmailTemplate eachTemplate : [SELECT Id, DeveloperName, Body, HtmlValue, Subject 
                    FROM EmailTemplate WHERE DeveloperName IN ('PassThrough_Completed', 'PassThrough_Rejected')]) 
            {
                if(eachTemplate.DeveloperName.equalsIgnoreCase('PassThrough_Completed')) {
                    completedTemplate = eachTemplate;
                } else if(eachTemplate.DeveloperName.equalsIgnoreCase('PassThrough_Rejected')) {
                    rejectedTemplate = eachTemplate;
                }
            }



            List < Messaging.SingleEmailMessage > sendEmailList = new List < Messaging.SingleEmailMessage > ();


            for(Id eachPOAId : listOfPOAIds) 
            {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                Partner_Order_Acceptance_Document__c eachPOA = mapOfPOA.get(eachPOAId);
                Set<String> toAddresses = new Set<String>();
                if(mapOfPOAIdVsPassthroughDetail.get(eachPOAId).CreatedBy.Email != null) {
                    //toAddresses.add([SELECT ID, Email FROM USER WHERE Id = :mapOfPOAIdVsPassthroughDetail.get(eachPOA).CreatedById][0].Email);
                    toAddresses.add(mapOfPOAIdVsPassthroughDetail.get(eachPOAId).CreatedBy.Email);
                }
                if(eachPOA.Opportunity__r.Channel_Manager__r.PAE_email__c!=null) {
                    toAddresses.add(eachPOA.Opportunity__r.Channel_Manager__r.PAE_email__c);
                }
                mail.setToAddresses(new List<String>(toAddresses));
                EmailTemplate tncTemplate = completedPOAIds.contains(eachPOAId) ? completedTemplate : rejectedTemplate;

                String plainTextBody = tncTemplate.Body
                    .replaceAll('#CustomerContactName#', mapOfPOAIdVsPassthroughDetail.get(eachPOAId).Customer_Name__c)
                    .replaceAll('#CustomerAccountName#', eachPOA.Opportunity__r.Account.Name)
                    .replaceAll('#POAName#', eachPoa.Name)
                    .replaceAll('#POALink#', urlPrefix + '/'+ eachPoa.Id)
                    .replaceAll('#PartnerInvolvedName#', eachPOA.Opportunity__r.Partner_Involved__r.Name);

                mail.setPlainTextBody(plainTextBody);
                String htmlBody = tncTemplate.HtmlValue
                    .replaceAll('#CustomerContactName#', mapOfPOAIdVsPassthroughDetail.get(eachPOAId).Customer_Name__c)
                    .replaceAll('#CustomerAccountName#', eachPOA.Opportunity__r.Account.Name)
                    .replaceAll('#POAName#', eachPoa.Name)
                    .replaceAll('#POALink#', urlPrefix + '/'+ eachPoa.Id)
                    .replaceAll('#PartnerInvolvedName#', eachPOA.Opportunity__r.Partner_Involved__r.Name);

                mail.setHtmlBody(htmlBody);
                mail.setSubject(tncTemplate.Subject.replaceAll('#CustomerAccountName#', eachPOA.Opportunity__r.Account.Name));
                mail.setWhatId(eachPOAId);
                mail.setSaveAsActivity(true);
                mail.setReplyTo('noreply@akamai.com');
                // partner support email address
                mail.setOrgWideEmailAddressId(partnerSupportEmailId);
                sendEmailList.add(mail);
            }

            System.DEBUG(LoggingLevel.ERROR, 'ND_D : ' + sendEmailList.size());
            System.DEBUG(LoggingLevel.ERROR, 'ND_D : ' + sendEmailList);

            if (!sendEmailList.isEmpty()) {
                Messaging.sendEmail(sendEmailList, false);
            }
        
        } catch(Exception e) {
                Sawyer.saw(e);
        }

    }
}