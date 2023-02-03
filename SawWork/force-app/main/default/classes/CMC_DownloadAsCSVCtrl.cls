/*
 * Author   : Vamsee Surya S
 * Date     : 14th Feb 2017
 * Purpose  : This class is the controller of CMC_DownloadAsCSV page and it will be used to download the Account details, 
 *            Valid and Invalid email address. This is implemented as part of CMC project (CR 3426181)             
 */
public class CMC_DownloadAsCSVCtrl {
    //This list will be used to set Valid and invalid Email Address. Email addresses will be stored as list of list
    public List<List<String>> listOfEmailsList {get;set;} 
    
    //This List will be used to set the Account Details
    public List<Account> accounts {get;set;}
    
    //This List will be used to set the Policy Domain Details
    public List<Policy_Domain__c> policyDomains {get;set;}
    
    //To store the Mailer Id
    public string mailerId;
    
    //To store the type - ValidEmails or InvalidEmails or AccountDetails
    public string download {get;set;}
    
    //To store the Header for the acccount details
    public string headers {get;set;}
    
    //Constructor
    public CMC_DownloadAsCSVCtrl(){
        //Mailer Id from the URL parameters
        mailerId = ApexPages.currentPage().getParameters().get('mailerId');
        //Type from the URL parameters
        download = ApexPages.currentPage().getParameters().get('download');
        Try{
            if(download == 'PolicyDomainDetails'){
                List<Attachment> attachmentList = [Select Id, Body, ContentType from ATTACHMENT where parentId =:mailerId AND Name = 'QueryString.txt' Limit 1];
                if(attachmentList.size() == 1){
                    String queryString = attachmentList[0].body.toString();
                    //Replace "Id" with required field API Name
                    queryString = queryString.replaceFirst('SELECT Id','SELECT AKAM_Policy_Domain_ID__c,Name,Account_ID__c,Account_Name__r.Name,Policy_Domain_State__c,Product__c,Service_Account__r.Name ');
                    policyDomains = database.query(queryString);
                    //Corresponding field names
                    headers = 'AKAM Policy Domain ID,Policy Domain Name,AKAM Account ID,Account Name,Policy Domain State,Product,Service Account Name';
                }
                else
                    system.debug('CMC_DownloadAsCSVCtrl : No QueryString File');
            }
            else if(download == 'AccountDetails'){
                List<Attachment> attachmentList = [Select Id, Body, ContentType from ATTACHMENT where parentId =:mailerId AND Name = 'QueryString.txt' Limit 1];
                if(attachmentList.size() == 1){
                    String queryString = attachmentList[0].body.toString();
                    //Replace "Id" with required field API Name
                    queryString = queryString.replaceFirst('SELECT Id','SELECT Akam_Account_Id__c,Name, Geography_Formula__c,Division_Formula__c,Division__c,Support_Level__c,Customer_Tier__c,Owner.name,Account_Status__c');
                    accounts = database.query(queryString);
                    //Corresponding field names
                    headers = 'Akam Account Id,Name,Geography,Division,Region,Support Level,Customer Tier,Account Owner,Account Status';
                }
                else
                    system.debug('CMC_DownloadAsCSVCtrl : No QueryString File');
            }
            else{
                // To get the valid and invalid email addresses
                EB_AkaMailer__c mailerObject = [Select Id, CMC_Manual_Email_Addresses__c from EB_AkaMailer__c where Id =:mailerId];
                List<String> allEmailsList = new List<String>();
                if(download == 'ValidEmails')
                    allEmailsList = CMC_MailerHelper.ValidateEmailAddresses(mailerObject.CMC_Manual_Email_Addresses__c,mailerObject.Id,true);
                else if(download == 'InvalidEmails')
                    allEmailsList = CMC_MailerHelper.ValidateEmailAddresses(mailerObject.CMC_Manual_Email_Addresses__c,mailerObject.Id,false);
                
                //Spliting the List into List of List because Maximum size for list 10,000 to use it on VF page
                Integer count = 0; 
                
                //This will store the list of Email list
                listOfEmailsList = new List<List<String>>();
                List<String> emails = new List<String>();
                for(String eachEmail : allEmailsList){
                    count = count + 1;
                    emails.add(eachEmail);
                    if(count == 9999){
                        //Creating the temp variable because 'emails' List need to be cleared
                        List<String> temp = new List<String>();
                        temp.addAll(emails);
                        listOfEmailsList.add(temp);
                        emails.clear();
                        //reset the count
                        count = 0;
                    }
                }
                allEmailsList.clear();
                if(emails.size() > 0)
                    listOfEmailsList.add(emails);  
          }
        }    
        Catch(Exception ex){
            System.debug('--Exception--');
            System.debug('Line Number :'+ex.getLineNumber());
            System.debug('Message :'+ex.getMessage()); 
            
        }
    }
}