/* ========================================================================
    Author: Sonia Sawhney
    Description: Utility class for Wizards 
    Created Date : 16/12/2014
    Modified By: Jaya on 27/04/2015 for sharing of ideas - CR 2995877
    Modified By: Prateek Bhuwania on 10/08/2018 for wizards migration to AppBattery
    ======================================================================== */
global class WizardsUtilClass
{     

    //Method added to remove hard coding of category and Sub category in controller
    webservice static List<String> getCatSubList(){
      AggregateResult countCat = [Select Count(Idea_Category_Subcategory__c) From Wizards_Category_SubCategory__c where Idea_Category_Subcategory__c != null][0];
      List<String> catSubcatList = new List<String>(); 
      for(Integer i=1;i<=integer.valueof(countCat.get('expr0'));i++){
        catSubcatList.add(Wizards_Category_SubCategory__c.getValues('c'+string.valueof(i)).Idea_Category_Subcategory__c);
      }  
      return catSubcatList;
    }
    
    //Method added to remove hard coding of Review status and Sub Status in controller
    webservice static List<String> getRevSubList(){
      AggregateResult countRev = [Select Count(Idea_ReviewSatus_SubStatus__c) From Wizards_ReviewStatus_SubStatus__c where Idea_ReviewSatus_SubStatus__c != null][0];
      List<String> revSubstatusList = new List<String>(); 
      for(Integer i=1;i<=integer.valueof(countRev.get('expr0'));i++){
        revSubstatusList.add(Wizards_ReviewStatus_SubStatus__c.getValues('r'+string.valueof(i)).Idea_ReviewSatus_SubStatus__c);
      }  
      return revSubstatusList;
    }

    //Method added to remove hard coding of Implementation Status and Sub Status in controller
    webservice static List<String> getImplementationSubList(){
      AggregateResult countRev = [Select Count(Idea_Implementation_StatusSubStatus__c) from Wizards_Implemetation_Status_Sub_Status__c where Idea_Implementation_StatusSubStatus__c!= null][0];
      List<String> ImplementationSubstatusList = new List<String>();
      for(Integer i=1; i<=integer.valueof(countRev.get('expr0')); i++){
        ImplementationSubstatusList.add(Wizards_Implemetation_Status_Sub_Status__c.getValues('i'+string.valueof(i)).Idea_Implementation_StatusSubStatus__c);
      }
      return ImplementationSubstatusList;
    }
    
    //Method to check if the logged in user has administrative priviledges to Wizard Ideas Object
    webservice static boolean isIdeaAdmin(String userId)
    {
        boolean isIdeaAdmin=false;
        //Check if the current user is assigned the wizards Idea permission set
        List<PermissionSetAssignment> assign = [Select AssigneeId from PermissionSetAssignment where PermissionSet.Name = 'Wizards_Admin' and AssigneeId = :userId limit 1];
        
        if(assign!=null && assign.size() >0)
        {
            isIdeaAdmin=true;
        }
        return isIdeaAdmin;
    }   
    
    webservice static list<PermissionSetAssignment> getAdminList()
    {
        list<PermissionSetAssignment> lstAdmins =  [Select AssigneeId, Assignee.Name, Assignee.Email from PermissionSetAssignment where PermissionSet.Name = 'Wizards_Admin'];      
        return lstAdmins;
    }
    
    webservice static list<PermissionSetAssignment> getReviwersList()
    {
        list<PermissionSetAssignment> lstReviewers =  [Select AssigneeId, Assignee.Name, Assignee.Email from PermissionSetAssignment where PermissionSet.Name = 'Wizards_Reviewer'];      
        return lstReviewers;        
    }
    
    webservice static Response DeleteAttachments(List<Id> attachIds)
    {       
        Database.DeleteResult[] results = Database.delete(attachIds,true);
        Response res = new Response();
        res.isSuccess = results[0].isSuccess();
        if(!res.isSuccess)
        {
            res.errormessage = results[0].getErrors()[0].getMessage();
        }
        return res;
    }

    webservice static Response CreateAttachments(Id ideaId,List<Attachment> attachments)
    { 
            ideaAttachment__c ia = [select Id from ideaAttachment__c where Idea__c = :ideaId];
            for(Attachment a:attachments) {
               a.ParentId = ia.Id;
            }
            Database.UpsertResult[] results = Database.Upsert(attachments, Schema.Attachment.Id, true);
            Response res = new Response();
            res.isSuccess = results[0].isSuccess();
            
            if(!res.isSuccess)
            {
                res.errormessage = results[0].getErrors()[0].getMessage();
            }

            return res;
    }        
    
    webservice static Response SaveIdea(Idea objIdea)
    {   
        if(objIdea.Team_Members__c == null)
          objIdea.Team_Members__c = null;
        Database.UpsertResult result = Database.Upsert(objIdea, Schema.Idea.Id, false);
        Response res = new Response();
        res.isSuccess = result.isSuccess();
        res.recordId = result.getId();
        if(!result.isSuccess())
        {
            res.errormessage = result.getErrors()[0].getMessage();
        } else {
            List<ideaAttachment__c> ias = [select Id from ideaAttachment__c where Idea__c = :res.recordId];
            if(ias.size() == 0) {
                ideaAttachment__c ideaAttach = new ideaAttachment__c();
                ideaAttach.Idea__c = res.recordId;
                insert ideaAttach;
            }    
        }
        return res;
    }
    
    webservice static Response SendMail(IdeaEmail__c objMail)
    {       
        Database.UpsertResult result = Database.Upsert(objMail, Schema.IdeaEmail__c.Id, false);
        Response res = new Response();
        res.isSuccess = result.isSuccess();
        res.recordId = result.getId();
        if(!result.isSuccess())
        {
            res.errormessage = result.getErrors()[0].getMessage();
        }
        return res;
    }
    
    webservice static IdeaComment__c SaveIdeaComment(IdeaComment__c objComment)
    {   
        Database.UpsertResult result = Database.Upsert(objComment, false);
        System.debug('Result ###'+result);
        return objComment;
    }
    
    static String validateEmail(String emailAddress)
    {
        String emailRegex = '([a-zA-Z0-9_\\-\\.]+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})';
        Pattern MyPattern = Pattern.compile(emailRegex);
        
        // Then instantiate a new Matcher object "MyMatcher"
        Matcher MyMatcher = MyPattern.matcher(emailAddress);
        
        if (!MyMatcher.matches()) {
        return 'invalid';
        }
        else
        {
            return 'valid';
        }
    }
    
    /* Start of changes by Jaya on 27/04/2015 for sharing of ideas - CR 2995877 */
    webservice static String shareIdea(String emailId,String IdeaUrl)
    {
        String emailIds = '';
        Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
        Messaging.SendEmailResult[] objListResult = new List<Messaging.SendEmailResult>();
        Messaging.SingleEmailMessage[] mailsToBeSent = new List<Messaging.SingleEmailMessage>();
        List<Messaging.SendEmailError> emptyList = new List<Messaging.SendEmailError>();
        List<String> toAddresses = new List<String>();
        Integer i;
        String strExceptionMessage = '';
        String emailValidate = '';
        System.debug(IdeaUrl);
        Integer index;
        index = IdeaUrl.lastIndexOf('/');
        String ideaId = IdeaUrl.substring(index+1);
        System.debug(ideaId);
        String emailBody = '';
        
        Idea idea = new Idea();
        idea = [select Title,Submitter_Name__c from Idea where Id = :ideaId];
        emailMessage.setSubject('My Wizards Idea');
        emailBody = '<html><body>Hello,<br/><br/>This is my Wizards Idea - ';
        emailBody += idea.Title+'.<br/>To view, like, comment or share the idea, use link - ';
        emailBody += IdeaUrl+'.<br/><br/>Visit the Wizards portal https://wizards.akamai.com today!<br/><br/>Best regards,<br/>'+idea.Submitter_Name__c+'<br/>';
        emailBody += '-----------------------<br/>Team Wizards,<br/>akamai-wizards@akamai.com</body></html>';
        
        emailMessage.setHtmlBody(emailBody);
        
        emailIds= emailId.replaceAll( '\\s+', '');
        if(emailIds.contains(','))
            toAddresses = emailIds.split(',');
        else
            toAddresses.add(emailIds);
            
        for(String toAddr:toAddresses)
        {
            emailValidate = validateEmail(toAddr);
            if(emailValidate == 'invalid')
                break;
        }
        if(emailValidate == 'invalid')
            return 'invalid';
            
        if(toAddresses != null && toAddresses.size()>0)
        {
            emailMessage.setToAddresses(toAddresses);
            mailsToBeSent.add(emailMessage);
            objListResult = Messaging.sendEmail(mailsToBeSent);
            for(i=0; i<objListResult.size(); i++)
            {            
                if (objListResult.get(i).getErrors() != emptyList)
                {
                    if(objListResult.get(i).getErrors().get(0).getStatusCode() == StatusCode.INVALID_EMAIL_ADDRESS)
                    {
                        if(objListResult.get(i).getErrors().get(0).getMessage() != null)
                        {
                            strExceptionMessage = objListResult.get(i).getErrors().get(0).getMessage();
                        }
                        else
                        {
                            strExceptionMessage = 'sendEmail failed. First error: INVALID_EMAIL_ADDRESS';
                        }
                    }
                }
            }
        }
        if(strExceptionMessage != '')
            return strExceptionMessage;
        else
            return 'Successful';
    }
    /* End of changes by Jaya on 27/04/2015 for sharing of ideas - CR 2995877 */
    
    /* Added by janantha for initializing data */
    public static Map<String,Map<String,String>> catSubcatEmail = new Map<String,Map<String,String>>();
    public static Map<String,String> temp = new Map<String,String>();
    public static List<String> emailIds = new List<String>();
    public static Map<String, String> emailIdUserName = new Map<String,String>();
    public static Map<String, String> emailIdUserId = new Map<String,String>();
    public static Map<String, String> userNameEmailId = new Map<String,String>();
    
    public static void initializeMaps()
    {
        for(Idea_Reviewer__c ideaReviewer:[select Category__c, Reviewer_Email__c, Sub_Category__c from Idea_Reviewer__c limit 50000])
        {
            emailIds.add(ideaReviewer.Reviewer_Email__c);
            temp = new Map<String,String>();
            if(catSubcatEmail.containsKey(ideaReviewer.Category__c) == true)
            {
                temp = catSubcatEmail.remove(ideaReviewer.Category__c);
            }
            temp.put(ideaReviewer.Sub_Category__c,ideaReviewer.Reviewer_Email__c);
            catSubcatEmail.put(ideaReviewer.Category__c,temp);           
        }
        system.debug('MAP*** '+catSubcatEmail);
        
        for(User user:[select Id, Name, Email from User where Email in :emailIds])
        {
            emailIdUserName.put(user.Email,user.Name);
            emailIdUserId.put(user.Email,user.Id);
            userNameEmailId.put(user.Name,user.Email);
        }
    } 
    
    global class Response
    {
        webService boolean isSuccess;
        webService Id recordId;
        webService string errormessage;
    }
}