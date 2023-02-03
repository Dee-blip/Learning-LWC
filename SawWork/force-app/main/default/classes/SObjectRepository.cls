@isTest
public class SObjectRepository
{
    private static Map<SobjectType, Set<SobjectField>> fieldsToBeRefreshed = new Map<SobjectType, Set<SobjectField>>
    {
        SFDC_MDF__c.sObjectType => new Set<SobjectField>{SFDC_MDF__c.Id, SFDC_MDF__c.Account__c, SFDC_MDF__c.Status__c, SFDC_MDF__c.Amount__c, SFDC_MDF__c.Funding_Approved__c, SFDC_MDF__c.CurrencyIsoCode, SFDC_MDF__c.Program_End_Date__c, SFDC_MDF__c.Fund_Request_Campaign__c, SFDC_MDF__c.OwnerId, SFDC_MDF__c.FCM__c, SFDC_MDF__c.Reserve_Closed__c, SFDC_MDF__c.Claimed_Amount__c, SFDC_MDF__c.Earliest_FC_Deadline__c, SFDC_MDF__c.Fund_Request_Approver__c,SFDC_MDF__c.CreatedDate, SFDC_MDF__c.Amount_In_Corporate_Currency__c, SFDC_MDF__c.Partner_Account_Owner__c},
        ContentVersion.sObjectType => new Set<SobjectField>{ContentVersion.Id, ContentVersion.Tag__c, ContentVersion.TagCsv, ContentVersion.PathOnClient, ContentVersion.Language__c, ContentVersion.Title, ContentVersion.RecordTypeId, ContentVersion.ContentDocumentId},
        CurrencyType.sObjectType => new Set<SobjectField>{CurrencyType.IsoCode, CurrencyType.IsCorporate, CurrencyType.IsActive, CurrencyType.DecimalPlaces, CurrencyType.ConversionRate},
        SFDC_MDF_Claim__c.sObjectType => new Set<SobjectField>{SFDC_MDF_Claim__c.Id, SFDC_MDF_Claim__c.Status__c, SFDC_MDF_Claim__c.Fund_Request__c, SFDC_MDF_Claim__c.CurrencyIsoCode, SFDC_MDF_Claim__c.Amount__c, SFDC_MDF_Claim__c.Account__c, SFDC_MDF_Claim__c.Fund_Request_Approved_Amount__c, SFDC_MDF_Claim__c.Approved_Amount__c, SFDC_MDF_Claim__c.CreatedDate},
        SFDC_Budget__c.sObjectType => new Set<SobjectField>{SFDC_Budget__c.Id, SFDC_Budget__c.Account__c, SFDC_Budget__c.Amount__c, SFDC_Budget__c.Partner_Marketing_Plan__c,SFDC_Budget__c.Active__c, SFDC_Budget__c.Claimed_Budget__c, SFDC_Budget__c.Fund_Claim_Deadline__c},
        Contact.sObjectType => new Set<SobjectField>{Contact.Id, Contact.FirstName, Contact.LastName, Contact.AccountId, Contact.Email, Contact.Partner_User__c},
        Lead.sObjectType => new Set<SobjectField>{Lead.Id, Lead.Status, Lead.Demand_Waterfall_Stage__c, Lead.OwnerIDAlt__c, Lead.OwnerId, Lead.FirstName, Lead.LastName, Lead.Associated_Account__c, Lead.Associated_Opportunity__c, Lead.Email, Lead.AKAM_Lead_ID__c, Lead.LeadAutoID__c, Lead.RecordTypeId,Lead.Lead_Owner__c, Lead.Marketo_AKAM_Account_ID__c},
        Task.sObjectType => new Set<SobjectField>{Task.WhatId, Task.WhoId, Task.Id, Task.Subject, Task.Status},
        SFDC_Budget__Share.sObjectType => new Set<SobjectField>{SFDC_Budget__Share.UserOrGroupId, SFDC_Budget__Share.ParentId, SFDC_Budget__Share.AccessLevel},
        Account.sObjectType => new Set<SobjectField>{Account.Id, Account.Name, Account.IsPartnerCustom__c, Account.Type , Account.AKAM_Account_ID__c,Account.OwnerId},
        Budget_Allocation__c.sObjectType => new Set<SobjectField>{ Budget_Allocation__c.Amount__c, Budget_Allocation__c.Budget__c, Budget_Allocation__c.Fund_Claim__c, Budget_Allocation__c.Fund_Request__c},
        Channel_Mapping__c.sObjectType => new Set<SobjectField>{Channel_Mapping__c.Id, Channel_Mapping__c.Master_Channel_Mapping__c, Channel_Mapping__c.Active__c, Channel_Mapping__c.PAE_Id__c,Channel_Mapping__c.MDF_Approver__c,Channel_Mapping__c.VAR_Manager_Status__c, Channel_Mapping__c.Temp_PAE__c, Channel_Mapping__c.Partner_Name__c},
        Opportunity.sObjectType => new Set<SobjectField>{Opportunity.Id, Opportunity.StageName, Opportunity.CloseDate, Opportunity.AccountId, Opportunity.MRR__c,Opportunity.CurrencyIsoCode, Opportunity.FCM__c, Opportunity.Partner_Involved__c},
        User.SObjectType => new Set<SobjectField>{User.Id, User.ProfileId, User.IsActive, User.UserRoleId, User.Email, User.LastName},
        OpportunityLineItem.sObjectType => new Set<SobjectField>{OpportunityLineItem.OpportunityId, OpportunityLineItem.MRR__c, OpportunityLineItem.NRR__c},
        Order_Approval__c.sObjectType => new set<SobjectField>{Order_Approval__c.Associated_Opportunity__c, Order_Approval__c.Id},
        Partner_Marketing_Activity__c.sObjectType => new Set<SObjectField>{Partner_Marketing_Activity__c.Id, Partner_Marketing_Activity__c.Activity_Quarter__c,Partner_Marketing_Activity__c.Approved_By__c,Partner_Marketing_Activity__c.Approved_Date__c,Partner_Marketing_Activity__c.Indirect_Campaign__c,Partner_Marketing_Activity__c.Activity_Status__c,Partner_Marketing_Activity__c.Partner__c},
        Partner_Profile__c.sObjectType => new Set<SobjectField>{Partner_Profile__c.Approval_Status__c, Partner_Profile__c.Partner_Country_ISO_Code__c, Partner_Profile__c.Partner_FR_Approver__c,Partner_Profile__c.RecordTypeId},
        Attachment.SObjectType => new Set<SobjectField>{Attachment.ParentId, Attachment.Id}
    };

    public static Sobject get(Id recordId)
    {
        List<Sobject> rcs = get(null, new List<Id>{recordId}, 1);

        if(rcs.size()>0)
            return rcs[0];

        return null;
    }

    public static List<Sobject> get(List<Id> recordIds)
    {
        return get(null, recordIds, recordIds.size());
    }

    public static SObject get(SObjectType sOTypeParam)
    {
        List<Sobject> sobjs = get(sOTypeParam, 1);
        if(sobjs.size()>0)
            return sobjs[0];
        return null;
    }

    private static List<String> getListOfStringsFromSetOfSobjectFields(Set<SobjectField> fields)
    {
        List<String> fieldsInStrings = new List<String>();

        for(SobjectField sf : fields)
        {
            fieldsInStrings.add(String.valueOf(sf));
        }

        return fieldsInStrings;

    }

    private static String sobjectFieldsToString(Set<SobjectField> fields)
    {
        return String.join(getListOfStringsFromSetOfSobjectFields(fields), ',');
    }

    public static List<String> getDefaultFields(SobjectType sOTypeParam)
    {
       // System.assert(fieldsToBeRefreshed.containsKey(sOTypeParam), 'field cache doesnt have:'+sOTypeParam);
        return getListOfStringsFromSetOfSobjectFields(fieldsToBeRefreshed.get(sOTypeParam));
    }

    public static List<SObject> get(String commaSeparatedFields, List<id> recordIds)
    {
        return get(commaSeparatedFields, recordIds, recordIds.size());
    }

    public static List<SObject> get(Set<SobjectField> fieldsList, List<id> recordIds)
    {
        return get(sobjectFieldsToString(fieldsList), recordIds, recordIds.size());
    }

    public static List<SObject> get(String commaSeparatedFields, List<id> recordIds, Integer qLimit)
    {
        return get(recordIds[0].getSobjectType(), commaSeparatedFields, new al.SetCondition('Id', al.Operator.INX, recordIds), qLimit);
    }

    /*

    public static List<SObject> get(SObjectType sOTypeParam, String commaSeparatedFields, List<Id> recordIds, al.NestableCondition() cond, Integer qLimit)
    {
        return get(sOTypeParam, commaSeparatedFields, new al.AndCondition(new al.SetCondition('Id', al.Operator.INX, recordIds), cond), qLimit);
    }

    */

    public static List<Lead> refresh(List<Lead> records)
    {
        if(records!=null && records.size()>0)
        {
            Lead firstRecord = records[0];
            List<Id> recordIds= new List<Id>();
            for(Lead ithRecord: records)
            {
                recordIds.add(ithRecord.Id);
            }
            return get(String.join(new List<String>(firstRecord.getPopulatedFieldsAsMap().keySet()), ','), recordIds);
        }
        return records;
    }

    public static List<Sobject> refresh(List<Sobject> records)
    {
        if(records!=null && records.size()>0)
        {
            Sobject firstRecord = records[0];
            List<Id> recordIds= new List<Id>();
            for(Sobject ithRecord: records)
            {
                recordIds.add(ithRecord.Id);
            }
            return get(String.join(new List<String>(firstRecord.getPopulatedFieldsAsMap().keySet()), ','), recordIds);
        }
        return records;
    }

    
    public static List<SObject> get(SObjectType sOTypeParam, Integer qLimit)
    {
        return get(sOTypeParam, null, null, qLimit);
    }

    public static List<Sobject> get(SobjectType sOTypeParam, String commaSeparatedFields)
    {
        return get(sOTypeParam, commaSeparatedFields, null, null);

    }
    public static List<Sobject> get(SobjectType sOTypeParam, String commaSeparatedFields, Integer qLimit)
    {
        return get(sOTypeParam, commaSeparatedFields, null, qLimit);

    }

    public static List<SObject> get(SObjectType sOTypeParam, String commaSeparatedFields, al.Condition cond, Integer qLimit)
    {
        List<String> fieldsToBeQueried = String.isBlank(commaSeparatedFields) ? getDefaultFields(sOTypeParam) : commaSeparatedFields.split(',');

        al.SoqlBuilder sqlbldr = new al.SoqlBuilder()
            .selectx(fieldsToBeQueried)
            .fromx(String.valueOf(sOTypeParam))
            .orderByx(new al.OrderBy('CreatedDate').descending().nullsLast());

        if(qLimit!=null)
            sqlbldr = sqlbldr.limitx(qLimit);

        if(cond!=null)
            sqlbldr = sqlbldr.wherex(cond);


        return Database.query(sqlbldr.toSoql());
    }

    public static Id getProfileId(String profileName)
    {
        return [select id from Profile where Name=:profileName limit 1].Id;
    }


    public static Account getPartnerAccount()
    {
        return [select id from account where isPartnerCustom__c=true order by createddate desc limit 1];
    }

    public static User getPartnerUser()
    {
        return [select id, ContactId, Contact.Partner_User__c, UserRoleId, Contact.AccountId,Name from  User where UserType='PowerPartner' and IsActive=true order by CreatedDate desc limit 1];
    }

    public static List<Lead> getLeads(Integer numOfLeads)
    {
        return (List<Lead>)get(Lead.sObjectType, numOfLeads);
    }

    public static List<Contact> getContacts(Integer numOfContacts)
    {
        return (List<Contact>)get(Contact.sObjectType, numOfContacts);
    }

    public static List<SFDC_Budget__c> getFundBudgets(Integer numberOfFundBudgets)
    {
        return (List<SFDC_Budget__c>)get(SFDC_Budget__c.sObjectType, numberOfFundBudgets);
    }

    public static List<SFDC_MDF_Claim__c> getFundClaims(Integer numberOfFCs)
    {
        return (List<SFDC_MDF_Claim__c>)get(SFDC_MDF_Claim__c.sObjectType, numberOfFCs);
    }
    public static SFDC_Budget__c getFundBudget()
    {
        return (SFDC_Budget__c)get(SFDC_Budget__c.sObjectType);
    }

    public static Lead getLead()
    {
        return (Lead)get(Lead.sObjectType);
    }
    public static Contact getContact()
    {
        return (Contact)get(Contact.sObjectType);
    }
    public static User getUser()
    {
        return (User)get(User.sObjectType);
    }

    public static Opportunity getOpportunity()
    {
        return (Opportunity)get(Opportunity.sObjectType);
    }

    public static Order_Approval__c getOrderApproval()
    {
        return (Order_Approval__c)get(Order_Approval__c.sObjectType);
    }

    public static OpportunityLineItem getOpportunityLineItem()
    {
        return (OpportunityLineItem)get(OpportunityLineItem.sObjectType);
    }

    public static Account getAccount()
    {
        return (Account)get(Account.sObjectType);
    }

    public static SFDC_MDF_Claim__c getFundClaim()
    {
        return (SFDC_MDF_Claim__c)get(SFDC_MDF_Claim__c.sObjectType);
    }

    public static Attachment getAttachment()
    {
        return (Attachment)get(Attachment.SObjectType);
    }

    public static ContentVersion getContentVersion()
    {
        return (ContentVersion)get(ContentVersion.sObjectType);
    }

    public static Partner_Marketing_Activity__c getPMA()
    {
        return (Partner_Marketing_Activity__c)get(Partner_Marketing_Activity__c.sObjectType);
    }

    public static List<Partner_Marketing_Activity__c> getPMAs(Integer ct)
    {
        return (List<Partner_Marketing_Activity__c>)get(Partner_Marketing_Activity__c.sObjectType, ct);
    }


    public static Partner_Profile__c getPartnerProfile()
    {
        return (Partner_Profile__c)get(Partner_Profile__c.sObjectType);
    }

    public static List<Partner_Profile__c> getPartnerProfiles(Integer ct)
    {
        return (List<Partner_Profile__c>)get(Partner_Profile__c.sObjectType, ct);
    }

    public static List<SFDC_MDF__c> getFundRequests(Integer numberOfFundRequests, List<String> statuses)
    {
        return get(SFDC_MDF__c.sObjectType, null, new al.SetCondition('Status__c', al.Operator.INX, statuses), numberOfFundRequests);
    }

    public static List<SFDC_MDF__c> getFundRequests(Integer numberOfFundRequests)
    {
        List<String> statuses =  new List<String>{'Approved', 'Submitted', 'Draft'};
        return getFundRequests(numberOfFundRequests, statuses);
    }

    public static SFDC_MDF__c getFundRequest(String stat)
    {
        List<SFDC_MDF__c> frs = getFundRequests(1, new List<String>{stat});

        if(frs.size()>0)
            return frs[0];

        return null;

    }

    public static SFDC_MDF__c getApprovedFundRequest()
    {
        return getFundRequest('Approved');
    }

    public static SFDC_MDF__c getSubmittedFundRequest()
    {
        return getFundRequest('Submitted');
    }

    public static SFDC_MDF__c getDraftFundRequest()
    {
        return getFundRequest('Draft');
    }

    public static User getSysAdminUser()
    {
        return [select id from user where profile.name='System Administrator' and isactive=true limit 1];
    }

    public static User getCRMIntegrationUser()
    {
        return [select id from user where  isactive=true and (profile.name='CRM Integration' OR profile.name = 'CRM Integration 2.0') limit 1];
    }

    public static User getCollectionsUser()
    {
        return [select id from user where profile.name='Collections' and isactive=true limit 1];
    }

    public static User getMarketingOpsUser()
    {
        return [select id from user where profile.name='Marketing Operations' and isactive=true limit 1];
    }

    public static User getSalesOpsUser()
    {
        return [select id from user where profile.name='Sales Operations' and isactive=true limit 1];
    }

    public static User getBizOpsUser()
    {
        return [select id from user where profile.name='Business Operations' and isactive=true limit 1];
    }
    public static User getSolutionsEngineer()
    {
        return [select id from user where profile.name='Solutions Engineer' and isactive=true limit 1];
    }
    public static User getSalesPAEUser()
    {
       return [ select id, name from User where Profile.Name='Sales - Partner Account Executive' and UserRole.Name='Worldwide' and isActive=true order by createddate desc limit 1];

    }
     public static User getFundRequestQualityQueueUser()
    {
        for(GroupMember gm:[select UserOrGroupId from GroupMember where group.name='Fund Request Quality Queue'])
        {
            if(String.valueOf(gm.UserOrGroupId).startsWith('005'))
            {
                return new User(id=gm.UserOrGroupId);
            }
        }

        return null;
    }


    public static User getGSSOpsUser()
    {
        return [select id from user where profile.name='GSS Operations' and isactive=true limit 1];
    }

    public static List<User> getSalesPAEUsers(Integer numberOfUsers)
    {
       return [ select id, name from User where Profile.Name='Sales - Partner Account Executive' and UserRole.Name='Worldwide' and isActive=true order by createddate desc limit :numberOfUsers];

    }


    public static Attachment getChildAttachment(Id pId)
    {
        List<Attachment> attList = (List<Attachment>)get(Attachment.sObjectType, null, new al.AndCondition().add(new al.FieldCondition('ParentId').equals(pId)), 1);

        if(attList.size()>0)
            return attList[0];

        return null;
    }

    public static Channel_Mapping__c getMasterChannelMapping()
    {
        List<Channel_Mapping__c> mstrs = (List<Channel_Mapping__c>)get(Channel_Mapping__c.sObjectType
                ,null
                ,new al.AndCondition().add(new al.FieldCondition('Master_Channel_Mapping__c').equals(true))
                .add(new al.FieldCondition('Active__c').equals(true))
                ,1);

        if(mstrs.size()>0)
            return mstrs[0];

        return null;
    }

    public static Contact getPartnerContact()
    {
        Contact ct = [select id,Partner_User__c,AccountId from Contact where Account.isPartnerCustom__c=true limit 1];
        return ct;
    }

    public static List<Task> getTasks(List<Id> taskWhatIds)
    {
        return (List<Task>)get(Task.sObjectType
                ,null
                ,new al.SetCondition('WhatId', al.Operator.INX, taskWhatIds)
                ,null);
    }

    public static List<CurrencyType> getCurrencyTypes(Integer qLimit)
    {
        return (List<CurrencyType>)get(CurrencyType.sObjectType
                ,null
                ,new al.FieldCondition('IsActive').equals(true)
                ,qLimit);
    }

    public static CurrencyType getCurrencyType()
    {
        List<CurrencyType> cs = getCurrencyTypes(1);

        if(cs.size()>0)
            return cs[0];

        return null;
    }

    //comment

}