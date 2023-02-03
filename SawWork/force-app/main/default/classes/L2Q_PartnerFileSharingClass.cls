//SFDC-6265
//Author : @Nagaraj Desai
public without sharing class L2Q_PartnerFileSharingClass {
    public static String themeDisplayed {get;set;}
    public L2Q_PartnerFileSharingClass() {
        themeDisplayed = NAPSettings.getValue('NapPortalTheme');
    }

    public static Map<String, String> generateContentDownloadUrl(ContentVersion contentVersionRecord, Map<String, String> returnValData) {
        ContentVersion duplicateContentVersionRecord = L2Q_ContentDocumentUtilClass.setContentVersion(contentVersionRecord.ContentLocation, contentVersionRecord.PathOnClient, contentVersionRecord.Title, contentVersionRecord.VersionData);
        //SFDC-7295-Start
        duplicateContentVersionRecord.isDuplicate__c = true;
        Network partnerCommunity = [SELECT id, Name,OptionsReputationEnabled FROM Network where name = 'Partners'];
        if(Test.isRunningTest()) {
            duplicateContentVersionRecord.NetworkId = partnerCommunity.id;
        }
        insert duplicateContentVersionRecord;
        System.DEBUG('ND_D : duplicateContentVersionRecord : ' + duplicateContentVersionRecord.Id);
        ContentVersion duplicateContentVersionRecordInserted = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :duplicateContentVersionRecord.Id];
        Id crmOpsUserId = Id.valueOf('005A0000001XPcDIAW');//add to metadata? - Not required as this is a temporary fix
        ContentDocumentLink duplicateDocumentLink = L2Q_ContentDocumentUtilClass.setContentDocumentLink(duplicateContentVersionRecordInserted.ContentDocumentId, crmOpsUserId, 'C', 'AllUsers');
        //link duplicate file to CRM Ops User with Collaborator Access -
        //So that CRM Ops User has access to delete this file
        insert duplicateDocumentLink;
        //SFDC-7295 -End

        Integer fileLifeValue = NAPSettings.getInt('ContentDeliveryFileLifeValue');
        ContentDistribution contentDistributionRecord = new L2Q_ContentDocumentUtilClass.ContentDistributionWrapper()
                                                                                .setName('Name Of The File Here') //Not setting exact file name as preview isn't shown (to avoid SOQL)
                                                                                .setContentVersionId(duplicateContentVersionRecord.Id)
                                                                                .setPreferencesAllowViewInBrowser()
                                                                                .setPreferencesAllowOriginalDownload()
                                                                                .setExpirationDate(DateTime.now().addSeconds(fileLifeValue))
                                                                                .getRecord();
        insert contentDistributionRecord;
        ContentDistribution contentDistributionRecordInserted = [SELECT Id, DistributionPublicUrl, ContentDownloadUrl FROM ContentDistribution WHERE Id = :contentDistributionRecord.Id];
        returnValData.put('fileDownloadUrl', contentDistributionRecordInserted.ContentDownloadUrl);
        returnValData.put('fileLifeValue', String.valueOf(fileLifeValue));
        returnValData.put('duplicateContentDocumentId', duplicateContentVersionRecordInserted.ContentDocumentId);
        return returnValData;
    }

    public static void logErrors(Exception e, String jobName) {
        String errorMessage = 'Error : ' + e.getMessage() + '\n' + 'Stack trace : ' + e.getStackTraceString();
	    Error_Log__c el = new Error_Log__c(Name = jobName, Class__c = 'CFA_ConfirmAttachmentController', Error_Message__c = errorMessage);
	    insert el;
    }

    @AuraEnabled
    public static Map<String, String> getDownloadURL(String contentVersionId) {
        Map<String, String> returnValData = new Map<String, String>();
        if(contentVersionId != null && contentVersionId != '') {
            Boolean hasCurrentContentVersionAccess = CurrentUser.hasFileAccess(Id.valueOf(contentVersionId));
            returnValData.put('hasCurrentContentVersionAccess', String.valueOf(hasCurrentContentVersionAccess));
            if(hasCurrentContentVersionAccess) {
                ContentVersion contentVersionRecord = [SELECT Id, contentLocation, PathOnClient, Title, VersionData, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionId];
                if(contentVersionRecord != null) {
                    try {
                        returnValData = generateContentDownloadUrl(contentVersionRecord, returnValData);
                    }
                    catch (Exception e) {
                        returnValData.put('errorMessage', e.getMessage());
                        logErrors(e, 'getDownloadURL');
                        return returnValData;
                    }
                }
                else {
                    returnValData.put('errorMessage', 'Unable to retrieve the required file');
                    return returnValData;
                }
            }
        } else {
            returnValData.put('hasCurrentContentVersionAccess', String.valueOf(false));
        }
        return returnValData;
    }

    @AuraEnabled
    public static Boolean deleteDuplicateContentDocument(String contentDocumentId) {
        if(contentDocumentId != null && contentDocumentId != '') {
            ContentDocument cd = new ContentDocument();
            cd.Id = contentDocumentId;
            try {
                delete cd;
            }
            catch(Exception e) {
                logErrors(e, 'deleteDuplicateContentDocument');
                return false;
            }
            return true;
        }
        return false;
    }

    // public static Boolean deleteContentVersion(String contentVersionId) {
    //     if(contentVersionId != null && contentVersionId != '') {
    //         try {
    //             delete cd;
    //         }
    //         catch(Exception e) {
    //             System.DEBUG(String.valueOf(e));
    //             return false;
    //         }
    //         return true;
    //     }
    //     return false;
    // }

}