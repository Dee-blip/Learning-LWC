//SFDC-1435
public with sharing class FieldOperatorConditionWrapper {
    
    //    private String fullCondition;
    //public FieldOperatorCondition fullCondition1;
    //public FieldOperatorCondition fullCondition2;
    public List<FieldOperatorCondition> conditions;
    public List<String> operatorTypes;

    //public FieldOperatorCondition(String fieldName, String Operator, String Condition){
    //        this.fieldName = fieldName;
    //        this.Operator = Operator;
    //        this.Condition = Condition;
    //        if(!String.isBlank(Condition))
    //          operatorType = 'Binary';
    //        else
    //          operatorType = 'Unary';
    //}
    //public FieldOperatorCondition(String fullCondition){

        
    //}

    

    //public void setFullCondition1(FieldOperatorCondition fullCondition1){
    //  this.fullCondition1 = fullCondition1;
    //}

    //public void setFullCondition2(FieldOperatorCondition fullCondition2){
    //  this.fullCondition2 = fullCondition2;
    //}

    //public void setOperator(String Operator){
    //  this.Operator = Operator;
    //}

    //public void setOperatorType(String operatorType){
    //  this.operatorType = operatorType;
    //}


       public static Boolean conditionChecker(Sobject sobjRecord,FieldOperatorConditionWrapper focWrapperInstance){
           system.debug(LoggingLevel.ERROR,':focWrapperInstance: '+focWrapperInstance);
        if(focWrapperInstance==null)
            return null;
        List<Boolean> conditionInterpretationList = new List<Boolean>();
        for(Integer index=0; index<focWrapperInstance.conditions.size();index++){
            Boolean conditionInterpretation = false;
            FieldOperatorCondition focInstance = focWrapperInstance.conditions.get(index);
             
            if(focInstance.operatorType.equalsIgnoreCase('Binary')){
                
                String fieldValue = String.valueOf(sobjRecord.get(focInstance.fieldName));
                if(fieldValue!=null){
                    if(focInstance.Operator == '=' || focInstance.Operator == '==')
                        conditionInterpretation = fieldValue.equalsIgnoreCase(focInstance.Condition);
                    if(focInstance.Operator == '!=')
                        conditionInterpretation = !fieldValue.equalsIgnoreCase(focInstance.Condition);
                    if(focInstance.Operator.equalsIgnoreCase('like'))
                        conditionInterpretation = fieldValue.contains(focInstance.Condition);
                    if(focInstance.Operator == '<')
                        conditionInterpretation = fieldValue < focInstance.Condition;
                    if(focInstance.Operator == '>')
                        conditionInterpretation = fieldValue > focInstance.Condition;
                }
                    //Consider IN
            }else{
                Boolean fieldValue = (Boolean)sobjRecord.get(focInstance.fieldName);
                if(focInstance.Operator.equalsIgnoreCase('NOT') || focInstance.Operator == '!')
                    conditionInterpretation = !fieldValue;
            }
            conditionInterpretationList.add(conditionInterpretation);
        }
        system.debug(LoggingLevel.ERROR,'conditionInterpretationList:: '+conditionInterpretationList);
        system.debug(LoggingLevel.ERROR,'focWrapperInstance.operatorTypes:: '+focWrapperInstance.operatorTypes);
        Boolean firstCondition = null;
        if(!conditionInterpretationList.isEmpty())
            firstCondition = conditionInterpretationList.get(0);
        if(focWrapperInstance.operatorTypes!=null && !focWrapperInstance.operatorTypes.isEmpty() && !conditionInterpretationList.isEmpty()){
            
            for(Integer index=1; index<conditionInterpretationList.size();index++){
                    String operator = focWrapperInstance.operatorTypes.get(index-1);
                    Boolean otherCondition = false;
                    //if(index<conditionInterpretationList.size()-1){
                   
                        otherCondition = conditionInterpretationList.get(index);
                    //}
                    if(operator.equalsIgnoreCase('AND') || Operator=='&&')
                        firstCondition = firstCondition && otherCondition;
                    if(operator.equalsIgnoreCase('OR') || Operator=='||')
                        firstCondition = firstCondition || otherCondition;

                }
        }
        system.debug(LoggingLevel.ERROR,' firstCondition: '+firstCondition+' focWrapperInstance: '+focWrapperInstance);
        return firstCondition;
    }

    public static FieldOperatorConditionWrapper populateFieldOperatorConditions(String fullCondition){
        //this.fullCondition = fullCondition;
        system.debug(LoggingLevel.ERROR,'rsh fullCondition: '+fullCondition);
        if(String.isBlank(fullCondition))
            return null;
        FieldOperatorConditionWrapper focWrapperInstance = new FieldOperatorConditionWrapper();
        focWrapperInstance.conditions = new List<FieldOperatorCondition>();
        focWrapperInstance.operatorTypes = new List<String>();
        
        //system.debug(LoggingLevel.ERROR,'rsh contains: '+fullCondition.contains('\n'));

        if(!fullCondition.contains('\n') && !fullCondition.contains('\r')){
            FieldOperatorCondition focInstance = new FieldOperatorCondition();
            focInstance.setInstanceVars(fullCondition);
            focWrapperInstance.conditions.add(focInstance);
        }else{
            List<String> splittedCondition = new List<String>();
            if(fullCondition.contains('\n\r'))
                splittedCondition = fullCondition.split('\n\r');
            if(fullCondition.contains('\n'))
                splittedCondition = fullCondition.split('\n');
            if(fullCondition.contains('\r'))
                splittedCondition = fullCondition.split('\r');
            //check if the condition mentioned are valid
            Integer splittedConditionSize = splittedCondition.size();
            system.debug(LoggingLevel.ERROR,' splittedCondition.size(): '+splittedConditionSize);
            if(Math.mod(splittedConditionSize,2)!=0){
                    for(Integer index=0; index<splittedConditionSize;index++){
                        String condn = splittedCondition.get(index);
                        FieldOperatorCondition focInstance = new FieldOperatorCondition();
                        focInstance.setInstanceVars(condn);
                        focWrapperInstance.conditions.add(focInstance);
                        if(index<splittedConditionSize-1){
                            index++;
                            focWrapperInstance.operatorTypes.add(splittedCondition.get(index).trim());
                        }
                    }
                }else{
                    system.debug(LoggingLevel.ERROR,' splittedCondition.size() not odd: '+splittedCondition.size());
                    Error_Log__c elc = new Error_Log__c(Name='FieldOperatorConditionWrapper', Class__c='FieldOperatorConditionWrapper', Error_Message__c=fullCondition+' is not proper as it has '+splittedCondition.size()+' lines.');
                    insert elc;
                }
        }

        system.debug(LoggingLevel.ERROR,':focInstance: '+focWrapperInstance);
        return focWrapperInstance;
    }

public class FieldOperatorCondition{
    public String fieldName;
    private String Operator;
    private String Condition;
    private String operatorType;

    private void setInstanceVars(String fullCondition){
        List<String> fullConditionList = new List<String>();

        if(fullCondition.indexOf(' ')!=-1)
            fullConditionList = fullCondition.split(' ');
        //Check for fullConditionList size for unary or binary operation.
        if(!fullConditionList.isEmpty()){
            this.fieldName = fullConditionList[0].trim();
            this.Operator = fullConditionList[1].trim();
            this.operatorType = 'Unary';
            if(fullConditionList.size()==3){
                this.Condition = fullConditionList[2].trim();
                this.operatorType = 'Binary';
            }
        }
    }
}
 //   public String getFieldName(){
 //     return fieldName;
 //   }

    //public String getOperator(){
 //     return Operator;
 //   }

 //   public String getCondition(){
 //     return Condition;
 //   }

 //   public String getOperatorType(){
 //     return operatorType;
 //   }    

    //public String convertSeparatorToSpace(){
    //  //Check if fullCondition has other separator than space e.g. -, * etc.
    //  //count num of occurence of other separator, if its 2, convert them to space.
    //  //if(fullCondition.indexOf('-')!=-1 AND fullCondition.indexOf(' ')==-1)
    //}

 //   private static integer countOccurrences(String baseStr, String toCount)
    //{
    //    integer count = 0;
    //    for (integer i=0; i < baseStr.length(); i++)
    //    {
    //        if (baseStr.charAt(i) == toCount)
    //        {
    //             count++;
    //        }
    //    }
    //    return count;
    //}
}