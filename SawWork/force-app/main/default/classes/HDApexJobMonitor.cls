public class HDApexJobMonitor {
  List<AsyncApexJob> jobLists = new List<AsyncApexJob>();
    List<HDApexJobSubscriber__c> subscribers = new List<HDApexJobSubscriber__c>();
    Map<Id,HDApexJobSubscriber__c> subscribersMap = new Map<Id,HDApexJobSubscriber__c>();
    Map<Id,String> content = new Map<Id,String>();
    
    public HDApexJobMonitor(){
        this.subscribers = getSubscribers();
        this.jobLists = getJobs();
    }
    
    private void sendMails(){
        Messaging.reserveSingleEmailCapacity(10);
        Map<String,OrgWideEmailAddress> owa = new Map<String,OrgWideEmailAddress>();
        for(OrgWideEmailAddress orgEmail :[select id, Address from OrgWideEmailAddress limit 500]){
            owa.put(orgEmail.Address, orgEmail);   
        }
        
        Id sfNoReplyAddressId = null;
        if(owa.containsKey('sf-no-reply@akamai.com')){
            sfNoReplyAddressId = owa.get('sf-no-reply@akamai.com').id;
        }
        List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
        for(String key :content.keySet()){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
             String[] toAddresses = new String[] {subscribersMap.get(key).SubscribedEmail__c};
            if(sfNoReplyAddressId != null){
                mail.setOrgWideEmailAddressId(sfNoReplyAddressId);
            }else{
                mail.setSenderDisplayName('Do Not Reply');
            }
            mail.setToAddresses(toAddresses);
            mail.setReplyTo('no-reply@akamai.com');
            
            mail.setSubject('Jobs Failed  ');
            //mail.setPlainTextBody(content);
            mail.setHtmlBody(content.get(key));
            mailList.add(mail);
        }
        Messaging.sendEmail(mailList);
        //if successfull update the last seen
        for(HDApexJobSubscriber__c s : subscribers){
            s.Last_Seen__c = System.now();
        }
        update subscribers;
    }
    
        
    
    
    
    private List<HDApexJobSubscriber__c> getSubscribers(){
        List<HDApexJobSubscriber__c> subscribers =  new  List<HDApexJobSubscriber__c>();
        subscribers = [select Name, Class_Names__c, Last_Seen__c, SubscribedEmail__c  from HDApexJobSubscriber__c limit 50];
        //subscribers
        for(HDApexJobSubscriber__c s : subscribers){
            subscribersMap.put(s.id, s);
        }
        return subscribers;
        
    }
    
    private List<AsyncApexJob> getJobs(){
        
        //get last seen datetime
        DateTime lastSeen = System.now();
        if(subscribers.size()>0){
            for(HDApexJobSubscriber__c subscriber : subscribers){
                if(subscriber.Last_Seen__c != null && lastSeen>subscriber.Last_Seen__c ){
                    lastSeen = subscriber.Last_Seen__c;
                }
            }
        }
        
        //if no last seen record found, set last seen date to previous day
        if(lastSeen == System.now()){
            lastSeen = System.now() -1;
        }
        
        
        //get all records after last seen
        List<AsyncApexJob> jobLists = new List<AsyncApexJob>();
        jobLists = [select id, apexclass.name, JobType, Status, createdDate, CompletedDate
                from AsyncApexJob 
                where status in ('Aborted','Failed') 
                and createdDate >= :lastSeen 
                order by createdDate desc
                limit 30000];
        return jobLists;
        
    }
    
    public void createContent(){
        
        //set of classes against subscribers
        Map<ID,Set<String>> classesAgainstSubscribers = new Map<ID,Set<String>>();
        
        for(HDApexJobSubscriber__c subscriber : subscribers){
            Set<String> temp = new Set<String>();
            List<String> clists = new List<String>();
            clists = subscriber.Class_Names__c.split(',');
            for(String s : clists){
                temp.add(s.trim());
            }
            temp.addAll(clists);
          classesAgainstSubscribers.put(subscriber.id, temp);            
        }
        
         
        //investigating every record
        if(jobLists !=null && jobLists.size()>0){
            for(AsyncApexJob job : jobLists){
                for(HDApexJobSubscriber__c subscriber : subscribers){
                    System.debug('test my avalailability');
                    System.debug('classesAgainstSubscribersget(subscriber.id) : '+classesAgainstSubscribers.get(subscriber.id));
                    System.debug('job.apexclass.name: '+ job.apexclass.name);
                    //List<String> tempList = new List<String>();
                    Set<String> tempSet = new Set<String>();
                    //tempList = classesAgainstSubscribers.get(subscriber.id);
                    tempSet.addAll(classesAgainstSubscribers.get(subscriber.id));
                    System.debug('tempSet :'+ tempSet);
                    if(tempSet.contains((job.apexclass.name))){
                       System.debug('condition satisfied '+ job.apexclass.name);
                        if(content.containsKey(subscriber.id)){
                            String temp = updateContent(subscriber.id, job, subscriber.Name);
                            content.put(subscriber.id,temp);
                            
                        }else {
                            String tempContent='<haed><style>  .Completed{background-color:#8FFF67;} .Failed{background-color:red;color:white} .Aborted{background-color:#00ccff;} </style></head>';
                            tempContent += '<table bordercolor="black" border=1 bgcolor="#E2CE5F"><thead><tr><th>Status</th><th>Job Subscriber Name</th><th>Apex Class Name</th><th>Apex Job ID</th><th>Created Date</th><th>Completed Date</th></tr></thead>';
                            tempContent += '<tbody>';
                            
                            content.put(subscriber.id, tempContent);
                            String temp = updateContent(subscriber.id, job, subscriber.Name);
                            content.put(subscriber.id,temp);
                        }
                    }
                }
            }
        }
        sendMails();
    }
    
    
    private String updateContent(ID sid, AsyncApexJob job, String Name){
        String temp = content.get(sid) + '<tr><div class="'+job.Status+'"><td><div class="'+job.Status+' common">'+ 
                            job.status+'</div></td><td>'+
            				Name+'</td><td>'+
                            job.apexclass.name+ '</td><td>'+
                            job.id+'</td><td>'+
                            job.CreatedDate+'</td><td>'+
                            job.CompletedDate+'</td></div></tr>';
        return temp;
    }
    
}