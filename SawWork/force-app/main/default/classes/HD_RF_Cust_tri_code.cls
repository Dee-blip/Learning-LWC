/*
Template: Apex Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 

Base Line : used as apart of requirement for Problem Management

Purpose : an implementation for trigger HD_Problem_Customization.trigger
          
Usage : used as an implementation for the business logic , for trigger HD_Problem_Customization.trigger
          
Test Class Associated : NONE

Controller (Boolean): False

Page Used/Associated (default -> NONE) : NONE

Trigger Associated : HD_Problem_Customization.trigger
              
*/
/*
Code Statistics :  9 soql Query Used
CPU usage from test class : 100-200 cpu utilization based on batch size
* Modification Log ===============================================================
* Date 				Author 					Modification
* Nov 29th, 2021    Aneesh Budnar           PRTORES-2358 - HD Code Scanner 1 fixes
*/

 
public with sharing class HD_RF_Cust_tri_code {

//global variables
private static BMCServiceDesk__Problem__c[] problemObject = null;
private static BMCServiceDesk__Category__c[] categoryList = new BMCServiceDesk__Category__c[]{}; 


// lets check how the class instance is available or not
private static HD_RF_Cust_tri_code instance = null ; 

//constructor to pass the values for default data allocation
private HD_RF_Cust_tri_code (BMCServiceDesk__Problem__c[] problem_Object)
{
    
    problemObject = problem_Object;
    
}

//Getting instance of the class before we actually execute the  business logic, Singleton patter wit lazy loading
public static HD_RF_Cust_tri_code getInstance( BMCServiceDesk__Problem__c[] problem_Object )
{
    if (  instance == null )
    {
        instance = new HD_RF_Cust_tri_code( problem_Object );
    }
    return instance;
}



// the purpose of the this method is to rectify the data and manage data errors,during insert , event before
public void dataRectifiaction_beforeInsert()
{
try{
for ( BMCServiceDesk__Problem__c prob : problemObject  )
{
        
if ( prob.Category_alias__c != null )
{
System.debug('-------> Executing the dataRectification_beforeInsert() Method');

//updating the Category Field before Insert or the new record
prob.BMCServiceDesk__FKCategory__c = prob.Category_alias__c;

//
Map<String,String> impactMap = new Map<String,String>();
impactMap.putAll( impactPickListToLookupValueExtractor() );

//
Map<String,String> urgencyMap = new Map<String,String>();
urgencyMap.putAll( urgencyPickListToLookupValueExtractor() );

System.debug('IMpact ------> '+prob.Impact_picklist__c);
prob.BMCServiceDesk__FKImpact__c = impactMap.get( prob.Impact_picklist__c );

System.debug('Urgency ------> '+prob.Urgency_picklist__c);
prob.BMCServiceDesk__FKUrgency__c = urgencyMap.get( prob.Urgency_picklist__c ); 

prob.BMCServiceDesk__FKPriority__c = CalculatePriorityID(prob.BMCServiceDesk__FKUrgency__c, prob.BMCServiceDesk__FKImpact__c );

//START Added code for CR 2605809 BY Hemant Kumar
//setting service Owner Field
if( prob.Override_Service_Owner__c == false )
{
prob.Service_Owners__c = serviceOwner(prob.Category_alias__c);
}
//END Added code for CR 2605809 BY Hemant Kumar


//Updating Owner Field
if(prob.Problem_Coordinator__c == null)
{
    prob.Problem_Coordinator__c = prob.OwnerId; 
}
else
{
    prob.OwnerID = prob.Problem_Coordinator__c;
}


}// if


}// for
processCCFields();
 
}
catch ( Exception e )
{
    //more exception has to be handled here
    System.debug('Error has happened !');
}// Catch Exception

} //public void dataRectifiaction()


//this is a scalable Method for Impact, we are using Custom setting called HD_IMPACT_PICKLIST_MAPPING
private static Map<string,string> impactPickListToLookupValueExtractor()
{
    //
    Map<String,String> ImpactMap = new Map<String,String>();
    List<HD_IMPACT_PICKLIST_MAPPING__c> impactList = new List<HD_IMPACT_PICKLIST_MAPPING__c>();
    //impactList = [ Select Id, Name  From BMCServiceDesk__Impact__c WHERE BMCServiceDesk__inactive__c = false LIMIT 100 ];
    impactList = HD_IMPACT_PICKLIST_MAPPING__c.getall().values();
    if(impactList.size() > 0)
    {
        for(HD_IMPACT_PICKLIST_MAPPING__c imp : impactList )
        {       
        ImpactMap.put( imp.Name ,imp.recordid__c);
        }//for
    }// if(impactList.size() > 0)
    
    return ImpactMap;
}//private static Map<string,string> impactPickListToLookupValueExtractor()



//this is a scalable Method for Urgency, we are using Custom setting called HD_URGENCY_PICKLIST_MAPPING__c
private static Map<String,String> urgencyPickListToLookupValueExtractor()
{
    Map<String,String> UrgencyMap = new Map<String,String>();
    List<HD_URGENCY_PICKLIST_MAPPING__c> UrgencyList = new List<HD_URGENCY_PICKLIST_MAPPING__c>();
    //UrgencyList = [ Select Id,Name From BMCServiceDesk__Urgency__c  WHERE BMCServiceDesk__inactive__c = false LIMIT 100 ];
    UrgencyList = HD_URGENCY_PICKLIST_MAPPING__c.getall().values();
    if( UrgencyList.size() > 0 )
    {
        for( HD_URGENCY_PICKLIST_MAPPING__c urg :  UrgencyList )
        {
            UrgencyMap.put( urg.Name ,urg.recordid__c);
        }//for
    }//if
    
    return UrgencyMap;
}//private static String urgencyPickListToLookupValueExtractor(String urgencyPickListValue)



//THis method is used to extract the priority based on urgency and Impact
private static String CalculatePriorityID(String urgencyId,String ImpactId)
{
Id PriorityID = null;
List<BMCServiceDesk__Priority__c> priority = new List<BMCServiceDesk__Priority__c>();
priority = [Select Id From BMCServiceDesk__Priority__c WHERE BMCServiceDesk__FKUrgency__c =:urgencyId  AND  BMCServiceDesk__FKImpact__c =:ImpactId  LIMIT 1];
if(priority.size() > 0 )
{
    PriorityID = priority[0].Id;
}

return PriorityID;  
}//private static String CalculatePriorityID(String urgencyId,String ImpactId)
    
//START Added code for CR 2605809 BY Hemant Kumar    
//THis method is used to extract the Service Owner for category    
private static String serviceOwner(String categoryId)
{
Id catID = null;
List<BMCServiceDesk__Category__c> catList = new List<BMCServiceDesk__Category__c>();
catList = [select Id,Name,Service_Owner__c from BMCServiceDesk__Category__c  WHERE Id=:categoryID LIMIT 1];
if(catList.size() > 0 )
{
    catID = catList[0].Service_Owner__c;
}

return catID;   
}//private static String CalculatePriorityID(String urgencyId,String ImpactId)    
//END Added code for CR 2605809 BY Hemant Kumar


//CC Field processor
private static void processCCFields()
{
System.debug('-------> Exectuing the processCCFields() Method');    
//number of HD_EmailCC fields Limit
Integer HD_EmailCC_present_limit = 6; 
//define an Sobject 
Sobject Problem_Sobject = new BMCServiceDesk__Problem__c(); 
    for (Sobject pst : problemObject)
    {
        if( pst.getSobjectType() == BMCServiceDesk__Problem__c.sObjectType )
        {
            Problem_Sobject = (BMCServiceDesk__Problem__c)pst;
         //nullify all the fields first before proceeding ... ! Important 
         for(Integer i = 0 ; i < HD_EmailCC_present_limit ;i++ )
         {
          Problem_Sobject.put('CC'+(i+1)+'__c', '');
         }
          //logic for extracting emails from CC__c Field 
        object CCtextValue = Problem_Sobject.get('CC__c');
        String rawcctext = null;
        if( CctextValue != null )
        {
        rawcctext = String.valueOf(CctextValue).normalizeSpace();
        }
     
         
      if( rawcctext != null )
    {           
        //Staring code update for CR 2320427- Make CC field smarter, by Hemant
        
        //adding ; if its not present in the CCtext String 
        if( ! rawcctext.endsWith(';') )
        {
        rawcctext  = rawcctext.normalizeSpace()+';';
        }
        
        //START adding logic to re-sync the pattern for best match to solve the few errors
         rawcctext  = rawcctext.normalizeSpace().deleteWhitespace();
         System.debug('Pattern Rectifier value normalizeSpace() ------------------> '+ rawcctext );
         rawcctext = rawcctext.replaceAll('\\b(.com)\\b(.com)*','.com');
         rawcctext = rawcctext.replaceAll('(,([\\,]*[\\s]*)*)','');
         rawcctext = rawcctext.replaceAll('.com','.com;');
         rawcctext = rawcctext.replaceAll('(\\b.com\\b)([\\s]*[;]*[\\s]*)*','.com;');
                 
         System.debug('Pattern Rectifier value with regexp substitution; ------------------> '+ rawcctext );
         
         
         
         // Staring code fix CR 2331057 - RF: Helpdesk BugFix for the exception that is being thrown out wrt email cc fields 
         if(rawcctext.contains(';;') == true)
         {
          rawcctext = rawcctext.replaceAll('([;])([\\s]*[;]*[\\s]*)*',';');
          System.debug('Pattern Rectifier value ;; to ; ------------------> '+ rawcctext );
         }
         if(rawcctext.contains('@@') == true)
         {
          rawcctext = rawcctext.replaceAll('\\b(@([\\@]*[\\s]*)*)\\b','@');
          System.debug('Pattern Rectifier value @@*  to @ with regexp ; ------------------> '+ rawcctext );
         }
         
         // END code fix CR 2331057 - RF: Helpdesk BugFix for the exception that is being thrown out wrt email cc fields
         
         
         
         System.debug('Pattern Rectifier value ------------------> '+ rawcctext );
         
        //END adding logic to re-sync the pattern for best match to solve the few errors
        
        //now adding the patternised value to CcText Field Again !important
        Problem_Sobject.put('CC__c', rawcctext.normalizeSpace());
        
       //END of code update for CR 2320427- Make CC field smarter, by Hemant
       
     //checking the CCtext email integrity 
     if( Pattern.matches('^((\\w+([-+.\']\\w+)*@akamai\\.com*([\\s]*?[;][\\s]*))*)$' ,rawcctext) == true  )
        {
        System.debug('--------> '+rawcctext.toLowerCase().trim());
        List<String> CcTextEmails = rawcctext.toLowerCase().trim().split(';');
        if ( ( CcTextEmails.size() > 0 ) &&  (  CcTextEmails.size() < 7 ) ) 
        
        {
   
           
         //now set the values based on CcText field     
         for(Integer i = 0 ; i < cCTextemails.size() ;i++ )
         {
        
         object currenttext = CcTextEmails.get(i);
         Problem_Sobject.put('CC'+(i+1)+'__c', currenttext );
         }
            
        }//if ( ( CcTextEmails.size() > 0 ) &&  (  CcTextEmails.size() < 11 ) )
        else
        {
           Problem_Sobject.addError('minimum 1 and maximum of 6 Cc emails are acceptable !'); //increased the limit to 10 , as per CR 2480916
           problemObject[0].CC__c.addError('minimum 1 and maximum of 6 Cc emails are acceptable !'); //increased the limit to 10 , as per CR 2480916
        }//if ( ( CcTextEmails.size() > 0 ) &&  (  CcTextEmails.size() < 11 ) )

        }// if( Pattern.matches *
        else
        {
        Problem_Sobject.addError('Cc Field : 1. Only akamai.com emails are accepted ! 2. Please enter (;) at the end of every email if necessary ! 3. Accepts up-to 6 emails field '); //increased the limit to 10 , as per CR 2480916
        problemObject[0].CC__c.addError('CCText : email pattern is not valid !'); 
        }// if( Pattern.matches *
        
    } //if ( incident_Sobject.get('CCText__c') != null )
         
         
        }//if( pst.getSobjectType() == BMCServiceDesk__Problem__c.sObjectType )
        
    }//for

    
}//private static void processCCFields()


//Call this method only in updating scenario, for setting prior values to the fields
//This method used for Update emails
public static void priorValuesetter( BMCServiceDesk__Problem__c[] OLDProblemTriggervalue  )
{     
    
    try{
        
    if(OLDProblemTriggervalue != null  )
    {
        


        
if (problemObject.size() == OLDProblemTriggervalue.size() ) 
{   
    List<BMCServiceDesk__Problem__c> currentversion = new List<BMCServiceDesk__Problem__c>();
    List<BMCServiceDesk__Problem__c> oldproblemvalues = new List<BMCServiceDesk__Problem__c>();
    currentversion.addAll(problemObject);
    oldproblemvalues.addAll(OLDProblemTriggervalue);
    
        for(Integer i=0;i< OLDProblemTriggervalue.size();i++ )
        {
                            
            currentversion[i].CC_Prior_value__c = oldproblemvalues[i].CC__c;
            currentversion[i].Root_Cause_Prior_value__c = oldproblemvalues[i].Root_Cause__c;
            currentversion[i].Description_Prior_value__c = oldproblemvalues[i].BMCServiceDesk__Problem_Description__c;
            currentversion[i].Impact_Prior_value__c = oldproblemvalues[i].BMCServiceDesk__Impact__c;
            currentversion[i].Service_Prior_value__c = oldproblemvalues[i].BMCServiceDesk__Category__c;
            currentversion[i].Status_Prior_value__c = oldproblemvalues[i].BMCServiceDesk__Status__c;
            currentversion[i].Urgency_Prior_value__c = oldproblemvalues[i].BMCServiceDesk__Urgency__c;
            currentversion[i].Closure_Category_Prior_value__c = oldproblemvalues[i].BMCServiceDesk__ClosureCategory__c;
            currentversion[i].Known_Error_Prior_value__c = String.valueof( oldproblemvalues[i].BMCServiceDesk__Known_Error__c );
            currentversion[i].Problem_For_Sensitive_Incide_Prior_value__c = String.valueOf( oldproblemvalues[i].Problem_For_Sensitive_Incident__c);
            currentversion[i].Problem_Coordinator_Prior_value__c = oldproblemvalues[i].Problem_Coordinator_formulafield__c;
            currentversion[i].Problem_Source_Prior_value__c  = oldproblemvalues[i].BMCServiceDesk__Problem_Source__c;
            currentversion[i].Resolution_Prior_value__c = oldproblemvalues[i].BMCServiceDesk__Problem_Resolution__c;
            currentversion[i].Root_Cause_Type_Prior_value__c = oldproblemvalues[i].Root_Cause_Type__c;
            currentversion[i].Service_Element_Prior_value__c = oldproblemvalues[i].Service_Element__c;
            //currentversion[i].Service_Owner_Prior_value__c = oldproblemvalues[i].Service_Owner__c;
            currentversion[i].Workaround_Prior_value__c = oldproblemvalues[i].BMCServiceDesk__Work_Around__c;
        }
        
}//if (problemObject.size() == OLDProblemTriggervalue.size() )
        
        
    }//if

    }//try
    catch(Exception e)
    {
        System.debug('Error has happened !'+e);
        
    }//Catch()
    
}//public static void priorValuesetter( BMCServiceDesk__Problem__c[] OLDProblemTriggervalue  )

//this method is used to send email to the sme
public static void smeEmailSender( BMCServiceDesk__Problem__c[] newTriggervalueforProblem)
{   
    //Changed as a part of CR s2610705 - Problem Mgmt - Email templates should be consistent 
    String recordLink = URL.getSalesforceBaseUrl().toExternalForm()+'/'+newTriggervalueforProblem[0].Id; 
    
    String[] toAddresses = new List<String>();
    Messaging.Singleemailmessage  mail = new Messaging.Singleemailmessage();// invoking mail class
    List<Subject_Matter_Expert__c> sme = new List<Subject_Matter_Expert__c>();
    sme = [Select   Name, Email__c From Subject_Matter_Expert__c s WHERE  Problem__c =: newTriggervalueforProblem[0].Id LIMIT 100];
    //Adding email to an string array
    if( sme.size() > 0 )
    {
for ( Subject_Matter_Expert__c smeemail : sme)
{
    toAddresses.add( smeemail.Email__c );
}
    
//Setting email entities    
mail.setToAddresses(toAddresses);
//mail.setEmailPriority(pString)
mail.setSubject('Problem #'+newTriggervalueforProblem[0].Name+' has been UPDATED');



//Construct Email body 
String emailbody = '<a href="'+ recordLink +'">'+newTriggervalueforProblem[0].Last_Modified_By_for_field__c +'</a> changed the following in Problem <a href="'+recordLink +'">#'+newTriggervalueforProblem[0].Name+'</a>';

emailbody += '<table style="width:300px;" border="1px"><tr><th>Field</th><th>Old Value</th><th>New Value</th></tr>';
//starting Dynamic inputs
if( newTriggervalueforProblem[0].Description_Prior_value__c != newTriggervalueforProblem[0].BMCServiceDesk__Problem_Description__c )
{
emailbody +='<tr><td>Description</td><td>'+ newTriggervalueforProblem[0].Description_Prior_value__c +'</td><td>'+newTriggervalueforProblem[0].BMCServiceDesk__Problem_Description__c +'</td></tr>';
}

if(newTriggervalueforProblem[0].Root_Cause_Type_Prior_value__c != newTriggervalueforProblem[0].Root_Cause_Type__c)
{
    emailbody +='<tr><td>Root Cause</td><td>'+ newTriggervalueforProblem[0].Root_Cause_Type_Prior_value__c +'</td><td>'+newTriggervalueforProblem[0].Root_Cause_Type__c +'</td></tr>';
}

//if(newTriggervalueforProblem[0].Root_Cause_Type_Prior_value__c != newTriggervalueforProblem[0].Root_Cause_Type__c)
//{
//  emailbody +='<tr><td>Root Cause</td><td>'+ newTriggervalueforProblem[0].Root_Cause_Type_Prior_value__c +'</td><td>'+newTriggervalueforProblem[0].Root_Cause_Type__c +'</td></tr>';
//}

if(newTriggervalueforProblem[0].Service_Prior_value__c != newTriggervalueforProblem[0].BMCServiceDesk__Category__c)
{
    emailbody +='<tr><td>Service</td><td>'+ newTriggervalueforProblem[0].Service_Prior_value__c +'</td><td>'+newTriggervalueforProblem[0].BMCServiceDesk__Category__c +'</td></tr>';
}

if(newTriggervalueforProblem[0].Known_Error_Prior_value__c !=  String.valueOf(newTriggervalueforProblem[0].BMCServiceDesk__Known_Error__c) )
{
    emailbody +='<tr><td>Known Error</td><td>'+ newTriggervalueforProblem[0].Known_Error_Prior_value__c +'</td><td>'+newTriggervalueforProblem[0].BMCServiceDesk__Known_Error__c +'</td></tr>';
}

if(newTriggervalueforProblem[0].Resolution_Prior_value__c != newTriggervalueforProblem[0].BMCServiceDesk__Problem_Resolution__c)
{
    emailbody +='<tr><td>Resolution</td><td>'+ newTriggervalueforProblem[0].Resolution_Prior_value__c +'</td><td>'+newTriggervalueforProblem[0].BMCServiceDesk__Problem_Resolution__c +'</td></tr>';
}

if(newTriggervalueforProblem[0].Workaround_Prior_value__c != newTriggervalueforProblem[0].BMCServiceDesk__Work_Around__c)
{
    emailbody +='<tr><td>Workaround</td><td>'+ newTriggervalueforProblem[0].Workaround_Prior_value__c +'</td><td>'+newTriggervalueforProblem[0].BMCServiceDesk__Work_Around__c +'</td></tr>';
}

if(newTriggervalueforProblem[0].Problem_For_Sensitive_Incide_Prior_value__c != String.valueOf( newTriggervalueforProblem[0].Problem_For_Sensitive_Incident__c))
{
    emailbody +='<tr><td>Problem For Sensitive Incident</td><td>'+ newTriggervalueforProblem[0].Problem_For_Sensitive_Incide_Prior_value__c +'</td><td>'+newTriggervalueforProblem[0].Problem_For_Sensitive_Incident__c +'</td></tr>';
}

if( newTriggervalueforProblem[0].Impact_Prior_value__c != newTriggervalueforProblem[0].BMCServiceDesk__Impact__c)
{
    emailbody +='<tr><td>Impact</td><td>'+ newTriggervalueforProblem[0].Impact_Prior_value__c +'</td><td>'+newTriggervalueforProblem[0].BMCServiceDesk__Impact__c +'</td></tr>';
}

if( newTriggervalueforProblem[0].Status_Prior_value__c != newTriggervalueforProblem[0].BMCServiceDesk__Status__c)
{
    emailbody +='<tr><td>Status</td><td>'+ newTriggervalueforProblem[0].Status_Prior_value__c +'</td><td>'+newTriggervalueforProblem[0].BMCServiceDesk__Status__c +'</td></tr>';
}

if( newTriggervalueforProblem[0].Urgency_Prior_value__c != newTriggervalueforProblem[0].BMCServiceDesk__Urgency__c)
{
    emailbody +='<tr><td>Urgency</td><td>'+ newTriggervalueforProblem[0].Urgency_Prior_value__c +'</td><td>'+newTriggervalueforProblem[0].BMCServiceDesk__Urgency__c +'</td></tr>';
}

if(newTriggervalueforProblem[0].Problem_Coordinator_Prior_value__c != newTriggervalueforProblem[0].Problem_Coordinator_formulafield__c)
{
    emailbody +='<tr><td>Problem Coordinator</td><td>'+ newTriggervalueforProblem[0].Problem_Coordinator_Prior_value__c +'</td><td>'+newTriggervalueforProblem[0].Problem_Coordinator_formulafield__c +'</td></tr>';
}
/*
if(newTriggervalueforProblem[0].Service_Owner_Prior_value__c != newTriggervalueforProblem[0].Service_Owner__c)
{
    emailbody +='<tr><td>Service Owner</td><td>'+ newTriggervalueforProblem[0].Service_Owner_Prior_value__c +'</td><td>'+newTriggervalueforProblem[0].Service_Owner__c +'</td></tr>';
}
*/
emailbody +='</table><br></br>';
//Changed as a part of CR 2610705 - Problem Mgmt - Email templates should be consistent 
emailbody +='To know more click on the Link below :'+recordLink;
emailbody +='<hr></hr>.';
//setting HTML BODY
mail.setHtmlBody( emailbody );
Messaging.sendEmail(new Messaging.Singleemailmessage[]{mail});
}//if( sme.size() > 0 )

}// public void smeEmailSender

// This method is used to update the problem values, when ever the Problem is linked to parent incident
public static void  updateProblemOnParentIncidentLink( BMCServiceDesk__Problem__c[] newProblemversion,BMCServiceDesk__Problem__c[] oldProblemversion  )
{
    System.debug('-----> Executing updateProblemOnParentIncidentLink' );
    List<Id> parentIncId = new List<Id>();
    for(BMCServiceDesk__Problem__c prbincId : newProblemversion)
    {
        parentIncId.add( prbincId.Parent_Incident__c); 
    }   
        
    List<BMCServiceDesk__Incident__c> incidentList = new List<BMCServiceDesk__Incident__c>();
    Map<String,String> impactIdMap = new Map<String,String>();
    impactIdMap.putAll(impactIdToNameValue());
    
    Map<String,String> urgencyIdMap = new Map<String,String>();
    urgencyIdMap.putAll(urgencyIdToNameValue());

    
    if( parentIncId.size() > 0 )
    {

    incidentList = [ Select  BMCServiceDesk__FKImpact__c,BMCServiceDesk__FKUrgency__c, BMCServiceDesk__FKCategory__c From BMCServiceDesk__Incident__c WHERE Id IN:parentIncId];
    
    
    if ( newProblemversion.size() > 0 &&  oldProblemversion == null)
    {
        for(BMCServiceDesk__Problem__c nwversion : newProblemversion)
        {
        
        if( nwversion.Parent_Incident__c != null )
    {
        

    for( BMCServiceDesk__Incident__c inc : incidentList )
    {
        nwversion.Impact_picklist__c = impactIdMap.get( inc.BMCServiceDesk__FKImpact__c );
        nwversion.Urgency_picklist__c = urgencyIdMap.get(  inc.BMCServiceDesk__FKUrgency__c );
        
    }//for


    }//if( nwversion.Parent_Incident__c != null )
    }//
    }//if ( newProblemversion.size() > 0  && oldProblemversion.size() == 0 )
    
    else if(newProblemversion.size() > 0  && oldProblemversion.size() > 0 && ( newProblemversion.size() == oldProblemversion.size()) )
    {
        System.debug('-----> Executing updateProblemOnParentIncidentLink() ---> Update Action Detected ! ');    
        for(Integer i = 0 ; i< oldProblemversion.size();i++ )
        {
            if( newProblemversion[i].Parent_Incident__c != oldProblemversion[i].Parent_Incident__c  )
            {
                
                    for( BMCServiceDesk__Incident__c inc : incidentList )
                    {
        
        newProblemversion[i].Impact_picklist__c = impactIdMap.get( inc.BMCServiceDesk__FKImpact__c );
        newProblemversion[i].Urgency_picklist__c = urgencyIdMap.get(  inc.BMCServiceDesk__FKUrgency__c );
        
                    }//for
                
                
            }//if

        }//for
        
    }//else if(newProblemversion.size() > 0  && oldProblemversion.size() > 0)
    
}//if( parentIncId.size() > 0 )
    
}//

////we are using Custome setting here ,HD_IMPACT_PICKLIST_MAPPING__c
private static Map<string,string> impactIdToNameValue()
{
    //
    Map<String,String> ImpactMap = new Map<String,String>();
    List<HD_IMPACT_PICKLIST_MAPPING__c> impactList = new List<HD_IMPACT_PICKLIST_MAPPING__c>();
    //impactList = [ Select Id, Name  From BMCServiceDesk__Impact__c WHERE BMCServiceDesk__inactive__c = false LIMIT 100 ];
    impactList = HD_IMPACT_PICKLIST_MAPPING__c.getall().values();
    if(impactList.size() > 0)
    {
        for(HD_IMPACT_PICKLIST_MAPPING__c imp : impactList )
        {       
        ImpactMap.put( imp.recordid__c ,imp.Name ) ;
        }//for
    }// if(impactList.size() > 0)
    
    return ImpactMap;
}//private static Map<string,string> impactIdToNameValue()

//we are using Custome setting here , HD_URGENCY_PICKLIST_MAPPING__c
private static Map<String,String> urgencyIdToNameValue()
{
    Map<String,String> UrgencyMap = new Map<String,String>();
    List<HD_URGENCY_PICKLIST_MAPPING__c> UrgencyList = new List<HD_URGENCY_PICKLIST_MAPPING__c>();
    //UrgencyList = [ Select Id,Name From BMCServiceDesk__Urgency__c  WHERE BMCServiceDesk__inactive__c = false LIMIT 100 ];
     UrgencyList = HD_URGENCY_PICKLIST_MAPPING__c.getall().values();
    if( UrgencyList.size() > 0 )
    {
        for( HD_URGENCY_PICKLIST_MAPPING__c urg :  UrgencyList )
        {
            UrgencyMap.put( urg.recordid__c , urg.Name );
        }//for
    }//if
    
    return UrgencyMap;
}//private static Map<String,String> urgencyPickListToLookupValueExtractor()


private static Map<String,String> problemStatusValuesNameid()
{
    Map<String,String> StatusMap = new Map<String,String>();
    List<BMCServiceDesk__Status__c> StatusList = new List<BMCServiceDesk__Status__c>();
    StatusList = [ Select Name, Id From BMCServiceDesk__Status__c  WHERE  BMCServiceDesk__appliesToProblem__c = true  LIMIT 100 ];
    if( StatusList.size() > 0 )
    {
        for( BMCServiceDesk__Status__c status :  StatusList )
        {
            StatusMap.put(status.Name,status.Id);
        }//for
    }//if
    
    return StatusMap;
}//private static Map<String,String> problemStatusValues()


//Validation Rule for Parent Problem
/*
* @Purpose : Checks Weather the particular Incident already linked to the specific Problem
*
*/
public static boolean parentIncidentLinkageValidation( BMCServiceDesk__Problem__c[] newObjectVersion,  BMCServiceDesk__Problem__c[] oldObjectVersion  )
{
    
    if((newObjectVersion[0].BMCServiceDesk__Problem_Source__c == 'Incident') && ( newObjectVersion[0].Parent_Incident__c == null ) &&(oldObjectVersion== null) )
    {
        newObjectVersion[0].addError('Please Enter the valid Incident , If problem Source is Incident');
        newObjectVersion[0].Parent_Incident__c.addError('Please Enter the valid Incident , If problem Source is Incident');
        
        return true;
    }
    else
    {
        return false;
    }
    
}//private static void parentIncidentLinkageValidation( String parentIncidentId )


//Use the method On Insert and Update
public static void UpdateStatusOnRootCauseAdd(BMCServiceDesk__Problem__c[] newObjectVersion,  BMCServiceDesk__Problem__c[] oldObjectVersion)
{
    System.debug('Executing : ------> UpdateStatusOnRootCauseAdd()' );
    //Getting New Problem value
    List<BMCServiceDesk__Problem__c> NewProblemvalue = new  List<BMCServiceDesk__Problem__c>();
    NewProblemvalue.addAll(newObjectVersion);
    
    List<BMCServiceDesk__Problem__c> OldProblemvalue = new  List<BMCServiceDesk__Problem__c>();
    if(oldObjectVersion != null)
    {
    //Getting Old Problem value
    OldProblemvalue.addAll(oldObjectVersion); 
    }
    
    //Getting all status Values         
    Map<String,String> status = new Map<String,String>();
    status.putAll( problemStatusValuesNameid() );
    System.debug('ROOT CAUSE DETERMINED :' +status.get('ROOT CAUSE DETERMINED'));
 if( newObjectVersion.size() > 0 && OldProblemvalue.size() > 0 && oldObjectVersion != null )
        {

            //Add logic here if updating the problem
            for( BMCServiceDesk__Problem__c probnew : NewProblemvalue)
            {
                for(BMCServiceDesk__Problem__c probold : OldProblemvalue)
                {
                    if( probnew.Root_Cause__c != probold.Root_Cause__c )
                    probnew.BMCServiceDesk__FKStatus__c = status.get('ROOT CAUSE DETERMINED');
                    
                }//old version
            }//new version
            
            
        }//If Old
      else 
        {
        //Add logic here if creation is new 

        
        }//If new

}//

/* 
 * this method will add the status when ever the know error is checked
 */
public static void updateStatusToKnowError(BMCServiceDesk__Problem__c[] newObjectVersion,  BMCServiceDesk__Problem__c[] oldObjectVersion)
{
    System.debug('Executing : ------> updateStatusToKnowError()' );
    //Getting New Problem value
    List<BMCServiceDesk__Problem__c> NewProblemvalue = new  List<BMCServiceDesk__Problem__c>();
    NewProblemvalue.addAll(newObjectVersion);
    
    List<BMCServiceDesk__Problem__c> OldProblemvalue = new  List<BMCServiceDesk__Problem__c>();
    if(oldObjectVersion != null)
    {
    //Getting Old Problem value
    OldProblemvalue.addAll(oldObjectVersion); 
    }
        //Getting all status Values         
    Map<String,String> status = new Map<String,String>();
    status.putAll( problemStatusValuesNameid() );
    System.debug('ROOT CAUSE DETERMINED :' +status.get('ROOT CAUSE DETERMINED'));
    for(integer i=0;i<newObjectVersion.size();i++)
    {
        if(newObjectVersion[i].BMCServiceDesk__Known_Error__c == true)
        {
            newObjectVersion[i].BMCServiceDesk__FKStatus__c = status.get('KNOWN ERROR');
        }//if
    }//for
}//


/*
*purpose@ This method is used for problem Incident link in Problem Managment
*addresses@  CR 2656731 - Problem Mgmt - Parent Incident not showing linked problems 
*@Developer Hemant Kumar
*@Date: 10-jul-2014
*@usage : Use it After Insert , can be used before and after update
*/
public static void insertIncidentProblemLink()
{
    //solving recursion occuring in the Code
    
    System.debug('--------> Executing insertIncidentProblemLink Method');
    System.debug(' Singleton Problem -------> '+problemObject );
    
    List<Id> currentProbId = new List<Id>();
    List<Id> currentINCId = new List<Id>();
    List<BMCServiceDesk__Problem__c> newProb = new List<BMCServiceDesk__Problem__c>();
    List<BMCServiceDesk__Incident_Problem_Link__c> incprobLnkList  = new List<BMCServiceDesk__Incident_Problem_Link__c>();
    List<BMCServiceDesk__Incident_Problem_Link__c> linkedINCPROBCheck  = new List<BMCServiceDesk__Incident_Problem_Link__c>();
    
    
    for(BMCServiceDesk__Problem__c currProb: problemObject )
    {
    currentProbId.add( currProb.Id );
    currentINCId.add( currProb.Parent_Incident__c );
    }//for(BMCServiceDesk__Problem__c currProb: problemObject )
    
    
    if(currentProbId.size() > 0 )
    {
    newProb = [Select Name,Parent_Incident__c,BMCServiceDesk__Problem_Source__c,Parent_Incident_formula__c from BMCServiceDesk__Problem__c Where Id IN :currentProbId  ];
    linkedINCPROBCheck = [ select id from BMCServiceDesk__Incident_Problem_Link__c where BMCServiceDesk__FKIncident__c IN:currentINCId AND BMCServiceDesk__FKProblem__c IN:currentProbId  ];
    
    if( linkedINCPROBCheck.size() == 0 )
    {
    
    if( newProb.size() > 0 )
    {
        for(BMCServiceDesk__Problem__c currProb: newProb )
        {
            if( currProb.BMCServiceDesk__Problem_Source__c == 'Incident' && (String.isNotBlank(currProb.Parent_Incident__c)))
            {
            System.debug(' NEWLY CREATED PROBLEM -------> '+problemObject );
            BMCServiceDesk__Incident_Problem_Link__c incprblnk = new BMCServiceDesk__Incident_Problem_Link__c();
            incprblnk.BMCServiceDesk__FKProblem__c = currProb.Id;   
            incprblnk.BMCServiceDesk__FKIncident__c = currProb.Parent_Incident__c;  
            incprblnk.Name = currProb.Parent_Incident_formula__c+'_'+currProb.Name;//+'Â'; 
            //Adding the incident object to List
            incprobLnkList.add(incprblnk);
            }//if( currProb.Parent_Incident__c != null || currProb.Parent_Incident__c != '' )
            
        }//for(BMCServiceDesk__Problem__c currProb: newProb )
        
        //inserting the Problem Incident Link
        Database.Saveresult[]  svlist = Database.insert( incprobLnkList );
        for( database.Saveresult sv : svlist )
        {
            if(sv.isSuccess())
            {
                System.debug('[SUCCESS]-----> Problem linked to Incident Successfully !');
            }//if(sv.isSuccess())
            else{
                for(Database.Error err : sv.getErrors())
                {
            System.debug('The following error has occurred.');                    
            System.debug(err.getStatusCode() + ': ' + err.getMessage());
            System.debug('Problem Incident field that affected this error: ' + err.getFields());
            incprobLnkList[0].addError('Problem Incident field that affected this error: ' + err.getFields());
                }//for(Database.Error err : sv.getErrors())
                
            }//else
            
        }//for( database.Saveresult sv : svlist )
        
    }//if( newProb.size() > 0 )
    }//if( linkedINCPROBCheck.size() == 0 )
    else
    {
        problemObject[0].addError('Incident already Linked !');
    }
}//if(currentProbId.size() > 0 )
    
}//public void insertIncidentProblemLink( BMCServiceDesk__Problem__c[] newObjectVersion )

/*
*purpose@ This method is used for getting status name via Id
*addresses@  CR 2610408 - Problem Mgmt - Change field type for Status & Service 
*@Developer Hemant Kumar
*@Date: 15-jul-2014
*@usage : Use it before Insert and update
*/
private static Map<String,String> problemStatusValueIdname()
{
    Map<String,String> StatusMap = new Map<String,String>();
    List<BMCServiceDesk__Status__c> StatusList = new List<BMCServiceDesk__Status__c>();
    StatusList = [ Select Name, Id From BMCServiceDesk__Status__c  WHERE  BMCServiceDesk__appliesToProblem__c = true  LIMIT 100 ];
    if( StatusList.size() > 0 )
    {
        for( BMCServiceDesk__Status__c status :  StatusList )
        {
            StatusMap.put(status.Id,status.Name);
        }//for
    }//if
    
    return StatusMap;
}//private static Map<String,String> problemStatusValues()

/*
*purpose@ This method is used in status picklist value logic in Problem Managment
*addresses@  CR 2610408 - Problem Mgmt - Change field type for Status & Service 
*@Developer Hemant Kumar
*@Date: 15-jul-2014
*@usage : Use it before Insert and update
*/
public static void statusPickListLogic( List<BMCServiceDesk__Problem__c> newObjVersion, List<BMCServiceDesk__Problem__c> oldObjVersion )
{
    System.debug('------>Executing statusPickListLogic method');
  List<BMCServiceDesk__Problem__c> newPrb = new List<BMCServiceDesk__Problem__c>();
  List<BMCServiceDesk__Problem__c> oldPrb = new List<BMCServiceDesk__Problem__c>();
  newPrb.addAll(newObjVersion);
  
  //getting Status List Name-Id Mapped
  Map<String,String> statusNameIdList = new Map<String,String>();
  statusNameIdList.putAll(problemStatusValuesNameid());
  //getting Status List Id-Name Mapped
  Map<String,String> statusIdNameList = new Map<String,String>();
  statusIdNameList.putAll( problemStatusValueIdname() );
  
  
  //check weather oldObjVersion is null
  if( oldObjVersion != null )
  {
    oldPrb.addAll(oldObjVersion);
    for( BMCServiceDesk__Problem__c newprob : newPrb )
    {
        for(BMCServiceDesk__Problem__c oldprob : oldPrb)
        {   
            System.debug('newprob.BMCServiceDesk__FKStatus__c ------> '+newprob.BMCServiceDesk__FKStatus__c);
            System.debug('ID-NAME STATUS---------->'+statusIdNameList.get(newprob.BMCServiceDesk__FKStatus__c));
            if(statusNameIdList.size() > 0 && statusIdNameList.size() > 0  )
            {
                if( oldprob.BMCServiceDesk__FKStatus__c != newprob.BMCServiceDesk__FKStatus__c || newprob.Status_Picklist__c =='' )
                {                   
                    System.Debug('---->FOUND STATUS LOOKUP CHANGED');
                    newprob.Status_Picklist__c = statusIdNameList.get(newprob.BMCServiceDesk__FKStatus__c);
                    
                }//if( oldprob.BMCServiceDesk__FKStatus__c != newprob.BMCServiceDesk__FKStatus__c )
                else
                {
                    System.Debug('---->FOUND STATUS PICKLIST CHANGED');
                    //START Updating a logic to Unset State Field in the Problem for CLOSED status
                    if( newprob.Status_Picklist__c == 'CLOSED')
                    {
                        newprob.BMCServiceDesk__State__c = false;
                    }
                    //END Updating a logic to Unset State Field in the Problem for CLOSED status
                    newprob.BMCServiceDesk__FKStatus__c = statusNameIdList.get( newprob.Status_Picklist__c );
                }
                
            }//if(statusNameIdList.size() > 0 && statusIdNameList.size() > 0  )
            
        }//for(BMCServiceDesk__Problem__c oldprob : oldPrb)
    }//for( BMCServiceDesk__Problem__c newprob : newPrb )
    
  }//if( oldObjVersion != null )
  else if( oldObjVersion == null ) //that means the record is NEW 
  {
    for( BMCServiceDesk__Problem__c newprob : newPrb )
    {
        newprob.Status_Picklist__c = statusIdNameList.get(newprob.BMCServiceDesk__FKStatus__c);
    }
    
  }//else
  
    
}//public static void statusPickListLogic( List<BMCServiceDesk__Problem__c> newObjVersion, List<BMCServiceDesk__Problem__c> oldObjVersion )

}//END of class