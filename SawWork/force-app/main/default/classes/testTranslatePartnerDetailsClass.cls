@isTest(seeAllData = false)
 private class testTranslatePartnerDetailsClass
{
    static User dmlUser = new User(id=UserInfo.getUserId());    
        
    @testSetUp static void insertCustomSettingsAndCreateData()  
    {   
        System.runAs(utilTestClass.getTestRunUser())    
        {   
            new SobjectBuilder(Environment_Setup__c.sObjectType)    
            .put(Environment_Setup__c.Environment_Type__c, 'Primary')   
            .put(Environment_Setup__c.Active_Org__c, true)  
            .put(Environment_Setup__c.Akam_Id_Start_String__c, 'F-')    
            .create();  
            new SObjectBuilder(Features_Toggle__c.sObjectType)  
                .put(Features_Toggle__c.name, 'isCronErrorMailViaCode') 
                .put(Features_Toggle__c.Toggle__c, false)   
                .create();  
            new SObjectBuilder(PRM_Settings__c.sObjectType) 
                .put(PRM_Settings__c.name, 'NonLitePermissionSets') 
                .put(PRM_Settings__c.Value__c, 'Has_DealRegistration_Access__c,Has_PartnerPlans_Access__c') 
                .create();  
            SObjectFactory.createPartnerUsers(1);   
            User partnerUser = SobjectRepository.getPartnerUser();  
             // create master CM for MDF_Approver__c    
            SobjectFactory.createDealRegUnsubmitted(partnerUser.Contact.AccountId); 
        }   
    }
    
    static testmethod void testTranslatePartnerDetailsMethod()
    {
        User partnerUser = SobjectRepository.getPartnerUser();
        User marketingUser = [select id from user where profile.name='partner marketing' and isactive=true limit 1];
        Partner_Profile__c pp;
        Partner_Profile__c child_pp;
        Test.startTest();
        System.runAs(utilTestClass.getTestRunUser())
        {
            pp = (Partner_Profile__c)new SobjectBuilder(Partner_Profile__c.sObjectType)
                .eagerPopulate()
                .put(Partner_Profile__c.Partner_Account_Name__c, partnerUser.Contact.AccountId)
                .put(Partner_Profile__c.approval_status__c, 'Approved')
                .put(Partner_Profile__c.Language__c,'English')
                .put(Partner_Profile__c.Translation_Status__c,'Ready for Translate')
                .create()
                .getRecord();
            child_pp = (Partner_Profile__c)new SobjectBuilder(Partner_Profile__c.sObjectType)
                .eagerPopulate()
                .put(Partner_Profile__c.Partner_Account_Name__c, partnerUser.Contact.AccountId)
                .put(Partner_Profile__c.approval_status__c, 'Approved')
                .put(Partner_Profile__c.Language__c,'Chinese')
                .put(Partner_Profile__c.Translation_Status__c,'Ready for Translate')
                .put(Partner_Profile__c.Non_English_Profile__r.Parent_English_Profile__c,pp.Id)
                .create()
                .getRecord();
        }
        String partnerProfileInJsonFormat = '[{"Id": "a2n0f00000ISQM0AAP","Parent_English_Profile__c":"a2n0f00000ISQM0AAP","Partner_Solutions_RTF__c": null,"Partner_Industry_Awards_Extended__c": null,"Partner_About__c": "<p>Secured Retail Networks, Inc (SRN) 是为零售业、餐饮业和酒店业安全网络环境提供咨询和集成解决方案的领先提供商。SRN 总部位于加利福尼亚州橘郡，由经验丰富的技术专业人员组成团队，为全球一些知名大品牌管理网络并提供网络支持。从策略和设计到部署和管理，SRN 使客户能够专注于最重要的事项，在安全可靠的网络上发展其核心业务。</p>","Industries_Served__c": "商业服务；金融服务；酒店和旅游；媒体和娱乐；零售和消费品","Partner_Highlights__c": null,"Partner_Address_Country1__c": "美国"}]';
        List<String> toRecipient = new List<String> {'ranreddy@akamai.com'};
        TranslatePartnerDetailsClass.TranslatePartnerDetailsMethod();
        System.runAs(marketingUser)
        {
            TranslatePartnerDetailsClass.TranslatePartnerDetailsMethod();
            
            List<ContentWorkspaceDoc> insertContentWorkspace = new List<ContentWorkspaceDoc>();
            Blob content = Blob.valueof(partnerProfileInJsonFormat);
            List<ContentVersion> cvList = new List<ContentVersion> ();
            ContentVersion cv1 = new ContentVersion();
            cv1.ContentLocation = 'S';
            cv1.VersionData = content;
            cv1.Title = 'de_DE_partner_profiles_for_translation_oct_23';
            cv1.PathOnClient = 'de_DE_partner_profiles_for_translation_oct_23.json';
            cvList.add(cv1);
            ContentVersion cv2 = new ContentVersion();
            cv2.ContentLocation = 'S';
            cv2.VersionData = content;
            cv2.Title = 'es_ES_partner_profiles_for_translation_oct_23';
            cv2.PathOnClient = 'es_ES_partner_profiles_for_translation_oct_23.json';
            cvList.add(cv2);
            ContentVersion cv3 = new ContentVersion();
            cv3.ContentLocation = 'S';
            cv3.VersionData = content;
            cv3.Title = 'fr_FR_partner_profiles_for_translation_oct_23';
            cv3.PathOnClient = 'fr_FR_partner_profiles_for_translation_oct_23.json';
            cvList.add(cv3);
            ContentVersion cv4 = new ContentVersion();
            cv4.ContentLocation = 'S';
            cv4.VersionData = content;
            cv4.Title = 'it_IT_partner_profiles_for_translation_oct_23';
            cv4.PathOnClient = 'it_IT_partner_profiles_for_translation_oct_23.json';
            cvList.add(cv4);
            ContentVersion cv5 = new ContentVersion();
            cv5.ContentLocation = 'S';
            cv5.VersionData = content;
            cv5.Title = 'ja_JP_partner_profiles_for_translation_oct_23';
            cv5.PathOnClient = 'ja_JP_partner_profiles_for_translation_oct_23.json';
            cvList.add(cv5);
            ContentVersion cv6 = new ContentVersion();
            cv6.ContentLocation = 'S';
            cv6.VersionData = content;
            cv6.Title = 'ko_KR_partner_profiles_for_translation_oct_23';
            cv6.PathOnClient = 'ko_KR_partner_profiles_for_translation_oct_23.json';
            cvList.add(cv6);
            ContentVersion cv7 = new ContentVersion();
            cv7.ContentLocation = 'S';
            cv7.VersionData = content;
            cv7.Title = 'pt_BR_partner_profiles_for_translation_oct_23';
            cv7.PathOnClient = 'pt_BR_partner_profiles_for_translation_oct_23.json';
            cvList.add(cv7);
            ContentVersion cv8 = new ContentVersion();
            cv8.ContentLocation = 'S';
            cv8.VersionData = content;
            cv8.Title = 'zh_CN_partner_profiles_for_translation_oct_23';
            cv8.PathOnClient = 'zh_CN_partner_profiles_for_translation_oct_23.json';
            cvList.add(cv8);
            insert cvList;
           
            TranslatePartnerDetailsClass.updatePartnerProfiles('de_DE_partner_profiles_for_translation_oct_23');
            TranslatePartnerDetailsClass.updatePartnerProfiles('es_ES_partner_profiles_for_translation_oct_23');
            TranslatePartnerDetailsClass.updatePartnerProfiles('fr_FR_partner_profiles_for_translation_oct_23');
            TranslatePartnerDetailsClass.updatePartnerProfiles('it_IT_partner_profiles_for_translation_oct_23');
            TranslatePartnerDetailsClass.updatePartnerProfiles('ja_JP_partner_profiles_for_translation_oct_23');
            TranslatePartnerDetailsClass.updatePartnerProfiles('ko_KR_partner_profiles_for_translation_oct_23');
            TranslatePartnerDetailsClass.updatePartnerProfiles('pt_BR_partner_profiles_for_translation_oct_23');
            TranslatePartnerDetailsClass.updatePartnerProfiles('zh_CN_partner_profiles_for_translation_oct_23');
        }
        Test.stopTest();
    }
}