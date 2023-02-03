public class BucherSuter_ACD_PageLayoutClass {
    
    public BucherSuter_ACD_PageLayoutClass()  {
            
    }
    
    public class LayoutWrapper {
        String sectionName;
        Integer sectionOrder;
        String recordTypeId;
        List<FieldWrapper> fields;

        public LayoutWrapper(String name, Integer order) {
            sectionName = name;
            sectionOrder = order;
            fields = new List<FieldWrapper>();
        }
        
    }
    
    public class FieldWrapper {
        string fieldName;
        string fieldValue;
        Boolean fieldValueBoolean;
        Boolean isBoolean;
        Boolean isRequired;
        Boolean isVisible;
        Boolean isReadonly;
        
        public FieldWrapper(String name, String value,Boolean booleanValue
                            ,Boolean required, Boolean readOnly, Boolean visible,Boolean booleanField) {
            fieldName = name;
            fieldValue = value;
            fieldValueBoolean = booleanValue;
            //order = fieldOrder;
            isRequired = required;
            isVisible = visible;
            isReadonly = readOnly;
            isBoolean = booleanField;
        }
        
    }
    
    @AuraEnabled
    public static String getFieldWrapper(String objectName, String recordType, String lob, String defaultValues ) {
        System.debug('objectname: ' + objectName);
        System.debug('rt: ' + recordType);
        
        
        Map<String,String> defValueMap = new Map<String,String>();
        if (defaultValues != null && defaultValues != '') {
            List<String> st = defaultValues.split(',');
            for (String s : st) {
                String[] ss = s.split('=');
                if (ss.size() == 2) {
                    defValueMap.put(ss[0],ss[1]);
                }
            }
        }
        
        
        
        Map<Integer,LayoutWrapper> sectionsMap  = new Map<Integer,LayoutWrapper>();

        LayoutWrapper sectionWrapperObject;
        FieldWrapper fieldWrapperObject;

        string recordTypeSearch = lob + '%';
        Integer sectionOrder;
        Boolean boolValue;
        Boolean boolField = false;
        System.debug('objectName is ' + objectName);
         System.debug('rt name is ' + recordType);
         System.debug('lob is  ' + lob);
        
        Id recordTypeIdValue = Schema.getGlobalDescribe().get(objectName).getDescribe().getRecordTypeInfosByName().get(recordType).getRecordTypeId();
        
        for(ACD_Custom_Page_Layout__mdt layoutRec: [Select IsBoolean__c, Default_Value__c ,Field__c ,Field_Order__c ,Read_Only__c , 
                                                Required__c , Section__c , Section_Order__c ,
                                                Visible_On_UI__c   from ACD_Custom_Page_Layout__mdt   
                                              where Object__c  = :objectName and 
                                                DeveloperName like :recordTypeSearch order by Section_Order__c,Field_Order__c]) {
                system.debug('layoutRec: ' + layoutRec);
                sectionOrder = layoutRec.Section_Order__c == 0.0? 1: Integer.valueOf(layoutRec.Section_Order__c);
                 if(!sectionsMap.containsKey(sectionOrder)) {
                     sectionWrapperObject = new  LayoutWrapper(layoutRec.Section__c,sectionOrder);
                      sectionsMap.put(sectionOrder,sectionWrapperObject);  
                }

                sectionWrapperObject = sectionsMap.get(sectionOrder);
                if(layoutRec.Field__c == 'RecordTypeId') {
                    sectionWrapperObject.recordTypeId = String.valueOf(recordTypeIdValue);
                } else {
                    boolValue = layoutRec.IsBoolean__c && layoutRec.Default_Value__c != null? Boolean.valueOf(layoutRec.Default_Value__c) : null;
                    boolField = boolValue != null ? true : false;
                    if (defValueMap.get(layoutRec.Field__c) != null) {
                        layoutRec.Default_Value__c = defValueMap.get(layoutRec.Field__c);
                    }
                    fieldWrapperObject = new FieldWrapper(layoutRec.Field__c, layoutRec.Default_Value__c,boolValue
                            ,layoutRec.Required__c, layoutRec.Read_Only__c, layoutRec.Visible_On_UI__c, boolField);
                
                     sectionWrapperObject.fields.add(fieldWrapperObject);
                    
                }
               sectionsMap.put(sectionOrder,sectionWrapperObject);  
                
            
        }
        return JSON.serialize(sectionsMap.values());
    }
}