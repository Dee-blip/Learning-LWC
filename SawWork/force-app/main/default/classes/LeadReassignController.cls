/*  CR 3100521 - New Button on Lead Record: "Reassign" 
 Developer - Hitesh Chawda 
Populates Reassign Reason and based on selection, LeadTriggerClass method handle the Reassignment 

Developer - Ruchika
Version: 1.0
Modifed date: 01/03/2018
SFDC-2331: Project Agility- modify lead reassign to support lightening and list view.
*/

public without sharing class LeadReassignController {


      public String leadRecord {get;set;}
      //To DO: list<Id>
    public List<Lead> Leads {get;set;}
    List<string> strIds = new List<string>();
    public String initialURL {get;set;}
    public String errorUnselected {get;set;}

    public LeadReassignController(ApexPages.StandardSetController controller) {
          
          controller.setPageSize(10);
             Leads = new List<Lead>();
          Leads = (List<Lead>)controller.getSelected();
          //comma separated list id?
          List<String> leadIds = new List<String>();
          for(Lead ld: Leads)
            leadIds.add(ld.id);

          system.debug(LoggingLevel.ERROR,'lstLeads:: '+Leads);
           System.PageReference prf= controller.cancel();
           initialURL = prf.getUrl();
           //id parameter will get passed by LeadReassignDetailController when called from detail view 
           //check if the invocation is from list view
           //To do: try if you can get the list view call from redirctor page.
           String curPageId = ApexPages.currentPage().getParameters().get('id');
           if(curPageId!=null){
                leadIds.clear();
                leadIds.add(curPageId);
           }
           leadRecord = json.serialize(leadIds);
           system.debug(LoggingLevel.ERROR,'leadRecord is isEmpty: '+leadIds.isEmpty());
            if(leadIds.isEmpty())
                errorUnselected = 'Please select atleast one record';


    }

//List<Lead>
//To do: pass string to lightening and get back.
      @AuraEnabled
    public static List<Lead> fetchLead(List<String> leadIds){
        List<Lead> ld = new List<Lead>();
        system.debug(LoggingLevel.ERROR,'LeadId:: '+leadIds);
        try {
            String query ='Select id,Reassign_Reason__c, Reassign__c,Reassign_Comments__c,ownerId,recordtype.name,Partner_Involved__c from lead where id IN :leadIds';
            system.debug(LoggingLevel.ERROR,'query:: '+query);
            ld = Database.query(query);
            AuraHandledException e=null;
            Id profileId= userinfo.getProfileId();

            if(ld.size()==0){
                         e = new AuraHandledException('No Lead Found');
                        e.setMessage('No Lead Found');
                    }
            for(Lead lsRec: ld){
                if ( lsRec.recordtype.name=='Converted Lead') {
                    //MARIT-1203 access to certain marketing profile to reassign owner for converted leads
                        //if(lsRec.size()==1){
                    if((MarketingUtilClass.getMarketingSettingsValue('ProfilesToReassignOwnerForConvertedLead') != null) && (!MarketingUtilClass.getMarketingSettingsValue('ProfilesToReassignOwnerForConvertedLead').contains(profileId)))
                    {
                            String Message = GsmUtilClass.getGSMSettingValue('converted_leads_error');
                             e = new AuraHandledException(Message);
                            e.setMessage(Message);
                        //}
                     }   
                }
            }
            if(e!=null){
                        throw e;
                    }
        } catch (QueryException e){
            System.debug(LoggingLevel.ERROR,'No record was found for the Id provided. Returning null Record');
        }
        return ld;
    }

    //MARIT-934
    @AuraEnabled
    public static Boolean fetchUserProfile(List<String> leadIds)
    {
      Id profileId= userinfo.getProfileId();
      List<Lead> ld = new List<Lead>();
      String query ='Select id,recordtype.name from lead where id IN :leadIds';
      Boolean result = false;
      String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
      system.debug(Logginglevel.ERROR,'Profile Name:'+profileName);
      ld = Database.query(query);
      AuraHandledException e=null;
      if(ld.size()==0)
      {
        e = new AuraHandledException('No Lead Found');
        e.setMessage('No Lead Found');
      }
      for(Lead lsRec: ld)
      {
        if ( lsRec.recordtype.name=='Partner Lead') 
        {
            return true;   
          }
      }
      if(MarketingUtilClass.getMarketingSettingsValue('RestrictReassignCTAProfiles').contains(profileName))
      {
        return false;
      }
      return true;
    }

    @AuraEnabled
    public static List<Lead> fetchLeadQA(String leadIds){
        List<Lead> ld = new List<Lead>();
         try {
            String query ='Select id,Reassign_Reason__c, Reassign__c,Reassign_Comments__c,ownerId,recordtype.name,Partner_Involved__c from lead where id =\''+leadIds+'\'';
            ld = Database.query(query);
            AuraHandledException e=null;
            Id profileId= userinfo.getProfileId();
            
            if(ld.size()==0){
                         e = new AuraHandledException('No Lead Found');
                        e.setMessage('No Lead Found');
                    }
            for(Lead lsRec: ld){
              //MARIT-1203 access to certain marketing profile to reassign owner for converted leads
                if ( lsRec.recordtype.name=='Converted Lead') {
                    if((MarketingUtilClass.getMarketingSettingsValue('ProfilesToReassignOwnerForConvertedLead') != null) && (!MarketingUtilClass.getMarketingSettingsValue('ProfilesToReassignOwnerForConvertedLead').contains(profileId)))
                    {
                      String Message = GsmUtilClass.getGSMSettingValue('converted_leads_error');
                      e = new AuraHandledException(Message);
                      e.setMessage(Message);
                     }       
                }
            }
            if(e!=null){
                        throw e;
                    }
        } catch (QueryException e){
            System.debug(LoggingLevel.ERROR,'No record was found for the Id provided. Returning null Record');
        }
        return ld;
    }

    @AuraEnabled
    public static String getUIThemeDescription() {
        String theme = UserInfo.getUiThemeDisplayed();
        return theme;
    }

@AuraEnabled
public static List<String> getLeadQueues(){
    List<QueueSobject> queueIdList = [select QueueId from QueueSobject where SobjectType = 'Lead'];
    List<String> queueIds = new List<String>();
    for(QueueSobject qsObj: queueIdList)
        queueIds.add('\''+qsObj.QueueId+'\'');
    return queueIds;
}

@AuraEnabled
public static void save(String userValue,String reassignReasonValue,List<String> leadIds,Id OwnerId) {

List<Lead> leadRecords = new List<Lead>();
Map<Id, Boolean> leadIdToForceRunMap = new Map<Id, Boolean>();//MARIT-339
List<FeedItem> chatterRecords = new List<FeedItem>();
for(Id leadId: leadIds){
    Lead leadRecord = new Lead(Id=leadId);
    if(!String.isBlank(reassignReasonValue)){
            leadRecord.Reassign_Comments__c = reassignReasonValue;
            // MARIT-642
            FeedItem chatterInstance = MARIT_ChatterUtilClass.createChatterInstance(leadId, 
                                                                         null, 
                                                                         '<b>Reassign Comments : </b>' + reassignReasonValue,
                                                                        true);
            chatterRecords.add(chatterInstance);
        }
        if(userValue.equals('assignUser')|| userValue.equals('assignQ') || userValue.equals('assignPU')){
            leadRecord.Reassign__c = False;
            leadRecord.OwnerId=OwnerId;
            leadRecord.Reassigned_Date__c = Datetime.now();
            leadRecord.Validation_Override__c = True;
        } 
      
      Id partnerRecordypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Partner Lead').getRecordTypeId();
        if (userValue.equals('assignPU')) {
            leadRecord.RecordTypeId = partnerRecordypeId;

        }
        
        leadRecord.Reassigned_By__c = UserInfo.getName();
        leadRecords.add(leadRecord);
        leadIdToForceRunMap.put(leadRecord.id, true);//MARIT-339
    }
    if(userValue.equals('RunRules'))
        LeadTriggerClass.runLeadReassignmentRules(leadRecords, leadIdToForceRunMap);

    try{
        if(!leadRecords.isEmpty() && (userValue.equals('assignUser') || userValue.equals('assignPU') || userValue.equals('assignQ')))
            update leadRecords;
        if (!chatterRecords.isEmpty()) {
        	MARIT_ChatterUtilClass.insertChatters(chatterRecords);
        }
            if (userValue.equals('assignPU')) {
              sendEmailToPartner(leadRecords);
            }
            //GsmUtilClass.doDatabaseUpdate(leadRecords,'LeadReassignController','LeadReassignController.save()');
    }
    catch(Exception ex){
        AuraHandledException e=null;
        e = new AuraHandledException(ex.getMessage());
        e.setMessage(ex.getMessage());
        if(e!=null)
           throw e;
            
        }
  }

  @AuraEnabled 
  public static void sendEmailToPartner(List<Lead> partnerLeads) {

    List<id> leadids = new List<Id>();
    for (lead l:partnerLeads) {
      leadids.add(l.id);
    }

    List<Lead> leadsForMail = [Select id,OwnerId, Owner.Email From Lead where id IN:leadids];


    String templateValue;
    templateValue = GsmUtilClass.getGSMSettingValue('PartnerLeadReassignTemplateId');
    if(Test.isRunningTest())
        templateValue = GSMSettings.getValue('LeadConversion_ESR_TemplateId');

    if (templateValue != null && templateValue != '') {

      List<Messaging.Singleemailmessage> emailList = new List<Messaging.Singleemailmessage>();

      for (Lead l:leadsForMail) {
        Messaging.Singleemailmessage email = new Messaging.Singleemailmessage();
        email.setTemplateId(templateValue); 
        email.setSaveAsActivity(false);
        List<String> toEmail = new List<String>();
        if(Test.isRunningTest())
            toEmail.add('testrunning@akamai.com');
        if(l.Owner.Email!=null)
            toEmail.add(l.Owner.Email);
        email.setTargetObjectId(l.id);
        email.setToAddresses(toEmail);
        emailList.add(email);

      }

      if(emailList.size() > 0) {
          Messaging.SendEmailResult [] r = Messaging.sendEmail(emailList);
      }
      
    }
  }

}