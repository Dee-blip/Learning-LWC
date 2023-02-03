/*=====================================================================================================+
Class name          :   SC_Jarvis_Attachment_Detail_Ctrl
Author              :   Vamsee Surya
Created             :   01-Aug-2021
Purpose             :   Controller class for Attachment Detail Page
Test Class          :   SC_Jarvis_TestClass

Last Modified   Developer       Purpose             
=============   ==========      =======
01-Aug-21       Vamsee Surya    Initial Development(Jira Ticket# ESESP-5675) 
08-Apr-22		Vamsee Surya	Removing Description Field (Jira Ticket # ESESP-6789)
+=====================================================================================================*/

public with sharing class SC_Jarvis_Attachment_Detail_Ctrl {


    public SC_Jarvis_Attachment_Detail_Ctrl() {

    }


    public class LabelValueWrapper
    {
        @AuraEnabled public string label;
        @AuraEnabled public string value;

        public LabelValueWrapper(String labelString, String valueString){
            label = labelString;
            value = valueString;
        }
    }

    public class attachmentDetailWrapper{
        @AuraEnabled public String title {get;set;}
        @AuraEnabled public String downloadURL {get;set;}
        @AuraEnabled public list<LabelValueWrapper> attachmentDetails {get;set;}

        public attachmentDetailWrapper(String titleValue, String downloadURLValue, list<LabelValueWrapper> attachmentDetailsValue){
            title = titleValue;
            downloadURL = downloadURLValue;
            attachmentDetails = attachmentDetailsValue;
        }
    }

    @AuraEnabled
    public static attachmentDetailWrapper getAttachmentDetail(String attachmentId){
        list<LabelValueWrapper> attachmentLabelValue = new list<LabelValueWrapper>();
        attachmentDetailWrapper eachWrapper;  
        for(ContentDocument eachDoc : [SELECT Id, Title,  Owner.Name, Filetype, FileExtension, Description, Createddate FROM ContentDocument WHERE Id = :attachmentId LIMIT 1]){
            LabelValueWrapper label1 = new LabelValueWrapper('Title', eachDoc.Title);
            LabelValueWrapper label2 = new LabelValueWrapper('Created By', eachDoc.Owner.Name);
            LabelValueWrapper label3 = new LabelValueWrapper('File Type', eachDoc.Filetype);
            LabelValueWrapper label4 = new LabelValueWrapper('File Extension', eachDoc.FileExtension);
            LabelValueWrapper label5 = new LabelValueWrapper('Created Date', string.valueOf(eachDoc.Createddate));
            attachmentLabelValue.add(label1);
            attachmentLabelValue.add(label2);
            attachmentLabelValue.add(label3);
            attachmentLabelValue.add(label4);
            attachmentLabelValue.add(label5);
            eachWrapper = new attachmentDetailWrapper(eachDoc.Title, eachDoc.Id, attachmentLabelValue);
        }

        return eachWrapper;
    }


}