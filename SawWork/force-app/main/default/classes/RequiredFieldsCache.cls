@isTest
public class RequiredFieldsCache
{
    public static String summ = 'fdas';

    public static IFieldProvider getGenericParentProvider(SObjectType sObjectType)
    {
        if (!genericParentProviders.containsKey(sObjectType))
            genericParentProviders.put(sObjectType, SObjectFactory.provideGenericParent(sObjectType));
        return genericParentProviders.get(sObjectType);
    }
    static Map<SObjectType, IFieldProvider> genericParentProviders = new Map<SObjectType, IFieldProvider>();

public static Map<SObjectType, Map<SObjectField, Object>> cache =
        new Map<SObjectType, Map<SObjectField, Object>>
    {
        Account.sObjectType => new Map<SObjectField, Object>
        {
            Account.Name => SObjectFieldProviders.getProvider('Fixed Length String'),
            Account.BillingCountry => 'USA',
            Account.BillingState => 'MA',
            Account.BillingStreet => '221b baker street',
            Account.BillingPostalCode => '02142',
            Account.BillingCity => 'Boston',
            Account.ShippingCountry => 'USA',
            Account.Type => 'Agency - Active',
            Account.Network_Account__c => false,
            Account.Website => SobjectFieldProviders.getProvider('Unique Website'),
            Account.ShippingState => 'MA'

        },
        Account_Reassignment_Rule__c.sObjectType => new Map<SObjectField, Object>
        {
            Account_Reassignment_Rule__c.Name => 'TSTNMRL',
            Account_Reassignment_Rule__c.Associated_User__c => getGenericParentProvider(User.sObjectType),
            Account_Reassignment_Rule__c.User_Role__c => GSMSettings.getValue('User_Role')
        },
        Account_Reassignment__c.sObjectType => new Map<SObjectField, Object>
        {
            Account_Reassignment__c.Reassign__c =>  true, 
            Account_Reassignment__c.Reassign_Status__c => 'Approval Pending'
        },
        API_Connector_Object__c.sObjectType => new Map<SobjectField, Object>
        {
            API_Connector_Object__c.Name=> 'PulsarSQAForTestClass',
            API_Connector_Object__c.Moniker__c=> 'EG1-HMAC-SHA256',
            API_Connector_Object__c.Crypto_Algorithm__c=> 'HmacSHA256',
            API_Connector_Object__c.Client_Token__c=> 'akab-tydnnhpruy3rteiw-ipb7mmkwmiky76ou',
            API_Connector_Object__c.Client_Secret__c=> 'JgBXtuC2hLl2D8OhwguaQz10eMnpC9Ppq0vrrWdxZFw=',
            API_Connector_Object__c.Access_Token__c=> 'akab-taor2cfmjpoq5dbr-qphdddodfr67rh6u',
            API_Connector_Object__c.Time_Format__c=> 'yyyyMMdd\'T\'HH:mm:ss',
            API_Connector_Object__c.API_Version__c=> 'v1',
            API_Connector_Object__c.Timeout__c=> 120000.0,
            API_Connector_Object__c.Refresh_Token__c=> 'none',
            API_Connector_Object__c.Host__c=> 'akab-bfpklseaga5uqysy-jrvokqxqakhfxmfq.luna.akamaiapis.net',
            API_Connector_Object__c.Named_Credential__c=> 'https://carrierakamai.my.salesforce.com'
        },
        Campaign.sObjectType => new Map<SObjectField, Object>
        {
            Campaign.Name => SObjectFieldProviders.getUniqueStringProvider(),
            Campaign.UTM_Tag__c => 'random_utm'
        },
        Channel_Hierarchy_Map__c.sObjectType => new Map<SobjectField, Object>
        {
            Channel_Hierarchy_Map__c.CHANNEL_GEOGRAPHY__c => 'Carrier APJ',
            Channel_Hierarchy_Map__c.CHANNEL_ID__c => '232323',
            Channel_Hierarchy_Map__c.CHANNEL_LEVEL_1__c => 'TeamL1',
            Channel_Hierarchy_Map__c.CHANNEL_LEVEL_2__c => 'TeamL2',
            Channel_Hierarchy_Map__c.CHANNEL_LEVEL_3__c => 'TeamL3',
            Channel_Hierarchy_Map__c.GLOBAL_PARTNER__c => 'AT&T'
        },
        Contact.sObjectType => new Map<SObjectField, Object>
        {
            Contact.FirstName => 'John',
            Contact.Email => new SObjectFieldProviders.UniqueStringProvider('jdoe_PLACEHOLDER@akamai.com'),
            Contact.Title => 'Director of Engineering',
            Contact.Phone => '1234567890',
            Contact.LastName => 'Doe',
            Contact.MobilePhone => '1234567890',
            Contact.MailingCountry => 'USA',
            Contact.MailingState => 'MA',
            Contact.MailingCity => 'Boston',
            Contact.MailingStreet => 'Broadway',
            Contact.MailingPostalCode => '02142'
        },
        Contract_Product__c.sObjectType => new Map<SobjectField, Object>
        {
            Contract_Product__c.UnitPrice__c => 100,
            Contract_Product__c.Average_Renewal_Usage_MRR__c => 400,
            Contract_Product__c.Average_Renewal_Commit_MRR__c => 400
        },
        ContentVersion.sObjectType => new Map<SObjectField, Object>
        {
            ContentVersion.Title => 'Some Content',
            ContentVersion.PathOnClient => 'some/path',
            ContentVersion.VersionData => Blob.valueOf('data')
        },
        Cron_Batch_Job__c.sObjectType => new Map<SObjectField, Object>
        {
            Cron_Batch_Job__c.Period__c => 'Day',
            Cron_Batch_Job__c.Run_Every__c => 1,
            Cron_Batch_Job__c.Scheduled_To_Run__c => DateTime.now()
        },
        Cron_Batch_Run__c.sObjectType => new Map<SObjectField, Object>
        {
            Cron_Batch_Run__c.Trigger_Batch_Run__c => true,
            Cron_Batch_Run__c.Scheduled_To_Run__c => DateTime.now()
        },
        DRASubprocessConfig__c.sObjectType => new Map<SObjectField, Object>
        {
            DRASubprocessConfig__c.Country__c=>'USA',
            DRASubprocessConfig__c.SDR_Name__c=>UserInfo.getUserId(),
            DRASubprocessConfig__c.Vertical__c => 'Hotel & Travel',
            DRASubprocessConfig__c.Sub_Vertical__c => 'Transportation',
            DRASubprocessConfig__c.Region_or_State__c => 'MA'

        },
        Lead.sObjectType => new Map<SObjectField, Object>
        {
            Lead.LastName => 'Doe',
            Lead.Company => 'ACME',
            Lead.Status => 'New',
            Lead.Product__c => 'Edge Tokenization',
            Lead.Product_Line__c => 'Security',
            Lead.Customer_Type__c => 'Direct',
            Lead.Project_Timeframe__c => '3 months or less',
            Lead.Business_Pain__c => 'Performance',
            Lead.Budget__c => 'Unsure',
            Lead.Lead_Type__c => 'Customer',
            Lead.AKAM_Lead_ID__c => new SObjectFieldProviders.UniqueStringProvider('TSTL_PLACEHOLDER'),
            Lead.Competitor__c => 'No Competitor',
            Lead.Email => 'fdajkl@gmail.com'
        },
        Merge_Contract_Header__c.sObjectType => new Map<SObjectField, Object>
        {
            Merge_Contract_Header__c.Name => new SObjectFieldProviders.UniqueFixedLengthStringProvider('TCTRCT', 8),
            Merge_Contract_Header__c.Currency__c => 'USD',
            Merge_Contract_Header__c.Effective_Start_Date__c => Date.today(),
            Merge_Contract_Header__c.Effective_End_Date__c => Date.today().addMonths(12),
            Merge_Contract_Header__c.Active__c => true
        },
        Opportunity.sObjectType => new Map<SObjectField, Object>
        {
            Opportunity.Name => new SObjectFieldProviders.UniqueFixedLengthStringProvider('TSTSMOP', 10),
            Opportunity.StageName => '1-Create',
            Opportunity.CloseDate => Date.today()
        },
        OpportunityLineItem.sObjectType => new Map<SobjectField, Object>
        {
            OpportunityLineItem.Quantity => 1,
            OpportunityLineItem.UnitPrice => 100,
           // OpportunityLineItem.PriceBookEntryId => getGenericParentProvider(PriceBookEntry.sObjectType),
            OpportunityLineItem.Projected_Monthly_commit_fees__c => 100,
            OpportunityLineItem.Average_Renewal_Commit_MRR__c => 100,
            OpportunityLineItem.NRR__c => 100,
            OpportunityLineItem.Average_Renewal_Usage_MRR__c => 100,
            OpportunityLineItem.Projected_Avg_Rev_Non_Commit__c => 100
        },
        Partner_Marketing_Activity__c.sObjectType => new Map<SobjectField, Object>
        {
            Partner_Marketing_Activity__c.Name => new SobjectFieldProviders.UniqueStringProvider('PMATST_PLACEHOLDER'),
            Partner_Marketing_Activity__c.Activity_Status__c => 'Planned',
            Partner_Marketing_Activity__c.Activity_Start_Date__c => Date.today(),
            Partner_Marketing_Activity__c.Forecast_Leads__c => 10,
            Partner_Marketing_Activity__c.Closed_Deals_Performance__c => 100,
            Partner_Marketing_Activity__c.Monthly_Bookings_Performance__c => 10,
            Partner_Marketing_Activity__c.Activity_Spend__c => 10,
            Partner_Marketing_Activity__c.Activity_Cost__c => 100
        },
        Partner_Marketing_Plan__c.sObjectType => new Map<SobjectField, Object>
        {
            Partner_Marketing_Plan__c.Name => new SobjectFieldProviders.UniqueStringProvider('PPPTST_PLACEHOLDER'),
            Partner_Marketing_Plan__c.Plan_Period__c => '2H ' + Date.today().year(),
            Partner_Marketing_Plan__c.Target_Geography__c => 'AMER',
            Partner_Marketing_Plan__c.Active__c=> true
        },
        PermissionSet.sObjectType => new Map<SObjectField, Object>
        {
            PermissionSet.Name => SObjectFactory.provideUniqueString('TestPermissions'),
            PermissionSet.Label => SObjectFactory.provideUniqueString('Test Permissions')
        },
        PriceBookEntry.sObjectType => new Map<SobjectField, Object>
        {
            PriceBookEntry.Pricebook2Id => Test.getStandardPricebookId(),
            PriceBookEntry.Product2Id => getGenericParentProvider(Product2.sObjectType),
            PriceBookEntry.CurrencyIsoCode => 'USD',
            PriceBookEntry.IsActive => true,
            PriceBookEntry.UnitPrice => 10
        },
        SFDC_Fund_Accural__c.sObjectType => new Map<SObjectField, Object>
        {
            SFDC_Fund_Accural__c.Revenue__c => 10000
        },
        SFDC_Budget__c.sObjectType => new Map<SObjectField, Object>
        {
            SFDC_Budget__c.Active__c => true,
            SFDC_Budget__c.Amount__c => 100,
            SFDC_Budget__c.Budget_Name__c => new SObjectFieldProviders.UniqueStringProvider('TSTBUD'+'_PLACEHOLDER'),
            SFDC_Budget__c.CurrencyIsoCode => 'USD',
            SFDC_Budget__c.Start_Earned_Date__c => Date.Today()-7,
            SFDC_Budget__c.End_Earned_Date__c => new SobjectFieldProviders.UniqueDateProvider(),
            SFDC_Budget__c.Fund_Request_Deadline__c => Date.today()+14,
            SFDC_Budget__c.Fund_Claim_Deadline__c => Date.today()+70
        },
        SFDC_Channel_Account_Plan__c.sObjectType => new Map<SobjectField, Object>
        {
            SFDC_Channel_Account_Plan__c.Name => new SObjectFieldProviders.UniqueStringProvider('TSTPLN_PLACEHOLDER')
        },
        SFDC_MDF__c.sObjectType => new Map<SobjectField, Object>
        {
            SFDC_MDF__c.Name => 'tstfn1',
            SFDC_MDF__c.Status__c => 'Draft',
            SFDC_MDF__c.Amount__c => 100,
            SFDC_MDF__c.Amount_in_corporate_currency__c => 100,
            SFDC_MDF__c.Program_End_Date__c => Date.today().addDays(2),
            SFDC_MDF__c.SOE_or_PubSec_Event__c => 'Yes',
            SFDC_MDF__c.Spender_Confirmed__c => true
        },
        SFDC_MDF_Claim__c.sObjectType => new Map<SobjectField, Object>
        {
            SFDC_MDF_Claim__c.SOE_PubSec_Documentation__c => true,
            SFDC_MDF_Claim__c.Fund_Claim_Activity_Spender__c => 'Akamai',
            SFDC_MDF_Claim__c.Amount__c => 100,
            SFDC_MDF_Claim__c.Status__c => 'Draft'
        },
        Attachment.sObjectType => new Map<SobjectField, Object>
        {
            Attachment.OwnerId => UserInfo.getUserId(),
            Attachment.Name => SobjectFieldProviders.getUniqueStringProvider(),
            Attachment.ContentType => 'image/png',
            Attachment.IsPrivate => false,
            Attachment.Body => Blob.valueOf('akmtst')
        },
        Budget_Allocation__c.sObjectType => new Map<SobjectField, Object>
        {
            Budget_Allocation__c.Amount__c => 100
        },
        Channel_Mapping__c.sObjectType => new Map<SobjectField, Object>
        {
            Channel_Mapping__c.Name => SobjectFieldProviders.getUniqueStringProvider(),
            Channel_Mapping__c.Active__c => true,
            Channel_Mapping__c.Master_Channel_Mapping__c => true,
            /*
           Channel_Mapping__c.MDF_Approver__c => getGenericParentProvider(User.sObjectType),
            Channel_Mapping__c.PAE_ID__c => getGenericParentProvider(User.sObjectType),
            */
            Channel_Mapping__c.FC_Approver__c => 'Fund Claim Queue'
        },
        Order_Approval__c.sObjectType => new Map<SobjectField, Object>
        {
            Order_Approval__c.Type__c => 'CDN',
            Order_Approval__c.Approvals_Required__c => 'Deal Desk; Legal',
            Order_Approval__c.DD_CCG_Expiration_Date__c => Date.today().addDays(-3),
            Order_Approval__c.RecordTypeId => GsmUtilClass.getGSMSettingValue('OA_CCG_Only_Approval_Id')
        },
        Order_Region_Reporting_Region_Mapping__c.sObjectType => new Map<SobjectField, Object>
        {
            Order_Region_Reporting_Region_Mapping__c.Name => 'North America',
            Order_Region_Reporting_Region_Mapping__c.Order_Region__c=>'North America',
            Order_Region_Reporting_Region_Mapping__c.Reporting_Region__c=>'N. America'
        },
        Sales_Approved_Country__c.sObjectType => new Map<SobjectField, Object>
        {
            Sales_Approved_Country__c.Name=>'USA',
            Sales_Approved_Country__c.Order_Region__c=>'North America',
            Sales_Approved_Country__c.Order_Currency__c=>'USD',
            Sales_Approved_Country__c.Sub_Region__c=>'Americas',
            Sales_Approved_Country__c.Region__c=>'Americas',
            Sales_Approved_Country__c.Is_Direct_Allowed__c=>true,
            Sales_Approved_Country__c.Is_Reselling_Allowed__c=>true
        },
        Order_Region_Reporting_Region_Mapping__c.sObjectType => new Map<SobjectField, Object>
        {
            Order_Region_Reporting_Region_Mapping__c.Name => 'North America',
            Order_Region_Reporting_Region_Mapping__c.Order_Region__c=>'North America',
            Order_Region_Reporting_Region_Mapping__c.Reporting_Region__c=>'N. America'
        },
        Sales_Approved_Country__c.sObjectType => new Map<SobjectField, Object>
        {
            Sales_Approved_Country__c.Name=>'USA',
            Sales_Approved_Country__c.Order_Region__c=>'North America',
            Sales_Approved_Country__c.Order_Currency__c=>'USD',
            Sales_Approved_Country__c.Sub_Region__c=>'Americas',
            Sales_Approved_Country__c.Region__c=>'Americas',
            Sales_Approved_Country__c.Is_Direct_Allowed__c=>true,
            Sales_Approved_Country__c.Is_Reselling_Allowed__c=>true
        },
        Partner_Profile__c.sObjectType => new Map<SObjectField, Object>
        {
            Partner_Profile__c.Partner_Address_Country1__c => 'India',
            Partner_Profile__c.Partner_Accreditation__c => 'Ion',
            Partner_Profile__c.Approval_Status__c => 'Draft'
        },
        User.sObjectType => new Map<SObjectField, Object>
        {
            User.LastName => 'DOE',
            User.LocaleSidKey => 'en_US',
            User.Email => SObjectFieldProviders.getUniqueEmailProvider(),
            User.LanguageLocaleKey => 'en_US',
            User.EmailEncodingKey => 'ISO-8859-1',
            User.TimeZoneSidKey => 'America/Denver',
            User.ProfileId => SObjectFactory.provideSalesOpsProfile(),
            User.UserRoleId => (Id)GSMSettings.getValue('TestUserRoleId'),
            User.Alias => SObjectFieldProviders.getUniqueStringProvider(),
            User.CommunityNickname => SObjectFieldProviders.getUniqueStringProvider(),
            User.UserName => SObjectFieldProviders.getUniqueEmailProvider()
            /*
            User.LastName => 'DOE',
            User.LocaleSidKey => 'en_US',
            User.Email => new SObjectFieldProviders.UniqueStringProvider('jhnfd_PLACEHOLDER@akamai.com'),
            User.LanguageLocaleKey => 'en_US',
            User.EmailEncodingKey => 'ISO-8859-1',
            User.TimeZoneSidKey => 'America/Denver',
            User.ProfileId => SObjectFactory.provideSalesOpsProfile(),
            User.UserRoleId => (Id)GSMSettings.getValue('TestUserRoleId'),
            User.Alias => new SObjectFieldProviders.UniqueStringProvider('jdoe_PLACEHOLDER'),
            User.CommunityNickname => new SObjectFieldProviders.UniqueStringProvider('jhn_PLACEHOLDER'),
            User.UserName => new SObjectFieldProviders.UniqueStringProvider('jnfd_PLACEHOLDER@akamai.com')
            */
        }
    };

    public static Map<SObjectField, Object> get(SObjectType sObjectType)
    {
        return cache.containsKey(sObjectType) ?
            cache.get(sObjectType) : new Map<SObjectField, Object>();
    }
}