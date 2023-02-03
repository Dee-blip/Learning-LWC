public with sharing class SF1_SendForOrderAcceptance {
        public static String resultSetCustom(Boolean errorOccured, String returnMessage, String oa_AttachmentList, String emailData, String oaAssociatedOppty) {

                Map<String,String> mapObject = new Map<String,String>();
                if(errorOccured != null) {
                        mapObject.put('errorOccured', String.valueOf(errorOccured));
                }
                if(returnMessage != null) {
                        mapObject.put('returnMessage', returnMessage);
                }
                if(oa_AttachmentList != null) {
                        mapObject.put('oa_AttachmentList', oa_AttachmentList);
                }
                if(emailData != null) {
                        mapObject.put('emailData', emailData);
                }
                if(oaAssociatedOppty != null) {
                        mapObject.put('oaAssociatedOppty', oaAssociatedOppty);
                }

                return JSON.serialize(mapObject);
        }

        public static String constructHtmlData(String contactName, String contactId, String partnerCcEmail, String emailSubject, String htmlBodyOfEmail) {

                Map<String,String> mapObject = new Map<String,String>();

                mapObject.put('contactName', contactName);
                mapObject.put('contactId', contactId);
                mapObject.put('partnerCcEmail', partnerCcEmail);
                mapObject.put('emailSubject', emailSubject);
                mapObject.put('htmlBodyOfEmail', htmlBodyOfEmail);

                return JSON.serialize(mapObject);
        }

        public static String getAssociatedOpptyData(String oaAssociatedOpptyId) {

                Opportunity oppty = [SELECT Id, Partner_Involved__c, Partner_Involved__r.ParentId FROM Opportunity WHERE Id =: oaAssociatedOpptyId];

                return JSON.serialize(oppty);
        }

        @AuraEnabled
        public static String getUIThemeDescription() {
                return GSMLite_UtilClass.getUIThemeDescription();
        }

        @AuraEnabled
        public static String getInitialValidation(String orderApprovalId) {
                CFA_SendEmailController oaObject = new CFA_SendEmailController(Id.valueOf(orderApprovalId), 'fromSF1');
                Map<String, Object> returnValObj = (Map<String, Object>)JSON.deserializeUntyped(oaObject.returnMessageJSON_ForSF1);

                if(returnValObj.get('errorOccured') == 'true') {
                        return oaObject.returnMessageJSON_ForSF1;
                }

                //System.DEBUG('returnValObj in SF1_SendForOrderAcceptance: ' + returnValObj);

                PageReference rtrVal = oaObject.validate();
                System.DEBUG('oaObject.oa.Associated_Opportunity__c in SF1_SendForOrderAcceptance: ' + oaObject.oa.Associated_Opportunity__c);
                System.DEBUG('returnMessageJSON_ForSF1 in SF1_SendForOrderAcceptance: ' + oaObject.returnMessageJSON_ForSF1);
                String returnValJSON = resultSetCustom(true, 'Unknown Error Occured', null, null, null);
                if(oaObject.mode == 0) {
                        returnValJSON = resultSetCustom(true, oaObject.ErrorMessage, null, null, null);
                }
                else if(oaObject.mode == 1) {
                        String htmlData = constructHtmlData(oaObject.contactName, oaObject.opp.CFA_To__c, oaObject.PartnerCcEmail, oaObject.emailSubject, oaObject.EmailBody);
                        returnValJSON = resultSetCustom(false, null, JSON.serialize(oaObject.oaAttachment), htmlData, getAssociatedOpptyData(oaObject.oa.Associated_Opportunity__c));
                }
                return returnValJSON;
        }

        @AuraEnabled
        public static String sendOAEmail(String orderApprovalId, List<Id> listOfCheckedIds, Map<String, String> htmlDataObj) {
                Set<Id> setOfCheckedIds = new Set<Id>(listOfCheckedIds); // converting the list to set for enhancing efficiency in the loop
                CFA_SendEmailController oaObject = new CFA_SendEmailController(Id.valueOf(orderApprovalId), 'fromSF1');
                //System.DEBUG('htmlDataObjJSON: ' + htmlDataObjJSON);
                // Map<String, Object> htmlDataObj = (Map<String, Object>)JSON.deserializeUntyped(htmlDataObjJSON);

                System.DEBUG('htmlDataObj: ' + htmlDataObj);
                oaObject.contactName = String.valueOf(htmlDataObj.get('contactName'));
                oaObject.opp.CFA_To__c = String.valueOf(htmlDataObj.get('contactId'));
                oaObject.PartnerCcEmail = String.valueOf(htmlDataObj.get('partnerCcEmail'));
                oaObject.emailSubject = String.valueOf(htmlDataObj.get('emailSubject'));
                oaObject.EmailBody = String.valueOf(htmlDataObj.get('htmlBodyOfEmail'));

                System.DEBUG('oaObject.opp is: ' + oaObject.opp);
                for(OA_EmailBlast_AttachmentWrapper eachAttachment : oaObject.oaAttachment) {
                        if(setOfCheckedIds.contains(eachAttachment.attach.ContentDocumentId)) {
                                eachAttachment.checked = true;
                        }
                        else {
                          eachAttachment.checked = false;
                        }
                }
                System.DEBUG('oaObject.oaAttachment is: ' + oaObject.oaAttachment);
                oaObject.Preview();
                Map<String, Object> returnValObj = (Map<String, Object>)JSON.deserializeUntyped(oaObject.returnMessageJSON_ForSF1);
                if(returnValObj.get('errorOccured') == 'true') {
                        return oaObject.returnMessageJSON_ForSF1;
                }
                else {
                        oaObject.SendEmail();
                        return oaObject.returnMessageJSON_ForSF1;
                }
                return oaObject.returnMessageJSON_ForSF1;
        }
}