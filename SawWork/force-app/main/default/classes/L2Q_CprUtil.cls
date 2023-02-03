/**Author : Rajesh Kumar 
 * JIRA : #SFDC-7368
 * Description : CPR Utility Class 
 */
public without sharing class L2Q_CprUtil {
    // Apex Method to provide Dependent picklist for CPR Functionality  
    @AuraEnabled
    public static Map < String, List < String >> getCountrydependentList() {
        return getDependentPicklistValues(Capacity_Allocation__c.Country__c);
    }
    //Re-Usable Method for getting dependent picklist  //SFDC-7368
    private static Map < String, List < String >> getDependentPicklistValues(Schema.sObjectField dependToken) { //pass valid dependent token to avoid any exception i.e null pointer
        Schema.DescribeFieldResult depend = dependToken.getDescribe();
        Schema.sObjectField controlToken = depend.getController();
        if (controlToken == null) {
            return new Map < String, List < String >> ();
        }
        Schema.DescribeFieldResult control = controlToken.getDescribe();
        List < Schema.PicklistEntry > controlEntries;
        if (control.getType() != Schema.DisplayType.Boolean) {
            controlEntries = control.getPicklistValues();
        }
        String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        Map < String, List < String >> dependentPicklistValues = new Map < String, List < String >> ();
        for (Schema.PicklistEntry entry: depend.getPicklistValues()) {
            if (entry.isActive() && String.isNotEmpty(String.valueOf(((Map < String, Object > ) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')))) {
                List < String > base64chars =
                    String.valueOf(((Map < String, Object > ) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')).split('');
                for (Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++) {
                    Object controlValue =
                        (controlEntries == null ?
                            (Object)(index == 1) :
                            (Object)(controlEntries[index].isActive() ? controlEntries[index].getLabel() : null)
                        );
                    Integer bitIndex = index / 6;
                    if (bitIndex > base64chars.size() - 1) {
                        break;
                    }
                    Integer bitShift = 5 - Math.mod(index, 6);
                    if (controlValue == null || (base64map.indexOf(base64chars[bitIndex]) & (1 << bitShift)) == 0) {
                        continue;
                    }
                    if (!dependentPicklistValues.containsKey((String) controlValue)) {
                        dependentPicklistValues.put((String) controlValue, new List < String > ());
                    }
                    dependentPicklistValues.get((String) controlValue).add(entry.getLabel());
                }
            }
        }
        return dependentPicklistValues;
    }

    public static List < PicklistWrapperClass > getPicklistvalues(Schema.DescribeFieldResult descField, String type) {
            List < PicklistWrapperClass > picklistValue = new List <PicklistWrapperClass > ();
            if (type == 'picklist') {
                PicklistWrapperClass pcNone = new PicklistWrapperClass();
                pcNone.label = '--None--';
                pcNone.value = '';
                picklistValue.add(pcNone);
            }
            try {
                List < Schema.PicklistEntry > picklistEntries = descField.getPickListValues();
                for (Schema.PicklistEntry picklistEntry: picklistEntries) {
                    if (picklistEntry.isActive()) {
                       PicklistWrapperClass pc = new PicklistWrapperClass();
                        pc.label = picklistEntry.getLabel();
                        pc.value = picklistEntry.getValue();
                        picklistValue.add(pc);
                    }
                }
            } catch(exception ex) {
                Sawyer.saw(ex);
                throw new AuraHandledException('System error occured');
            }
            return picklistValue;
        }
    
    // return list of CPR Allocations  //SFDC-7368
    public static List < Capacity_Allocation__c > preparerequestapproveList(List < CPRrequestapprovewrapper > cp, String type) {
        List < Capacity_Allocation__c > ls = new List < Capacity_Allocation__c > ();
        for (CPRrequestapprovewrapper c: cp) {
            Capacity_Allocation__c cf = new Capacity_Allocation__c();
            if (String.isNotBlank(c.recordid)) {
                cf.id = c.recordid;
            } else {
                cf.Associated_CPR__r = new Capacity_Request__c(uniqueid__c = c.parentunqid);
            }

            if (type == 'approval') {
                cf.Approved_Capacity__c = Decimal.valueOf(c.approvedcapacity);
            } else {
                cf.Requested_Capacity__c = Decimal.valueOf(c.allocatedcapacity);
                cf.Country__c = c.country;
                cf.region__c = c.region;
            }
            ls.add(cf);
        }
        return ls;
    }
 @AuraEnabled
 public static string getCPRcountryvalidMapping() {
  return  GSMSettings.getVerbose('L2Q_CPR_Valid_Country_Mapping');
 }

    public class CPRallocationwrapper {
        @AuraEnabled public string recordid;
        @AuraEnabled public string country;
        @AuraEnabled public string region;
        @AuraEnabled public String cprid;
        @AuraEnabled public Decimal allocatedcapacity;
        @AuraEnabled public Decimal approvedcapacity;
       
    }
    public class SchemaWrapper {
        @AuraEnabled public List < dataformationWrapper > schemaData;
        @AuraEnabled public string fieldSet;
        @AuraEnabled public string objName;
        @AuraEnabled public string uomfd;
        @AuraEnabled public Integer recordLimit;
        @AuraEnabled public String orderby;
        @AuraEnabled public String filter;
        @AuraEnabled public string readonlyStatuscondition;
        @AuraEnabled public string timeZone;
        @AuraEnabled public string cpheader;
        @AuraEnabled public boolean approvedFieldenabled;
        @AuraEnabled public String fieldlabelMapping;  // Rajesh SFDC-7368
        @AuraEnabled public String nullclonefield;  // Rajesh SFDC-7368
        @AuraEnabled public String countrysplitreadStatus;  // Rajesh SFDC-7368
    }
    public class DataformationWrapper {
        @AuraEnabled public String fieldType;
        @AuraEnabled public String fieldLabel;
        @AuraEnabled public String fieldapiName;
        @AuraEnabled public List < PicklistWrapperClass > picklistValues;
        @AuraEnabled public String refrencedTo;
        @AuraEnabled public boolean isrequired;
        @AuraEnabled public boolean readonly;
        @AuraEnabled public String helptext;
        @AuraEnabled public string fieldWidth;
        

    }
    public class PicklistWrapperClass {
        @AuraEnabled public string label;
        @AuraEnabled public string value;

    }
    public class CPRrequestapprovewrapper {
        public String parentrecid;
        public String parentunqid;
        public String recordid;
        public String rowunqid;
        public String country;
        public String allocatedcapacity;
        public String approvedcapacity;
        public String region;
        public Integer index;
    }
}