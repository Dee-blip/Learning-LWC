/*=====================================================================================================+

|  HISTORY  |                                                                            

|  DATE           DEVELOPER   CR          DESCRIPTION                                                       

|  ===========    =========   =======     =========== 

|  26-SEP-2014    Akhila      2613747     This class is used for below functionality:
1. To send SI updates to Case Owner
|                               
15-OCT-2014    Himanshu    2797149     2. Send notification when status changed with related JIRA tickets/Bugzilla CRs details
|  
13-feb-2015    Jay         2627751                                     

|  14-Aug-2015    Aditya      3110191     Calculate and display Account Tier info on Incident                                        

|  01-Feb-2017    Vandhana    3630471     SOC: Closed tickets (linked to an SI) getting re-opened when SI is moved between phases.

|  22-Oct-2018    Pinkesh     ESESP-630   Disable email notifications if any change is made on customer advisory section or status of the incident record

|  07-April-2020  Sheena      ESESP-1767  Added recursive check for email notifications on Status change
+=====================================================================================================*/

public with sharing class SI_TriggerClass {
    
    public static boolean statusChangedTracked = false;
    public static boolean statusRecursiveCheck = true;
    
    /* Commenting as part of ESESP-630: Disable email notifications if any change is made on customer advisory section or status of the incident record
public static void SendUpdatetoCaseOwner(List<BMCServiceDesk__Incident__c> SI_Ids,Map<Id,BMCServiceDesk__Incident__c> oldMap){

List<Messaging.SingleEmailMessage> lmails = new List<Messaging.SingleEmailMessage>();


String EmailAddr = EmailHandler_CS__c.getInstance('ccare').Email_Address__c;
for(Case c:[Select Id,Owner.Email,OwnerId,Incident__c,Incident__r.Owner.Email,Incident__r.SI_GSS_Inc_Manager_BIL__r.Email,Akam_Case_Id__c,Incident__r.Customer_Advisory__c,Incident__r.BMCServiceDesk__Status_ID__c,Incident__r.BMCServiceDesk__FKStatus__c,Incident__r.Name,Incident__r.SI_Incident_Link__c from Case where Incident__c IN :SI_Ids])
{
Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

//if owner is user
if(c.OwnerId.getsObjectType()==User.getsObjectType())
{
mail.setToAddresses(new List<String>{c.Owner.Email,EmailAddr});
}
else
{
mail.setToAddresses(new List<String>{EmailAddr}); 
}

if(c.Incident__r.SI_GSS_Inc_Manager_BIL__c == null)
mail.setCcAddresses(new List<String>{c.Incident__r.Owner.Email});  
else
mail.setCcAddresses(new List<String>{c.Incident__r.Owner.Email,c.Incident__r.SI_GSS_Inc_Manager_BIL__r.Email});

// ____________________________________________________________
// !!! IMPORTANT !!! 
// NOTE - IF THIS CASE SUBJECT IS CHANGED, PLEASE MAKE A CHANGE IN EmailToCaseHandler.cls IN THE RE-OPEN MANAGED SECURITY CASES LOGIC. SEARCH FOR CR 3628251 AND UPDATE THE CASE SUBJECT IN IF CONDITION

String Sub = '[AKAM-CASE #'+c.Akam_Case_Id__c+'] Update on Service Incident #'+c.Incident__r.Name;
// ____________________________________________________________

mail.setSubject(Sub);
String FieldsChanged =null;

//if status is changed
if(c.Incident__r.BMCServiceDesk__FKStatus__c != oldMap.get(c.Incident__c).BMCServiceDesk__FKStatus__c)
FieldsChanged = 'Status';

//if customer advisory is changed
if(c.Incident__r.Customer_Advisory__c != oldMap.get(c.Incident__c).Customer_Advisory__c)
{
if(FieldsChanged == null)
FieldsChanged = 'CustomerAdvisory.';
else
FieldsChanged = FieldsChanged+' , CustomerAdvisory.';
}
String Body = 'There is an update to Service Incident #<a href='+URL.getSalesforceBaseUrl().toExternalForm()+'/'+c.Incident__c+'>'+c.Incident__r.Name+'</a>.<br><br>'+
'Field[s] updated: '+FieldsChanged+'<br><br>'+'Please view the Service Incident record via Remedyforce for the current status,<br>'+
'including customer messaging, mitigation plan, root cause diagnosis, recurrence prevention plan, etc.';
mail.setHtmlBody(Body);
lmails.add(mail);
}

if(lmails.size()>0)
Messaging.sendEmail(lmails);
} 

// Called from Trigger - SI_Customizations
// Purpose - Main method for sending emails after all calculations*/
    public void sendEmailStatusChange(list<BMCServiceDesk__Incident__c> allPhaseChangeSI)
    {
        // List to fetch all Incoming Service Incidents with Parent fields
        List<BMCServiceDesk__Incident__c> allPhaseChangeSIwithParentdata = [select Id,Name,BMCServiceDesk__Service_Request_Title__c,
                                                                            BMCServiceDesk__FKCategory__r.Name,
                                                                            BMCServiceDesk__FKStatus__r.Name,
                                                                            SI_Incident_Start_Time_InternationalForm__c,
                                                                            BMCServiceDesk__FKImpact__r.Name,
                                                                            BMCServiceDesk__Category_ID__c,
                                                                            Owner.Name,BMCServiceDesk__incidentDescription__c,
                                                                            SI_Created_Date_International_format__c,
                                                                            Customer_Advisory__c,
                                                                            CreatedBy.Name,
                                                                            CreatedBy.email 
                                                                            from BMCServiceDesk__Incident__c
                                                                            where id In :allPhaseChangeSI];
        // List to store all Individual Emails
        List<Messaging.SingleEmailMessage> Allmails = new List<Messaging.SingleEmailMessage>();
        
        // For Individual Email
        Messaging.SingleEmailMessage eachMail;
        
        // List to store SI Type from RelatedList Object - Related CR/NOCCIssue/SevereVulnerability 
        List<string> allSITypes = new List<string>();
        for(SI_RelatedList_Type__c eachSIRec : SI_RelatedList_Type__c.getall().values()){
            allSITypes.add(eachSIRec.Name);
        }
        
        // Map to store SI Id - Type field of "Related CR/NOCCIssue/SevereVulnerability"  + List of URL
        Map<string,List<string>> allSI_Type_URLListMap = new Map<string,List<string>>();
        allSI_Type_URLListMap = calculate_allSI_Type_URLListMap(allPhaseChangeSIwithParentdata,allSITypes);
        
        // Setting To Add
        String[] toAdd = new String[] {};
            
            // Setting Subject
            string setSubject;
        
        // Setting Body
        string setBody;
        
        // Loop for each Service Incident
        for(BMCServiceDesk__Incident__c eachSIrec : allPhaseChangeSIwithParentdata){
            
            // Initializing Individual Email
            eachMail = new Messaging.SingleEmailMessage();
            
            // Calculating To Address
            toAdd = new String[] {};
                toAdd.add(eachSIrec.CreatedBy.email);
            toAdd.add(calculateToAddfrmSev(eachSIrec));
            
            // Calculating Subject
            setSubject = 'Status change - SI ' + eachSIrec.Name + ': ' + eachSIrec.BMCServiceDesk__Service_Request_Title__c + 
                ' (Ref:IN:' + eachSIrec.Name + ')' ;
            
            // Calculating Body          
            setBody = calculateBody(allSI_Type_URLListMap,eachSIrec,allSITypes);
            
            // Setting all Email Message Parameters
            eachMail.setSubject(setSubject);
            eachMail.setToAddresses( toAdd );
            eachMail.setHtmlBody(setBody);
            Allmails.add(eachMail);
            
        }
        
        if(Allmails.size()>0){
            Messaging.sendEmail(Allmails);
            // Changes for ESESP-1767: Added recursive check for email notifications on Status change
            statusRecursiveCheck = false;
            //End of changes
        }
    }
    
    // Called from Method - sendEmailStatusChange
    // Purpose - Calculating values for Map (allSI_Type_URLListMap)
    public Map<string,List<string>> calculate_allSI_Type_URLListMap(list<BMCServiceDesk__Incident__c> allPhaseChangeSI,List<string> allSITypes)
    {
        // key to store SI Id - Type
        string SI_Id_TypeKey = null;
        
        // Map to store SI Id - Type field of "Related CR/NOCCIssue/SevereVulnerability"  + List of URL
        Map<string,List<string>> allSI_Type_URLListMap = new Map<string,List<string>>();
        
        // List to store all Related URLs
        List<string> allRelatedURLs;
        
        
        
        // Loop for "Related CR/NOCCIssue/SevereVulnerability" object 
        for(SI_AssociatedWorkItems__c eachRelatedrec : [select Id,SI_URL__c,SI_Type__c,SI_RemedyForce_Incident__c 
                                                        from SI_AssociatedWorkItems__c  
                                                        where SI_Type__c In :allSITypes and 
                                                        SI_RemedyForce_Incident__c In :allPhaseChangeSI]){
                                                            
                                                            // Setting Value for Key
                                                            SI_Id_TypeKey = eachRelatedrec.SI_RemedyForce_Incident__c + '-' + eachRelatedrec.SI_Type__c;
                                                            
                                                            // Fetching Existing List Of URLs
                                                            allRelatedURLs = allSI_Type_URLListMap.get(SI_Id_TypeKey);
                                                            
                                                            if(allRelatedURLs == null){
                                                                allRelatedURLs = new List<string>();
                                                            }
                                                            
                                                            allRelatedURLs.add(eachRelatedrec.SI_URL__c);
                                                            allSI_Type_URLListMap.put(SI_Id_TypeKey,allRelatedURLs);
                                                        }
        
        return allSI_Type_URLListMap;
        
    }
    
    // Called from Method - sendEmailStatusChange
    // Purpose - Calculating Email Body for each mail
    public string calculateBody(Map<string,List<string>> allSI_Type_URLListMap, BMCServiceDesk__Incident__c eachSIrec,List<string> allSITypes){
        
        // Setting Body
        string setBody;
        
        // List to store all URLs for each SI
        List<string> allURLs = new List<string>();
        
        // .......Setting All Bugzilla CR Links..........
        string setAllCR_JiraLinks = ' ';
        
        // Loop for Each SI Type Value
        for (string eachSIType : allSITypes){
            
            allURLs = allSI_Type_URLListMap.get(eachSIrec.Id + '-' + eachSIType);
            
            if(allURLs <> null && allURLs.size() > 0){
                
                setAllCR_JiraLinks += '<b>Related ' + eachSIType + ':</b><br>';
                
                for(integer count=0 ; count < allURLs.size() ; count++){
                    
                    setAllCR_JiraLinks += (count+1) + '. ' + allURLs[count] +'<br>';
                }
            }
            else
            {
                setAllCR_JiraLinks += '..No ' + eachSIType + ' is associated to this Service Incident..<br>';
            }
            
            setAllCR_JiraLinks +='<br>';
        }
        
        // Setting SI Record URL
        string recURL = URL.getSalesforceBaseUrl().toExternalForm()+'/'+eachSIrec.Id;
        
        // Formatting Description
        string setDescrition = eachSIrec.BMCServiceDesk__incidentDescription__c;
        try{
            
            setDescrition = (setDescrition <> null && setDescrition.length() > 2) ? setDescrition.replaceAll('\n','<br>') : setDescrition;
            
        }
        catch(exception e){}
        
        
        // Final Body
        setBody = eachSIrec.BMCServiceDesk__FKCategory__r.Name + ' Incident ' + eachSIrec.Name + ' ' + 
            '<a href='+ recURL + '>' + recURL + '</a>.<br><br>'+
            'Title: ' + eachSIrec.BMCServiceDesk__Service_Request_Title__c + '<br>' +
            'Status (Phase): ' + eachSIrec.BMCServiceDesk__FKStatus__r.Name + '<br>' +
            'Impact Started: ' + eachSIrec.SI_Incident_Start_Time_InternationalForm__c + '<br>' +
            'Impact (Severity): ' + eachSIrec.BMCServiceDesk__FKImpact__r.Name + '<br>' +
            'Category: ' + eachSIrec.BMCServiceDesk__Category_ID__c + '<br>' +
            'Owner (Technical Incident Manager): ' + eachSIrec.Owner.Name + '<br>' +
            'Description (Customer Impact): ' + '<br>' + setDescrition + '<br>' +
            'Customer Advisory: ' + eachSIrec.Customer_Advisory__c + '<br>' +
            'Created Date: ' + eachSIrec.SI_Created_Date_International_format__c + '<br>' +
            'Created By: ' + eachSIrec.CreatedBy.Name + '<br><br>' +
            setAllCR_JiraLinks + '<br>' + '------------<br>' +
            'This document and its contents are Akamai Confidential and are provided subject to the terms and conditions' +
            ' of the Nondisclosure Agreement (or the confidentiality provisions of the Akamai Terms and Conditions or your Akamai' +
            ' reseller or similar agreement) executed by Akamai and the recipient.';
        
        return setBody;
        
    }
    
    // Called from Method - sendEmailStatusChange
    // Purpose - Calculating To Address based on Severity from Custom setting
    public string calculateToAddfrmSev(BMCServiceDesk__Incident__c eachSIrec){
        
        // Setting To Add
        string setToAdd;
        
        if(eachSIrec.BMCServiceDesk__FKImpact__r.Name == 'Severity 1')
            setToAdd = SIMailingLists__c.getValues('SIEmailIds').SI_Severity1MailingList__c;
        else if (eachSIrec.BMCServiceDesk__FKImpact__r.Name == 'Severity 2')
            setToAdd = SIMailingLists__c.getValues('SIEmailIds').SI_Severity2MailingList__c;
        else if (eachSIrec.BMCServiceDesk__FKImpact__r.Name == 'Severity 3')
            setToAdd = SIMailingLists__c.getValues('SIEmailIds').SI_Severity3MailingList__c;
        else
            setToAdd = SIMailingLists__c.getValues('SIEmailIds').SI_Severity4MailingList__c;
        
        return setToAdd;
    }
    
    
    
    //Method to count the Account Tier for SI   
    Public void getAccountTierCount(list <BMCServiceDesk__Incident__c> incidentList){
        
        //List to store the Impacted Account records for all Incident Id passed from the trigger SI_Customization
        List<SI_ServiceIncidentImpactedCustomers__c> impactedAccList = [select id,SI_Service_Incident__c,Tier__c from SI_ServiceIncidentImpactedCustomers__c where SI_Service_Incident__c  IN : incidentList];
        
        //Map to store Incident Id and Account Tier
        Map<id,List<String>> accountTierMap = new Map<ID, list<String>>();
        
        //List to store all Tiers
        List<String> tierListAll = new List<String>();
        
        //for loop to store the Incident ID and Account Tier List in accountTierMap    
        for(SI_ServiceIncidentImpactedCustomers__c forEachSIAcc : impactedAccList){
            
            //checking if Map return null, for the first loop it will be null
            if(accountTierMap.get(forEachSIAcc.SI_Service_Incident__c) == Null){
                
                //Initialize the list
                accountTierMap.put(forEachSIAcc.SI_Service_Incident__c,new List<String>());
                
                //Add the Incident Id and Tier
                accountTierMap.get(forEachSIAcc.SI_Service_Incident__c).add(forEachSIAcc.Tier__c);
                
            } 
            else
            {
                //for the next loop it will keep adding Tier to the existing list
                accountTierMap.get(forEachSIAcc.SI_Service_Incident__c).add(forEachSIAcc.Tier__c);
            }
            
        }
        
        //List to store the Incident 
        List<BMCServiceDesk__Incident__c> incidentUpdtList = new List<BMCServiceDesk__Incident__c>();
        
        //For each incident       
        for(BMCServiceDesk__Incident__c forEachIncident : incidentList){
            
            //Setting the variable to 0
            integer tierCountAPlus = 0;
            integer tierCountA = 0;
            integer tierCountB = 0;
            integer tierCountC = 0;
            
            If(accountTierMap.get(forEachIncident.id) != Null){ 
                //for each Tier value      
                for(String impAccString : (accountTierMap.get(forEachIncident.id))){
                    
                    //Calculating the count of each Tier for an incident
                    
                    if(impAccString == 'A+'){
                        tierCountAPlus += 1;
                    }
                    else if(impAccString == 'A'){
                        tierCountA += 1;
                    }
                    else if(impAccString == 'B'){
                        tierCountB += 1;
                    }
                    else if(impAccString == 'C'){
                        tierCountC += 1;
                    }
                    
                }
                
                // Updating the Incident field with the Tier Count
                forEachIncident.Total_Tier_Count__c = 'Tier A+ : '+tierCountAPlus +' | '+'Tier A : '+tierCountA+' | '+'Tier B : '+tierCountB+' | '+'Tier C : '+tierCountC ;
                
                //Adding to the Incident List
                incidentUpdtList.add(forEachIncident);
            }
        }         
    }          
}