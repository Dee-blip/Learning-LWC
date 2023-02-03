public class TranslatePartnerDetailsClass {

    @AuraEnabled
    public static String TranslatePartnerDetailsMethod()
    {
        String returnStatus;
        Id profileId=userinfo.getProfileId();
        String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
        if(profileName != 'Partner Marketing' && profileName!= 'Partner Support')
        {
            returnStatus = 'You are not authorized. \nOnly Partner Marketing and Partner Support users can perform this operation.';
            return returnStatus;
        }
        returnStatus = 'There are no Partner Profiles under approved status for translation.';
        List<String> toEmailAddresses = new List<String>();
        //List<String> listOfLanguages = new List<String> {'German','Spanish','French','Italian','Japanese','Korean','Chinese'};
        // AGH SFDC-9577 changed this to support Portuguese
        List<String> listOfLanguages = PartnerProfileTriggerClass.getSupportedLanguages();
        List<Map<String, String>> partnerDetailsMap = new List<Map<String, String>>();
        //SFDC-6778 : Updated query to support fast track functionality
        List<partner_profile__c> listOfAllPartnerProfiles = [select Id, Language__c, parent_english_profile__c, Partner_Address_Country1__c, Partner_Solutions_RTF__c, Partner_Industry_Awards_Extended__c, Partner_Highlights__c, Partner_About__c, Industries_Served__c, (Select Id,Translation_Status__c from Non_English_Profile__r where Translation_Status__c = 'Ready for Translate' or (parent_english_profile__r.Fast_Track__c = true and Translation_Status__c = 'Translation Completed')) 
                                                             from partner_profile__c 
                                                             where approval_status__c='Approved' and Language__c='English' and isdeleted=false];
        List<partner_profile__c> listOfPartnerProfiles = new List<partner_profile__c>(); 
        for(partner_profile__c eachPartnerProfile : listOfAllPartnerProfiles)
        {
            Integer childRecords = eachPartnerProfile.Non_English_Profile__r.size();
            if(childRecords > 0)
                listOfPartnerProfiles.add(eachPartnerProfile);
        }
        //SFDC-6778 : Updated query to support fast track functionality
        List<partner_profile__c> listOfChildProfiles = [select Id, Language__c, parent_english_profile__c, parent_english_profile__r.Partner_Address_Country1__c, parent_english_profile__r.Partner_Solutions_RTF__c, parent_english_profile__r.Partner_Industry_Awards_Extended__c, parent_english_profile__r.Partner_Highlights__c, parent_english_profile__r.Partner_About__c, parent_english_profile__r.Industries_Served__c 
                                                        from partner_profile__c 
                                                        where parent_english_profile__r.approval_status__c='Approved' and parent_english_profile__r.Language__c='English' and isdeleted=false and parent_english_profile__r.isdeleted=false and (Translation_Status__c='Ready for Translate' or (parent_english_profile__r.Fast_Track__c = true and Translation_Status__c = 'Translation Completed')) and Language__c IN :listOfLanguages];
        if(listOfPartnerProfiles.isEmpty())
            return returnStatus;

        toEmailAddresses.add(GsmUtilClass.getGSMSettingValue('PartnerProfile_Details_Recipient'));
        for(partner_profile__c eachPartnerProfile : listOfPartnerProfiles)
        {
            Map<String, String> m = new Map<String, String>
            {
                'Partner_Address_Country1__c' => String.isBlank(eachPartnerProfile.Partner_Address_Country1__c) ? '' : eachPartnerProfile.Partner_Address_Country1__c.unescapeHtml4(),
                'Partner_Highlights__c' => String.isBlank(eachPartnerProfile.Partner_Highlights__c) ? '' : eachPartnerProfile.Partner_Highlights__c.unescapeHtml4(),
                'Industries_Served__c' => String.isBlank(eachPartnerProfile.Industries_Served__c) ? '' : eachPartnerProfile.Industries_Served__c.unescapeHtml4(),
                'Partner_About__c'=> String.isBlank(eachPartnerProfile.Partner_About__c) ? '' : eachPartnerProfile.Partner_About__c.unescapeHtml4(),
                'Partner_Industry_Awards_Extended__c' => String.isBlank(eachPartnerProfile.Partner_Industry_Awards_Extended__c) ? '' : eachPartnerProfile.Partner_Industry_Awards_Extended__c.unescapeHtml4(),
                'Partner_Solutions_RTF__c' => String.isBlank(eachPartnerProfile.Partner_Solutions_RTF__c) ? '' : eachPartnerProfile.Partner_Solutions_RTF__c.unescapeHtml4(),
                'Parent_English_Profile__c' => String.isBlank(eachPartnerProfile.Id) ? '' : eachPartnerProfile.Id,
                'Id' => String.isBlank(eachPartnerProfile.Id) ? '' : eachPartnerProfile.Id
            };
            partnerDetailsMap.add(m);
        }
        String partnerProfileInJsonFormat = JSON.serializePretty(partnerDetailsMap);
        DateTime dt = DateTime.now();
        String fileName = dt.format('yyyy_MMM_dd_HH_mm_ss') + '_partner_profiles_to_be_translated_eng.json';
        String wsName = GsmUtilClass.getGSMSettingValue('Partner_Profile_English_Version_Folder');
        InsertJSONFileInLib(partnerProfileInJsonFormat,fileName, wsName);
        Boolean mailSent = sendEmailToTranslationTeam(toEmailAddresses,null,partnerProfileInJsonFormat);
        if(mailSent)
        {
            for(partner_profile__c eachPartnerProfile : listOfChildProfiles)
                eachPartnerProfile.Translation_Status__c = 'Submitted for Translation';
            update listOfChildProfiles;
        }
        else
        {
            returnStatus = 'Encountered an error while sending email.';
            return returnStatus;
        }
        returnStatus = String.valueOf(listOfPartnerProfiles.size()) + ' Partner Profiles are sent for translation.';
        return returnStatus;
    }

    public static void InsertJSONFileInLib(String partnerProfileInJsonFormat, String fileName, String wsName)
    {
        List<ContentWorkspaceDoc> insertContentWorkspace = new List<ContentWorkspaceDoc>();
        Blob content = Blob.valueof(partnerProfileInJsonFormat);
        ContentVersion cv = new ContentVersion();
        cv.ContentLocation = 'S';
        cv.VersionData = content;
        cv.Title = filename;
        cv.PathOnClient = filename + '.json';
        insert cv;
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        List<ContentWorkspace> listOfPartnerWorkspace = [SELECT Id FROM ContentWorkspace WHERE Name = :wsName LIMIT 1];

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = cv.ContentDocumentId;
        cdl.ShareType = 'I';
        cdl.Visibility = 'AllUsers';

        if(!listOfPartnerWorkspace.isEmpty())
        {
            ContentWorkspace partnerWorkspace = listOfPartnerWorkspace[0];
            cdl.LinkedEntityId = partnerWorkspace.Id; //Magic happens here
            insert cdl;
        }
    }

    public static Boolean sendEmailToTranslationTeam(List<String> toRecipient,List<String> ccRecipient, String partnerProfileInJsonFormat)
    {
        Messaging.SingleEmailMessage[] sendEmailList = new List<Messaging.SingleEmailMessage>();
        List<EmailTemplate> tplList = [select Id, Body, Subject FROM EmailTemplate WHERE Name = 'Partner Profile Translation Email Template' limit 1];
        if(!tplList.isEmpty())
        {
            EmailTemplate tpl = tplList[0];
            String message = tpl.Body;
            String subject = tpl.Subject;
            List<Messaging.Emailfileattachment> fileAttachments = new List<Messaging.Emailfileattachment>();
            Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
            DateTime dt = DateTime.now();
            String fileName = dt.format('yyyy_MMM_dd_HH_mm_ss') + '_partner_profiles_to_be_translated_eng.json';
            efa.setFileName(fileName);
            Blob partnerProfileInBlobFormat = Blob.valueOf(partnerProfileInJsonFormat);
            efa.setBody(partnerProfileInBlobFormat);
            fileAttachments.add(efa);
            
            Messaging.SingleEmailMessage mail=new Messaging.SingleEmailMessage();
            mail.setToAddresses(toRecipient);
            mail.setSubject(subject);
            if(ccRecipient!=null)
                mail.setCcAddresses(ccRecipient);
            mail.setBccSender(false);
            mail.setUseSignature(false);
            mail.setHtmlBody(message);
            mail.setFileAttachments(fileAttachments);
            mail.setTemplateId(tpl.Id);
            sendEmailList.add(mail);
            List<Messaging.Sendemailresult> results = Messaging.sendEmail(sendEmailList);
            if(results[0].isSuccess()==true)
                return true;
        }
        return false;
    }
    
    @AuraEnabled
    public static String updatePartnerProfiles(String documentName)
    {
        String returnStatus;
        Id profileId=userinfo.getProfileId();
        String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
        if(profileName != 'Partner Marketing' && profileName!= 'Partner Support')
        {
            returnStatus = 'You are not authorized. \nOnly Partner Marketing and Partner Support users can perform this operation.';
            return returnStatus;
        }
        returnStatus = 'Encountered an error in updating Partner Profiles because following Parent Records are not found):\n';
        List<ContentVersion> documentContent = [SELECT Id, Title, VersionData from ContentVersion where Title = :documentName AND IsLatest = TRUE];
        delete [SELECT Id,Title,FileType from ContentDocument WHERE title =:documentName];
        if(!documentContent.isEmpty())
        {
            String language;
            String title;
            Blob docBlobFormat;
            String docStringFormat;
            List<partner_profile__c> translatePartnerDetailsList = new List<partner_profile__c>();
            List<partner_profile__c> childPartnerDetailsList = new List<partner_profile__c>();
            List<String> partner_profile_ids = new List<String>();

            title = documentContent[0].Title.left(5); 
            docBlobFormat = documentContent[0].VersionData;
            docStringFormat = docBlobFormat.toString();
            try
            {
                JSONParser parser = JSON.createParser(docStringFormat);
                while(parser.nextToken()!= null)
                {
                    if(parser.getCurrentName()=='Parent_English_Profile__c')
                    {
                        parser.nextToken();
                        partner_profile_ids.add(parser.getText());
                    }
                }
            }
            catch(Exception e)
            {
                returnStatus = 'Encountered an error due to invalid JSON format.';
                return returnStatus;
            }
            
            if(title == 'de_DE')
                language = 'German';
            else if(title == 'es_ES')
                language = 'Spanish';
            else if(title == 'fr_FR')
                language = 'French';
            else if(title == 'it_IT')
                language = 'Italian';
            else if(title == 'ja_JP')
                language = 'Japanese';
            else if(title == 'ko_KR')
                language = 'Korean';
            else if(title == 'pt_BR')
                language = 'Portuguese';
            else if(title== 'zh_CN')
                language = 'Chinese';
            else
            {
                returnStatus = 'Invalid file name. First 5 characters of file name should signify language.';
                return returnStatus;
            }
            translatePartnerDetailsList = [SELECT Id, (SELECT Id, Translation_Status__c, Language__c, Partner_Solutions_RTF__c, Partner_Industry_Awards_Extended__c, Partner_About__c, Industries_Served__c, Partner_Highlights__c, Partner_Address_Country1__c, Parent_English_Profile__c
                                                       from Non_English_Profile__r 
                                                       where Language__c = :language) 
                                            from partner_profile__c 
                                            where Id IN :partner_profile_ids];

            JSONParser parser = JSON.createParser(docStringFormat);
            while(parser.nextToken() != JSONToken.END_ARRAY)
            {
                if(parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText()!='Id')
                {
                    partner_profile__c child_pp;
                    if(parser.getText() == 'Parent_English_Profile__c')
                    {
                        parser.nextToken();
                        for(partner_profile__c pp : translatePartnerDetailsList)
                            if(pp.Id == parser.getText() && !pp.Non_English_Profile__r.isEmpty())
                                child_pp = pp.Non_English_Profile__r;
                        if(child_pp == null)
                            returnStatus = returnStatus + parser.getText() + '\n';
                    }
                    while(child_pp!= null && parser.nextToken() != JSONToken.END_OBJECT)
                    {
                        String attr = parser.getText();
                        parser.nextToken();
                        if(attr == 'Partner_About__c')
                            child_pp.Partner_About__c = parser.getText();
                        else if(attr == 'Partner_Solutions_RTF__c')
                            child_pp.Partner_Solutions_RTF__c = parser.getText();
                        else if(attr == 'Partner_Industry_Awards_Extended__c')
                            child_pp.Partner_Industry_Awards_Extended__c = parser.getText();
                        else if(attr == 'Industries_Served__c')
                            child_pp.Industries_Served__c = parser.getText();
                        else if(attr == 'Partner_Highlights__c')
                            child_pp.Partner_Highlights__c = parser.getText();
                        else if(attr == 'Partner_Address_Country1__c')
                            child_pp.Partner_Address_Country1__c = parser.getText();
                        else
                        {
                            returnStatus = 'Unknown attribute ' + attr + ' found in JSON file.';
                            return returnStatus;
                        }
                    }
                    if(child_pp!= null)
                    {
                        child_pp.Translation_Status__c = 'Translation Completed';
                        childPartnerDetailsList.add(child_pp);
                    }
                }
            }
            if(returnStatus != 'Encountered an error in updating Partner Profiles because following Parent Records are not found):\n')
                return returnStatus;
            update childPartnerDetailsList;
            DateTime dt = DateTime.now();
            documentName = documentName + '_' + dt.format('HH_mm_ss');
            String wsName = GsmUtilClass.getGSMSettingValue('Partner_Profile_Non_Eng_Version_Folder');
            InsertJSONFileInLib(docStringFormat,documentName,wsName);
            returnStatus = 'Records from ' + documentName + ' successfully uploaded.';
        }
        return returnStatus;
    }

    //SFDC-6778
    @AuraEnabled
    public static String deactivatePartnerProfile(String partnerProfileId) {
        Partner_Profile__c partnerProfileRecord = [SELECT Id, Approval_Status__c FROM Partner_Profile__c WHERE Id = :partnerProfileId];
        //Code Review Comments - move handleUnlockRecord func in try block : Team Review Comments
        try {
            if(partnerProfileRecord.Approval_Status__c == 'Approved' || partnerProfileRecord.Approval_Status__c == 'Pending') {
                PartnerCommCommonController.handleUnlockRecord(partnerProfileRecord.Id);
            }
            partnerProfileRecord.Approval_Status__c = 'Inactive';
            update partnerProfileRecord;
            
        }
        catch (Exception e) {
            return 'Error : ' + e.getMessage();
        }
        return 'This Partner Profile has been successfully deactivated';
    }
}