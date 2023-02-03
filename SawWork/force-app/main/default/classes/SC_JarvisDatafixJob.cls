public without sharing class SC_JarvisDatafixJob implements Database.Batchable<sObject>, Database.Stateful{
    
    List<String> akamAccountIds;
    Set<String> processedAkamAccountIds = new Set<String>();
    
    public SC_JarvisDatafixJob(List<String> akamAccountIds) {
        this.akamAccountIds = akamAccountIds;
    }

    String getQuery() {
        String query;
        if(akamAccountIds != null) {
            query = 'select id, AKAM_Account_ID__c  from Account where type like \'%- Active%\' and akam_account_id__c  in :akamAccountIds';
        }else {
            query = 'select id, AKAM_Account_ID__c  from Account where type like \'%- Active%\' ';
        }
        return query;
    }

    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(getQuery());
    }

    public void execute(Database.BatchableContext BC, List<Account> accList){

        List<String> toInsertGroupNames = new List<String>();

        for(Account acc: accList) {
            String accGroupName  = SC_JarvisDatafixJob.prepareGroupName('JARVIS_ACCOUNT' + acc.Akam_account_id__c);
            toInsertGroupNames.add(accGroupName);
        }
		
        String childAccount, parentAccount;
        for(Merge_Contract_Header__c mc: [select id, Original_Contract_Id__c, Account_Name__c,Contract_Type__c, Parent_Contract__r.Account_Name__c,
           	Parent_Contract__r.Account_Name__r.AKAM_Account_id__c, Account_Name__r.AKAM_Account_id__c from Merge_Contract_Header__c where 
                                        Effective_end_Date__c > today and Account_Name__c in :accList]) {
            String contractReadGroup =  SC_JarvisDatafixJob.prepareGroupName('JARVIS_CONTRACT' + mc.Original_Contract_Id__c + '_WRITE');
            String contractWriteGroup =  SC_JarvisDatafixJob.prepareGroupName('JARVIS_CONTRACT' + mc.Original_Contract_Id__c + '_READ');
            toInsertGroupNames.add(contractReadGroup);
            toInsertGroupNames.add(contractWriteGroup);
			if(mc.Parent_Contract__r.Account_Name__r.AKAM_Account_id__c != null && mc.Account_Name__r.AKAM_Account_id__c != null && 
               mc.Account_Name__r.AKAM_Account_id__c != mc.Parent_Contract__r.Account_Name__r.AKAM_Account_id__c &&
				mc.Contract_Type__c == 'Indirect Customer')
			{
                childAccount = String.valueOf(mc.Account_Name__c).substring(0, 15);
                parentAccount = String.valueOf(mc.Parent_Contract__r.Account_Name__c).substring(0, 15);
				toInsertGroupNames.add(SC_Jarvis_utility.prepareGroupName('JA_' + childAccount +'_' + parentAccount + '_R'));
				toInsertGroupNames.add(SC_Jarvis_utility.prepareGroupName('JA_' + childAccount +'_' + parentAccount + '_W'));
                                                
			}
                                            
        }

        Map<String,String> pdIdToName = new Map<String,String>();
        for( Policy_Domain__c pd:  [select id from Policy_Domain__c where Account_Name__c in :accList 
        and Policy_Domain_State__c = 'Active']) 
        {
            String jarvisPdGroupName = 'JARVIS_PD' + SC_JarvisDatafixJob.convertToEighteen(pd.id);
            toInsertGroupNames.add(jarvisPdGroupName);
            pdIdToName.put(pd.Id,jarvisPdGroupName);
        }
        

        createPublicGroupForSObject(toInsertGroupNames);

        List<String> contactString = new List<String>();
        for(Authorized_Contact__c contactRec: [Select id,Contact_Name__c, Policy_Domain__c from Authorized_Contact__c where 
        Policy_Domain__c in :pdIdToName.keySet() and Contact_Name__r.Active_Portal_Login__c = true])
        {
            contactString.add(contactRec.Contact_Name__c + '-' + SC_JarvisDatafixJob.convertToEighteen(contactRec.Policy_Domain__c));
        }
        if(contactString.size() > 0)
        {
            addContactToPublicGroups(contactString);
        }
        for(Account acc: accList) {
            processedAkamAccountIds.add(acc.Akam_Account_id__c);
        }
    }
    
    public void finish(Database.BatchableContext BC)
    {
        User usr = [select id,  email from user where  id = :UserInfo.getUserid()];
        List<String> toAddresses = new List<String> {'shprasan@akamai.com'}; 
        List<String> failedRecords = new List<String>();
        for(Account acc: Database.query(getQuery())) {
            if(!processedAkamAccountIds.contains(acc.Akam_Account_Id__c)) {
                failedRecords.add(acc.Akam_Account_Id__c);
            }
        }

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setSubject('Jarvis Datafix Batch Job : ' + bc.getJobId());
        String emailBody = ' Successfully processed Account records ' + processedAkamAccountIds.size() + ' \n'
                            + ' Failed Account Records ' + failedRecords.size() + '\n'
                            + String.join(failedRecords, '\n');
        mail.setPlainTextBody(emailBody);
        mail.setToAddresses(toAddresses);

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

        //database.executeBatch(new SC_Jarvis_Create_Caseshare_Batch(akamAccountIds));
    }
    
    
    public static void createPublicGroupForSObject(list<string> sObjectgrps)
    {        
        set<string> existinggroups = new set<string>();
        existinggroups.addall(sObjectgrps);
        
        for(group eachexistinggroup : [select name from group where name in :sObjectgrps])
        {
            existinggroups.remove(eachexistinggroup.name);
        }
        
        list<group> grpstobecreated = new list<group>();
        
        if(existinggroups.size()>0){    
            for(string eachnewgrp : existinggroups)
            {
                group grp = new Group( Name=eachnewgrp, DeveloperName = eachnewgrp, type='Regular' );
                grpstobecreated.add(grp);
            }
        }
        database.insert(grpstobecreated,false);
        
    }
    
    public static String prepareGroupName(String groupName)
    {
        return groupName != null && groupName.contains('-')? groupName.replaceAll('-','_') : groupName;
    }
	
    public static String convertToEighteen(String recordId)
    {
        String idStr = recordId;   // 15 character id
        Id idval = idStr;                   // assign to ID variable
        idStr = idval;                      // back to string to prove the point
        return idStr;
    }
    
    public static void addContactToPublicGroups(list<string> contactIDsfromTrigger)
    {
        
        map<string,string> contactid_userid = new map<string,string>();
        map<string,string> groupname_groupid = new map<string,string>();
        
        set<id> contactidsset= new set<id>();
        set<string> groupnamesset= new set<string>();
        
        for(string eachstring : contactIDsfromTrigger)
        {	
            string groupname = 'JARVIS_PD'+eachstring.split('-')[1];
            string contactid = eachstring.split('-')[0];
            contactidsset.add(contactid);
            groupnamesset.add(groupname);
        }
        
        for(group eachgroup : [select id, name from group where name in :groupnamesset])
        {
            groupname_groupid.put(eachgroup.name, eachgroup.id);
        }
        
        for(user eachuserrec : [select id,contactid from user where contactid IN :contactidsset])
        {
            contactid_userid.put(eachuserrec.contactid,eachuserrec.id);
        }
        
        list<GroupMember> associatedgrpmember= new list<GroupMember>();
        
        for( string eachrecord : contactIDsfromTrigger)
        {
            //Get list of contacts to be added from group name and contacts map
            string groupname = 'JARVIS_PD'+eachrecord.split('-')[1];
            string contactid = eachrecord.split('-')[0];
            
            string userid = contactid_userid.get(contactid);
            if(userid!=null)
            {
                GroupMember grpmem = new GroupMember (GroupId=groupname_groupid.get(groupname), UserOrGroupId=userid); 
                associatedgrpmember.add(grpmem); 
            }
        }
        database.insert(associatedgrpmember, false);
    }
    
    

}