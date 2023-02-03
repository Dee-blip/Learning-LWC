public with sharing class CPQ_CloneHandler {

    private List<sObject> insertedRecords;
    private List<sObject> insertRecords;

    public CPQ_CloneHandler() {
        this.insertedRecords = new List<SObject>();
        this.insertRecords = new List<SObject>(); 
    }

    public List<sObject> run(CPQ_SobjectClone cloneInstance){

        this.insertRecords = cloneInstance.beforeClone();

        if(insertRecords.size() > 0){
            Insert insertRecords;
            this.insertedRecords = cloneInstance.afterClone(insertRecords);
        } 
        //if this operation throws any exception the calling function should handle it. 
        return this.insertedRecords;
    }
}