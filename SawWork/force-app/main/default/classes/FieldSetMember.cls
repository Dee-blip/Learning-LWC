/**
   History
      
      --Developer       --Date         --Description        --Story
      Ruchika sharma    18/04/2017     Created this Class   SFDC-1548
        
*/
public class FieldSetMember {

    public FieldSetMember(Schema.FieldSetMember f ) {
        this.DBRequired = f.DBRequired;
        this.fieldPath = f.fieldPath;
        this.label = f.label;
        this.required = f.required;
        this.type = '' + f.getType();
        
    }

    public FieldSetMember(Boolean DBRequired) {
        this.DBRequired = DBRequired;
    }

    @AuraEnabled
    public Boolean DBRequired { get;set; }

    @AuraEnabled
    public String fieldPath { get;set; }

    @AuraEnabled
    public String label { get;set; }

    @AuraEnabled
    public Boolean required { get;set; }

    @AuraEnabled
    public String type { get; set; }

    @AuraEnabled
    public Object value { get;  private set;}


    public void setValue(sObject sobjRecord){
        if(sobjRecord!=null){
            this.value = sobjRecord.get(fieldPath);
            system.debug(LoggingLevel.ERROR,'value: '+this.value);
        }
    }
}