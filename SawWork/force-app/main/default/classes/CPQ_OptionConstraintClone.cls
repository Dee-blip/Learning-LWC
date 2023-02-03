public with sharing class CPQ_OptionConstraintClone extends CPQ_SobjectClone{

    private Id sourceProductId;
    private Id newProductId;
    public Map<Id,Id> optionIdMap{get; private set;}
    // public Map<Id, SBQQ__ProductOption__c> contstrainingOption {get; private set;}

    public CPQ_OptionConstraintClone(Id sourceProductId, Id newProductId,  Map<Id, Id> optionIdMap) {
        super('SBQQ__OptionConstraint__c');
        
        this.sourceProductId = sourceProductId;
        this.newProductId = newProductId;
        this.optionIdMap = optionIdMap;

        // contstrainingOption = new Map<Id, SBQQ__ProductOption__c>();

    }

    public override List<Sobject> beforeClone(){

        List<SObject> clonedRecords = new List<Sobject>();
        Map<String, Sobject> keyOCMap = new Map<String, Sobject>();

        if(sourceProductId != null){

            String parentQuery =
            ' SELECT ' +
            String.join( parentFieldNames, ',' ) +
            ' FROM ' +
            sObjectType +
            ' WHERE ' +
            ' SBQQ__ConfiguredSKU__c = :sourceProductId ' 
            ;
            //would need a map<productId, Map<featureId, featureNumber>>
            //
            // Set<Id> constrainedIds = new Set<Id>();

            List<SObject> parentRecords = Database.query( parentQuery );
    
            for(Integer i = 0; i < parentRecords.size(); i++){
                String key = this.uniqueKey((SBQQ__OptionConstraint__c)parentRecords[i]);
                Sobject clone = parentRecords[i].clone(false, true);
                keyOCMap.put(key, clone);
                // contstrainingOption.add(Id(clone.get('SBQQ__configuredSKU__c')));
            
            }

            // contstrainingOption = new Map<Id,Product2>([SELECT Id, Name, ProductCode FROM SBQQ__ProductOption__c WHERE SBQQ__ConfiguredSKU__c IN :constrainedIds]);

        }
       

        clonedRecords = createOptionContraint(keyOCMap);

        for(Integer i = 0; i < clonedRecords.size(); i++){
            // clonedRecords[i].put('CPQExternalID__c', '');
            clonedRecords[i].put('SBQQ__ConfiguredSKU__c', this.newProductId);
        }

        return clonedRecords;

    }

    public override List<SObject> afterClone(List<SObject> clonedRecords){

        return clonedRecords;
    }

    private List<Sobject> createOptionContraint(Map<String, SObject> sourceOCMap){

        List<Sobject> returnList = new List<sobject>();

        Map<String,Constrains> constraintsMap = new Map<String,Constrains>();

        for(SBQQ__ProductOption__c item: [SELECT Id, CPQ_Charge_Type__c, CPQ_ListItemGroup__c, CPQ_ListItemSet__c, CPQ_Measurement__c, CPQ_Billing_Model__c, CPQ_Billing_Frequency__c, SBQQ__ConfiguredSKU__c, SBQQ__ProductName__c FROM SBQQ__ProductOption__c WHERE CPQ_ListItemGroup__c != null AND SBQQ__ConfiguredSKU__c = :this.newProductId]){
            
            if(!constraintsMap.containsKey(item.CPQ_ListItemSet__c)){
                constraintsMap.put(item.CPQ_ListItemSet__c, new Constrains(item.CPQ_ListItemSet__c));
            }
            
            Constrains tempConstraints = constraintsMap.get(item.CPQ_ListItemSet__c);

            if (item.CPQ_Charge_Type__c.equalsIgnoreCase('Flat Fee')) { 
                tempConstraints.constrainedOption = item;
            } else {
                tempConstraints.constrainingOptions.add(item);
            }

            constraintsMap.put(item.CPQ_ListItemSet__c,tempConstraints);
        
        }

        // for(Id configSKU: this.sourceProductIds){

        List<SBQQ__OptionConstraint__c> tempList = new List<SBQQ__OptionConstraint__c>();
       
        for(String setName: constraintsMap.keySet() ){
            tempList.addAll(this.generateConstraints(constraintsMap.get(setName), this.newProductId));
        }

            
            //check if the cloned map has rule with same name, if it is newly added then ignore. if it is old then we need to 
        for(SBQQ__OptionConstraint__c item: tempList){
            String key = this.uniqueKey(item);
            System.debug(' oc key ' + key);
            if(sourceOCMap.containsKey(key)){
                sourceOCMap.remove(key);
            }
            returnList.add((SObject)item);
        }
        // }

        if(!sourceOCMap.isEmpty()){
            
            for(String key: sourceOCMap.keySet()){
                
                SBQQ__OptionConstraint__c temp = (SBQQ__OptionConstraint__c)sourceOCMap.get(key);
                if(optionIdMap.get(temp.SBQQ__ConstrainingOption__c) != null && optionIdMap.get(temp.SBQQ__ConstrainedOption__c) != null){
                    temp.SBQQ__ConstrainingOption__c = optionIdMap.get(temp.SBQQ__ConstrainingOption__c);
                    temp.SBQQ__ConstrainedOption__c = optionIdMap.get(temp.SBQQ__ConstrainedOption__c);
                    returnList.add((SObject)temp);
                }   
            }
        }

        return returnList;
    }

    private List<SBQQ__OptionConstraint__c> generateConstraints(Constrains constraint, Id configuredSKU){

        List<SBQQ__OptionConstraint__c> returnList = new List<SBQQ__OptionConstraint__c>();
        if(constraint.constrainedOption == null){
            return returnList;
        }
        for(SBQQ__ProductOption__c po: constraint.constrainingOptions){
            returnList.add(this.createOptionContraintRecord(po, constraint.constrainedOption, configuredSKU));
        }
        return returnList;

    }

    private SBQQ__OptionConstraint__c createOptionContraintRecord(SBQQ__ProductOption__c constrainingOption, SBQQ__ProductOption__c constrainedOption, Id configSKU){

        SBQQ__OptionConstraint__c returnLine = new SBQQ__OptionConstraint__c();

        returnLine.name = constrainingOption.SBQQ__ProductName__c  + ':' + constrainedOption.SBQQ__ProductName__c ;
        returnLine.SBQQ__Type__c = 'Dependency';
        returnLine.SBQQ__ConfiguredSKU__c = configSKU;
        returnLine.SBQQ__ConstrainingOption__c = constrainingOption.Id;
        returnLine.SBQQ__ConstrainedOption__c = constrainedOption.Id;
        returnLine.SBQQ__Active__c = true;

        return returnLine;

    }

    private class Constrains{

        protected SBQQ__ProductOption__c constrainedOption{set; get;} //i.e flat fee
        protected List<SBQQ__ProductOption__c> constrainingOptions{set; get;} //i.e >20TB commits
        protected String criteria{private set; get;}

        private Constrains(String criteria){
            this.criteria = criteria;
            this.constrainingOptions = new List<SBQQ__ProductOption__c>();
        }

    }

    private String uniqueKey(SBQQ__OptionConstraint__c oc){
        
        return (String)oc.Name;

    }
}