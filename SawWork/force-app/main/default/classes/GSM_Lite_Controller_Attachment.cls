public  class GSM_Lite_Controller_Attachment 
{

    @AuraEnabled
    public static Id uploadFiles(Id parentId, String fileName, String base64Data, String contentType, String fileId) {
        // check if fileId id ''(Always blank in first chunk), then call the saveTheFile method,
        //  which is save the check data and return the attachemnt Id after insert, 
        //  next time (in else) we are call the appentTOFile() method
        //   for update the attachment with reamins chunks   
        if (fileId == '') {
            fileId = saveTheFile(parentId, fileName, base64Data, contentType);
        } else {
            appendToFile(fileId, base64Data);
        }
 
        return Id.valueOf(fileId);
    }
 
    public static Id saveTheFile(Id parentId, String fileName, String base64Data, String contentType) {
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
 
        Attachment oAttachment = new Attachment();
        oAttachment.parentId = parentId;
 
        oAttachment.Body = EncodingUtil.base64Decode(base64Data);
        oAttachment.Name = fileName;
        oAttachment.ContentType = contentType;
 
        insert oAttachment;
 
        return oAttachment.Id;
    }
 
    private static void appendToFile(Id fileId, String base64Data) {
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
 
        Attachment a = [
            SELECT Id, Body
            FROM Attachment
            WHERE Id =: fileId
        ];
 
        String existingBody = EncodingUtil.base64Encode(a.Body);
 
        a.Body = EncodingUtil.base64Decode(existingBody + base64Data);
 
        update a;
    }

    @AuraEnabled
    public static Map<String,List<String>> getInitValues( String objId)
    {
        
        Map<String,List<String>> retBlankValue = new Map<String,List<String>>();
        //Check if User has Access to this record
        for(UserRecordAccess ura : [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE UserId =: UserInfo.getUserId() AND RecordId =: objId])
        {
            if(ura.HasEditAccess == false)
            {
                return retBlankValue;
            }
        }
        // if access then proceed to Initialize values
        Map<String,List<String>> ret = new Map<String,List<String>>();
        ret.put('DocumentType',GSMLite_UtilClass.populatePickList('Legal_Documents__c','Document_Type__c'));
        ret.put('AkamaiType',GSMLite_UtilClass.populatePickList('Legal_Documents__c','Akamai_Standard_or_Customized__c'));

        Id idToProccess = Id.valueof(objId);

        Schema.sObjectType entityType = idToProccess.getSObjectType();
        List<String> temp = new List<String>();
        List<String> tempOpp = new List<String>();
        if(entityType == Account.sObjectType)
        {
            Account a = [ select id,name from Account where id =: objId];
            temp.add(a.id);
            temp.add(a.Name);
            ret.put('Account',temp);
            ret.put('Opportunity',tempOpp);
        }
        else if(entityType == Opportunity.sObjectType)
        {
            Opportunity o = [ select Account.id,Account.name,Id,Name from Opportunity where id =: objId];
            temp.add(o.Account.id);
            temp.add(o.Account.name);
            ret.put('Account',temp);
            tempOpp.add(o.id);
            tempOpp.add(o.name);
            ret.put('Opportunity',tempOpp);
        }
        else if(entityType == Order_Approval__c.sObjectType)
        {
            Order_Approval__c oa = [ select Associated_Opportunity__r.Account.id,Associated_Opportunity__r.Account.Name,Associated_Opportunity__r.Name,Associated_Opportunity__r.Id from Order_Approval__c where id =: objId];
            temp.add(oa.Associated_Opportunity__r.Account.id);
            temp.add(oa.Associated_Opportunity__r.Account.Name);
            ret.put('Account',temp);
            tempOpp.add(oa.Associated_Opportunity__r.Id);
            tempOpp.add(oa.Associated_Opportunity__r.Name);
            ret.put('Opportunity',tempOpp);
        }
        else
        {
            return retBlankValue;
        }
        

        return ret;
        
    }

    @AuraEnabled
    public static String insertDocumentRepoRecord(String docName, String accountId, String effectiveDate, String expirationDate, String akamaiType, String documentType, String originalOpportunityId, String masterLegalDocumentId, String relatedObjectId )
    {
        try
        {
        Legal_Documents__c ld = new Legal_Documents__c();
        ld.Name = docName;
        ld.Account__c = Id.valueof(accountId);
        ld.Effective_Date__c = Date.valueOf(effectiveDate);
        ld.Expiration_Date__c = Date.valueOf(expirationDate);
        ld.Document_Type__c = documentType;
        ld.Akamai_Standard_or_Customized__c = akamaiType;
        ld.Original_Opportunity__c = originalOpportunityId;
        ld.Legal_Documents__c = masterLegalDocumentId;
        ld.Related_Object_Id__c = relatedObjectId;
        insert ld;
        return ld.Id;
        
        }
        catch(Exception e)
        {
            return 'Error : '+e.getMessage()+' '+e.getStackTraceString();
        }
        


    }
   
    @AuraEnabled
    public static String addAttachmenttoRecord(String recordId, String attachmentId)
    {
        try
        {
     

        Attachment l = [select id,name,parentId,Body,ContentType from Attachment where id=: attachmentId];
        Attachment lNew = new Attachment();
        lNew.name = l.name;
        lNew.contentType = l.contentType;
        lNew.Body = l.Body;
        lNew.parentId = recordId;
        insert lNew;
        return 'Success : Attachment(s) have been added!';
        }
        catch(Exception e)
        {
            return 'Error : '+e.getMessage()+' '+e.getStackTraceString();
        }
        


    }


    
}