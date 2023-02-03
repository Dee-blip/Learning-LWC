@isTest
public class SObjectFactory
{
    public static User ADMIN_USER
    {
        get
        {
            if (ADMIN_USER == null)
                ADMIN_USER = [
                    SELECT Id FROM User WHERE IsActive = true
                    AND Profile.Name = 'System Administrator'
                    LIMIT 1
                ];
            return ADMIN_USER;
        }
        private set;
    }
    public static Boolean isProduction
    {
        get
        {
            if (isProduction == null)
                isProduction = ![SELECT IsSandbox FROM Organization limit 1].IsSandbox;
            return isProduction;
        }
        private set;
    }

    public static Integer getRecordThreshold()
    {
        return isProduction ? 5 : Limits.getLimitQueries() + 1;
    }

    // no fields
    public static SObject build(SObjectType sObjectType) { return build(sObjectType, 1)[0]; }
    public static SObject create(SObjectType sObjectType) { return create(sObjectType, 1)[0]; }
    
    public static List<SObject> build(SObjectType sObjectType, Integer count)
    {
        return build(sObjectType, count, /*fieldToValue*/ null);
    }
    public static List<SObject> create(SObjectType sObjectType, Integer count)
    {
        return create(sObjectType, count, /*fieldToValue*/ null);
    }
    
    // one field
    public static SObject build(SObjectType sObjectType, SObjectField field, Object value)
    {
        return build(sObjectType, 1, field, value)[0];
    }
    public static SObject create(SObjectType sObjectType, SObjectField field, Object value)
    {
        return create(sObjectType, 1, field, value)[0];
    }
    
    public static List<SObject> build(SObjectType sObjectType, Integer count, SObjectField field, Object value)
    {
        return build(sObjectType, count, new Map<SObjectField, Object> { field => value });
    }
    public static List<SObject> create(SObjectType sObjectType, Integer count, SObjectField field, Object value)
    {
        return create(sObjectType, count, new Map<SObjectField, Object> { field => value });
    }
    
    // all fields
    public static List<SObject> build(SObjectType sObjectType, Integer count, Map<SObjectField, Object> fieldToValue)
    {
        Map<SobjectField, Object> fields ;

        if (fieldToValue == null)
            fields= RequiredFieldsCache.get(sObjectType);
        else
            fields = fieldToValue;
        
        List<SObject> records = new List<SObject>();
        while (records.size() < count)
        {
            Sobject record;
            if(fields!=null && fields.size()>0)
            {
                record = sObjectType.newSObject();
                for (SObjectField field : fields.keySet())
                {
                    Object value = fields.get(field);
                    if (value instanceOf IFieldProvider)
                        value = ((IFieldProvider)value).getValue();

                    record.put(field, value);
                    System.debug(Logginglevel.error, 'AGH_D in create for field:'+String.valueof(field)+'with value:'+value);
                }
            }
            else
            {
                IFieldProvider provider =SobjectFieldProviders.getProvider(String.valueOf(sObjectType));
                record = (Sobject)provider.getValue();
            }

            records.add(record);
        }
        return records;
    }

    /*
    public static List<SObject> build(ObjectType oType, Integer count)
    {
        List<SObject> records = new List<SObject>();
        IFieldProvider provider =SobjectFieldProviders.getProvider(oType);
        while (records.size() < count)
        {
            if(provider!=null)
            {
                records.add((Sobject)provider.getValue());
            }
        }
        return records;
    }
    public static List<SObject> create(ObjectType oType, Integer count)
    {
        List<SObject> records = build(oType, count);
        insert records;
        return records;
    }
    */
    public static List<SObject> create(
        SObjectType sObjectType, Integer count,
        Map<SObjectField, Object> fieldToValue
    )
    {
        List<SObject> records = build(sObjectType, count, fieldToValue);
        insert records;
        return records;
    }

    
    // providers

    public static IFieldProvider provideSalesOpsProfile()
    {
        return new SObjectFieldProviders.QueryParentProvider(
            'SELECT Id FROM Profile WHERE Name = \'Sales Operations\' LIMIT 1'
        );
    }

    
    public static IFieldProvider provideUniqueNumber()
    {
        return new SObjectFieldProviders.UniqueNumberProvider();
    }
    public static IFieldProvider provideUniqueNumber(Integer start)
    {
        return new SObjectFieldProviders.UniqueNumberProvider(start);
    }

    public static IFieldProvider provideUniqueDate()
    {
        return new SObjectFieldProviders.UniqueDateProvider();
    }
    public static IFieldProvider provideUniqueDate(Date startDate)
    {
        return new SObjectFieldProviders.UniqueDateProvider(startDate);
    }

    public static IFieldProvider provideUniqueString()
    {
        return new SObjectFieldProviders.UniqueStringProvider();
    }
    public static IFieldProvider provideUniqueString(String base)
    {
        return new SObjectFieldProviders.UniqueStringProvider(base);
    }
    
    public static IFieldProvider provideUniqueFixedLengthString(Integer length)
    {
        return new SObjectFieldProviders.UniqueFixedLengthStringProvider(length);
    }
    public static IFieldProvider provideUniqueFixedLengthString(String base, Integer length)
    {
        return new SObjectFieldProviders.UniqueFixedLengthStringProvider(base, length);
    }

        
    public static IFieldProvider provideDummyId(SObjectType sObjectType)
    {
        return new SObjectFieldProviders.DummyIdProvider(sObjectType);
    }

    public static IFieldProvider provideGenericParent(SObjectType sObjectType)
    {
        return new SObjectFieldProviders.GenericParentProvider(sObjectType);
    }
    public static IFieldProvider provideGenericParent(SObjectType sObjectType, SObjectField field, Object value)
    {
        return new SObjectFieldProviders.GenericParentProvider(sObjectType, field, value);
    }

    public static IFieldProvider provideList(List<Object> values)
    {
        return new SObjectFieldProviders.ListProvider(values);
    }

    public static IFieldProvider provideParents(SObjectType sObjectType, Integer count)
    {
        return new SObjectFieldProviders.MultiParentProvider(SObjectFactory.create(sObjectType, count));
    }
    public static IFieldProvider provideParents(List<SObject> parents)
    {
        return new SObjectFieldProviders.MultiParentProvider(parents);
    }
    public static IFieldProvider provideParents(Set<Id> parentIds)
    {
        return new SObjectFieldProviders.MultiParentProvider(parentIds);
    }

    public static IFieldProvider provideQueriedParent(String query)
    {
        return new SObjectFieldProviders.QueryParentProvider(query);
    }
    public static IFieldProvider provideQueriedParent(SObjectType sObjectType)
    {
        return new SObjectFieldProviders.QueryParentProvider(sObjectType);
    }

    public static void startBatchRun(String batchJobType)
    {
        Cron_Batch_Job__c cbj = (Cron_Batch_Job__c)new SObjectBuilder(Cron_Batch_Job__c.sObjectType)
            .eagerPopulate()
            .put(Cron_Batch_Job__c.Name, batchJobType)
            .put(Cron_Batch_Job__c.Batch_Job_Type__c, batchJobType)
            .create()
            .getRecord();

        new SObjectBuilder(Cron_Batch_Run__c.sObjectType)
            .eagerPopulate()
            .put(Cron_Batch_Run__c.Cron_Batch_Job__c, cbj.Id)
            .create();
    }



    public static List<Account> createPartnerAccounts(Integer numberOfPartnerAccounts)
    {
        //SFDC-6405
        SobjectBuilder partnerAccountBuilder = new SobjectBuilder(Account.sObjectType).eagerPopulate()
            .put(Account.Partner_Type__c, 'ADS Partner')
            .put(Account.Partner_Status__c, 'Partner')
            .put(Account.Partner_Tier__c, 'Registered')
            .put(Account.Partner_Reach__c, 'AMER')
            .put(Account.website,'www.akamai.com')
            .count(numberOfPartnerAccounts)
            .create();

        partnerAccountBuilder.put(Account.Validation_Override__c, true)
            .put(Account.IsPartnerCustom__c, true)
            .put(Account.IsPartner, true)
            .updateAll();

        return (List<Account>)partnerAccountBuilder.getRecords();

    }

    public static List<User> createPartnerUsers(List<Account> partnerAccounts)
    {

       List<Contact> partnerContacts = (List<Contact>)new SobjectBuilder(Contact.sObjectType)
            .eagerPopulate()
            .put(Contact.AccountId, partnerAccounts)
            .put(Contact.Subscribed_to_Library__c, true)
            .put(Contact.Active_Partner__c, true)
            .count(partnerAccounts.size())
            .create()
            .getRecords();

       List<User> partnerUsers = (List<User>) new SobjectBuilder(User.sObjectType)
                                                .eagerPopulate()
                                                .put(User.ContactId, partnerContacts)
                                                .nullify(User.UserRoleId)
                                                .put(User.Can_Accept_POA__c, true)
                                                .put(User.UserPermissionsSFContentUser, true)
                                                .put(User.Has_view_content_in_portals__c, true)
                                                .put(User.Has_MDF_Access__c, true)
                                                .put(User.Has_DealRegistration_Access__c, true)
                                                .put(User.ProfileId, SobjectRepository.getProfileId('Partner Community Admin'))
                                                .count(partnerAccounts.size())
                                                .create()
                                                .getRecords();

       if(partnerAccounts.size()==1)
       {
           PartnerAccessController.updateRemoveUserPermissionSet(partnerUsers[0], partnerContacts[0]);
       }
       return partnerUsers;
    }

    public static Account createPoolUserAccount()
    {
        String poolUserId = GSMSettings.getValue('ONAPoolOpsIdList').split(',').get(0);
        Account onaAccount = (Account)new SobjectBuilder(Account.sObjectType)
            .eagerPopulate()
            .put(Account.Name, 'ZFPP1')
            .put(Account.OwnerId, poolUserId)
            .put(Account.Vertical__c, 'Hotel & Travel')
            .put(Account.Sub_Vertical__c, 'Transportation')

            .create()
            .getRecord();

        return onaAccount;

    }
    public static Account createONAAccount()
    {
        Account onaAccount = (Account)new SobjectBuilder(Account.sObjectType)
            .eagerPopulate()
            .put(Account.Name, 'ZFGT1')
            .put(Account.OwnerId, GsmUtilClass.getGSMSettingValue('ONA_User_Id'))
            .put(Account.Vertical__c, 'Hotel & Travel')
            .put(Account.Sub_Vertical__c, 'Transportation')
            .create()
            .getRecord();

        return onaAccount;

    }

    public static List<User> createPartnerUsers(Integer numberOfPartnerUsers)
    {
            // create an account
            // update to partner
            // create contact
            // create partner user
            // update permissions on partner user
        Account partnerAccount = (Account)new SobjectBuilder(Account.sObjectType)
            .eagerPopulate()
            .put(Account.Partner_Type__c, 'ADS Partner')
            .put(Account.Partner_Status__c, 'Partner')
            .put(Account.Partner_Tier__c, 'Registered')
            .put(Account.POA_Email_List__c, 'fdajkldf@akamai.com')
            .put(Account.Partner_Reach__c, 'AMER')
            .put(account.website,'www.parweb.com')
            .create()
            .getRecord();

        partnerAccount.IsPartner=true;
        partnerAccount.IsPartnerCustom__c=true;
        partnerAccount.Validation_Override__c=true;
        update partnerAccount;

       List<Contact> partnerContacts = (List<Contact>)new SobjectBuilder(Contact.sObjectType)
            .eagerPopulate()
            .put(Contact.AccountId, partnerAccount.Id)
            .put(Contact.Subscribed_to_Library__c, true)
            .put(Contact.Active_Partner__c, true)
            .count(numberOfPartnerUsers)
            .create()
            .getRecords();

       L2Q_UserTriggerClass.updateAccountLicensesFirstRunFlag=false;
       List<User> partnerUsers = (List<User>) new SobjectBuilder(User.sObjectType)
                                                .eagerPopulate()
                                                .put(User.ContactId, partnerContacts)
                                                .nullify(User.UserRoleId)
                                                .put(User.Can_Accept_POA__c, true)
                                                .put(User.UserPermissionsSFContentUser, true)
                                                .put(User.Has_view_content_in_portals__c, true)
                                                .put(User.Has_MDF_Access__c, true)
                                                .put(User.Has_DealRegistration_Access__c, true)
                                                .put(User.ProfileId, SobjectRepository.getProfileId('Partner Community Admin'))
                                                .count(numberOfPartnerUsers)
                                                .create()
                                                .getRecords();

       List<Contact> contactsTobeUpdated = new List<Contact>();
       for(User pUser: partnerUsers)
       {
           System.assert(pUser.ContactId!=null, 'pUser is:'+pUser);
           contactsTobeUpdated.add(new Contact(id=pUser.ContactId, Validation_Override__c=true, Partner_User__c=pUser.Id));
       }

       update contactsTobeUpdated;

       if(numberOfPartnerUsers==1)
       {
           PartnerAccessController.updateRemoveUserPermissionSet(partnerUsers[0], partnerContacts[0]);
       }

       return partnerUsers;

    }

    public static User createSalesPaeWithWorldwideRole()
    {
        User sUser =(User) new SObjectBuilder(User.SObjectType)
            .eagerPopulate()
            .put(User.ProfileId, GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id'))
            .put(User.UserRoleId, GSMSettings.getValue('WorldwideUserRoleId'))
            .create()
            .getRecord();

        return sUser;

    }
    public static List<User> createSalesPaeWithWorldwideRole(Integer numberOfUsers)
    {
        List<User> sUserList =(List<User>) new SObjectBuilder(User.SObjectType)
            .eagerPopulate()
            .put(User.ProfileId, GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id'))
            .put(User.UserRoleId, GSMSettings.getValue('WorldwideUserRoleId'))
            .count(numberOfUsers)
            .create()
            .getRecords();

        return sUserList;

    }

    public static List<User> createSalesPaeWithDelegatedApprover()
    {
        User delegatedApprover= createSalesPaeWithWorldwideRole();

        List<User> paeWithHisDelegatedApprover = new List<User>();

        User pae=(User) new SObjectBuilder(User.SObjectType)
            .eagerPopulate()
            .put(User.ProfileId, GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id'))
            .put(User.UserRoleId, GSMSettings.getValue('WorldwideUserRoleId'))
            .put(User.DelegatedApproverId, delegatedApprover.Id)
            .create()
            .getRecord();

        paeWithHisDelegatedApprover.add(pae);
        paeWithHisDelegatedApprover.add(delegatedApprover);

        return paeWithHisDelegatedApprover;

    }

    public static Channel_Mapping__c createChannelMapping(Id partnerAccountId)
    {
        List<User> paeUsers = SObjectRepository.getSalesPAEUsers(3);

        Channel_Mapping__c cm = (Channel_Mapping__c)new SobjectBuilder(Channel_Mapping__c.sObjectType)
            .eagerPopulate()
            .put(Channel_Mapping__c.Master_Channel_Mapping__c, true)
            .put(Channel_Mapping__c.Active__c, true)
            .put(Channel_Mapping__c.PAE_ID__c, paeUsers[0].Id)
            .put(Channel_Mapping__c.MDF_Approver__c, paeUsers[1].Id)
            .put(Channel_Mapping__c.Partner_Name__c, partnerAccountId)
            .put(Channel_Mapping__c.Comp_Owner1__c, paeUsers[2].Id)
            .create()
            .getRecord();

        return cm;
    }

    public static void insertOpptyTeamMemberForPartner(List<User> pUsers, Id opptyId)
    {
        List<OpportunityTeamMember> otms = new List<OpportunityTeamMember>();

        for(User pUser: pUsers)
        {
            OpportunityTeamMember member = new OpportunityTeamMember();
            member.OpportunityId = opptyId;
            member.UserId = pUser.Id;
            member.TeamMemberRole = 'Partner';
            member.OpportunityAccessLevel = 'Edit';
            otms.add(member);
        }

        if (otms.size()>0) {
            insert otms;
        }
    }

    public static Opportunity createDealRegUnsubmitted(Id partnerAccountId)
    {
        Channel_Mapping__c channelMapping = createChannelMapping(partnerAccountId);
        Map<String, Schema.RecordTypeInfo> rtMap = Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName();

        Opportunity opp =(Opportunity) new SobjectBuilder(Opportunity.sObjectType)
            .eagerPopulate()
            .put(Opportunity.Partner_Involved__c, partnerAccountId)
            .put(Opportunity.Deal_Type__c, 'Indirect')
            .put(Opportunity.RecordTypeId, rtMap.get('Deal Reg Unsubmitted').getRecordTypeId())
            .put(Opportunity.Channel_Manager__c, channelMapping.Id)
            .create()
            .getRecord();

        return opp;
    }

}