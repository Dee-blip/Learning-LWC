public class l2q_chimeNotificationBatch implements Database.Batchable<sObject>, Database.Stateful {
    set<Id> chimeIds = new Set<Id>();
    map<Id,String> mapResponseCapturedBy = new map<Id,String>();
    public Database.QueryLocator start(Database.BatchableContext bc) {
        string query = 'select id, Response_by_Customer__c,CHIME__c,notified_SE__c,LastModifiedBy.name from CHIME_Response__c where Response_by_Customer__c = true and notified_SE__c = false'; 
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext bc, List<CHIME_Response__c> records){
        for(CHIME_Response__c record : records){
            chimeIds.add(record.CHIME__c);
            mapResponseCapturedBy.put(record.CHIME__c,record.LastModifiedBy.name);
            record.notified_SE__c= true;
        }
        update records;
    }
    public void finish(Database.BatchableContext bc){
        List<chime__c> chimeList = [select id,CreatedById,Account__c,Account__r.name,Opportunity__r.name,CHIME_Name__c  from chime__c where id in: chimeIds];
        set<Id> setAccountList = new Set<Id>();
        Map<Id,Set<Id>> mapchimeUsers = new Map<Id,Set<Id>>();
        
        //get the users who created the chime.
        Map<Id,Id> mapAccountChime = new Map<Id,Id>(); 
        for(chime__c chime : chimeList ){
            if(mapchimeUsers.containskey(chime.id)){
                mapchimeUsers.get(chime.id).add(chime.CreatedById);
            }
            else{
                mapchimeUsers.put(chime.id,new Set<id>{chime.CreatedById});
            }
                        
            mapAccountChime.put(chime.Account__c,chime.id);
            setAccountList.add(chime.Account__c);
        }
        
        //get the case owners if case owner is not queue
        List<Case> caseList = new List<Case>();
        caseList = [Select id,OwnerId,Owner.name,Chime_Form__c from case where Chime_Form__c in:chimeIds and Chime_Case_Type__c = 'Integration Case'];
        for(Case cs: caseList){
            if('User'==cs.OwnerId.getSObjectType().getDescribe().getName()){
                if(mapchimeUsers.containskey(cs.Chime_Form__c)){
                    mapchimeUsers.get(cs.Chime_Form__c).add(cs.OwnerId);
                }
                else{
                    mapchimeUsers.put(cs.Chime_Form__c,new Set<id>{cs.OwnerId});
                }
            }
        }
        
        //Get the Account team members with role of Technical Sales -Primary
        List<AccountTeamMember> AccTeamMembers = new List<AccountTeamMember>();
        AccTeamMembers = [select id, AccountId, TeamMemberRole,userid ,Account.Name from AccountTeamMember where Accountid in:setAccountList];
        
        for(AccountTeamMember atm : AccTeamMembers){
            if(atm.TeamMemberRole == 'Technical Sales - Primary'){
                if(mapAccountChime.containsKey(atm.AccountId)){
                 	mapchimeUsers.get(mapAccountChime.get(atm.AccountId)).add(atm.UserId);
                    break;
                }
            }
        }
        
        
        //Get emails details of Users
        Map<Id,User> mapUserDetails = new Map<Id,User>();
        Set<Id> UserIds = new Set<Id>();
        for(id key: mapchimeUsers.keyset()){
            for(id innerkey : mapchimeUsers.get(key)){
                UserIds.add(innerkey);
            }
        }
        List<User> listUsers =[Select Id, email from User where id in:UserIds];
        for(User us: listUsers){
        	mapUserDetails.put(us.Id,us);
        }
        
        //Email sending part
            Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage>();
        for(Chime__c chime:chimeList){
            List<String> emails = new List<String>();
            for(Id userid: mapchimeUsers.get(chime.id)){
                emails.add(mapUserDetails.get(userid).email);
            }
            System.debug('emails:'+emails);
            String baseUrl = System.URL.getSalesforceBaseUrl().toExternalForm();
        	String msg='';
        
            msg= 'Hi'+',' +'<br/>' +'<br/>' + mapResponseCapturedBy.get(chime.Id) + ' has modified the CHIME Form '+'<html><a href="'+baseUrl+'/'+chime.id+'">'+chime.CHIME_Name__c	+'</a></html>'+'. Please use the audit trail section on the form to understand what has changed.'+'<br/>'+'<br/>';
            msg += 'Account Name:  <html><a href="'+baseUrl+'/'+chime.Account__c+'">' + chime.Account__r.name + '</a><br/></html>' ; 
            msg += 'Opportunity Name: <html><a href="'+baseUrl+'/'+chime.Opportunity__c+'">'  + chime.Opportunity__r.name + '</a><br/>' ; 
            msg = msg + '<br/>' +'Thank you';
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.toAddresses = emails;
            	//mail.toAddresses =new String[] {'mamahaja@akamai.com'};
                mail.setSubject(mapResponseCapturedBy.get(chime.Id) + ' has modified '+chime.CHIME_Name__c);
                mail.setHtmlBody(msg);
                messages.add(mail);
            
        }
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);

    }
}