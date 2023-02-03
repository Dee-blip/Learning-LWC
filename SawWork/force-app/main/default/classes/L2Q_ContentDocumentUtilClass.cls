/**
   @author: Nagaraj Desai
   Created this class as part of SFDC-3953 : Attachment Migration To Files
 **/
 
 
public without sharing class L2Q_ContentDocumentUtilClass {
        L2Q_ContentDocumentUtilClass() {

        }

        private static ContentVersion createContentVersion(String contentLocation, String pathOnClient, String title, Blob versionData) {
                ContentVersion contentVersion = new ContentVersion();
                contentVersion.ContentLocation = contentLocation; // S specify this document is in SF, use E for external files
                contentVersion.PathOnClient = pathOnClient; // The files name, extension is very important here which will help the file in preview.
                contentVersion.Title = title; // Display name of the files
                contentVersion.VersionData = versionData; // converting your binary string to Blob
                return contentVersion;
        }

        public static ContentVersion setContentVersion(String contentLocation, String pathOnClient, String title, String versionData) {
                return createContentVersion(contentLocation, pathOnClient, title, EncodingUtil.base64Decode(versionData));
        }

        public static ContentVersion setContentVersion(String contentLocation, String pathOnClient, String title, Blob versionData) {
                return createContentVersion(contentLocation, pathOnClient, title, versionData);
        }

        private static ContentDocumentLink createContentDocumentLink(Id contentDocumentId, Id linkedEntityId, String shareType, String visibility) {
                //Create ContentDocumentLink
                ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
                contentDocumentLink.ContentDocumentId = contentDocumentId;
                contentDocumentLink.LinkedEntityId = linkedEntityId; // you can use objectId,GroupId etc
                contentDocumentLink.ShareType = shareType; // Inferred permission, checkout description of ContentDocumentLink object for more details
                contentDocumentLink.Visibility = visibility;
                return contentDocumentLink;
        }

        public static ContentDocumentLink setContentDocumentLink(Id contentDocumentId, Id linkedEntityId, String shareType, String visibility) {
                return createContentDocumentLink(contentDocumentId, linkedEntityId, shareType, visibility);
        }

        private static ContentWorkspaceDoc createContentWorkspaceDoc(Id contentWorkspaceId, Id contentDocumentId) {
                ContentWorkspaceDoc conWorkSpaceDoc = new ContentWorkspaceDoc();
                conWorkSpaceDoc.ContentWorkspaceId = contentWorkspaceId;
                conWorkSpaceDoc.ContentDocumentId = contentDocumentId;
                return conWorkSpaceDoc;
        }

        public static ContentWorkspaceDoc setContentWorkspaceDoc(Id contentWorkDocId, Id contentDocumentId) {
                return createContentWorkspaceDoc(contentWorkDocId, contentDocumentId);
        }

        private static ContentVersionAttribute__c createContentVersionAttribute(Id contentVersionId, String attributeName, Id partnerAccountId) {
                ContentVersionAttribute__c contentVerAttribute = new ContentVersionAttribute__c();
                contentVerAttribute.ContentVersionId__c = contentVersionId;
                contentVerAttribute.Attribute_Name__c = attributeName;
                contentVerAttribute.Partner_Account__c = partnerAccountId;
                return contentVerAttribute;
        }

        public static ContentVersionAttribute__c setContentVersionAttribute(Id contentVersionId, String attributeName, Id partnerAccountId) {
                return createContentVersionAttribute(contentVersionId, attributeName, partnerAccountId);
        }

        //SFDC-6265
        public class ContentDistributionWrapper {
                ContentDistribution contentDistributionRecord;

                public ContentDistributionWrapper() {
                        this.contentDistributionRecord = new ContentDistribution();
                        this.contentDistributionRecord.PreferencesAllowViewInBrowser = false;
                        this.contentDistributionRecord.preferencesLinkLatestVersion = false;
                        this.contentDistributionRecord.preferencesNotifyOnVisit = false;
                        this.contentDistributionRecord.preferencesAllowOriginalDownload = false;
                        this.contentDistributionRecord.preferencesExpires = false;
                        this.contentDistributionRecord.PreferencesPasswordRequired = false;
                }

                public ContentDistributionWrapper setName(String contentDistributionRecordName) {
                        this.contentDistributionRecord.Name = contentDistributionRecordName;
                        return this;
                }

                public ContentDistributionWrapper setContentVersionId(String contentVersionId) {
                        this.contentDistributionRecord.contentVersionId = contentVersionId;
                        return this;
                }

                public ContentDistributionWrapper setPreferencesAllowViewInBrowser() {
                        this.contentDistributionRecord.PreferencesAllowViewInBrowser = true;
                        return this;
                }

                public ContentDistributionWrapper setPreferencesLinkLatestVersion() {
                        this.contentDistributionRecord.PreferencesLinkLatestVersion = true;
                        return this;
                }

                public ContentDistributionWrapper setPreferencesNotifyOnVisit() {
                        this.contentDistributionRecord.PreferencesNotifyOnVisit = true;
                        return this;
                }

                public ContentDistributionWrapper setPreferencesPasswordRequired() {
                        this.contentDistributionRecord.PreferencesPasswordRequired = true;
                        return this;
                }

                public ContentDistributionWrapper setPreferencesAllowOriginalDownload() {
                        this.contentDistributionRecord.PreferencesAllowOriginalDownload = true;
                        return this;
                }

                public ContentDistributionWrapper setExpirationDate(DateTime expirationDate) {
                        this.contentDistributionRecord.PreferencesExpires = true;
                        this.contentDistributionRecord.ExpiryDate = expirationDate;
                        return this;
                }

                public ContentDistribution getRecord() {
                        return this.contentDistributionRecord;
                }
        }

        //SFDC-9134

        public static String getContentVersionFromCD (String cdid){
                //latest published version id
                List<ContentDocument> cvids =  [Select LatestPublishedVersionId from ContentDocument where id =: cdid  limit 1];
                String retstring = '' ;
                if(cvids.size()>0){
                        retstring = cvids[0].LatestPublishedVersionId;
                }
                return retstring;


        }
}