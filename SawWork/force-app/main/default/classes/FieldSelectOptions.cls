public with sharing class FieldSelectOptions {
   private String objectName;
   private List<SelectOption> options = new List<SelectOption>();
   
   public FieldSelectOptions(String objectName,String fieldType) {
     this.objectName = objectName;
     Schema.SObjectType ot = Schema.getGlobalDescribe().get(objectName);
     System.assert(ot != null, 'Unknown object name "' + objectName + '" in schema ' + Schema.getGlobalDescribe());
     init(ot, fieldType);
   }
   
   public FieldSelectOptions(Schema.SObjectType ot,String fieldType) {
     init(ot, fieldType);
   }
   
   private void init(Schema.SObjectType ot,String fieldType) {
   	 options.add(new SelectOption('', ''));
     Map<String,Schema.SObjectField> fields = ot.getDescribe().fields.getMap();
     options.clear();
     
     Map<String,String> fieldMap = new Map<String,String>();
     List<String> fieldNames = new List<String>();
     for (String fn : fields.keySet()) {
       Schema.DescribeFieldResult f = fields.get(fn).getDescribe() ;
       if (fieldType != null ) {
       	   if (fieldType.equals(Util.NUMBER_TYPE)) {
		       if(f.getType() == Schema.DisplayType.PERCENT || f.getType() == Schema.DisplayType.DOUBLE) { 
		         fieldNames.add(f.getLabel());
		         fieldMap.put(f.getLabel(),f.getName());
		       }
       	   } else if (fieldType.equals(Util.STRING_TYPE)) {
               if(f.getType() == Schema.DisplayType.STRING || f.getType() == Schema.DisplayType.PICKLIST) { 
		         fieldNames.add(f.getLabel());
		         fieldMap.put(f.getLabel(),f.getName());
		       }       
		   } else if (fieldType.equals(Util.NUMBER_STRING_TYPE)) {
               if(f.getType() == Schema.DisplayType.STRING || f.getType() == Schema.DisplayType.Integer || f.getType() == Schema.DisplayType.ID) { 
		         fieldNames.add(f.getLabel());
		         fieldMap.put(f.getLabel(),f.getName());
		         
		       }  
       	   }  else {
       	   	     fieldNames.add(f.getLabel());
		         fieldMap.put(f.getLabel(),f.getName());
       	   }
       } else {
		    fieldNames.add(f.getLabel());
		    fieldMap.put(f.getLabel(),f.getName());
            
       }
     }
     if(fieldNames.size() > 0) {
     	fieldNames.sort();
     	for(String fieldName : fieldNames) {
     		options.add(new SelectOption(fieldMap.get(fieldName), fieldName));
     	}
     }
   }
 
   public List<SelectOption> getOptions() {
     return options;
   }

}