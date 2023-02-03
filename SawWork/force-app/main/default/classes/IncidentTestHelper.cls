/*
* File Name: IncidentTestHelper
* Description : Builder class for the 'BMCServiceDesk__Incident__c' object to be used in test classes
* @author : 
* Modification Log ===============================================================
* Date 				Author 				Modification
* Oct 13th, 2020    Aneesh Budnar       PRTORES-1966 - HD Service Request Field Level Encryption , Team level bifurcation and data integrity
*/
public class IncidentTestHelper {
        
    /*
    * Builder class that build the 'BMCServiceDesk__Incident__c' object.
    */
    public class IncidentBuilder{
        private BMCServiceDesk__Incident__c record;
        
        public IncidentBuilder() {
            record = new BMCServiceDesk__Incident__c(
                HD_Ticket_Priority__c = '4', 
                BMCServiceDesk__FKClient__c = System.userInfo.getUserId(),
                BMCServiceDesk__FKUrgency__c = HD_Test_Data_Factory.urgencyMap.get('Severity 3'),
                BMCServiceDesk__FKImpact__c = HD_Test_Data_Factory.impactMap.get('LOW'),
                BMCServiceDesk__FKCategory__c = HD_Test_Data_Factory.categoryMap.get('P2R'),
                BMCServiceDesk__incidentDescription__c = 'Test Data Description values');
        }
        
        public IncidentBuilder(BMCServiceDesk__Incident__c incident) {
            record = incident.clone();
        }
         
        public IncidentBuilder withClient(Id userId) {
            record.BMCServiceDesk__FKClient__c = userId;
            return this;
        }
         
        public IncidentBuilder withRecordTypeId(String recordTypeId) {
            record.RecordTypeId = recordTypeId;
            return this;
        }
         
        public IncidentBuilder withDescription(String description) {
            record.BMCServiceDesk__IncidentDescription__c = description;
            return this;
        }
         
        public IncidentBuilder withVIPStatus(Boolean isVIPTicket) {
            record.VIP_Ticket__c = isVIPTicket;
            return this;
        }

        public IncidentBuilder withCategory(Id categoryId) {
            record.BMCServiceDesk__FKCategory__c = categoryId;
            return this;
        }
         
        public IncidentBuilder withIncidentGroup(String incidentGroup) {
            record.HD_IncidentGroup__c  = incidentGroup;
            return this;
        }
         
        public IncidentBuilder withRegion(String region) {
            record.HD_HR_Region__c  = region;
            return this;
        }
         
        public IncidentBuilder withSRTitle(String srTitle) {
            record.BMCServiceDesk__Service_Request_Title__c  = srTitle;
            return this;
        }
        
        public IncidentBuilder withResolution(String resolution) {
            record.BMCServiceDesk__incidentResolution__c = resolution;
            return this;
        }
        
        public IncidentBuilder withEffort(String effort) {
            record.Effort_Estimation__c = effort;
            return this;
        }
        
        public IncidentBuilder withSupportType(String supportType) {
            record.Support_Type__c = supportType;
            return this;
        }
        
        public BMCServiceDesk__Incident__c build() {
            return record;
        }
        
        public BMCServiceDesk__Incident__c buildAndSave() {
            insert record;
            return record;
        }
    }

}