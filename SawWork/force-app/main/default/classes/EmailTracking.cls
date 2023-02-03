/***
    EmailTracking
    @author Vinayendra T N <vinatara@akamai.com>
    @Description : This class is used to create task on recieving a email
                   The email subject will contain #ref [<object id>]
                   the task to attched to corresponding object id
     * History:
 * =========================
 * Developer        Date        Description
 * --------------------------------------------------------------------------------------------------
   Vinayendra T N   5/2011      Created Class
   Vinayendra T N   7/2011      CR 1186960 Email Tracker Issues
   Vinayendra T N   10/2011     CR 1343441 Email tracking : Bug fix
**/
global class EmailTracking implements Messaging.InboundEmailHandler {
    public static String getSFId(string subjecttext,integer s)
    {
        String match;
        Integer l;
        Integer mleft;
        Integer mright;
        s += 5;
        l = subjecttext.length();
        match = subjecttext.substring(s,l);
        mleft=match.indexof('[');
        mright=match.indexof(']');
        match=match.substring(mleft+1,mright);
        match=match.trim();
        return match;
    }
   public static Task createtask(User usr,Id taskwhatid,string subjecttext,string bodytext)
    {
        Task ta=new Task();
        ta.OwnerId=usr.id;
        if(taskwhatid!=null)
                ta.WhatId=taskwhatid;
        ta.Subject=subjecttext;
        ta.Type__c='Email';
        ta.Description =bodytext;
        ta.Status='Completed';
        ta.AKAM_Created_By__c=usr.Alias;
        ta.AKAM_Created_Date__c=Datetime.now();
        ta.AKAM_Modified_By__c=usr.Alias;
        ta.AKAM_Modified_Date__c=Datetime.now();
        ta.AKAM_System__c='FORCE';        
        return ta;
    }
//private static Email_to_Case__c CustomSettings = Email_to_Case__c.getInstance('Momentum');
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {

        //create result for email operation
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        
        String ContextAlias = GsmUtilClass.getGSMSettingValue('EmailTracking_ContextAlias'); // SFDC-2705 Custom Settings Migration
        String delimiter = GsmUtilClass.getGSMSettingValue('EmailTracking_delimiter'); // SFDC-2705 Custom Settings Migration;    
        String bodytext;
        
        bodytext='From Address:'+email.fromAddress;
        bodytext+='\n To Address:';
        if(email.toAddresses!=null && email.toAddresses.size()>0)
        {
           for(String toA:email.toAddresses)
                bodytext+=toA+',';
        }
        bodytext+='\n Cc Address(If Any):';
        if(email.ccAddresses!=null && email.ccAddresses.size()>0)
        {
         for(String toA:email.ccAddresses)
                bodytext+=toA+',';
        }
        bodytext+='\n';
        
        String emailbodyText='Body:\n';
        
        if (email.plainTextBody != null && email.plainTextBody.replaceAll(' ','').replaceAll('\n', '') != '' && email.plainTextBody.replaceAll(' ','').replaceAll('\n', '') != 'Force.comSandbox')
                  emailbodyText += email.plainTextBody;
        else if( email.htmlBody != null && email.htmlBody != '' )
        {
                    string htmlresult = email.htmlBody.replaceAll('<br/>', '\n');
                    //result = result.replaceAll('\n', '');
                    htmlresult = htmlresult.replaceAll('<br />', '\n');
                    htmlresult = htmlresult.replaceAll('<br>', '\n');
                    htmlresult = htmlresult.replaceAll('</br>', '\n');
                    htmlresult = htmlresult.replaceAll('</p>', '\n');
                    htmlresult = htmlresult.replaceAll('\n\n', '\n');
                    //regular expression to match all HTML/XML tags
                    string HTML_TAG_PATTERN = '<style.*?>.*?</style>';
                    // compile the pattern     
                    pattern myPattern = pattern.compile(HTML_TAG_PATTERN);
                    // get your matcher instance
                    matcher myMatcher = myPattern.matcher(htmlresult);
                    //remove the tags     
                    htmlresult = myMatcher.replaceAll('');
                    myPattern = pattern.compile('<.*?>');
                    // get your matcher instance
                    myMatcher = myPattern.matcher(htmlresult);
                    //remove the tags     
                    htmlresult = myMatcher.replaceAll('');
                    emailbodyText += htmlresult;
        }
        bodytext+=emailbodyText;
                    
        String subjecttext = email.subject;
        // users alias is needed to stamp the Akam fields
        User user,usr,defaultUsr;
        for(User u: [select Id, Akam_User_Id__c,Alias,email,IsActive from User where email = :email.fromAddress or Alias = :ContextAlias])
        {
                    if(u.email == email.fromAddress && u.IsActive==TRUE)
                    usr = u;
                    else if (u.Alias == ContextAlias)
                    defaultUsr = u;
        }
        
        if(usr!=null)
               user=usr;
        else
               user=defaultUsr;
        Task ta;
        if (subjecttext.lastindexof(delimiter) != -1)
        {
            Integer s = subjecttext.lastindexof(delimiter);
                 //public string getCaseNumber(string subjecttext,integer s)
            string match=getSFId(subjecttext,s);
            Id sObjId=match;//GetId(match);
            ta=createtask(user,sObjId,email.subject,bodytext);
            insert ta;
        } 
        else
            {
                // If the id is not found, Log it as a activity for CRMOPS
                ta=createtask(defaultUsr,null,email.subject,'Email Tracking of Product Approval Emails: Reference Id is missing\n'+bodytext);
                insert ta;
            }
            /*{
                FeedPost f = new FeedPost();
                f.ParentId = '005A0000001XPcD';
                f.title = email.subject;
                //f.linkurl = rolledUpfPost.linkurl;
                f.Body = 'Product Approvals: No Reference Id found\nSubject:'+email.subject+'\n'+bodytext;
                insert f;
            }*/
            //Throw new CustomException('Reference Id is missing');
        /*result.message='The data has been added successfully: '+ ta.id;
        result.success = true;                    
        return result;*/
        //Dont return anthing for the user
            return null;
                   

    }
     //CR 2770464 - rsharma: Moving test methods defined in this non test class to MiscTestClass
    //static TestMethod void TestEmailTracking()
    //{
    //    // create a new email and envelope object
    //  Messaging.InboundEmail email = new Messaging.InboundEmail() ;
    //  Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      
    //  String delimiter= GSM_Custom_Settings__c.getInstance('EmailTracking#delimiter').Value__c ;
      
    //  Profile pr = [select id from profile where name='Sales - Rep'][0];
    //  User usr = new User(alias = 'user', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__usr@akamai.com',profileid = pr.Id);
    //  usr.AKAM_User_ID__c = 'ABC123';
    //  insert usr;
    //  Product_Approvals__c pa = new Product_Approvals__c(Name='test');
    //  insert pa;
    //  email.subject = 'Testing New Case5 '+delimiter+' ['+pa.id+']';
    //  //email.bodytext = 'Creating a test case in test class';
    //  email.plainTextBody= '1234567889';
    //  email.fromname = 'FirstName LastName';
    //  email.fromAddress = 'salesop@akamai.com';

    //  EmailTracking et= new EmailTracking();
    //  et.handleInboundEmail(email, env);
     
    //  Task tsk;
    //  for(Task task1:[Select id,Subject,Status,Type__c,WhoId,OwnerId from Task where WhatId= :pa.id and Type__c='Email'])
    //  tsk=task1;
    //  System.assertEquals(tsk.Status,'Completed');
    //  System.assertEquals(tsk.Type__c,'Email');
    //  System.assertEquals(tsk.Subject, email.subject);
      
    //  email.subject = 'Testing New Case5 without reference Id';
    //  //email.bodytext = 'Creating a test case in test class';
    //  email.htmlBody = '1234567889';
    //  email.fromname = 'FirstName LastName';
    //  email.fromAddress = 'salesop2@akamai.com';
    //  et.handleInboundEmail(email, env);
    //}
    
}